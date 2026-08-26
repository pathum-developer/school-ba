package com.elvencode.schoolba.school.branch.service;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import com.elvencode.schoolba.school.branch.dto.BranchDto;
import com.elvencode.schoolba.school.branch.dto.SaveBranchDetailsRequest;

public interface IBranchService {

    BranchDto saveBranchDetails(UUID schoolId, SaveBranchDetailsRequest request);

    Optional<BranchDto> findActiveBranchById(UUID id);

    Optional<BranchDto> findBranchBySchoolIdAndCode(UUID schoolId, String branchCode);

    Optional<BranchDto> findActiveBranchBySchoolCodeAndBranchCode(String schoolCode, String branchCode);

    Optional<BranchDto> findActiveHeadOffice(UUID schoolId);

    boolean existsBySchoolIdAndCode(UUID schoolId, String branchCode);

    List<BranchDto> findActiveBranchesBySchoolId(UUID schoolId);

    List<BranchDto> findActiveBranchesBySchoolCode(String schoolCode);
}
