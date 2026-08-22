package com.elvencode.schoolba.auth.jwt;

import java.util.UUID;

public record AccessTokenClaims(
        UUID accountId,
        UUID sessionId,
        long authorizationVersion,
        long credentialVersion
) {
}
