package com.elvencode.schoolba.school.branch.controller;

import java.net.URI;
import java.util.List;
import java.util.UUID;

import com.elvencode.schoolba.school.branch.dto.BranchDto;
import com.elvencode.schoolba.school.branch.dto.SaveBranchDetailsRequest;
import com.elvencode.schoolba.school.branch.service.IBranchService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

@RestController
@RequestMapping("/schools/{schoolId}/branches")
public class BranchController {

    private static final String API_VERSION_1_BASELINE = "1.0+";

    private final IBranchService branchService;

    public BranchController(IBranchService branchService) {
        this.branchService = branchService;
    }

    @GetMapping(value = "/active", version = API_VERSION_1_BASELINE)
    public ResponseEntity<List<BranchDto>> findActiveBranchesBySchoolId(@PathVariable UUID schoolId) {
        return ResponseEntity.ok(branchService.findActiveBranchesBySchoolId(schoolId));
    }

    @PostMapping(version = API_VERSION_1_BASELINE)
    public ResponseEntity<BranchDto> saveBranchDetails(
            @PathVariable UUID schoolId,
            @Valid @RequestBody SaveBranchDetailsRequest request
    ) {
        BranchDto branch = branchService.saveBranchDetails(schoolId, request);
        URI location = ServletUriComponentsBuilder.fromCurrentRequest()
                .path("/{branchCode}")
                .buildAndExpand(branch.code())
                .toUri();
        return ResponseEntity.created(location).body(branch);
    }
}
