package com.elvencode.schoolba.school.branch.controller;

import java.util.UUID;

import com.elvencode.schoolba.AbstractIntegrationTest;
import com.elvencode.schoolba.domainclasses.Domain;
import com.elvencode.schoolba.school.entity.School;
import com.elvencode.schoolba.school.repository.SchoolRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Covers GET /api/schools/{schoolId}/branches/active, mapped to
 * {@code BranchController#findActiveBranchesBySchoolId}. The save endpoint on the same
 * controller is covered by {@link SaveBranchDetailsApiTest}.
 */
class FindActiveBranchesBySchoolIdApiTest extends AbstractIntegrationTest {

    /** WebConfig prefixes every controller with /api. */
    private static final String ACTIVE_BRANCHES_URL = "/api/schools/{schoolId}/branches/active";

    @Autowired
    private SchoolRepository schoolRepository;

    @Test
    void listsActiveBranchesWithHeadOfficeFirstThenNameAscending() throws Exception {
        School school = Domain.createSchool(schoolData -> {
            schoolData.setCode("elven");
            schoolData.setBranches(Domain.createBranches(
                    branchData -> {
                        branchData.setCode("wellawatte");
                        branchData.setName("Wellawatte");
                    },
                    branchData -> {
                        branchData.setCode("rajagiriya");
                        branchData.setName("Rajagiriya");
                        branchData.setAddress("12 Rajagiriya Road");
                        branchData.setHeadOffice(true);
                    },
                    branchData -> {
                        branchData.setCode("battaramulla");
                        branchData.setName("Battaramulla");
                    },
                    branchData -> {
                        branchData.setCode("closed-yard");
                        branchData.setName("Closed Yard");
                        branchData.setActive(false);
                    }
            ));
        });
        schoolRepository.saveAndFlush(school);

        mockMvc.perform(get(ACTIVE_BRANCHES_URL, school.getId()))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                // The inactive branch is filtered out, leaving three.
                .andExpect(jsonPath("$.length()").value(3))
                // Head office first, then the rest by name ascending.
                .andExpect(jsonPath("$[0].code").value("rajagiriya"))
                .andExpect(jsonPath("$[1].code").value("battaramulla"))
                .andExpect(jsonPath("$[2].code").value("wellawatte"))
                // Full response shape, checked on the head office.
                .andExpect(jsonPath("$[0].schoolCode").value("elven"))
                .andExpect(jsonPath("$[0].name").value("Rajagiriya"))
                .andExpect(jsonPath("$[0].branchType").value("BRANCH"))
                .andExpect(jsonPath("$[0].address").value("12 Rajagiriya Road"))
                .andExpect(jsonPath("$[0].headOffice").value(true))
                .andExpect(jsonPath("$[0].active").value(true))
                .andExpect(jsonPath("$[1].headOffice").value(false));
    }

    @Test
    void returnsAnEmptyListWhenTheSchoolHasNoActiveBranches() throws Exception {
        School school = Domain.createSchool(schoolData -> {
            schoolData.setCode("elven");
            schoolData.setBranches(Domain.createBranches(
                    branchData -> {
                        branchData.setCode("closed-yard");
                        branchData.setActive(false);
                    }
            ));
        });
        schoolRepository.saveAndFlush(school);

        mockMvc.perform(get(ACTIVE_BRANCHES_URL, school.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));
    }

    @Test
    void returnsNotFoundWhenTheSchoolDoesNotExist() throws Exception {
        UUID unknownSchoolId = UUID.randomUUID();

        mockMvc.perform(get(ACTIVE_BRANCHES_URL, unknownSchoolId))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.errorMessage").value("School not found with id: " + unknownSchoolId));
    }
}
