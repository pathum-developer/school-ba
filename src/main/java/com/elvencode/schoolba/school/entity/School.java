package com.elvencode.schoolba.school.entity;

import java.time.OffsetDateTime;
import java.util.UUID;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import org.hibernate.annotations.DynamicInsert;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "school")
@DynamicInsert
@Getter
@Setter
public class School {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, length = 64, unique = true)
    private String code;

    @Column(nullable = false, length = 160)
    private String name;

    @Column(name = "short_name", nullable = false, length = 80)
    private String shortName;

    @Column(name = "established_year", nullable = false)
    private Short establishedYear;

    @Column(name = "hotline_href", nullable = false, length = 64)
    private String hotlineHref;

    @Column(name = "whatsapp_href", nullable = false, length = 128)
    private String whatsappHref;

    @Column(nullable = false, length = 254)
    private String email;

    @Column(name = "singleton_key", nullable = false, unique = true)
    private Boolean singletonKey;

    @Column(name = "created_at", nullable = false)
    private OffsetDateTime createdAt;

    @Column(name = "created_by", nullable = false)
    private UUID createdBy;

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;

    @Column(name = "updated_by", nullable = false)
    private UUID updatedBy;
}
