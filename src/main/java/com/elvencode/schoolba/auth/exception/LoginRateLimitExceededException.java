package com.elvencode.schoolba.auth.exception;

import java.time.Duration;

public class LoginRateLimitExceededException extends AuthenticationRejectedException {

    private final Duration retryAfter;

    public LoginRateLimitExceededException(Duration retryAfter) {
        super("Too many login attempts. Try again later.");
        this.retryAfter = retryAfter;
    }

    public Duration getRetryAfter() {
        return retryAfter;
    }
}
