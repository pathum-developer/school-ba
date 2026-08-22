package com.elvencode.schoolba.auth.entity;

import com.elvencode.schoolba.auth.enums.AccountType;

import java.security.Principal;
import java.util.UUID;

public record AuthenticatedPrincipal(
        UUID accountId,
        AccountType accountType,
        UUID sessionId
) implements Principal {

    @Override
    public String getName() {
        return accountId.toString();
    }
}
