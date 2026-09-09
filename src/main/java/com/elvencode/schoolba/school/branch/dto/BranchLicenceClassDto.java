package com.elvencode.schoolba.school.branch.dto;

import java.math.BigDecimal;

public record BranchLicenceClassDto(
        String code,
        String name,
        BigDecimal priceLkr
) {
}
