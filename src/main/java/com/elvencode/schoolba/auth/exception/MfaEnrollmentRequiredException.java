package com.elvencode.schoolba.auth.exception;

public class MfaEnrollmentRequiredException extends AuthenticationRejectedException {

    public MfaEnrollmentRequiredException() {
        super("Multi-factor authentication enrollment is required.");
    }
}
