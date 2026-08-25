package com.elvencode.schoolba.school.branch.dto;

import java.util.List;

public record BranchDetailsResponse(
        String id,
        String kind,
        String name,
        String address,
        String phone,
        boolean headOffice,
        List<LicenseClassOfferingResponse> licenseClasses
) {

    public record LicenseClassOfferingResponse(
            String code,
            String name,
            String description,
            String priceLkr
    ) {
    }
}
