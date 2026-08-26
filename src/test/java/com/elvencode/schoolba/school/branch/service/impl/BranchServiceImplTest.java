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
import com.elvencode.schoolba.school.entity.School;
import com.elvencode.schoolba.school.enums.BranchType;
import com.elvencode.schoolba.school.repository.SchoolRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class BranchServiceImplTest {

    private static final String SCHOOL_CODE = "elven";
    private static final UUID SCHOOL_ID = UUID.fromString("20000000-0000-0000-0000-000000000001");
    private static final String BRANCH_CODE = "rajagiriya";

    @Mock
    private BranchRepository branchRepository;

    @Mock
    private SchoolRepository schoolRepository;

    private BranchServiceImpl branchService;

    @BeforeEach
    void setUp() {
        branchService = new BranchServiceImpl(branchRepository, schoolRepository, new BranchMapper());
    }

    @Test
    void savesBranchDetails() {
        School school = school();
        SaveBranchDetailsRequest request = request("nawala", false);
        when(schoolRepository.findById(SCHOOL_ID)).thenReturn(Optional.of(school));
        when(branchRepository.existsBySchool_IdAndCode(SCHOOL_ID, "nawala")).thenReturn(false);
        when(branchRepository.save(any(Branch.class))).thenAnswer(invocation -> invocation.getArgument(0));

        BranchDto branchDto = branchService.saveBranchDetails(SCHOOL_ID, request);

        assertThat(branchDto.schoolCode()).isEqualTo(SCHOOL_CODE);
        assertThat(branchDto.code()).isEqualTo("nawala");
        assertThat(branchDto.name()).isEqualTo("Nawala");
        assertThat(branchDto.branchType()).isEqualTo(BranchType.BRANCH);
        assertThat(branchDto.address()).isEqualTo("Nawala Road, Nawala, Sri Lanka");
        assertThat(branchDto.headOffice()).isFalse();
        assertThat(branchDto.active()).isTrue();

        ArgumentCaptor<Branch> branchCaptor = ArgumentCaptor.forClass(Branch.class);
        verify(branchRepository).save(branchCaptor.capture());
        assertThat(branchCaptor.getValue().getSchool()).isSameAs(school);
        assertThat(branchCaptor.getValue().getCode()).isEqualTo("nawala");
    }

    @Test
    void rejectsSaveWhenSchoolDoesNotExist() {
        SaveBranchDetailsRequest request = request("nawala", false);
        when(schoolRepository.findById(SCHOOL_ID)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> branchService.saveBranchDetails(SCHOOL_ID, request))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessage("School not found with id: " + SCHOOL_ID);

        verifyNoInteractions(branchRepository);
    }

    @Test
    void rejectsNullSaveRequest() {
        assertThatThrownBy(() -> branchService.saveBranchDetails(SCHOOL_ID, null))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("request must not be null");

        verifyNoInteractions(branchRepository, schoolRepository);
    }

    @Test
    void rejectsSaveWhenBranchCodeAlreadyExistsForSchool() {
        SaveBranchDetailsRequest request = request(BRANCH_CODE, true);
        when(schoolRepository.findById(SCHOOL_ID)).thenReturn(Optional.of(school()));
        when(branchRepository.existsBySchool_IdAndCode(SCHOOL_ID, BRANCH_CODE)).thenReturn(true);

        assertThatThrownBy(() -> branchService.saveBranchDetails(SCHOOL_ID, request))
                .isInstanceOf(DuplicateResourceException.class)
                .hasMessage("Branch already exists with code: rajagiriya for school id: " + SCHOOL_ID);

        verify(branchRepository, never()).save(any(Branch.class));
    }

    @Test
    void rejectsSaveWhenHeadOfficeAlreadyExistsForSchool() {
        SaveBranchDetailsRequest request = request("nawala", true);
        when(schoolRepository.findById(SCHOOL_ID)).thenReturn(Optional.of(school()));
        when(branchRepository.existsBySchool_IdAndCode(SCHOOL_ID, "nawala")).thenReturn(false);
        when(branchRepository.findBySchool_IdAndHeadOfficeTrue(SCHOOL_ID))
                .thenReturn(Optional.of(branch("rajagiriya", "Rajagiriya", BranchType.BRANCH, true)));

        assertThatThrownBy(() -> branchService.saveBranchDetails(SCHOOL_ID, request))
                .isInstanceOf(DuplicateResourceException.class)
                .hasMessage("School already has a head office branch: rajagiriya");

        verify(branchRepository, never()).save(any(Branch.class));
    }

    @Test
    void findsActiveBranchBySchoolAndBranchCodesAsDto() {
        Branch branch = branch(BRANCH_CODE, "Rajagiriya", BranchType.BRANCH, true);
        when(branchRepository.findBySchool_CodeAndCodeAndActiveTrue(SCHOOL_CODE, BRANCH_CODE))
                .thenReturn(Optional.of(branch));

        assertThat(branchService.findActiveBranchBySchoolCodeAndBranchCode(SCHOOL_CODE, BRANCH_CODE))
                .hasValueSatisfying(branchDto -> {
                    assertThat(branchDto.schoolCode()).isEqualTo(SCHOOL_CODE);
                    assertThat(branchDto.code()).isEqualTo(BRANCH_CODE);
                    assertThat(branchDto.name()).isEqualTo("Rajagiriya");
                    assertThat(branchDto.branchType()).isEqualTo(BranchType.BRANCH);
                    assertThat(branchDto.headOffice()).isTrue();
                    assertThat(branchDto.active()).isTrue();
                });
    }

    @Test
    void returnsEmptyWhenActiveBranchDoesNotExist() {
        when(branchRepository.findBySchool_CodeAndCodeAndActiveTrue(SCHOOL_CODE, "missing-branch"))
                .thenReturn(Optional.empty());

        assertThat(branchService.findActiveBranchBySchoolCodeAndBranchCode(SCHOOL_CODE, "missing-branch"))
                .isEmpty();
    }

    @Test
    void listsActiveBranchesAsDtos() {
        when(branchRepository.findAllBySchool_CodeAndActiveTrueOrderByHeadOfficeDescNameAsc(SCHOOL_CODE))
                .thenReturn(List.of(
                        branch("rajagiriya", "Rajagiriya", BranchType.BRANCH, true),
                        branch("kaduwela-yard", "Kaduwela Training Yard", BranchType.YARD, false)
                ));

        assertThat(branchService.findActiveBranchesBySchoolCode(SCHOOL_CODE))
                .extracting(BranchDto::code)
                .containsExactly("rajagiriya", "kaduwela-yard");
    }

    @Test
    void returnsEmptyActiveBranchListWhenSchoolExists() {
        when(branchRepository.findAllBySchool_IdAndActiveTrueOrderByHeadOfficeDescNameAsc(SCHOOL_ID))
                .thenReturn(List.of());
        when(schoolRepository.existsById(SCHOOL_ID)).thenReturn(true);

        assertThat(branchService.findActiveBranchesBySchoolId(SCHOOL_ID)).isEmpty();
    }

    @Test
    void rejectsActiveBranchListWhenSchoolDoesNotExist() {
        when(branchRepository.findAllBySchool_IdAndActiveTrueOrderByHeadOfficeDescNameAsc(SCHOOL_ID))
                .thenReturn(List.of());
        when(schoolRepository.existsById(SCHOOL_ID)).thenReturn(false);

        assertThatThrownBy(() -> branchService.findActiveBranchesBySchoolId(SCHOOL_ID))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessage("School not found with id: " + SCHOOL_ID);
    }

    private static SaveBranchDetailsRequest request(String code, boolean headOffice) {
        String name = code.equals(BRANCH_CODE) ? "Rajagiriya" : "Nawala";
        String address = code.equals(BRANCH_CODE)
                ? "Cotta Road, Rajagiriya, Sri Lanka"
                : "Nawala Road, Nawala, Sri Lanka";
        return new SaveBranchDetailsRequest(code, name, BranchType.BRANCH, address, headOffice);
    }

    private static Branch branch(String code, String name, BranchType branchType, boolean headOffice) {
        return new Branch(
                school(),
                code,
                name,
                branchType,
                "Cotta Road, Rajagiriya, Sri Lanka",
                headOffice
        );
    }

    private static School school() {
        School school = new School();
        school.setCode(SCHOOL_CODE);
        return school;
    }
}
