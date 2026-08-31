package com.elvencode.schoolba.school.branch.service.impl;

import com.elvencode.schoolba.common.exception.ResourceNotFoundException;
import com.elvencode.schoolba.school.branch.dto.BranchDto;
import com.elvencode.schoolba.school.branch.entity.Branch;
import com.elvencode.schoolba.school.branch.mapper.BranchMapper;
import com.elvencode.schoolba.school.branch.repository.BranchRepository;
import com.elvencode.schoolba.school.enums.BranchType;
import com.elvencode.schoolba.school.repository.SchoolRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertThrows;
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
}
