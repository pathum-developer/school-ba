package com.elvencode.schoolba.auth.dto;

public record AccessTokenResponse(
        String accessToken,
        String tokenType,
        long expiresIn
) implements LoginResponse {
    @Override
    public String toString() {
        return "AccessTokenResponse[accessToken=[REDACTED], tokenType=" + tokenType
                + ", expiresIn=" + expiresIn + "]";
    }
}
