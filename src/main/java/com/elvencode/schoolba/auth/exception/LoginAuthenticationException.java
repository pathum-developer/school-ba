package com.elvencode.schoolba.auth.exception;

import com.elvencode.schoolba.auth.entity.LoginAccount;
import org.springframework.security.authentication.BadCredentialsException;

import java.util.Optional;

public class LoginAuthenticationException extends BadCredentialsException {

    private final LoginAccount account;

    public LoginAuthenticationException(LoginAccount account) {
        super("Authentication failed.");
        this.account = account;
    }

    public Optional<LoginAccount> account() {
        return Optional.ofNullable(account);
    }
}
