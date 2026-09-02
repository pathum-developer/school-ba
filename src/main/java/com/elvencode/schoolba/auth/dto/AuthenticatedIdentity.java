package com.elvencode.schoolba.auth.dto;

import java.util.List;
import java.util.UUID;

import org.springframework.security.core.GrantedAuthority;

public record AuthenticatedIdentity(
        UUID id,
        UUID schoolId,
        UUID platformOperatorId,
        UUID staffId,
        UUID learnerId,
        String username,
        Integer authorizationVersion,
        List<GrantedAuthority> authorityList
) {
}
