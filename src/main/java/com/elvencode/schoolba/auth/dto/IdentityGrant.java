package com.elvencode.schoolba.auth.dto;

import java.io.Serializable;
import java.util.Objects;
import java.util.UUID;

import com.elvencode.schoolba.auth.enums.ScopeType;

/**
 * One permission an account holds, together with where it applies.
 *
 * <p>Flattened from {@code t_identity_role_assignment} through {@code x_role_permission}
 * to {@code r_permission}: the role is what an administrator manages, but the permission
 * code plus its scope is all an authorization check ever needs, and roles may be renamed
 * freely because nothing checks their names.
 *
 * @param permissionCode {@code r_permission.code}, for example {@code learner:read}
 * @param scopeType      how wide the grant reaches
 * @param schoolId       the school the grant covers; null only for a {@code PLATFORM} grant
 * @param branchId       the branch the grant covers; non-null only for a {@code BRANCH} grant
 */
public record IdentityGrant(
        String permissionCode,
        ScopeType scopeType,
        UUID schoolId,
        UUID branchId
) implements Serializable {

    public IdentityGrant {
        Objects.requireNonNull(permissionCode, "permissionCode must not be null");
        Objects.requireNonNull(scopeType, "scopeType must not be null");
    }
}
