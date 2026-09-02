package com.elvencode.schoolba.auth.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

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
     * <p>Native because the three tables it walks have no entities: authentication only
     * ever reads this shape, and mapping roles, grants and the permission catalogue as
     * an object graph would cost several queries per sign-in for data nothing else uses.
     *
     * <p>Column aliases are quoted so PostgreSQL preserves their case for the projection;
     * unquoted, it would fold them to lower case and no property would bind.
     */
    @Query(
            value = """
                    select distinct permission.code       as "permissionCode",
                                    assignment.scope_type as "scopeType",
                                    assignment.school_id  as "schoolId",
                                    assignment.branch_id  as "branchId"
                    from t_identity_role_assignment assignment
                    join x_role_permission role_permission
                            on role_permission.role_id = assignment.role_id
                    join r_permission permission
                            on permission.id = role_permission.permission_id
                    where assignment.identity_id = :identityId
                            and (assignment.expires_at is null or assignment.expires_at > now())
                    """,
            nativeQuery = true
    )
    List<IdentityGrantProjection> findGrantListByIdentityId(@Param("identityId") UUID identityId);

}
