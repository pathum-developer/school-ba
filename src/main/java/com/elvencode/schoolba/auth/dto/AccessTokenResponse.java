package com.elvencode.schoolba.auth.dto;

public record AccessTokenResponse(
        String accessToken,
        String tokenType,
        long expiresIn
) implements LoginResponse {
}
