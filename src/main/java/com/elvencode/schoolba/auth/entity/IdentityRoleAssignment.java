package com.elvencode.schoolba.auth.entity;

import java.time.LocalDateTime;
import java.util.UUID;

import com.elvencode.schoolba.audit.entity.BaseEntity;
import com.elvencode.schoolba.auth.enums.RoleAudience;
import com.elvencode.schoolba.auth.enums.ScopeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;
import org.hibernate.annotations.DynamicInsert;
import org.hibernate.annotations.DynamicUpdate;

/**
 * One role given to one login, at one scope, optionally until a date.
 *
 * <p>The scope is copied onto the grant rather than read from the role, because the same role
 * can be handed out at different reaches: a branch manager role granted for one branch is a
 * different grant from the same role granted for another. {@link #schoolId} and
 * {@link #branchId} say which, and the check constraints keep the pair consistent with
 * {@link #scopeType}.
 *
 * <p>Role, identity and granter are mapped as plain identifiers rather than associations, for
 * the reason {@link Identity} gives: sign-in reads this table to collect permission codes and
 * never needs the objects behind those ids, so an association would load rows nothing reads.
 */
@Entity
@Table(name = "t_identity_role_assignment")
@DynamicInsert
@DynamicUpdate
@Getter
@Setter
@NoArgsConstructor
@ToString(onlyExplicitlyIncluded = true)
public class IdentityRoleAssignment extends BaseEntity {

    private static final int SCOPE_TYPE_MAX_LENGTH = 32;
    private static final int ASSIGNABLE_TO_MAX_LENGTH = 32;

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @ToString.Include
    private UUID id;

    /** The login this grant belongs to. */
    @NotNull
    @Column(name = "identity_id", nullable = false)
    @ToString.Include
    private UUID identityId;

    @NotNull
    @Column(name = "role_id", nullable = false)
    @ToString.Include
    private UUID roleId;

    /** How wide this particular grant reaches, which need not be the role's own scope. */
    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(name = "scope_type", nullable = false, length = SCOPE_TYPE_MAX_LENGTH)
    private ScopeType scopeType;

    /** The school this grant covers. Null only for a {@code PLATFORM} grant. */
    @Column(name = "school_id")
    private UUID schoolId;

    /** The branch this grant covers. Non-null exactly when the scope is {@code BRANCH}. */
    @Column(name = "branch_id")
    private UUID branchId;

    /** Copied from the role, so a grant records the audience it was made under. */
    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(name = "assignable_to", nullable = false, length = ASSIGNABLE_TO_MAX_LENGTH)
    private RoleAudience assignableTo;

    /**
     * Must equal {@code assignableTo == STAFF}, which {@code ck_identity_role_assignment_audience}
     * enforces. Stored rather than derived so the partial indexes on staff grants can use it.
     */
    @NotNull
    @Column(name = "is_staff", nullable = false)
    private Boolean staff;

    /** The staff member this grant is for. Required for any {@code BRANCH} scoped grant. */
    @Column(name = "staff_id")
    private UUID staffId;

    /**
     * The login that made this grant. Never null: every grant names a granter, and the
     * bootstrap administrator points at itself because nobody above it exists.
     */
    @NotNull
    @Column(name = "granted_by", nullable = false)
    private UUID grantedBy;

    @Column(name = "granted_at", nullable = false)
    private LocalDateTime grantedAt;

    /**
     * When this grant stops counting, or null to never expire. Sign-in filters on it rather
     * than deleting expired rows, so the history of what was held stays readable.
     */
    @Column(name = "expires_at")
    private LocalDateTime expiresAt;
}
