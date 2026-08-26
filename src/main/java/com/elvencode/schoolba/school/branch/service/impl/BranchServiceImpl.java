package com.elvencode.schoolba.school.branch.service.impl;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import com.elvencode.schoolba.common.exception.DuplicateResourceException;
import com.elvencode.schoolba.common.exception.ResourceNotFoundException;
import com.elvencode.schoolba.school.branch.dto.BranchDto;
import com.elvencode.schoolba.school.branch.dto.request.SaveBranchDetailsRequest;
import com.elvencode.schoolba.school.branch.entity.Branch;
import com.elvencode.schoolba.school.branch.mapper.BranchMapper;
import com.elvencode.schoolba.school.branch.repository.BranchRepository;
import com.elvencode.schoolba.school.branch.service.IBranchService;
import com.elvencode.schoolba.school.entity.School;
import com.elvencode.schoolba.school.repository.SchoolRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
public class BranchServiceImpl implements IBranchService {

    private final BranchRepository branchRepository;
    private final SchoolRepository schoolRepository;
    private final BranchMapper branchMapper;

    public BranchServiceImpl(
            BranchRepository branchRepository,
            SchoolRepository schoolRepository,
            BranchMapper branchMapper
    ) {
        this.branchRepository = branchRepository;
        this.schoolRepository = schoolRepository;
        this.branchMapper = branchMapper;
    }

    @Override
    @Transactional
    public BranchDto saveBranchDetails(UUID schoolId, SaveBranchDetailsRequest request) {
        if (request == null) {
            throw new IllegalArgumentException("request must not be null");
        }
        String branchCode = normalizeCode(request.code(), "branch code");
        School school = findSchool(schoolId);

        if (branchRepository.existsBySchool_IdAndCode(schoolId, branchCode)) {
            throw new DuplicateResourceException(
                    "Branch already exists with code: " + branchCode + " for school id: " + schoolId
            );
        }

        if (request.headOffice()) {
            ensureHeadOfficeDoesNotExist(schoolId);
        }

        Branch branch = branchMapper.toBranch(school, request);
        return branchMapper.toBranchDto(branchRepository.save(branch));
    }

    @Override
    public Optional<BranchDto> findActiveBranchById(UUID id) {
        return branchRepository.findByIdAndActiveTrue(requireId(id, "branch id"))
                .map(branchMapper::toBranchDto);
    }

    @Override
    public Optional<BranchDto> findBranchBySchoolIdAndCode(UUID schoolId, String branchCode) {
        return branchRepository.findBySchool_IdAndCode(
                        requireId(schoolId, "school id"),
                        normalizeCode(branchCode, "branch code")
                )
                .map(branchMapper::toBranchDto);
    }

    @Override
    public Optional<BranchDto> findActiveBranchBySchoolCodeAndBranchCode(String schoolCode, String branchCode) {
        return branchRepository.findBySchool_CodeAndCodeAndActiveTrue(
                        normalizeCode(schoolCode, "school code"),
                        normalizeCode(branchCode, "branch code")
                )
                .map(branchMapper::toBranchDto);
    }

    @Override
    public Optional<BranchDto> findActiveHeadOffice(UUID schoolId) {
        return branchRepository.findBySchool_IdAndHeadOfficeTrueAndActiveTrue(requireId(schoolId, "school id"))
                .map(branchMapper::toBranchDto);
    }

    @Override
    public boolean existsBySchoolIdAndCode(UUID schoolId, String branchCode) {
        return branchRepository.existsBySchool_IdAndCode(
                requireId(schoolId, "school id"),
                normalizeCode(branchCode, "branch code")
        );
    }

    @Override
    public List<BranchDto> findActiveBranchesBySchoolId(UUID schoolId) {
        UUID requiredSchoolId = requireId(schoolId, "school id");
        List<Branch> branches = branchRepository
                .findAllBySchool_IdAndActiveTrueOrderByHeadOfficeDescNameAsc(requiredSchoolId);

        if (branches.isEmpty() && !schoolRepository.existsById(requiredSchoolId)) {
            throw schoolNotFound(requiredSchoolId);
        }

        return branchMapper.toBranchDtoList(branches);
    }

    @Override
    public List<BranchDto> findActiveBranchesBySchoolCode(String schoolCode) {
        return branchMapper.toBranchDtoList(
                branchRepository.findAllBySchool_CodeAndActiveTrueOrderByHeadOfficeDescNameAsc(
                        normalizeCode(schoolCode, "school code")
                )
        );
    }

    private School findSchool(UUID schoolId) {
        UUID requiredSchoolId = requireId(schoolId, "school id");
        return schoolRepository.findById(requiredSchoolId)
                .orElseThrow(() -> schoolNotFound(requiredSchoolId));
    }

    private void ensureHeadOfficeDoesNotExist(UUID schoolId) {
        branchRepository.findBySchool_IdAndHeadOfficeTrue(schoolId)
                .ifPresent(headOffice -> {
                    throw new DuplicateResourceException(
                            "School already has a head office branch: " + headOffice.getCode()
                    );
                });
    }

    private static ResourceNotFoundException schoolNotFound(UUID schoolId) {
        return new ResourceNotFoundException("School not found with id: " + schoolId);
    }

    private static UUID requireId(UUID id, String fieldName) {
        if (id == null) {
            throw new IllegalArgumentException(fieldName + " must not be null");
        }
        return id;
    }

    private static String normalizeCode(String code, String fieldName) {
        if (code == null || code.isBlank()) {
            throw new IllegalArgumentException(fieldName + " must not be blank");
        }
        return code.trim();
    }
}
