package com.elvencode.schoolba.school.branch.dto;

import com.elvencode.schoolba.school.enums.BranchType;

public record BranchDto(
        String schoolCode,
        String code,
        String name,
        BranchType branchType,
        String address,
        boolean headOffice,
        boolean active
) {
}
