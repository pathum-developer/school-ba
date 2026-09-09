package com.elvencode.schoolba.school.branch.service.impl;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import com.elvencode.schoolba.common.exception.ResourceNotFoundException;
import com.elvencode.schoolba.school.branch.dto.BranchDto;
import com.elvencode.schoolba.school.branch.dto.BranchLicenceClassDto;
import com.elvencode.schoolba.school.branch.entity.Branch;
import com.elvencode.schoolba.school.branch.mapper.BranchMapper;
import com.elvencode.schoolba.school.branch.repository.BranchRepository;
import com.elvencode.schoolba.school.enums.BranchType;
import com.elvencode.schoolba.school.repository.SchoolRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class BranchServiceImplTest {

    private static final UUID SCHOOL_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final String BRANCH_CODE = "rajagiriya";

    @Mock
    private BranchRepository branchRepository;

    @Mock
    private SchoolRepository schoolRepository;

    @Mock
    private BranchMapper branchMapper;

    @Test
    void findBranchDetailsByCodeReturnsBranchDetails() {
        BranchServiceImpl branchService = new BranchServiceImpl(branchRepository, schoolRepository, branchMapper);
        Branch branch = new Branch();
        BranchDto expectedBranch = new BranchDto(
                "elven",
                BRANCH_CODE,
                "Rajagiriya",
                BranchType.BRANCH,
                "No 1, Main Road",
                false,
                true,
                List.of()
        );

        when(branchRepository.findDetailedBySchool_IdAndCode(SCHOOL_ID, BRANCH_CODE))
                .thenReturn(Optional.of(branch));
        when(branchMapper.toBranchDto(branch)).thenReturn(expectedBranch);

        BranchDto actualBranch = branchService.findBranchDetailsByCode(SCHOOL_ID, BRANCH_CODE);

        assertSame(expectedBranch, actualBranch);
        verify(branchRepository).findDetailedBySchool_IdAndCode(SCHOOL_ID, BRANCH_CODE);
        verify(branchMapper).toBranchDto(branch);
    }

    @Test
    void findBranchDetailsByCodeThrowsWhenBranchDoesNotExist() {
        BranchServiceImpl branchService = new BranchServiceImpl(branchRepository, schoolRepository, branchMapper);

        when(branchRepository.findDetailedBySchool_IdAndCode(SCHOOL_ID, BRANCH_CODE))
                .thenReturn(Optional.empty());
        when(schoolRepository.existsById(SCHOOL_ID)).thenReturn(true);

        ResourceNotFoundException exception = assertThrows(
                ResourceNotFoundException.class,
                () -> branchService.findBranchDetailsByCode(SCHOOL_ID, BRANCH_CODE)
        );

        assertEquals(
                "Branch not found with code: " + BRANCH_CODE + " for school id: " + SCHOOL_ID,
                exception.getMessage()
        );
    }

    @Test
    void findLicenceClassListByBranchCodeReturnsLicenceClasses() {
        BranchServiceImpl branchService = new BranchServiceImpl(branchRepository, schoolRepository, branchMapper);
        List<BranchLicenceClassDto> expectedLicenceClassList = List.of(
                new BranchLicenceClassDto("B", "Dual purpose motor vehicle", new BigDecimal("48000.00")),
                new BranchLicenceClassDto("C", "Motor lorry", new BigDecimal("96000.00"))
        );

        when(branchRepository.findLicenceClassListBySchoolIdAndBranchCode(SCHOOL_ID, BRANCH_CODE))
                .thenReturn(expectedLicenceClassList);

        List<BranchLicenceClassDto> actualLicenceClassList =
                branchService.findLicenceClassListByBranchCode(SCHOOL_ID, BRANCH_CODE);

        assertEquals(expectedLicenceClassList, actualLicenceClassList);
        verify(branchRepository).findLicenceClassListBySchoolIdAndBranchCode(SCHOOL_ID, BRANCH_CODE);
    }

    @Test
    void findLicenceClassListByBranchCodeReturnsEmptyListWhenBranchHasNoOfferings() {
        BranchServiceImpl branchService = new BranchServiceImpl(branchRepository, schoolRepository, branchMapper);

        when(branchRepository.findLicenceClassListBySchoolIdAndBranchCode(SCHOOL_ID, BRANCH_CODE))
                .thenReturn(List.of());
        when(branchRepository.existsBySchool_IdAndCode(SCHOOL_ID, BRANCH_CODE)).thenReturn(true);

        List<BranchLicenceClassDto> actualLicenceClassList =
                branchService.findLicenceClassListByBranchCode(SCHOOL_ID, BRANCH_CODE);

        assertTrue(actualLicenceClassList.isEmpty());
        verify(branchRepository).findLicenceClassListBySchoolIdAndBranchCode(SCHOOL_ID, BRANCH_CODE);
        verify(branchRepository).existsBySchool_IdAndCode(SCHOOL_ID, BRANCH_CODE);
    }

    @Test
    void findLicenceClassListByBranchCodeThrowsWhenBranchDoesNotExist() {
        BranchServiceImpl branchService = new BranchServiceImpl(branchRepository, schoolRepository, branchMapper);

        when(branchRepository.findLicenceClassListBySchoolIdAndBranchCode(SCHOOL_ID, BRANCH_CODE))
                .thenReturn(List.of());
        when(branchRepository.existsBySchool_IdAndCode(SCHOOL_ID, BRANCH_CODE)).thenReturn(false);
        when(schoolRepository.existsById(SCHOOL_ID)).thenReturn(true);

        ResourceNotFoundException exception = assertThrows(
                ResourceNotFoundException.class,
                () -> branchService.findLicenceClassListByBranchCode(SCHOOL_ID, BRANCH_CODE)
        );

        assertEquals(
                "Branch not found with code: " + BRANCH_CODE + " for school id: " + SCHOOL_ID,
                exception.getMessage()
        );
    }

    @Test
    void deleteBranchByCodeDeletesExistingBranch() {
        BranchServiceImpl branchService = new BranchServiceImpl(branchRepository, schoolRepository, branchMapper);

        when(branchRepository.deleteBySchoolIdAndCode(SCHOOL_ID, BRANCH_CODE)).thenReturn(1);

        branchService.deleteBranchByCode(SCHOOL_ID, BRANCH_CODE);

        verify(branchRepository).deleteBySchoolIdAndCode(SCHOOL_ID, BRANCH_CODE);
    }

    @Test
    void deleteBranchByCodeThrowsWhenBranchDoesNotExist() {
        BranchServiceImpl branchService = new BranchServiceImpl(branchRepository, schoolRepository, branchMapper);

        when(branchRepository.deleteBySchoolIdAndCode(SCHOOL_ID, BRANCH_CODE)).thenReturn(0);
        when(schoolRepository.existsById(SCHOOL_ID)).thenReturn(true);

        ResourceNotFoundException exception = assertThrows(
                ResourceNotFoundException.class,
                () -> branchService.deleteBranchByCode(SCHOOL_ID, BRANCH_CODE)
        );

        assertEquals(
                "Branch not found with code: " + BRANCH_CODE + " for school id: " + SCHOOL_ID,
                exception.getMessage()
        );
    }
}
