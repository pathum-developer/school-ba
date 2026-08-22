package com.elvencode.schoolba.auth.dto;

import java.time.Instant;

public record MfaRequiredResponse(
        String status,
        String challengeId,
        Instant expiresAt
) implements LoginResponse {
}
