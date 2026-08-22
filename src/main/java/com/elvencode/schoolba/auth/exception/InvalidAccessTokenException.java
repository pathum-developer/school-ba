package com.elvencode.schoolba.auth.exception;

public class InvalidAccessTokenException extends RuntimeException {

    public InvalidAccessTokenException() {
        super("The access token is invalid.");
    }
}
