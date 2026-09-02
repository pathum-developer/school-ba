package com.elvencode.schoolba.config.security;

import com.elvencode.schoolba.auth.dto.AuthenticatedIdentity;
import com.elvencode.schoolba.auth.service.IIdentityAuthenticationService;
import lombok.RequiredArgsConstructor;
import org.jspecify.annotations.Nullable;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.stereotype.Component;

/**
 * Adapts Spring Security's authentication contract to this application's identity store.
 *
 * <p>Holds no rules of its own. Deciding whether a password is right and whether an account
 * may sign in is authentication workflow and lives in {@code auth}; what belongs here is
 * only the translation between a framework {@link Authentication} and that service.
 */
@Component
@RequiredArgsConstructor
public class SchoolIdentityAuthenticationProvider implements AuthenticationProvider {

    private static final String MISSING_CREDENTIALS_MESSAGE = "Bad credentials";

    private final IIdentityAuthenticationService identityAuthenticationService;

    /**
     * Never returns null. A null return means "this provider cannot judge these credentials",
     * which would let {@code ProviderManager} fall through to another provider carrying the
     * same username and password; every outcome here is either a principal or a failure.
     */
    @Override
    public @Nullable Authentication authenticate(Authentication authentication) throws AuthenticationException {
        String username = authentication.getName();
        String password = credentials(authentication);

        AuthenticatedIdentity identity = identityAuthenticationService.authenticate(username, password);

        // Credentials are dropped rather than carried over: the token lives in the security
        // context for the whole request, and nothing downstream has any use for the password.
        return UsernamePasswordAuthenticationToken.authenticated(
                identity,
                null,
                identity.getAuthorities()
        );
    }

    private String credentials(Authentication authentication) {
        Object credentials = authentication.getCredentials();
        if (credentials == null) {
            throw new BadCredentialsException(MISSING_CREDENTIALS_MESSAGE);
        }
        return credentials.toString();
    }

    @Override
    public boolean supports(Class<?> authentication) {
        return (UsernamePasswordAuthenticationToken.class.isAssignableFrom(authentication));
    }
}
