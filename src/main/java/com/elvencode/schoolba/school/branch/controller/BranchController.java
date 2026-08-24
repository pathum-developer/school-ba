package com.elvencode.schoolba.school.branch.controller;

import com.elvencode.schoolba.school.branch.dto.BranchDetailsResponse;
import com.elvencode.schoolba.school.branch.service.BranchService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/branches")
public class BranchController {

    private final BranchService branchService;

    public BranchController(BranchService branchService) {
        this.branchService = branchService;
    }

    @GetMapping(value = {
            "/code/{branchCode}",
            "/code/{branchCode}/name/{branchName}"
    }, version = "1.0+")
    public BranchDetailsResponse getBranchDetailsByCodeOrName(
            @PathVariable (name="branchCode") String Code,
            @PathVariable(required = false) String branchName
    ) {
        if (branchName == null) {
            throw new RuntimeException("Branch details lookup is not implemented yet."+Code);
        }
        throw new RuntimeException("Branch details lookup is not implemented yet."+Code+" "+branchName);
    }

    @GetMapping(value = "/code/{branchCode}/address/{address}", version = "1.0+")
    public BranchDetailsResponse getBranchDetailsByCodeAndAddress(@PathVariable Map<String,String> filterMap) {
        throw new RuntimeException("getBranchDetailsByCodeAndAddress is not implemented yet."+filterMap.get("branchCode") +"->"+ filterMap.get("address"));
    }
}
