package com.elvencode.schoolba.school.branch.controller;

import java.util.UUID;

import com.elvencode.schoolba.AbstractIntegrationTest;
import com.elvencode.schoolba.domainclasses.Domain;
import com.elvencode.schoolba.school.entity.School;
import com.elvencode.schoolba.school.repository.SchoolRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Covers POST /api/schools/{schoolId}/branches, mapped to
 * {@code BranchController#saveBranchDetails}: the created response, the request validation,
 * and each conflict the service rejects.
 */
class SaveBranchDetailsApiTest extends AbstractIntegrationTest {

    /** WebConfig prefixes every controller with /api. */
    private static final String SAVE_BRANCH_URL = "/api/schools/{schoolId}/branches";

    private static final String BRANCH_ADDRESS = "24 Nawala Road";

    @Autowired
    private SchoolRepository schoolRepository;

    @Test
    void createsTheBranchAndReturnsItWithALocationHeader() throws Exception {
        School school = Domain.createSchool(schoolData -> schoolData.setCode("elven"));
        schoolRepository.saveAndFlush(school);

        mockMvc.perform(post(SAVE_BRANCH_URL, school.getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(branchJson("nawala", "Nawala", true)))
                .andExpect(status().isCreated())
                .andExpect(header().string(
                        "Location",
                        "http://localhost/api/schools/" + school.getId() + "/branches/nawala"))
                .andExpect(jsonPath("$.schoolCode").value("elven"))
                .andExpect(jsonPath("$.code").value("nawala"))
                .andExpect(jsonPath("$.name").value("Nawala"))
                .andExpect(jsonPath("$.branchType").value("BRANCH"))
                .andExpect(jsonPath("$.address").value(BRANCH_ADDRESS))
                .andExpect(jsonPath("$.headOffice").value(true))
                // Not part of the request: the entity defaults a new branch to active.
                .andExpect(jsonPath("$.active").value(true));
    }

    @Test
    void reportsFieldErrorsWhenTheRequestFailsValidation() throws Exception {
        School school = Domain.createSchool(schoolData -> schoolData.setCode("elven"));
        schoolRepository.saveAndFlush(school);

        mockMvc.perform(post(SAVE_BRANCH_URL, school.getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(branchJson("Nawala Branch", "   ", false)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code")
                        .value("Code must contain lowercase letters or digits separated by single hyphens"))
                .andExpect(jsonPath("$.name").value("Name must not be blank"));
    }

    @Test
    void returnsNotFoundWhenSavingAgainstAnUnknownSchool() throws Exception {
        UUID unknownSchoolId = UUID.randomUUID();

        mockMvc.perform(post(SAVE_BRANCH_URL, unknownSchoolId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(branchJson("nawala", "Nawala", false)))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.errorMessage").value("School not found with id: " + unknownSchoolId));
    }

    @Test
    void returnsConflictWhenTheBranchCodeAlreadyExistsInTheSchool() throws Exception {
        School school = Domain.createSchool(schoolData -> {
            schoolData.setCode("elven");
            schoolData.setBranches(Domain.createBranches(
                    branchData -> branchData.setCode("nawala")
            ));
        });
        schoolRepository.saveAndFlush(school);

        mockMvc.perform(post(SAVE_BRANCH_URL, school.getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(branchJson("nawala", "Nawala Two", false)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.errorMessage")
                        .value("Branch already exists with code: nawala for school id: " + school.getId()));
    }

    @Test
    void returnsConflictWhenTheSchoolAlreadyHasAHeadOffice() throws Exception {
        School school = Domain.createSchool(schoolData -> {
            schoolData.setCode("elven");
            schoolData.setBranches(Domain.createBranches(
                    branchData -> {
                        branchData.setCode("rajagiriya");
                        branchData.setHeadOffice(true);
                    }
            ));
        });
        schoolRepository.saveAndFlush(school);

        mockMvc.perform(post(SAVE_BRANCH_URL, school.getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(branchJson("nawala", "Nawala", true)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.errorMessage")
                        .value("School already has a head office branch: rajagiriya"));
    }

    /** Only the fields a test varies are parameters; the rest stay constant across these tests. */
    private static String branchJson(String code, String name, boolean headOffice) {
        return """
                {
                  "code": "%s",
                  "name": "%s",
                  "branchType": "BRANCH",
                  "address": "%s",
                  "headOffice": %s
                }
                """.formatted(code, name, BRANCH_ADDRESS, headOffice);
    }
}
