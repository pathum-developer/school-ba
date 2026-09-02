package com.elvencode.schoolba.auth.service;

import com.elvencode.schoolba.auth.dto.AuthenticatedIdentity;
import org.springframework.security.core.AuthenticationException;

/**
 * Verifies a username and password against the identity store and loads what the account
 * is allowed to do.
 *
 * <p>Lives in {@code auth} rather than beside the Spring Security provider that calls it:
 * this is the authentication workflow, and {@code config.security} holds only framework
 * wiring. Keeping it here also lets token refresh reuse the same rules later.
 */
public interface IIdentityAuthenticationService {

    /**
     * @param username    as entered; case and surrounding whitespace are folded here
     * @param rawPassword the submitted password, never logged and never stored
     * @return the authenticated principal, with every unexpired grant the account holds
     * @throws AuthenticationException if the credentials do not match, or the account is
     *                                 not in a state that may sign in. The reason is not
     *                                 disclosed to the caller of the login endpoint.
     */
    AuthenticatedIdentity authenticate(String username, String rawPassword);
}
