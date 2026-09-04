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
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.hamcrest.Matchers.emptyString;
import static org.hamcrest.Matchers.not;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Signs in against m_identity, so it needs a database carrying the demo seed.
 *
 * <p>The context is deliberately not overridden to reference,demo here. Changeset 029 inserts
 * into m_app_user and changeset 030 renames that table to m_identity, so the seed applies only
 * while it runs ahead of the rename, on a database built in a single pass. Turning demo on for
 * an existing reference-only database makes 029 fail on a table that no longer exists.
 */
@SpringBootTest
@AutoConfigureMockMvc
class AuthControllerTest {

    /** The bootstrap administrator seeded by changeset 029, which runs in the demo context. */
    private static final String IDENTITY_ID = "70000000-0000-0000-0000-000000000001";
    private static final String SCHOOL_ID = "20000000-0000-0000-0000-000000000001";
    private static final String STAFF_ID = "60000000-0000-0000-0000-000000000001";
    private static final String USERNAME = "elven_super";
    private static final String PASSWORD = "ElvenSuper@123";

    /**
     * Every permission the school super admin role carries, in the order the principal sorts
     * them. Asserted in full so that changing what the bootstrap role grants has to be an
     * explicit decision here as well.
     */
    private static final List<String> EXPECTED_PERMISSION_CODE_LIST = List.of(
            "branch-license-class:manage",
            "branch:create",
            "branch:manage-status",
            "branch:read",
            "branch:update",
            "staff:read"
    );

    private final MockMvc mockMvc;
    private final Environment env;

    @Autowired
    AuthControllerTest(MockMvc mockMvc, Environment env) {
        this.mockMvc = mockMvc;
        this.env = env;
    }

    @Test
    void apiLoginReturnsJwtTokenNamingTheAuthenticatedAccount() throws Exception {
        Claims claims = parseClaims(loginToken());

        // The subject names the account, which is what a JWT subject is for.
        assertEquals(IDENTITY_ID, claims.getSubject());
        assertEquals(USERNAME, claims.get(ApplicationConstant.JWT_USERNAME_CLAIM, String.class));
        assertEquals(SCHOOL_ID, claims.get(ApplicationConstant.JWT_SCHOOL_ID_CLAIM, String.class));
        assertEquals(STAFF_ID, claims.get(ApplicationConstant.JWT_STAFF_ID_CLAIM, String.class));
        assertEquals(1, claims.get(ApplicationConstant.JWT_AUTHORIZATION_VERSION_CLAIM, Integer.class));

        // A staff login has no learner, and the claim is left out rather than written as null.
        assertNull(claims.get(ApplicationConstant.JWT_LEARNER_ID_CLAIM, String.class));
    }

    /**
     * The scope is the half a bare permission code cannot carry: a school-wide branch:read and
     * a branch-scoped one are the same string, and only these fields separate them.
     */
    @Test
    void apiLoginReturnsJwtTokenCarryingEveryGrantWithItsScope() throws Exception {
        Claims claims = parseClaims(loginToken());

        List<?> grantList = claims.get(ApplicationConstant.JWT_GRANT_LIST_CLAIM, List.class);
        assertEquals(1, grantList.size(), "every grant shares one scope, so they group into one entry");

        Map<?, ?> grant = (Map<?, ?>) grantList.getFirst();
        assertEquals("SCHOOL", grant.get(ApplicationConstant.JWT_GRANT_SCOPE_TYPE));
        assertEquals(SCHOOL_ID, grant.get(ApplicationConstant.JWT_GRANT_SCHOOL_ID));
        assertNull(grant.get(ApplicationConstant.JWT_GRANT_BRANCH_ID));
        assertEquals(
                EXPECTED_PERMISSION_CODE_LIST,
                grant.get(ApplicationConstant.JWT_GRANT_PERMISSION_CODE_LIST)
        );
    }

    @Test
    void apiLoginRejectsInvalidCredentials() throws Exception {
        mockMvc.perform(post("/api/login/public")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(loginBody(USERNAME, "wrong-password")))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.errorMessage").value("Invalid username or password"));
    }

    @Test
    void jwtTokenAuthenticatesSecuredApiRequest() throws Exception {
        mockMvc.perform(get("/api/schools/profile")
                        .header(ApplicationConstant.JWT_HEADER, ApplicationConstant.JWT_TOKEN_PREFIX + loginToken()))
                .andExpect(status().isOk());
    }

    @Test
    void securedApiRequestRejectsInvalidJwtToken() throws Exception {
        mockMvc.perform(get("/api/schools/profile")
                        .header(ApplicationConstant.JWT_HEADER, ApplicationConstant.JWT_TOKEN_PREFIX + "invalid-token"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.errorMessage").value("Invalid token received"));
    }

    private String loginBody(String username, String password) {
        return """
                {
                  "username": "%s",
                  "password": "%s"
                }
                """.formatted(username, password);
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
                        .content(loginBody(USERNAME, PASSWORD)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("OK"))
                .andExpect(jsonPath("$.user.username").value(USERNAME))
                .andExpect(jsonPath("$.token").value(not(emptyString())))
                .andReturn();

        return JsonPath.read(result.getResponse().getContentAsString(), "$.token");
    }
}
