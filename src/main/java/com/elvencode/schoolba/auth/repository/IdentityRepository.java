package com.elvencode.schoolba.auth.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import com.elvencode.schoolba.auth.entity.Identity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface IdentityRepository extends JpaRepository<Identity, UUID> {

    Optional<Identity> findByUsername(String username);

    @Query(
            value = """
                    select distinct permission.code
                    from t_identity_role_assignment assignment
                    join x_role_permission role_permission
                        on role_permission.role_id = assignment.role_id
                    join r_permission permission
                        on permission.id = role_permission.permission_id
                    where assignment.identity_id = :identityId
                        and (assignment.expires_at is null or assignment.expires_at > current_timestamp)
                    order by permission.code
                    """,
            nativeQuery = true
    )
    List<String> findPermissionCodeListByIdentityId(@Param("identityId") UUID identityId);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("""
            update Identity identity
            set identity.failedAttemptCount = 0,
                identity.lockedUntil = null,
                identity.lastLoginAt = CURRENT_TIMESTAMP
            where identity.id = :identityId
            """)
    void recordSuccessfulLogin(@Param("identityId") UUID identityId);
}
