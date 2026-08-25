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

    //     ToDo
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

    //     ToDo
    @GetMapping(value = "/code/{branchCode}/address/{address}", version = "1.0+")
    public BranchDetailsResponse getBranchDetailsByCodeAndAddress(@PathVariable Map<String,String> filterMap) {
        throw new RuntimeException("getBranchDetailsByCodeAndAddress is not implemented yet."+filterMap.get("branchCode") +"->"+ filterMap.get("address"));
    }

    //     ToDo
    @GetMapping(value = "/search", version = "1.0+")
    public BranchDetailsResponse getBranchDetailsByCode(@RequestParam (required = false, defaultValue = "001", name = "branchCode") String Code) {
        throw new RuntimeException("getBranchDetailsByCod is not implemented yet."+Code);
    }

    //     ToDo
    @GetMapping(value = "/headers", version = "1.0+")
    public BranchDetailsResponse readRequestHeaders(@RequestHeader("User-Agent") String userAgent,@RequestHeader(name = "User-location", required = false) String userLocation) {
        throw new RuntimeException("readRequestHeaders is not implemented yet."+userAgent +" -> "+userLocation);
    }

    //     ToDo
    @GetMapping(value = "/user-headers", version = "1.0+")
    public BranchDetailsResponse readRequestHeadersByHttpHeaders(@RequestHeader HttpHeaders requestHeaders) {
        throw new RuntimeException("readRequestHeaders is not implemented yet."+requestHeaders.get("User-Agent") );
    }
}
