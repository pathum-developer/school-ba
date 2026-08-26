package com.elvencode.schoolba.school.branch.repository;

import java.util.UUID;

import com.elvencode.schoolba.school.branch.entity.Branch;
import com.elvencode.schoolba.school.enums.BranchType;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
class BranchRepositoryTest {

    private static final UUID ELVEN_SCHOOL_ID = UUID.fromString("20000000-0000-0000-0000-000000000001");
    private static final String ELVEN_SCHOOL_CODE = "elven";

    @Autowired
    private BranchRepository branchRepository;

    @Test
    void findsActiveBranchByStableSchoolAndBranchCodes() {
        assertThat(branchRepository.findBySchool_CodeAndCodeAndActiveTrue(ELVEN_SCHOOL_CODE, "rajagiriya"))
                .hasValueSatisfying(branch -> {
                    assertThat(branch.getCode()).isEqualTo("rajagiriya");
                    assertThat(branch.getName()).isEqualTo("Rajagiriya");
                    assertThat(branch.getBranchType()).isEqualTo(BranchType.BRANCH);
                    assertThat(branch.isHeadOffice()).isTrue();
                    assertThat(branch.isActive()).isTrue();
                });
    }

    @Test
    void findsActiveHeadOfficeForSchool() {
        assertThat(branchRepository.findBySchool_IdAndHeadOfficeTrueAndActiveTrue(ELVEN_SCHOOL_ID))
                .hasValueSatisfying(branch -> assertThat(branch.getCode()).isEqualTo("rajagiriya"));
    }

    @Test
    void detectsDuplicateBranchCodeWithinSchool() {
        assertThat(branchRepository.existsBySchool_IdAndCode(ELVEN_SCHOOL_ID, "wellawatte")).isTrue();
        assertThat(branchRepository.existsBySchool_IdAndCode(ELVEN_SCHOOL_ID, "missing-branch")).isFalse();
    }

    @Test
    void listsActiveBranchesWithHeadOfficeFirstThenName() {
        assertThat(branchRepository.findAllBySchool_CodeAndActiveTrueOrderByHeadOfficeDescNameAsc(ELVEN_SCHOOL_CODE))
                .extracting(Branch::getCode)
                .containsExactly("rajagiriya", "battaramulla", "kaduwela-yard", "wellawatte");
    }
}
