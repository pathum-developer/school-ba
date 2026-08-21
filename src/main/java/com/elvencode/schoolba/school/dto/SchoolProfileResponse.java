package com.elvencode.schoolba.school.dto;

public record SchoolProfileResponse(
        String name,
        String shortName,
        String hotline,
        String hotlineHref,
        String whatsappHref,
        String email,
        int established
) {
}
