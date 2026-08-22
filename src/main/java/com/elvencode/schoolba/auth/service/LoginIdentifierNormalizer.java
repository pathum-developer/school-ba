package com.elvencode.schoolba.auth.service;

import org.springframework.stereotype.Component;

import java.util.Locale;

@Component
public class LoginIdentifierNormalizer {

    public String normalize(String identifier) {
        String normalized = identifier.strip();
        if (normalized.contains("@")) {
            return normalized.toLowerCase(Locale.ROOT);
        }
        return normalized.replaceAll("[\\s()\\-]", "");
    }
}
