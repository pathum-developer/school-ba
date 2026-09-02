package com.elvencode.schoolba.auth.service.impl;

import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.UUID;

import com.elvencode.schoolba.auth.dto.AuthenticatedIdentity;
import com.elvencode.schoolba.auth.dto.IdentityGrant;
import com.elvencode.schoolba.auth.entity.Identity;
import com.elvencode.schoolba.auth.enums.ScopeType;
import com.elvencode.schoolba.auth.repository.IdentityGrantProjection;
import com.elvencode.schoolba.auth.repository.IdentityRepository;
import com.elvencode.schoolba.auth.service.IIdentityAuthenticationService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.DisabledException;
import org.springframework.security.authentication.LockedException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Slf4j
@Service
@Transactional(readOnly = true)
public class IdentityAuthenticationServiceImpl implements IIdentityAuthenticationService {

    /**
     * One message for every credential failure, whatever the cause. Saying "no such user"
     * would turn the login endpoint into a directory of who has an account.
     */
    private static final String BAD_CREDENTIALS_MESSAGE = "Bad credentials";

    private static final String ACCOUNT_LOCKED_MESSAGE = "Account is temporarily locked";
    private static final String ACCOUNT_NOT_ACTIVE_MESSAGE = "Account is not active";

    /** Hashed once at startup and matched against when there is no real hash to check. */
    private static final String ABSENT_ACCOUNT_PASSWORD = "absentAccountPassword";

    private final IdentityRepository identityRepository;
    private final PasswordEncoder passwordEncoder;
    private final String absentAccountPasswordHash;

    public IdentityAuthenticationServiceImpl(
            IdentityRepository identityRepository,
            PasswordEncoder passwordEncoder
    ) {
        this.identityRepository = identityRepository;
        this.passwordEncoder = passwordEncoder;
        this.absentAccountPasswordHash = passwordEncoder.encode(ABSENT_ACCOUNT_PASSWORD);
    }

    @Override
    public AuthenticatedIdentity authenticate(String username, String rawPassword) {
        String normalizedUsername = normalizeUsername(username);
        Identity identity = findAuthenticatedIdentity(normalizedUsername, rawPassword);
        verifyAccountMaySignIn(identity);

        List<IdentityGrant> grantList = loadGrantList(identity.getId());
        log.debug("Authenticated identity {} with {} permission grants", identity.getId(), grantList.size());
        return new AuthenticatedIdentity(identity, grantList);
    }

    /**
     * Verifies the password before looking at account state, so a wrong password always
     * fails the same way whatever condition the account is in. Checking status first, as
     * Spring's own provider does, tells an attacker holding only a username whether that
     * account exists and whether it is suspended.
     */
    private Identity findAuthenticatedIdentity(String normalizedUsername, String rawPassword) {
        if (!StringUtils.hasText(rawPassword)) {
            throw new BadCredentialsException(BAD_CREDENTIALS_MESSAGE);
        }

        Optional<Identity> found = identityRepository.findByUsername(normalizedUsername);

        // Empty when there is no such account, and also when the account exists but has no
        // password yet, which is what a pending activation looks like.
        String passwordHash = found
                .map(Identity::getPasswordHash)
                .orElse(absentAccountPasswordHash);

        // Runs even when there is no account, and when the account has no password yet, so
        // that an unknown username costs the same wall-clock time as a known one.
        boolean passwordMatches = passwordEncoder.matches(rawPassword, passwordHash);

        if (found.isEmpty() || found.get().getPasswordHash() == null || !passwordMatches) {
            log.warn("Failed login attempt for username {}", normalizedUsername);
            throw new BadCredentialsException(BAD_CREDENTIALS_MESSAGE);
        }
        return found.get();
    }

    /**
     * Refuses any account that is not active, which covers pending activation, suspended,
     * locked and disabled. Throws {@code AccountStatusException} subtypes on purpose:
     * {@code ProviderManager} stops at those instead of offering the credentials to the
     * next provider in the chain.
     */
    private void verifyAccountMaySignIn(Identity identity) {
        if (identity.isLockedOut()) {
            log.warn("Rejected login for identity {}: locked until {}", identity.getId(), identity.getLockedUntil());
            throw new LockedException(ACCOUNT_LOCKED_MESSAGE);
        }
        if (!identity.isEligibleToAuthenticate()) {
            log.warn("Rejected login for identity {}: status {}", identity.getId(), identity.getStatus());
            throw new DisabledException(ACCOUNT_NOT_ACTIVE_MESSAGE);
        }
    }

    private List<IdentityGrant> loadGrantList(UUID identityId) {
        return identityRepository.findGrantListByIdentityId(identityId)
                .stream()
                .map(this::toGrant)
                .toList();
    }

    private IdentityGrant toGrant(IdentityGrantProjection projection) {
        return new IdentityGrant(
                projection.getPermissionCode(),
                ScopeType.valueOf(projection.getScopeType()),
                projection.getSchoolId(),
                projection.getBranchId()
        );
    }

    /**
     * Usernames are stored lower case, so typing ELVEN_SUPER must find elven_super. Folding
     * with {@link Locale#ROOT} keeps the result independent of the server's default locale,
     * which would otherwise turn a dotless i into something the index cannot find.
     */
    private String normalizeUsername(String username) {
        if (!StringUtils.hasText(username)) {
            throw new BadCredentialsException(BAD_CREDENTIALS_MESSAGE);
        }
        return username.trim().toLowerCase(Locale.ROOT);
    }
}
