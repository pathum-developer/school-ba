package com.elvencode.schoolba.auth.entity;

import java.util.Objects;
import java.util.UUID;

public record MfaFactor(UUID id, String factorType) {

    public MfaFactor {
        Objects.requireNonNull(id, "id must not be null");
        Objects.requireNonNull(factorType, "factorType must not be null");
    }
}
