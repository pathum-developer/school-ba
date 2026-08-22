package com.elvencode.schoolba.auth.entity;

import java.util.UUID;

public record MfaFactor(UUID id, String factorType) {
}
