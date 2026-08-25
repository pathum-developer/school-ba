package com.elvencode.schoolba.school.branch.controller;

import com.elvencode.schoolba.school.branch.dto.BranchDetailsResponse;
import com.elvencode.schoolba.school.branch.service.BranchService;
import org.springframework.http.HttpHeaders;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/branches")
public class BranchController {

    private final BranchService branchService;

    public BranchController(BranchService branchService) {
        this.branchService = branchService;
    }

}
