package com.elvencode.schoolba.school.branch.controller;

import java.util.List;
import java.util.UUID;

import com.elvencode.schoolba.auth.constants.PermissionCode;
import com.elvencode.schoolba.auth.dto.AuthenticatedIdentity;
import com.elvencode.schoolba.auth.dto.IdentityGrant;
import com.elvencode.schoolba.auth.enums.IdentityStatus;
import com.elvencode.schoolba.auth.enums.ScopeType;
import com.elvencode.schoolba.auth.jwt.JwtUtil;
import com.elvencode.schoolba.common.constants.ApplicationConstant;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.greaterThan;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class BranchControllerAuthorizationTest {

    private static final UUID IDENTITY_ID = UUID.fromString("70000000-0000-0000-0000-000000000101");
    private static final UUID SCHOOL_ID = UUID.fromString("20000000-0000-0000-0000-000000000001");
    private static final UUID STAFF_ID = UUID.fromString("60000000-0000-0000-0000-000000000001");
    private static final UUID BRANCH_ID = UUID.fromString("30000000-0000-0000-0000-000000000001");
    private static final String BRANCH_CODE = "rajagiriya";

    private final MockMvc mockMvc;
    private final JwtUtil jwtUtil;

    @Autowired
    BranchControllerAuthorizationTest(MockMvc mockMvc, JwtUtil jwtUtil) {
        this.mockMvc = mockMvc;
        this.jwtUtil = jwtUtil;
    }

    @Test
    void licenceClassApiAcceptsMatchingSchoolScopedPermission() throws Exception {
        String token = token(List.of(
                new IdentityGrant(PermissionCode.BRANCH_LICENSE_CLASS_READ, ScopeType.SCHOOL, SCHOOL_ID, null)
        ));

        mockMvc.perform(get("/api/schools/{schoolId}/branches/licence-classes", SCHOOL_ID)
                        .param("branchCode", BRANCH_CODE)
                        .header(ApplicationConstant.JWT_HEADER, ApplicationConstant.JWT_TOKEN_PREFIX + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()", greaterThan(0)));
    }

    @Test
    void licenceClassApiAcceptsMatchingBranchScopedPermission() throws Exception {
        String token = token(List.of(
                new IdentityGrant(PermissionCode.BRANCH_LICENSE_CLASS_READ, ScopeType.BRANCH, SCHOOL_ID, BRANCH_ID)
        ));

        mockMvc.perform(get("/api/schools/{schoolId}/branches/licence-classes", SCHOOL_ID)
                        .param("branchCode", BRANCH_CODE)
                        .header(ApplicationConstant.JWT_HEADER, ApplicationConstant.JWT_TOKEN_PREFIX + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()", greaterThan(0)));
    }

    @Test
    void licenceClassApiRejectsTokenWithoutReadPermission() throws Exception {
        String token = token(List.of(
                new IdentityGrant("branch:read", ScopeType.SCHOOL, SCHOOL_ID, null)
        ));

        mockMvc.perform(get("/api/schools/{schoolId}/branches/licence-classes", SCHOOL_ID)
                        .param("branchCode", BRANCH_CODE)
                        .header(ApplicationConstant.JWT_HEADER, ApplicationConstant.JWT_TOKEN_PREFIX + token))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.errorMessage").value("Access denied"));
    }

    private String token(List<IdentityGrant> grantList) {
        AuthenticatedIdentity identity = new AuthenticatedIdentity(
                IDENTITY_ID,
                "authorization_test",
                "Authorization Test",
                SCHOOL_ID,
                STAFF_ID,
                null,
                IdentityStatus.ACTIVE,
                1,
                grantList
        );
        return jwtUtil.generateJwtToken(
                org.springframework.security.authentication.UsernamePasswordAuthenticationToken.authenticated(
                        identity,
                        null,
                        identity.getAuthorities()
                )
        );
    }
}
