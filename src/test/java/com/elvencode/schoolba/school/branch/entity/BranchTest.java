package com.elvencode.schoolba.school.branch.entity;

import com.elvencode.schoolba.school.entity.School;
import com.elvencode.schoolba.school.enums.BranchType;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatIllegalArgumentException;

class BranchTest {

    private final School school = new School();

    @Test
    void createsActiveBranchWithNormalizedDetails() {
        Branch branch = new Branch(
                school,
                " rajagiriya ",
                " Rajagiriya ",
                BranchType.BRANCH,
                " Cotta Road, Rajagiriya ",
                true
        );

        assertThat(branch.getSchool()).isSameAs(school);
        assertThat(branch.getCode()).isEqualTo("rajagiriya");
        assertThat(branch.getName()).isEqualTo("Rajagiriya");
        assertThat(branch.getBranchType()).isEqualTo(BranchType.BRANCH);
        assertThat(branch.getAddress()).isEqualTo("Cotta Road, Rajagiriya");
        assertThat(branch.isHeadOffice()).isTrue();
        assertThat(branch.isActive()).isTrue();
    }

    @Test
    void updatesMutableDetailsAndLifecycleState() {
        Branch branch = new Branch(
                school,
                "kaduwela",
                "Kaduwela",
                BranchType.BRANCH,
                "Kaduwela",
                false
        );

        branch.updateDetails(
                " Kaduwela Training Yard ",
                BranchType.YARD,
                " Avissawella Road, Kaduwela ",
                false
        );
        branch.deactivate();

        assertThat(branch.getName()).isEqualTo("Kaduwela Training Yard");
        assertThat(branch.getBranchType()).isEqualTo(BranchType.YARD);
        assertThat(branch.getAddress()).isEqualTo("Avissawella Road, Kaduwela");
        assertThat(branch.isActive()).isFalse();

        branch.activate();

        assertThat(branch.isActive()).isTrue();
    }

    @Test
    void rejectsInvalidBranchCode() {
        assertThatIllegalArgumentException()
                .isThrownBy(() -> new Branch(
                        school,
                        "Rajagiriya Branch",
                        "Rajagiriya",
                        BranchType.BRANCH,
                        "Cotta Road, Rajagiriya",
                        true
                ))
                .withMessage("code must contain lowercase letters or digits separated by single hyphens");
    }

    @Test
    void rejectsBlankMutableDetails() {
        Branch branch = new Branch(
                school,
                "rajagiriya",
                "Rajagiriya",
                BranchType.BRANCH,
                "Cotta Road, Rajagiriya",
                true
        );

        assertThatIllegalArgumentException()
                .isThrownBy(() -> branch.updateDetails(" ", BranchType.BRANCH, "Address", true))
                .withMessage("name must not be blank");
    }
}
