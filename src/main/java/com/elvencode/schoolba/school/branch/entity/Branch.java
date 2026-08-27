package com.elvencode.schoolba.school.branch.entity;

import java.util.UUID;
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
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;
import org.hibernate.annotations.DynamicInsert;

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
@Setter
@NoArgsConstructor
@ToString(onlyExplicitlyIncluded = true)
public class Branch extends BaseEntity {

    private static final int CODE_MAX_LENGTH = 64;
    private static final int NAME_MAX_LENGTH = 160;
    private static final int ADDRESS_MAX_LENGTH = 255;

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
    @Column(name = "address", nullable = false)
    private String address;

    @Column(name = "is_head_office", nullable = false)
    private boolean headOffice;

    @Column(name = "is_active", nullable = false)
    private boolean active = true;

}
