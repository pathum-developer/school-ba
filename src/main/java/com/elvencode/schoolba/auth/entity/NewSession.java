package com.elvencode.schoolba.auth.entity;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

public record NewSession(
        UUID sessionId,
        UUID sessionFamilyId,
        UUID refreshTokenId,
        UUID accountId,
        byte[] refreshTokenHash,
        long authorizationVersion,
        long credentialVersion,
        Instant authenticatedAt,
        Instant idleExpiresAt,
        Instant absoluteExpiresAt
) {

    public NewSession {
        Objects.requireNonNull(sessionId, "sessionId must not be null");
        Objects.requireNonNull(sessionFamilyId, "sessionFamilyId must not be null");
        Objects.requireNonNull(refreshTokenId, "refreshTokenId must not be null");
        Objects.requireNonNull(accountId, "accountId must not be null");
        refreshTokenHash = Objects.requireNonNull(
                refreshTokenHash,
                "refreshTokenHash must not be null"
        ).clone();
        Objects.requireNonNull(authenticatedAt, "authenticatedAt must not be null");
        Objects.requireNonNull(idleExpiresAt, "idleExpiresAt must not be null");
        Objects.requireNonNull(absoluteExpiresAt, "absoluteExpiresAt must not be null");
    }

    @Override
    public byte[] refreshTokenHash() {
        return refreshTokenHash.clone();
    }

    @Override
    public String toString() {
        return "NewSession[sessionId=" + sessionId + ", sessionFamilyId=" + sessionFamilyId
                + ", refreshTokenId=" + refreshTokenId + ", accountId=" + accountId
                + ", refreshTokenHash=[REDACTED], authorizationVersion=" + authorizationVersion
                + ", credentialVersion=" + credentialVersion
                + ", authenticatedAt=" + authenticatedAt + ", idleExpiresAt=" + idleExpiresAt
                + ", absoluteExpiresAt=" + absoluteExpiresAt + "]";
    }
}
