package com.elvencode.schoolba.school.branch.controller;

import com.elvencode.schoolba.school.branch.dto.BranchDetailsResponse;
import com.elvencode.schoolba.school.branch.service.BranchService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/school/branches")
public class BranchController {

    private final BranchService branchService;

    public BranchController(BranchService branchService) {
        this.branchService = branchService;
    }

    @GetMapping(value = {
            "/code/{branchCode}",
            "/code/{branchCode}/name/{branchName}"
    }, version = "1.0+")
    public BranchDetailsResponse getBranchDetailsById(
            @PathVariable String branchCode,
            @PathVariable(required = false) String branchName
    ) {
        if (branchName == null) {
            return branchService.getBranchDetailsById(branchCode);
        }

        return branchService.getBranchDetailsByCodeAndName(branchCode, branchName);
    }
}
