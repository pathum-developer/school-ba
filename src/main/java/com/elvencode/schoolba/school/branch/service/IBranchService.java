package com.elvencode.schoolba.school.branch.service;

import java.util.List;
import java.util.UUID;

import com.elvencode.schoolba.school.branch.dto.BranchDto;
import com.elvencode.schoolba.school.branch.dto.request.PatchBranchDetailsRequest;
import com.elvencode.schoolba.school.branch.dto.request.SaveBranchDetailsRequest;

public interface IBranchService {

    BranchDto saveBranchDetails(UUID schoolId, SaveBranchDetailsRequest request);

    BranchDto patchBranchDetails(UUID schoolId, String branchCode, PatchBranchDetailsRequest request);

    List<BranchDto> findActiveBranchesBySchoolId(UUID schoolId);

    void deleteBranchByCode(UUID schoolId, String branchCode);

}
