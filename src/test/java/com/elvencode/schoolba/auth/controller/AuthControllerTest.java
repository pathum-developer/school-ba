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

import static org.hamcrest.Matchers.emptyString;
import static org.hamcrest.Matchers.not;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
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
                                  "username": "ElvenUser",
                                  "password": "ElvenPassword"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("OK"))
                .andExpect(jsonPath("$.user.username").value("ElvenUser"))
                .andExpect(jsonPath("$.user.roleList").doesNotExist())
                .andExpect(jsonPath("$.token").value(not(emptyString())))
                .andReturn();

        String token = JsonPath.read(result.getResponse().getContentAsString(), "$.token");
        Claims claims = parseClaims(token);

        assertEquals("ElvenUser", claims.get("username", String.class));
        assertEquals(List.of("USER"), claims.get("roles", List.class));
    }

    @Test
    void apiLoginRejectsInvalidCredentials() throws Exception {
        mockMvc.perform(post("/api/login/public")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "username": "ElvenUser",
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
                                  "username": "ElvenUser",
                                  "password": "ElvenPassword"
                                }
                                """))
                .andExpect(status().isOk())
                .andReturn();

        return JsonPath.read(result.getResponse().getContentAsString(), "$.token");
    }
}
