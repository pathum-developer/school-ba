package com.elvencode.schoolba.auth.controller;

import com.elvencode.schoolba.common.constants.ApplicationConstant;
import com.jayway.jsonpath.JsonPath;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.core.env.Environment;
import org.springframework.http.MediaType;
import org.springframework.test.context.jdbc.Sql;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.List;

import static org.hamcrest.Matchers.emptyString;
import static org.hamcrest.Matchers.not;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@Sql(statements = {
        """
        INSERT INTO public.m_staff (
            id, school_id, employee_no, full_name, national_id, date_of_birth, designation,
            employment_status, phone_number, phone_number_e164, email, address, joined_on
        )
        SELECT '60000000-0000-0000-0000-000000000101', school.id, 'E-0101', 'Elven Test Super Admin',
               '199012345679', DATE '1990-05-15', 'School Administrator', 'ACTIVE',
               '077 480 1190', '+94774801190', 'test.super.admin@elvendriving.lk',
               'Cotta Road, Rajagiriya, Sri Lanka', DATE '2026-01-01'
        FROM public.m_school school
        WHERE school.code = 'elven'
        ON CONFLICT ON CONSTRAINT uk_staff_school_employee_no DO UPDATE
        SET employment_status = 'ACTIVE',
            phone_number = EXCLUDED.phone_number,
            phone_number_e164 = EXCLUDED.phone_number_e164,
            email = EXCLUDED.email,
            updated_at = now(),
            updated_by = 'system';
        """,
        """
        INSERT INTO public.m_identity (
            id, school_id, platform_operator_id, staff_id, learner_id, username,
            phone_number, phone_number_e164, password_hash, display_name, status
        )
        SELECT '70000000-0000-0000-0000-000000000101', staff.school_id, NULL, staff.id, NULL, 'elven_super',
               '077 480 1190', '+94774801190',
               '$2a$10$OfnRkLUdXhruJgcKC3I2NO536UZBvxBuQVoE9bPBRU09rluycVyXi',
               'Elven Test Super Admin', 'ACTIVE'
        FROM public.m_staff staff
        WHERE staff.id = '60000000-0000-0000-0000-000000000101'
        ON CONFLICT ON CONSTRAINT uk_identity_username DO UPDATE
        SET password_hash = EXCLUDED.password_hash,
            status = 'ACTIVE',
            locked_until = NULL,
            failed_attempt_count = 0,
            updated_at = now(),
            updated_by = 'system';
        """,
        """
        INSERT INTO public.t_identity_role_assignment (
            identity_id, role_id, scope_type, school_id, branch_id, assignable_to, is_staff,
            staff_id, granted_by
        )
        SELECT identity.id, role.id, role.scope_type, role.school_id, NULL, role.assignable_to,
               identity.is_staff, identity.staff_id, identity.id
        FROM public.m_identity identity
        JOIN public.m_role role
          ON role.school_id = identity.school_id
         AND role.code = 'school-super-admin'
         AND role.scope_type = 'SCHOOL'
        WHERE identity.username = 'elven_super'
        ON CONFLICT ON CONSTRAINT uk_identity_role_assignment_grant DO NOTHING;
        """
})
class AuthControllerTest {

    private final MockMvc mockMvc;
    private final Environment env;

    @Autowired
    AuthControllerTest(MockMvc mockMvc, Environment env) {
        this.mockMvc = mockMvc;
        this.env = env;
    }

    @Test
    void apiLoginReturnsJwtTokenWithAuthenticatedUserClaims() throws Exception {
        MvcResult result = mockMvc.perform(post("/api/login/public")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "username": "ELVEN_SUPER",
                                  "password": "ElvenSuper@123"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("OK"))
                .andExpect(jsonPath("$.user.username").value("elven_super"))
                .andExpect(jsonPath("$.user.roleList").doesNotExist())
                .andExpect(jsonPath("$.token").value(not(emptyString())))
                .andReturn();

        String token = JsonPath.read(result.getResponse().getContentAsString(), "$.token");
        Claims claims = parseClaims(token);

        assertEquals("elven_super", claims.get("username", String.class));
        assertEquals(List.of(), claims.get("roles", List.class));
        assertEquals(
                List.of(
                        "branch:create",
                        "branch-license-class:manage",
                        "branch:manage-status",
                        "branch:read",
                        "branch:update",
                        "staff:read"
                ),
                claims.get("authorities", List.class)
        );
    }

    @Test
    void apiLoginRejectsInvalidCredentials() throws Exception {
        mockMvc.perform(post("/api/login/public")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "username": "elven_super",
                                  "password": "wrong-password"
                                }
                                """))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.errorMessage").value("Invalid username or password"));
    }

    @Test
    void jwtTokenAuthenticatesSecuredApiRequest() throws Exception {
        String token = loginToken();

        mockMvc.perform(get("/api/schools/profile")
                        .header(ApplicationConstant.JWT_HEADER, ApplicationConstant.JWT_TOKEN_PREFIX + token))
                .andExpect(status().isOk());
    }

    @Test
    void securedApiRequestRejectsInvalidJwtToken() throws Exception {
        mockMvc.perform(get("/api/schools/profile")
                        .header(ApplicationConstant.JWT_HEADER, ApplicationConstant.JWT_TOKEN_PREFIX + "invalid-token"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.errorMessage").value("Invalid token received"));
    }

    private Claims parseClaims(String token) {
        String secret = env.getProperty(
                ApplicationConstant.JWT_SECRET_KEY,
                ApplicationConstant.JWT_SECRET_DEFAULT_VALUE
        );
        SecretKey secretKey = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));

        return Jwts.parser()
                .verifyWith(secretKey)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    private String loginToken() throws Exception {
        MvcResult result = mockMvc.perform(post("/api/login/public")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "username": "elven_super",
                                  "password": "ElvenSuper@123"
                                }
                                """))
                .andExpect(status().isOk())
                .andReturn();

        return JsonPath.read(result.getResponse().getContentAsString(), "$.token");
    }
}
