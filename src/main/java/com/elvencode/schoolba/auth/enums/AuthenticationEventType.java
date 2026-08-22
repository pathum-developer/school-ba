package com.elvencode.schoolba.auth.enums;

public enum AuthenticationEventType {
    LOGIN_FAILED,
    LOGIN_RATE_LIMITED,
    LOGIN_MFA_ENROLLMENT_REQUIRED,
    LOGIN_MFA_REQUIRED,
    LOGIN_SUCCEEDED
}
