package com.elvencode.schoolba.school.branch.entity;

import java.util.Objects;
import java.util.UUID;
import java.util.regex.Pattern;

import com.elvencode.schoolba.audit.entity.BaseEntity;
import com.elvencode.schoolba.school.entity.School;
import com.elvencode.schoolba.school.enums.BranchType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.ForeignKey;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.ToString;
import org.hibernate.annotations.DynamicInsert;
import org.hibernate.proxy.HibernateProxy;

@Entity
@Table(
        name = "branch",
        uniqueConstraints = @UniqueConstraint(
                name = "uk_branch_school_code",
                columnNames = {"school_id", "code"}
        )
)
@DynamicInsert
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@ToString(onlyExplicitlyIncluded = true)
public class Branch extends BaseEntity {

    private static final int CODE_MAX_LENGTH = 64;
    private static final int NAME_MAX_LENGTH = 160;
    private static final int ADDRESS_MAX_LENGTH = 255;
    private static final Pattern CODE_PATTERN = Pattern.compile("^[a-z0-9]+(?:-[a-z0-9]+)*$");

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @ToString.Include
    private UUID id;

    @NotNull
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(
            name = "school_id",
            nullable = false,
            updatable = false,
            foreignKey = @ForeignKey(name = "fk_branch_school")
    )
    private School school;

    @NotBlank
    @Size(max = CODE_MAX_LENGTH)
    @Column(name = "code", nullable = false, updatable = false, length = CODE_MAX_LENGTH)
    @ToString.Include
    private String code;

    @NotBlank
    @Size(max = NAME_MAX_LENGTH)
    @Column(name = "name", nullable = false, length = NAME_MAX_LENGTH)
    @ToString.Include
    private String name;

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(name = "branch_type", nullable = false, length = 32)
    @ToString.Include
    private BranchType branchType = BranchType.BRANCH;

    @NotBlank
    @Size(max = ADDRESS_MAX_LENGTH)
    @Column(name = "address", nullable = false, length = ADDRESS_MAX_LENGTH)
    private String address;

    @Column(name = "is_head_office", nullable = false)
    private boolean headOffice;

    @Column(name = "is_active", nullable = false)
    private boolean active = true;

    public Branch(
            School school,
            String code,
            String name,
            BranchType branchType,
            String address,
            boolean headOffice
    ) {
        this.school = Objects.requireNonNull(school, "school must not be null");
        this.code = requireValidCode(code);
        updateDetails(name, branchType, address, headOffice);
    }

    public void updateDetails(
            String name,
            BranchType branchType,
            String address,
            boolean headOffice
    ) {
        this.name = requireText(name, "name", NAME_MAX_LENGTH);
        this.branchType = Objects.requireNonNull(branchType, "branchType must not be null");
        this.address = requireText(address, "address", ADDRESS_MAX_LENGTH);
        this.headOffice = headOffice;
    }

    public void activate() {
        active = true;
    }

    public void deactivate() {
        active = false;
    }

    @Override
    public final boolean equals(Object other) {
        if (this == other) {
            return true;
        }
        if (other == null || effectiveClass(this) != effectiveClass(other)) {
            return false;
        }
        Branch branch = (Branch) other;
        return id != null && id.equals(branch.getId());
    }

    @Override
    public final int hashCode() {
        return effectiveClass(this).hashCode();
    }

    private static String requireValidCode(String code) {
        String validatedCode = requireText(code, "code", CODE_MAX_LENGTH);
        if (!CODE_PATTERN.matcher(validatedCode).matches()) {
            throw new IllegalArgumentException(
                    "code must contain lowercase letters or digits separated by single hyphens"
            );
        }
        return validatedCode;
    }

    private static String requireText(String value, String fieldName, int maxLength) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(fieldName + " must not be blank");
        }

        String normalizedValue = value.trim();
        if (normalizedValue.length() > maxLength) {
            throw new IllegalArgumentException(
                    fieldName + " must not exceed " + maxLength + " characters"
            );
        }
        return normalizedValue;
    }

    private static Class<?> effectiveClass(Object entity) {
        if (entity instanceof HibernateProxy proxy) {
            return proxy.getHibernateLazyInitializer().getPersistentClass();
        }
        return entity.getClass();
    }
}
