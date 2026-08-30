package com.elvencode.schoolba.school.branch.dto.request;

import com.elvencode.schoolba.school.enums.ContactType;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record SaveContactNoRequest(
        ContactType contactType,

        @NotBlank(message = "Phone number must not be blank")
        @Size(max = 32, message = "Phone number must not exceed 32 characters")
        @Pattern(
                regexp = "^[0-9 +()\\-]+$",
                message = "Phone number can contain only digits, spaces, plus signs, parentheses, and hyphens"
        )
        String phoneNumber,

        @NotBlank(message = "E.164 phone number must not be blank")
        @Size(max = 16, message = "E.164 phone number must not exceed 16 characters")
        @Pattern(
                regexp = "^\\+[1-9][0-9]{7,14}$",
                message = "E.164 phone number must start with + and contain 8 to 15 digits"
        )
        String phoneNumberE164,

        boolean primary,

        @Min(value = 1, message = "Display order must be greater than zero")
        int displayOrder
) {
}
