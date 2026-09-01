package com.elvencode.schoolba.school.dto;

import com.elvencode.schoolba.school.enums.TenantStatus;

public record SchoolProfileDto(
        String code,
        String name,
        String shortName,
        Short establishedYear,
        String hotlineHref,
        String whatsappHref,
        String email,
        TenantStatus tenantStatus
) {
}
