package com.elvencode.schoolba.school.branch.service;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import com.elvencode.schoolba.common.exception.DuplicateResourceException;
import com.elvencode.schoolba.common.exception.ResourceNotFoundException;
import com.elvencode.schoolba.school.branch.dto.BranchDto;
import com.elvencode.schoolba.school.branch.dto.SaveBranchDetailsRequest;
import com.elvencode.schoolba.school.branch.entity.Branch;
import com.elvencode.schoolba.school.branch.mapper.BranchMapper;
import com.elvencode.schoolba.school.branch.repository.BranchRepository;
import com.elvencode.schoolba.school.entity.School;
import com.elvencode.schoolba.school.repository.SchoolRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
public class BranchService implements IBranchService {

    private final BranchRepository branchRepository;
    private final SchoolRepository schoolRepository;
    private final BranchMapper branchMapper;

    public BranchService(
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
        String branchCode = normalizedBranchCode(request);
        School school = schoolRepository.findById(schoolId)
                .orElseThrow(() -> new ResourceNotFoundException("School not found with id: " + schoolId));

        if (branchRepository.existsBySchoolIdAndCode(schoolId, branchCode)) {
            throw new DuplicateResourceException(
                    "Branch already exists with code: " + branchCode + " for school id: " + schoolId
            );
        }

        if (request.headOffice()) {
            branchRepository.findBySchoolIdAndHeadOfficeTrueAndActiveTrue(schoolId)
                    .ifPresent(headOffice -> {
                        throw new DuplicateResourceException(
                                "School already has an active head office branch: " + headOffice.getCode()
                        );
                    });
        }

        Branch branch = branchMapper.toBranch(school, request);
        return branchMapper.toBranchDto(branchRepository.save(branch));
    }

    @Override
    public Optional<BranchDto> findActiveBranchById(UUID id) {
        return branchRepository.findByIdAndActiveTrue(id)
                .map(branchMapper::toBranchDto);
    }

    @Override
    public Optional<BranchDto> findBranchBySchoolIdAndCode(UUID schoolId, String branchCode) {
        return branchRepository.findBySchoolIdAndCode(schoolId, branchCode)
                .map(branchMapper::toBranchDto);
    }

    @Override
    public Optional<BranchDto> findActiveBranchBySchoolCodeAndBranchCode(String schoolCode, String branchCode) {
        return branchRepository.findBySchoolCodeAndCodeAndActiveTrue(schoolCode, branchCode)
                .map(branchMapper::toBranchDto);
    }

    @Override
    public Optional<BranchDto> findActiveHeadOffice(UUID schoolId) {
        return branchRepository.findBySchoolIdAndHeadOfficeTrueAndActiveTrue(schoolId)
                .map(branchMapper::toBranchDto);
    }

    @Override
    public boolean existsBySchoolIdAndCode(UUID schoolId, String branchCode) {
        return branchRepository.existsBySchoolIdAndCode(schoolId, branchCode);
    }

    @Override
    public List<BranchDto> findActiveBranchesBySchoolId(UUID schoolId) {
        return branchMapper.toBranchDtoList(
                branchRepository.findAllBySchoolIdAndActiveTrueOrderByHeadOfficeDescNameAsc(schoolId)
        );
    }

    @Override
    public List<BranchDto> findActiveBranchesBySchoolCode(String schoolCode) {
        return branchMapper.toBranchDtoList(
                branchRepository.findAllBySchoolCodeAndActiveTrueOrderByHeadOfficeDescNameAsc(schoolCode)
        );
    }

    private static String normalizedBranchCode(SaveBranchDetailsRequest request) {
        if (request == null || request.code() == null || request.code().isBlank()) {
            throw new IllegalArgumentException("code must not be blank");
        }
        return request.code().trim();
    }
}
