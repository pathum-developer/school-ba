package com.elvencode.schoolba.school.branch.dto.request;

import java.util.List;

import com.elvencode.schoolba.school.enums.BranchType;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record PatchBranchDetailsRequest(
        @Pattern(regexp = ".*\\S.*", message = "Name must not be blank")
        @Size(max = 160, message = "Name must not exceed 160 characters")
        String name,

        BranchType branchType,

        @Pattern(regexp = ".*\\S.*", message = "Address must not be blank")
        @Size(max = 255, message = "Address must not exceed 255 characters")
        String address,

        Boolean headOffice,

        Boolean active,

        List<@Valid @NotNull(message = "Contact number must not be null") SaveContactNoRequest> contactNoList
) {
}
