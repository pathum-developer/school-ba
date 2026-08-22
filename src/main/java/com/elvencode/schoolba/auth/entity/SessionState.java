package com.elvencode.schoolba.auth.entity;

import com.elvencode.schoolba.auth.enums.AccountType;

import java.time.Instant;
import java.util.UUID;

public record SessionState(
        UUID sessionId,
        UUID accountId,
        AccountType accountType,
        String accountLifecycleState,
        long accountAuthorizationVersion,
        long accountCredentialVersion,
        String sessionLifecycleState,
        long sessionAuthorizationVersion,
        long sessionCredentialVersion,
        Instant mfaAuthenticatedAt,
        Instant idleExpiresAt,
        Instant absoluteExpiresAt
) {
}
