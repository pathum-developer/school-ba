package com.elvencode.schoolba.auth.entity;

import java.time.LocalDateTime;

import com.elvencode.schoolba.auth.enums.ScopeType;
import jakarta.persistence.Column;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;
import org.hibernate.annotations.DynamicInsert;
import org.springframework.data.annotation.CreatedBy;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

/**
 * A permission carried by a role.
 *
 * <p>Not a plain {@code @ManyToMany} join table, which is why it is an entity of its own. It
 * also stores the role's scope and the permission's scope ceiling, so that
 * {@code ck_role_permission_scope_depth} can refuse a role that reaches wider than a permission
 * allows without the database having to read either parent row. Hibernate would never populate
 * those two columns through a {@code @JoinTable}, and they are {@code NOT NULL}.
 *
 * <p>Does not extend {@code BaseEntity}: this table records only who created a link and when,
 * having no update columns, and its key is a pair rather than a generated identifier.
 */
@Entity
@Table(name = "x_role_permission")
@DynamicInsert
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@ToString(onlyExplicitlyIncluded = true)
public class RolePermission {

    private static final int SCOPE_TYPE_MAX_LENGTH = 32;
    private static final int CREATED_BY_MAX_LENGTH = 20;

    @EmbeddedId
    @ToString.Include
    private RolePermissionId id;

    /** Copied from the role. Denormalized so the scope depth check needs no join. */
    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(name = "role_scope_type", nullable = false, length = SCOPE_TYPE_MAX_LENGTH)
    private ScopeType roleScopeType;

    /** Copied from the permission, for the same reason as {@link #roleScopeType}. */
    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(name = "permission_max_scope_type", nullable = false, length = SCOPE_TYPE_MAX_LENGTH)
    private ScopeType permissionMaxScopeType;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @CreatedBy
    @Column(name = "created_by", nullable = false, updatable = false, length = CREATED_BY_MAX_LENGTH)
    private String createdBy;
}
