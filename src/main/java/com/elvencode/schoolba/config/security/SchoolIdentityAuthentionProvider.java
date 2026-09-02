package com.elvencode.schoolba.config.security;

import com.elvencode.schoolba.auth.dto.AuthenticatedIdentity;
import com.elvencode.schoolba.auth.service.IIdentityAuthenticationService;
import lombok.RequiredArgsConstructor;
import org.jspecify.annotations.Nullable;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class SchoolIdentityAuthentionProvider implements AuthenticationProvider {

    private final IIdentityAuthenticationService identityAuthenticationService;

    @Override
    public @Nullable Authentication authenticate(Authentication authentication) throws AuthenticationException {
        if (!supports(authentication.getClass())) {
            return null;
        }

        AuthenticatedIdentity identity = identityAuthenticationService.authenticate(
                authentication.getName(),
                String.valueOf(authentication.getCredentials())
        );

        UsernamePasswordAuthenticationToken authenticatedToken = new UsernamePasswordAuthenticationToken(
                identity.username(),
                null,
                identity.authorityList()
        );
        authenticatedToken.setDetails(identity);
        return authenticatedToken;
    }

    @Override
    public boolean supports(Class<?> authentication) {
        return (UsernamePasswordAuthenticationToken.class.isAssignableFrom(authentication));
    }
}
