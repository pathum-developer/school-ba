package com.elvencode.schoolba.auth.dto;

import java.util.Map;

public record AuthErrorResponse(
        String code,
        String message,
        Map<String, String> fields
) {
    public AuthErrorResponse(String code, String message) {
        this(code, message, Map.of());
    }
}
