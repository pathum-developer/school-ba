package com.elvencode.schoolba.school.branch.entity;

import java.math.BigDecimal;
import java.util.UUID;

import com.elvencode.schoolba.audit.entity.BaseEntity;
import com.elvencode.schoolba.school.entity.LicenseClass;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.ForeignKey;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.ToString;
import org.hibernate.annotations.Immutable;

@Entity
@Table(name = "x_branch_license_class")
@Immutable
@Getter
@NoArgsConstructor
@ToString(onlyExplicitlyIncluded = true)
public class BranchLicenseClass extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @ToString.Include
    private UUID id;

    @NotNull
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(
            name = "branch_id",
            nullable = false,
            updatable = false,
            foreignKey = @ForeignKey(name = "fk_branch_license_class_branch")
    )
    private Branch branch;

    @NotNull
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(
            name = "license_class_id",
            nullable = false,
            updatable = false,
            foreignKey = @ForeignKey(name = "fk_branch_license_class_license_class")
    )
    private LicenseClass licenseClass;

    @NotNull
    @DecimalMin(value = "0.01")
    @Column(name = "price_lkr", nullable = false, updatable = false, precision = 12, scale = 2)
    private BigDecimal priceLkr;
}
