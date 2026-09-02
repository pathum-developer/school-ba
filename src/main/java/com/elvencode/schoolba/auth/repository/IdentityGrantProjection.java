package com.elvencode.schoolba.auth.repository;

import java.util.UUID;

/**
 * One row of the grant lookup in {@link IdentityRepository#findGrantListByIdentityId(UUID)}.
 *
 * <p>An interface projection rather than a record because the query is native: it spans
 * three tables that have no JPA entities, and mapping a constructor to a native result set
 * would need an explicit {@code @SqlResultSetMapping} to buy nothing.
 */
public interface IdentityGrantProjection {

    String getPermissionCode();

    /** The raw column value; {@code ck_identity_role_assignment_scope_type} keeps it a valid scope. */
    String getScopeType();

    UUID getSchoolId();

    UUID getBranchId();
}
