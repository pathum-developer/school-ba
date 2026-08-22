package com.elvencode.schoolba.auth.dto;

public record LoginOutcome(LoginResponse response, String refreshToken) {

    public boolean hasRefreshToken() {
        return refreshToken != null;
    }

    @Override
    public String toString() {
        return "LoginOutcome[response=" + response + ", refreshToken=[REDACTED]]";
    }
}
