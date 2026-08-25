package com.elvencode.schoolba.school.dto;

public record SchoolProfileDto(
        String code,
        String name,
        String shortName,
        Short establishedYear,
        String hotlineHref,
        String whatsappHref,
        String email,
        Boolean singletonKey
) {
}
