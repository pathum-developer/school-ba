package com.elvencode.schoolba.auth.service.impl;

import java.time.Clock;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

import com.elvencode.schoolba.auth.dto.AuthenticatedIdentity;
import com.elvencode.schoolba.auth.entity.Identity;
import com.elvencode.schoolba.auth.enums.IdentityStatus;
import com.elvencode.schoolba.auth.repository.IdentityRepository;
import com.elvencode.schoolba.auth.service.IIdentityAuthenticationService;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.DisabledException;
import org.springframework.security.authentication.LockedException;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class IdentityAuthenticationServiceImpl implements IIdentityAuthenticationService {

    private static final String INVALID_CREDENTIALS_MESSAGE = "Invalid username or password";

    private final IdentityRepository identityRepository;
    private final PasswordEncoder passwordEncoder;
    private final Clock clock;

    public IdentityAuthenticationServiceImpl(
            IdentityRepository identityRepository,
            PasswordEncoder passwordEncoder,
            Clock clock
    ) {
        this.identityRepository = identityRepository;
        this.passwordEncoder = passwordEncoder;
        this.clock = clock;
    }

    @Override
    @Transactional
    public AuthenticatedIdentity authenticate(String username, String password) {
        String normalizedUsername = normalizeUsername(username);
        String providedPassword = requirePassword(password);
        Identity identity = identityRepository.findByUsername(normalizedUsername)
                .orElseThrow(() -> new BadCredentialsException(INVALID_CREDENTIALS_MESSAGE));

        requireActiveIdentity(identity);
        requireValidPassword(identity, providedPassword);

        identityRepository.recordSuccessfulLogin(identity.getId());

        return new AuthenticatedIdentity(
                identity.getId(),
                identity.getSchoolId(),
                identity.getPlatformOperatorId(),
                identity.getStaffId(),
                identity.getLearnerId(),
                identity.getUsername(),
                identity.getAuthorizationVersion(),
                authorityList(identity.getId())
        );
    }

    private void requireActiveIdentity(Identity identity) {
        LocalDateTime currentTime = LocalDateTime.now(clock);
        if (identity.isTemporarilyLocked(currentTime) || identity.getStatus() == IdentityStatus.LOCKED) {
            throw new LockedException("Account is locked");
        }
        if (identity.getStatus() != IdentityStatus.ACTIVE) {
            throw new DisabledException("Account is not active");
        }
    }

    private void requireValidPassword(Identity identity, String password) {
        if (!identity.hasUsablePassword() || !passwordEncoder.matches(password, identity.getPasswordHash())) {
            throw new BadCredentialsException(INVALID_CREDENTIALS_MESSAGE);
        }
    }

    private List<GrantedAuthority> authorityList(UUID identityId) {
        return identityRepository.findPermissionCodeListByIdentityId(identityId)
                .stream()
                .map(SimpleGrantedAuthority::new)
                .map(GrantedAuthority.class::cast)
                .toList();
    }

    private static String normalizeUsername(String username) {
        if (username == null || username.isBlank()) {
            throw new BadCredentialsException(INVALID_CREDENTIALS_MESSAGE);
        }
        return username.trim().toLowerCase(Locale.ROOT);
    }

    private static String requirePassword(String password) {
        if (password == null || password.isBlank()) {
            throw new BadCredentialsException(INVALID_CREDENTIALS_MESSAGE);
        }
        return password;
    }
}
