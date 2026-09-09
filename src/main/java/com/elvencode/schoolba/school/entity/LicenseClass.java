package com.elvencode.schoolba.school.entity;

import java.util.UUID;

import com.elvencode.schoolba.audit.entity.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.ToString;
import org.hibernate.annotations.Immutable;

@Entity
@Table(name = "r_license_class")
@Immutable
@Getter
@NoArgsConstructor
@ToString(onlyExplicitlyIncluded = true)
public class LicenseClass extends BaseEntity {

    private static final int CODE_MAX_LENGTH = 64;
    private static final int NAME_MAX_LENGTH = 120;

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @ToString.Include
    private UUID id;

    @NotBlank
    @Size(max = CODE_MAX_LENGTH)
    @Column(name = "code", nullable = false, updatable = false, length = CODE_MAX_LENGTH, unique = true)
    @ToString.Include
    private String code;

    @NotBlank
    @Size(max = NAME_MAX_LENGTH)
    @Column(name = "name", nullable = false, updatable = false, length = NAME_MAX_LENGTH)
    @ToString.Include
    private String name;

    @Min(1)
    @Column(name = "display_order", nullable = false, updatable = false)
    private int displayOrder;

    @Column(name = "is_active", nullable = false, updatable = false)
    private boolean active = true;
}
