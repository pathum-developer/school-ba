package com.elvencode.schoolba.auth.service;

import com.elvencode.schoolba.auth.entity.AuthenticatedPrincipal;
import com.elvencode.schoolba.auth.entity.SessionState;
import com.elvencode.schoolba.auth.enums.AccountType;
import com.elvencode.schoolba.auth.exception.InvalidAccessTokenException;
import com.elvencode.schoolba.auth.jwt.AccessTokenClaims;
import com.elvencode.schoolba.auth.repository.AuthSessionRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.Instant;

@Service
public class SessionAuthenticationService {

    private final AuthSessionRepository authSessionRepository;
    private final Clock clock;

    public SessionAuthenticationService(AuthSessionRepository authSessionRepository, Clock clock) {
        this.authSessionRepository = authSessionRepository;
        this.clock = clock;
    }

    @Transactional(readOnly = true)
    public AuthenticatedPrincipal authenticate(AccessTokenClaims claims) {
        SessionState state = authSessionRepository.findSessionState(claims.sessionId())
                .orElseThrow(InvalidAccessTokenException::new);
        Instant now = clock.instant();

        if (!"ACTIVE".equals(state.accountLifecycleState())
                || !"ACTIVE".equals(state.sessionLifecycleState())
                || !state.accountId().equals(claims.accountId())
                || state.accountAuthorizationVersion() != state.sessionAuthorizationVersion()
                || state.accountCredentialVersion() != state.sessionCredentialVersion()
                || claims.authorizationVersion() != state.sessionAuthorizationVersion()
                || claims.credentialVersion() != state.sessionCredentialVersion()
                || (state.accountType() == AccountType.STAFF && state.mfaAuthenticatedAt() == null)
                || !now.isBefore(state.idleExpiresAt())
                || !now.isBefore(state.absoluteExpiresAt())) {
            throw new InvalidAccessTokenException();
        }

        return new AuthenticatedPrincipal(state.accountId(), state.accountType(), state.sessionId());
    }
}
