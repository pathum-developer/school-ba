package com.elvencode.schoolba.auth.entity;

import com.elvencode.schoolba.auth.enums.AccountType;

import java.security.Principal;
import java.util.Objects;
import java.util.UUID;

public record AuthenticatedPrincipal(
        UUID accountId,
        AccountType accountType,
        UUID sessionId
) implements Principal {

    public AuthenticatedPrincipal {
        Objects.requireNonNull(accountId, "accountId must not be null");
        Objects.requireNonNull(accountType, "accountType must not be null");
        Objects.requireNonNull(sessionId, "sessionId must not be null");
    }

    @Override
    public String getName() {
        return accountId.toString();
    }
}
