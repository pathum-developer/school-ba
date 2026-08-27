package com.elvencode.schoolba.audit.entity;

import jakarta.persistence.Column;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.MappedSuperclass;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.proxy.HibernateProxy;
import org.springframework.data.annotation.CreatedBy;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedBy;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter @Setter
@MappedSuperclass
@EntityListeners(AuditingEntityListener.class)
public abstract class BaseEntity {

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @CreatedBy
    @Column(name = "created_by", nullable = false, updatable = false, length = 20)
    private String createdBy;

    @LastModifiedDate
    @Column(name = "updated_at", nullable = false,insertable = false)
    private LocalDateTime updatedAt;

    @LastModifiedBy
    @Column(name = "updated_by", nullable = false, length = 20,insertable = false)
    private String updatedBy;

    /**
     * Every entity is identified by a generated UUID. Declared here so equality can be
     * defined once for all entities instead of being repeated in each subclass.
     */
    public abstract UUID getId();

    /**
     * Entities are equal when they are the same instance, or when they are the same entity
     * type and share a non-null identifier. A null identifier means the entity has not been
     * persisted yet, so two distinct unsaved entities are never equal.
     */
    @Override
    public final boolean equals(Object other) {
        if (this == other) {
            return true;
        }
        if (other == null || effectiveClass(this) != effectiveClass(other)) {
            return false;
        }
        UUID id = getId();
        return id != null && id.equals(((BaseEntity) other).getId());
    }

    /**
     * Constant per entity type so the hash never changes when a transient entity is assigned
     * an identifier on persist. A changing hash would strand the entity in the wrong bucket
     * of any hash-based collection it had already been added to.
     */
    @Override
    public final int hashCode() {
        return effectiveClass(this).hashCode();
    }

    /**
     * Unwraps a lazy-loading proxy to the entity type it stands in for, so a proxy and a
     * fully loaded instance of the same row compare as the same type.
     */
    private static Class<?> effectiveClass(Object entity) {
        if (entity instanceof HibernateProxy proxy) {
            return proxy.getHibernateLazyInitializer().getPersistentClass();
        }
        return entity.getClass();
    }
}
