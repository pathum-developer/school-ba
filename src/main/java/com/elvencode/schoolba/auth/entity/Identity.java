package com.elvencode.schoolba.auth.entity;

import java.time.LocalDateTime;
import java.util.UUID;

import com.elvencode.schoolba.audit.entity.BaseEntity;
import com.elvencode.schoolba.auth.enums.IdentityStatus;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;
import org.hibernate.annotations.DynamicInsert;

@Entity
@Table(name = "m_identity")
@DynamicInsert
@Getter
@Setter
@NoArgsConstructor
@ToString(onlyExplicitlyIncluded = true)
public class Identity extends BaseEntity {

    private static final int USERNAME_MAX_LENGTH = 64;
    private static final int PASSWORD_HASH_MAX_LENGTH = 255;
    private static final int DISPLAY_NAME_MAX_LENGTH = 160;

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @ToString.Include
    private UUID id;

    @Column(name = "school_id", updatable = false)
    private UUID schoolId;

    @Column(name = "platform_operator_id", updatable = false)
    private UUID platformOperatorId;

    @Column(name = "staff_id", updatable = false)
    private UUID staffId;

    @Column(name = "learner_id", updatable = false)
    private UUID learnerId;

    @Column(name = "is_staff", nullable = false, insertable = false, updatable = false)
    private boolean staff;

    @Column(name = "username", nullable = false, length = USERNAME_MAX_LENGTH, unique = true, updatable = false)
    @ToString.Include
    private String username;

    @Column(name = "password_hash", length = PASSWORD_HASH_MAX_LENGTH)
    private String passwordHash;

    @Column(name = "display_name", nullable = false, length = DISPLAY_NAME_MAX_LENGTH)
    private String displayName;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 32)
    private IdentityStatus status = IdentityStatus.PENDING_ACTIVATION;

    @Column(name = "authorization_version", nullable = false, insertable = false, updatable = false)
    private Integer authorizationVersion;

    @Column(name = "failed_attempt_count", nullable = false)
    private short failedAttemptCount;

    @Column(name = "locked_until")
    private LocalDateTime lockedUntil;

    @Column(name = "last_login_at")
    private LocalDateTime lastLoginAt;

    public boolean isTemporarilyLocked(LocalDateTime currentTime) {
        return lockedUntil != null && lockedUntil.isAfter(currentTime);
    }

    public boolean hasUsablePassword() {
        return passwordHash != null && !passwordHash.isBlank();
    }
}
