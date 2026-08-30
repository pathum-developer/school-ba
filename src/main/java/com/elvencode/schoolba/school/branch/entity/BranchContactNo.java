package com.elvencode.schoolba.school.branch.entity;

import java.util.UUID;

import com.elvencode.schoolba.audit.entity.BaseEntity;
import com.elvencode.schoolba.school.enums.ContactType;
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
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;
import org.hibernate.annotations.DynamicInsert;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

@Entity
@Table(
        name = "branch_contact_number",
        uniqueConstraints = {
                @UniqueConstraint(
                        name = "uk_branch_contact_number_branch_phone",
                        columnNames = {"branch_id", "phone_number"}
                ),
                @UniqueConstraint(
                        name = "uk_branch_contact_number_branch_display_order",
                        columnNames = {"branch_id", "display_order"}
                )
        }
)
@DynamicInsert
@Getter
@Setter
@NoArgsConstructor
@ToString(onlyExplicitlyIncluded = true)
public class BranchContactNo extends BaseEntity {

    private static final int CONTACT_TYPE_MAX_LENGTH = 32;
    private static final int PHONE_NUMBER_MAX_LENGTH = 32;
    private static final int PHONE_NUMBER_E164_MAX_LENGTH = 16;

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @ToString.Include
    private UUID id;

    @NotNull
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @OnDelete(action = OnDeleteAction.CASCADE)
    @JoinColumn(
            name = "branch_id",
            nullable = false,
            updatable = false,
            foreignKey = @ForeignKey(name = "fk_branch_contact_number_branch")
    )
    private Branch branch;

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(name = "contact_type", nullable = false, length = CONTACT_TYPE_MAX_LENGTH)
    @ToString.Include
    private ContactType contactType = ContactType.GENERAL;

    @NotBlank
    @Size(max = PHONE_NUMBER_MAX_LENGTH)
    @Pattern(regexp = "^[0-9 +()\\-]+$")
    @Column(name = "phone_number", nullable = false, length = PHONE_NUMBER_MAX_LENGTH)
    @ToString.Include
    private String phoneNumber;

    @NotBlank
    @Size(max = PHONE_NUMBER_E164_MAX_LENGTH)
    @Pattern(regexp = "^\\+[1-9][0-9]{7,14}$")
    @Column(name = "phone_number_e164", nullable = false, length = PHONE_NUMBER_E164_MAX_LENGTH)
    private String phoneNumberE164;

    @Column(name = "is_primary", nullable = false)
    private boolean primary;

    @Min(1)
    @Column(name = "display_order", nullable = false)
    private int displayOrder = 1;
}
