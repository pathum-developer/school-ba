package com.elvencode.schoolba.auth.entity;

import java.time.Instant;
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
        refreshTokenHash = refreshTokenHash.clone();
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
