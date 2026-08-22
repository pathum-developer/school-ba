package com.elvencode.schoolba.auth.service;

import com.elvencode.schoolba.auth.entity.LoginAccount;
import com.elvencode.schoolba.auth.exception.LoginAuthenticationException;
import com.elvencode.schoolba.auth.repository.LoginAccountRepository;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class DatabaseAuthenticationProvider implements AuthenticationProvider {

    private final LoginAccountRepository loginAccountRepository;
    private final PasswordEncoder passwordEncoder;
    private final String dummyPasswordHash;

    public DatabaseAuthenticationProvider(
            LoginAccountRepository loginAccountRepository,
            PasswordEncoder passwordEncoder,
            SecureTokenService secureTokenService
    ) {
        this.loginAccountRepository = loginAccountRepository;
        this.passwordEncoder = passwordEncoder;
        this.dummyPasswordHash = passwordEncoder.encode(secureTokenService.generateOpaqueToken());
    }

    @Override
    public Authentication authenticate(Authentication authentication) throws AuthenticationException {
        String identifier = authentication.getName();
        String password = authentication.getCredentials() instanceof String credentials
                ? credentials
                : "";
        LoginAccount account = loginAccountRepository.findByLoginIdentifier(identifier).orElse(null);
        String passwordHash = account != null && account.hasSupportedPasswordHash()
                ? account.secretHash()
                : dummyPasswordHash;

        boolean passwordMatches;
        try {
            passwordMatches = passwordEncoder.matches(password, passwordHash);
        } catch (IllegalArgumentException exception) {
            passwordMatches = false;
        }

        if (account == null
                || !account.isEligibleForLogin()
                || !account.hasSupportedPasswordHash()
                || !passwordMatches) {
            throw new LoginAuthenticationException(account);
        }

        return new UsernamePasswordAuthenticationToken(account, null, List.of());
    }

    @Override
    public boolean supports(Class<?> authentication) {
        return UsernamePasswordAuthenticationToken.class.isAssignableFrom(authentication);
    }
}
