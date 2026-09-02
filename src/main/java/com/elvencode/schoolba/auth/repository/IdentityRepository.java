package com.elvencode.schoolba.auth.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import com.elvencode.schoolba.auth.dto.IdentityGrant;
import com.elvencode.schoolba.auth.entity.Identity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface IdentityRepository extends JpaRepository<Identity, UUID> {

    /**
     * Usernames are stored lower case and constrained to it, so the caller must fold the
     * entered value before calling. Looking up case-insensitively here instead would make
     * the unique index unusable and turn every sign-in into a sequential scan.
     */
    Optional<Identity> findByUsername(String username);

    /**
     * Every unexpired permission the account holds, with the scope each was granted at.
     *
     * <p>Builds {@link IdentityGrant} straight from the result through a constructor
     * expression, so there is no projection to map and no string to convert: the scope
     * arrives as a {@code ScopeType} because the column is mapped as one.
     *
     * <p>Joins the link table directly instead of walking an association through the role.
     * Only the permission codes are wanted, and the role itself is never read, so mapping
     * the association would add an entity to load on the sign-in path for nothing.
     *
     * <p>Compares against the database clock rather than the application's, so a grant
     * expires at the same instant for every caller regardless of what time their host
     * thinks it is.
     */
    @Query("""
            select distinct new com.elvencode.schoolba.auth.dto.IdentityGrant(
                           permission.code,
                           assignment.scopeType,
                           assignment.schoolId,
                           assignment.branchId)
            from IdentityRoleAssignment assignment
            join RolePermission rolePermission
                    on rolePermission.id.roleId = assignment.roleId
            join Permission permission
                    on permission.id = rolePermission.id.permissionId
            where assignment.identityId = :identityId
                    and (assignment.expiresAt is null or assignment.expiresAt > current_timestamp)
            """)
    List<IdentityGrant> findGrantListByIdentityId(@Param("identityId") UUID identityId);

}
