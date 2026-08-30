package com.elvencode.schoolba.auth.exception;

public class InvalidLoginCredentialsException extends RuntimeException {

    public InvalidLoginCredentialsException(String message, Throwable cause) {
        super(message, cause);
    }
}
