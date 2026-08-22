package com.elvencode.schoolba.auth.entity;

import com.elvencode.schoolba.auth.enums.AccountType;

import java.time.Instant;
import java.util.Objects;
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

    public LoginAccount {
        Objects.requireNonNull(id, "id must not be null");
        Objects.requireNonNull(accountType, "accountType must not be null");
        Objects.requireNonNull(lifecycleState, "lifecycleState must not be null");
        Objects.requireNonNull(secretHash, "secretHash must not be null");
        Objects.requireNonNull(hashAlgorithm, "hashAlgorithm must not be null");
    }

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
