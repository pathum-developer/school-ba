package com.elvencode.schoolba.school.controller;

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
 * Covers GET /api/schools/getProfile, mapped to {@code SchoolController#getProfile}.
 */
class GetProfileApiTest extends AbstractIntegrationTest {

    /**
     * WebConfig prefixes every controller with /api, so the mapping declared on SchoolController
     * resolves here and not at /schools/getProfile.
     */
    private static final String GET_PROFILE_URL = "/api/schools/getProfile";

    /** SchoolServiceImpl looks the profile up by this code, which it hardcodes. */
    private static final String CONFIGURED_SCHOOL_CODE = "elven";

    @Autowired
    private SchoolRepository schoolRepository;

    @Test
    void returnsTheProfileOfTheConfiguredSchool() throws Exception {
        School school = Domain.createSchool(schoolData -> {
            schoolData.setCode(CONFIGURED_SCHOOL_CODE);
            schoolData.setName("Northern Driving Academy");
            schoolData.setShortName("Northern");
            schoolData.setEstablishedYear((short) 1987);
            schoolData.setHotlineHref("tel:+94112223344");
            schoolData.setWhatsappHref("https://wa.me/94112223344");
            schoolData.setEmail("hello@northern.lk");
            schoolData.setBranches(Domain.createBranches(
                    branchData -> {
                        branchData.setCode("ra-rathnapura");
                        branchData.setName("Rathnapura Branch");
                    }
            ));
        });
        schoolRepository.saveAndFlush(school);

        mockMvc.perform(get(GET_PROFILE_URL))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.code").value(CONFIGURED_SCHOOL_CODE))
                .andExpect(jsonPath("$.name").value("Northern Driving Academy"))
                .andExpect(jsonPath("$.shortName").value("Northern"))
                .andExpect(jsonPath("$.establishedYear").value(1987))
                .andExpect(jsonPath("$.hotlineHref").value("tel:+94112223344"))
                .andExpect(jsonPath("$.whatsappHref").value("https://wa.me/94112223344"))
                .andExpect(jsonPath("$.email").value("hello@northern.lk"))
                .andExpect(jsonPath("$.singletonKey").value(true));
    }
}
