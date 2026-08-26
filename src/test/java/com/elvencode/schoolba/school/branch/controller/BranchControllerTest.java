package com.elvencode.schoolba.school.branch.controller;

import java.util.List;
import java.util.UUID;

import com.elvencode.schoolba.common.exception.GlobalExceptionHandler;
import com.elvencode.schoolba.school.branch.dto.BranchDto;
import com.elvencode.schoolba.school.branch.dto.request.SaveBranchDetailsRequest;
import com.elvencode.schoolba.school.branch.service.IBranchService;
import com.elvencode.schoolba.school.enums.BranchType;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.accept.ApiVersionStrategy;
import org.springframework.web.servlet.config.annotation.ApiVersionConfigurer;

import static org.hamcrest.Matchers.hasSize;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ExtendWith(MockitoExtension.class)
class BranchControllerTest {

    private static final UUID SCHOOL_ID = UUID.fromString("20000000-0000-0000-0000-000000000001");
    private static final MediaType ELVEN_API_MEDIA_TYPE =
            MediaType.parseMediaType("application/vnd.elven+json");
    private static final MediaType API_VERSION_1_MEDIA_TYPE =
            MediaType.parseMediaType("application/vnd.elven+json;v=1.0");

    @Mock
    private IBranchService branchService;

    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(new BranchController(branchService))
                .setControllerAdvice(new GlobalExceptionHandler())
                .setApiVersionStrategy(apiVersionStrategy())
                .build();
    }

    @Test
    void findsActiveBranchesBySchoolId() throws Exception {
        when(branchService.findActiveBranchesBySchoolId(SCHOOL_ID))
                .thenReturn(List.of(
                        new BranchDto(
                                "elven",
                                "rajagiriya",
                                "Rajagiriya",
                                BranchType.BRANCH,
                                "Cotta Road, Rajagiriya, Sri Lanka",
                                true,
                                true
                        )
                ));

        mockMvc.perform(get("/schools/{schoolId}/branches/active", SCHOOL_ID)
                        .accept(API_VERSION_1_MEDIA_TYPE))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].schoolCode").value("elven"))
                .andExpect(jsonPath("$[0].code").value("rajagiriya"))
                .andExpect(jsonPath("$[0].name").value("Rajagiriya"))
                .andExpect(jsonPath("$[0].branchType").value("BRANCH"))
                .andExpect(jsonPath("$[0].address").value("Cotta Road, Rajagiriya, Sri Lanka"))
                .andExpect(jsonPath("$[0].headOffice").value(true))
                .andExpect(jsonPath("$[0].active").value(true));

        verify(branchService).findActiveBranchesBySchoolId(SCHOOL_ID);
    }

    @Test
    void savesBranchDetails() throws Exception {
        SaveBranchDetailsRequest request = new SaveBranchDetailsRequest(
                "nawala",
                "Nawala",
                BranchType.BRANCH,
                "Nawala Road, Nawala, Sri Lanka",
                false
        );
        when(branchService.saveBranchDetails(eq(SCHOOL_ID), eq(request)))
                .thenReturn(new BranchDto(
                        "elven",
                        "nawala",
                        "Nawala",
                        BranchType.BRANCH,
                        "Nawala Road, Nawala, Sri Lanka",
                        false,
                        true
                ));

        mockMvc.perform(post("/schools/{schoolId}/branches", SCHOOL_ID)
                        .accept(API_VERSION_1_MEDIA_TYPE)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "code": "nawala",
                                  "name": "Nawala",
                                  "branchType": "BRANCH",
                                  "address": "Nawala Road, Nawala, Sri Lanka",
                                  "headOffice": false
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(header().string("Location", "http://localhost/schools/" + SCHOOL_ID + "/branches/nawala"))
                .andExpect(jsonPath("$.schoolCode").value("elven"))
                .andExpect(jsonPath("$.code").value("nawala"))
                .andExpect(jsonPath("$.name").value("Nawala"))
                .andExpect(jsonPath("$.branchType").value("BRANCH"))
                .andExpect(jsonPath("$.address").value("Nawala Road, Nawala, Sri Lanka"))
                .andExpect(jsonPath("$.headOffice").value(false))
                .andExpect(jsonPath("$.active").value(true));

        verify(branchService).saveBranchDetails(eq(SCHOOL_ID), eq(request));
    }

    @Test
    void rejectsInvalidSaveBranchDetailsRequest() throws Exception {
        mockMvc.perform(post("/schools/{schoolId}/branches", SCHOOL_ID)
                        .accept(API_VERSION_1_MEDIA_TYPE)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "code": "Nawala Branch",
                                  "name": "",
                                  "branchType": "BRANCH",
                                  "address": "Nawala Road, Nawala, Sri Lanka",
                                  "headOffice": false
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code")
                        .value("Code must contain lowercase letters or digits separated by single hyphens"))
                .andExpect(jsonPath("$.name").value("Name must not be blank"));

        verifyNoInteractions(branchService);
    }

    @Test
    void rejectsNullSaveBranchDetailsRequest() throws Exception {
        mockMvc.perform(post("/schools/{schoolId}/branches", SCHOOL_ID)
                        .accept(API_VERSION_1_MEDIA_TYPE)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("null"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorMessage").value("Request body is invalid or unreadable"));

        verifyNoInteractions(branchService);
    }

    private static ApiVersionStrategy apiVersionStrategy() {
        TestApiVersionConfigurer configurer = new TestApiVersionConfigurer();
        configurer
                .useMediaTypeParameter(ELVEN_API_MEDIA_TYPE, "v")
                .addSupportedVersions("1.0")
                .setDefaultVersion("1.0");
        return configurer.getStrategy();
    }

    private static final class TestApiVersionConfigurer extends ApiVersionConfigurer {

        private ApiVersionStrategy getStrategy() {
            return getApiVersionStrategy();
        }
    }
}
