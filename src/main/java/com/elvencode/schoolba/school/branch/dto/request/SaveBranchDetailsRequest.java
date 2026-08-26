package com.elvencode.schoolba.school.branch.dto.request;

import com.elvencode.schoolba.school.enums.BranchType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record SaveBranchDetailsRequest(
        @NotBlank(message = "Code must not be blank")
        @Size(max = 64, message = "Code must not exceed 64 characters")
        @Pattern(
                regexp = "^[a-z0-9]+(?:-[a-z0-9]+)*$",
                message = "Code must contain lowercase letters or digits separated by single hyphens"
        )
        String code,

        @NotBlank(message = "Name must not be blank")
        @Size(max = 160, message = "Name must not exceed 160 characters")
        String name,

        @NotNull(message = "Branch type must not be null")
        BranchType branchType,

        @NotBlank(message = "Address must not be blank")
        @Size(max = 255, message = "Address must not exceed 255 characters")
        String address,

        boolean headOffice
) {
}
