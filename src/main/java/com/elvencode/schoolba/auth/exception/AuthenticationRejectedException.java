package com.elvencode.schoolba.auth.exception;

public abstract class AuthenticationRejectedException extends RuntimeException {

    protected AuthenticationRejectedException(String message) {
        super(message);
    }
}
