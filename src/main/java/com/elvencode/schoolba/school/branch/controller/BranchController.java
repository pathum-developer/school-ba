package com.elvencode.schoolba.school.branch.controller;

import java.net.URI;
import java.util.List;
import java.util.UUID;

import com.elvencode.schoolba.school.branch.dto.BranchDto;
import com.elvencode.schoolba.school.branch.dto.request.PatchBranchDetailsRequest;
import com.elvencode.schoolba.school.branch.dto.request.SaveBranchDetailsRequest;
import com.elvencode.schoolba.school.branch.service.IBranchService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Pattern;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

@RestController
@RequestMapping("/schools/{schoolId}/branches")
public class BranchController {

    private static final String API_VERSION_1_BASELINE = "1.0+";
    private static final String BRANCH_CODE_REGEXP = "^[a-z0-9]+(?:-[a-z0-9]+)*$";
    private static final String BRANCH_CODE_MESSAGE =
            "Branch code must contain lowercase letters or digits separated by single hyphens";

    private final IBranchService branchService;

    public BranchController(IBranchService branchService) {
        this.branchService = branchService;
    }

    @GetMapping(value = "/active", version = API_VERSION_1_BASELINE)
    public ResponseEntity<List<BranchDto>> findActiveBranchesBySchoolId(
            @PathVariable UUID schoolId
    ) {
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

    @PatchMapping(value = "/{branchCode}", version = API_VERSION_1_BASELINE)
    public ResponseEntity<BranchDto> patchBranchDetails(
            @PathVariable UUID schoolId,
            @PathVariable
            @Pattern(regexp = BRANCH_CODE_REGEXP, message = BRANCH_CODE_MESSAGE)
            String branchCode,
            @Valid @RequestBody PatchBranchDetailsRequest request
    ) {
        return ResponseEntity.ok(branchService.patchBranchDetails(schoolId, branchCode, request));
    }

    @DeleteMapping(value = "/{branchCode}", version = API_VERSION_1_BASELINE)
    public ResponseEntity<Void> deleteBranchByCode(
            @PathVariable UUID schoolId,
            @PathVariable
            @Pattern(regexp = BRANCH_CODE_REGEXP, message = BRANCH_CODE_MESSAGE)
            String branchCode
    ) {
        branchService.deleteBranchByCode(schoolId, branchCode);
        return ResponseEntity.noContent().build();
    }
}
