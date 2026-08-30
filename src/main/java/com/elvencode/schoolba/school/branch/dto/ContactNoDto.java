package com.elvencode.schoolba.school.branch.dto;

import com.elvencode.schoolba.school.enums.ContactType;

public record ContactNoDto(
        ContactType contactType,
        String phoneNumber,
        String phoneNumberE164,
        boolean primary,
        int displayOrder
) {
}
