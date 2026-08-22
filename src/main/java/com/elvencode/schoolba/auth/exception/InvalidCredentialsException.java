package com.elvencode.schoolba.auth.exception;

public class InvalidCredentialsException extends AuthenticationRejectedException {

    public InvalidCredentialsException() {
        super("Authentication failed.");
    }
}
