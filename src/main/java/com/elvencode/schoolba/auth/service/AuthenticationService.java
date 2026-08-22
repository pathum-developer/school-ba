package com.elvencode.schoolba.auth.service;

import com.elvencode.schoolba.auth.dto.AccessTokenResponse;
import com.elvencode.schoolba.auth.dto.LoginOutcome;
import com.elvencode.schoolba.auth.dto.LoginRequest;
import com.elvencode.schoolba.auth.dto.MfaRequiredResponse;
import com.elvencode.schoolba.auth.entity.LoginAccount;
import com.elvencode.schoolba.auth.entity.MfaFactor;
import com.elvencode.schoolba.auth.entity.NewSession;
import com.elvencode.schoolba.auth.enums.AccountType;
import com.elvencode.schoolba.auth.enums.AuthenticationEventType;
import com.elvencode.schoolba.auth.exception.AuthenticationRejectedException;
import com.elvencode.schoolba.auth.exception.InvalidCredentialsException;
import com.elvencode.schoolba.auth.exception.LoginRateLimitExceededException;
import com.elvencode.schoolba.auth.exception.MfaEnrollmentRequiredException;
import com.elvencode.schoolba.auth.jwt.JwtTokenService;
import com.elvencode.schoolba.auth.repository.AuthChallengeRepository;
import com.elvencode.schoolba.auth.repository.AuthSessionRepository;
import com.elvencode.schoolba.auth.repository.AuthenticationEventRepository;
import com.elvencode.schoolba.auth.repository.LoginAccountRepository;
import com.elvencode.schoolba.auth.repository.MfaFactorRepository;
import com.elvencode.schoolba.config.security.AuthProperties;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

@Service
public class AuthenticationService {

    private final LoginAccountRepository loginAccountRepository;
    private final MfaFactorRepository mfaFactorRepository;
    private final AuthChallengeRepository authChallengeRepository;
    private final AuthSessionRepository authSessionRepository;
    private final AuthenticationEventRepository authenticationEventRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenService jwtTokenService;
    private final SecureTokenService secureTokenService;
    private final LoginIdentifierNormalizer identifierNormalizer;
    private final AuthProperties properties;
    private final Clock clock;
    private final String dummyPasswordHash;

    public AuthenticationService(
            LoginAccountRepository loginAccountRepository,
            MfaFactorRepository mfaFactorRepository,
            AuthChallengeRepository authChallengeRepository,
            AuthSessionRepository authSessionRepository,
            AuthenticationEventRepository authenticationEventRepository,
            PasswordEncoder passwordEncoder,
            JwtTokenService jwtTokenService,
            SecureTokenService secureTokenService,
            LoginIdentifierNormalizer identifierNormalizer,
            AuthProperties properties,
            Clock clock
    ) {
        this.loginAccountRepository = loginAccountRepository;
        this.mfaFactorRepository = mfaFactorRepository;
        this.authChallengeRepository = authChallengeRepository;
        this.authSessionRepository = authSessionRepository;
        this.authenticationEventRepository = authenticationEventRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtTokenService = jwtTokenService;
        this.secureTokenService = secureTokenService;
        this.identifierNormalizer = identifierNormalizer;
        this.properties = properties;
        this.clock = clock;
        validateDurations(properties);
        this.dummyPasswordHash = passwordEncoder.encode(secureTokenService.generateOpaqueToken());
    }

    @Transactional(noRollbackFor = AuthenticationRejectedException.class)
    public LoginOutcome login(LoginRequest request, String sourceFingerprint) {
        Instant now = clock.instant();
        String normalizedIdentifier = identifierNormalizer.normalize(request.identifier());
        byte[] identifierHash = secureTokenService.hash(normalizedIdentifier);
        byte[] sourceFingerprintHash = secureTokenService.hash(sourceFingerprint);

        enforceRateLimit(identifierHash, sourceFingerprintHash, now);

        Optional<LoginAccount> accountResult = loginAccountRepository
                .findByLoginIdentifier(normalizedIdentifier);
        LoginAccount account = accountResult.orElse(null);
        boolean passwordMatches = matchesPassword(request.password(), account);

        if (account == null || !account.isEligibleForLogin() || !passwordMatches) {
            recordEvent(AuthenticationEventType.LOGIN_FAILED, account, null,
                    identifierHash, sourceFingerprintHash, now);
            throw new InvalidCredentialsException();
        }

        loginAccountRepository.markPasswordUsed(account.id(), now);
        Optional<MfaFactor> activeMfaFactor = mfaFactorRepository.findActiveFactor(account.id());
        if (account.accountType() == AccountType.STAFF || activeMfaFactor.isPresent()) {
            return requireMfa(account, activeMfaFactor, identifierHash, sourceFingerprintHash, now);
        }
        return establishSession(account, identifierHash, sourceFingerprintHash, now);
    }

