package com.elvencode.schoolba.auth.dto;

import java.util.Map;

public record AuthValidationErrorResponse(
        String code,
        String message,
        Map<String, String> fields
) {
    public AuthValidationErrorResponse {
        fields = Map.copyOf(fields);
    }
}
