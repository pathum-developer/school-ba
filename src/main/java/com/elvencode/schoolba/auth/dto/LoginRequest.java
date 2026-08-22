package com.elvencode.schoolba.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record LoginRequest(
        @NotBlank(message = "Identifier is required.")
        @Size(max = 320, message = "Identifier is too long.")
        String identifier,

        @NotBlank(message = "Password is required.")
        @Size(max = 256, message = "Password is too long.")
        String password
) {
    @Override
    public String toString() {
        return "LoginRequest[identifier=" + identifier + ", password=[REDACTED]]";
    }
}
