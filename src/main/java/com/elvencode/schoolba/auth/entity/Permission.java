package com.elvencode.schoolba.auth.entity;

import java.util.UUID;

import com.elvencode.schoolba.audit.entity.BaseEntity;
import com.elvencode.schoolba.auth.enums.ScopeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;
import org.hibernate.annotations.DynamicInsert;
import org.hibernate.annotations.DynamicUpdate;

/**
 * One thing the system can be asked to allow, such as {@code branch:read}.
 *
 * <p>A fixed catalogue rather than user data. Rows are seeded by changeset and referenced by
 * roles; nothing creates a permission at runtime, because a code that no {@code @PreAuthorize}
 * expression mentions would allow nothing no matter who held it.
 */
@Entity
@Table(name = "r_permission")
@DynamicInsert
@DynamicUpdate
@Getter
@Setter
@NoArgsConstructor
@ToString(onlyExplicitlyIncluded = true)
public class Permission extends BaseEntity {

    private static final int CODE_MAX_LENGTH = 64;
    private static final int RESOURCE_MAX_LENGTH = 32;
    private static final int ACTION_MAX_LENGTH = 32;
    private static final int SCOPE_TYPE_MAX_LENGTH = 32;
    private static final int DESCRIPTION_MAX_LENGTH = 255;

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @ToString.Include
    private UUID id;

    /**
     * What an authorization check asks for, shaped {@code resource:action}. This is the value
     * that reaches Spring Security as a granted authority, so it is the permission's real
     * identity; {@link #resource} and {@link #action} exist to group and report on it.
     */
    @NotBlank
    @Size(max = CODE_MAX_LENGTH)
    @Column(name = "code", nullable = false, length = CODE_MAX_LENGTH, unique = true)
    @ToString.Include
    private String code;

    @NotBlank
    @Size(max = RESOURCE_MAX_LENGTH)
    @Column(name = "resource", nullable = false, length = RESOURCE_MAX_LENGTH)
    private String resource;

    @NotBlank
    @Size(max = ACTION_MAX_LENGTH)
    @Column(name = "action", nullable = false, length = ACTION_MAX_LENGTH)
    private String action;

    /**
     * The widest scope this permission may ever be granted at. A role may not carry a
     * permission whose ceiling is narrower than the role's own scope, which is what
     * {@code ck_role_permission_scope_depth} enforces on the link table.
     */
    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(name = "max_scope_type", nullable = false, length = SCOPE_TYPE_MAX_LENGTH)
    private ScopeType maxScopeType;

    @NotBlank
    @Size(max = DESCRIPTION_MAX_LENGTH)
    @Column(name = "description", nullable = false, length = DESCRIPTION_MAX_LENGTH)
    private String description;
}