    private void enforceRateLimit(byte[] identifierHash, byte[] sourceFingerprintHash, Instant now) {
        AuthProperties.RateLimit rateLimit = properties.rateLimit();
        long recentFailures = authenticationEventRepository.countRecentFailures(
                identifierHash,
                sourceFingerprintHash,
                now.minus(rateLimit.window())
        );
        if (recentFailures < rateLimit.maxFailures()) {
            return;
        }
        authenticationEventRepository.record(
                AuthenticationEventType.LOGIN_RATE_LIMITED,
                null,
                null,
                identifierHash,
                sourceFingerprintHash,
                now
        );
        throw new LoginRateLimitExceededException(rateLimit.window());
    }

    private boolean matchesPassword(String password, LoginAccount account) {
        String hash = account != null && account.hasSupportedPasswordHash()
                ? account.secretHash()
                : dummyPasswordHash;
        try {
            return passwordEncoder.matches(password, hash)
                    && account != null
                    && account.hasSupportedPasswordHash();
        } catch (IllegalArgumentException exception) {
            return false;
        }
    }

    private LoginOutcome requireMfa(
            LoginAccount account,
            Optional<MfaFactor> activeMfaFactor,
            byte[] identifierHash,
            byte[] sourceFingerprintHash,
            Instant now
    ) {
        if (activeMfaFactor.isEmpty()) {
            recordEvent(AuthenticationEventType.LOGIN_MFA_ENROLLMENT_REQUIRED, account, null,
                    identifierHash, sourceFingerprintHash, now);
            throw new MfaEnrollmentRequiredException();
        }

        String rawChallenge = secureTokenService.generateOpaqueToken();
        Instant expiresAt = now.plus(properties.mfa().challengeTtl());
        authChallengeRepository.replacePendingLoginChallenge(
                UUID.randomUUID(),
                account.id(),
                activeMfaFactor.get().id(),
                secureTokenService.hash(rawChallenge),
                now,
                expiresAt
        );
        recordEvent(AuthenticationEventType.LOGIN_MFA_REQUIRED, account, null,
                identifierHash, sourceFingerprintHash, now);
        return new LoginOutcome(
                new MfaRequiredResponse("mfa_required", rawChallenge, expiresAt),
                null
        );
    }

    private LoginOutcome establishSession(
            LoginAccount account,
            byte[] identifierHash,
            byte[] sourceFingerprintHash,
            Instant now
    ) {
        String rawRefreshToken = secureTokenService.generateOpaqueToken();
        byte[] refreshTokenHash = secureTokenService.hash(rawRefreshToken);
        Instant absoluteExpiresAt = now.plus(properties.session().absoluteTimeout());
        Instant idleExpiresAt = earlier(
                now.plus(properties.session().idleTimeout()),
                absoluteExpiresAt
        );
        UUID sessionId = UUID.randomUUID();
        authSessionRepository.create(new NewSession(
                sessionId,
                UUID.randomUUID(),
                UUID.randomUUID(),
                account.id(),
                refreshTokenHash,
                account.authorizationVersion(),
                account.credentialVersion(),
                now,
                idleExpiresAt,
                absoluteExpiresAt
        ));

        JwtTokenService.IssuedAccessToken accessToken = jwtTokenService.issue(account, sessionId);
        recordEvent(AuthenticationEventType.LOGIN_SUCCEEDED, account, sessionId,
                identifierHash, sourceFingerprintHash, now);
        return new LoginOutcome(
                new AccessTokenResponse(
                        accessToken.value(),
                        "Bearer",
                        jwtTokenService.accessTokenTtl().toSeconds()
                ),
                rawRefreshToken
        );
    }

    private void recordEvent(
            AuthenticationEventType eventType,
            LoginAccount account,
            UUID sessionId,
            byte[] identifierHash,
            byte[] sourceFingerprintHash,
            Instant occurredAt
    ) {
        authenticationEventRepository.record(
                eventType,
                account == null ? null : account.id(),
                sessionId,
                identifierHash,
                sourceFingerprintHash,
                occurredAt
        );
    }

    private Instant earlier(Instant first, Instant second) {
        return first.isBefore(second) ? first : second;
    }

    private void validateDurations(AuthProperties authProperties) {
        requirePositive(authProperties.session().idleTimeout(), "Session idle timeout");
        requirePositive(authProperties.session().absoluteTimeout(), "Session absolute timeout");
        requirePositive(authProperties.mfa().challengeTtl(), "MFA challenge TTL");
        requirePositive(authProperties.rateLimit().window(), "Login rate-limit window");
    }

    private void requirePositive(Duration duration, String name) {
        if (duration.isZero() || duration.isNegative()) {
            throw new IllegalStateException(name + " must be positive.");
        }
    }
}
