package com.elvencode.schoolba.auth.dto;

import java.time.Instant;

public record MfaRequiredResponse(
        String status,
        String challengeId,
        Instant expiresAt
) implements LoginResponse {
    @Override
    public String toString() {
        return "MfaRequiredResponse[status=" + status + ", challengeId=[REDACTED], expiresAt="
                + expiresAt + "]";
    }
}
