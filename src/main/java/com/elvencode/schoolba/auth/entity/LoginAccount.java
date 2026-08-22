package com.elvencode.schoolba.auth.entity;

import com.elvencode.schoolba.auth.enums.AccountType;

import java.time.Instant;
import java.util.UUID;

public record LoginAccount(
        UUID id,
        AccountType accountType,
        String lifecycleState,
        Instant identityVerifiedAt,
        long authorizationVersion,
        long credentialVersion,
        String secretHash,
        String hashAlgorithm
) {

    public boolean isEligibleForLogin() {
        return "ACTIVE".equals(lifecycleState) && identityVerifiedAt != null;
    }

    public boolean hasSupportedPasswordHash() {
        return "BCRYPT".equalsIgnoreCase(hashAlgorithm);
    }

    @Override
    public String toString() {
        return "LoginAccount[id=" + id + ", accountType=" + accountType
                + ", lifecycleState=" + lifecycleState + ", identityVerifiedAt=" + identityVerifiedAt
                + ", authorizationVersion=" + authorizationVersion
                + ", credentialVersion=" + credentialVersion
                + ", secretHash=[REDACTED], hashAlgorithm=" + hashAlgorithm + "]";
    }
}
