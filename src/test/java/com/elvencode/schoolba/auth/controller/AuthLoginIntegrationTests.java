package com.elvencode.schoolba.auth.controller;

import com.elvencode.schoolba.auth.enums.AuthenticationEventType;
import com.elvencode.schoolba.auth.jwt.AccessTokenClaims;
import com.elvencode.schoolba.auth.jwt.JwtTokenService;
import com.elvencode.schoolba.auth.service.SecureTokenService;
import com.jayway.jsonpath.JsonPath;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.ZoneOffset;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.not;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(properties =
        "app.auth.jwt.signing-key-base64=MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=")
@AutoConfigureMockMvc
@Transactional
class AuthLoginIntegrationTests {

    private static final String IDENTIFIER = "student.login@example.com";
    private static final String PASSWORD = "Correct horse battery staple!";

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JdbcClient jdbcClient;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtTokenService jwtTokenService;

    @Autowired
    private SecureTokenService secureTokenService;

    @Test
    void loginCreatesRevocableSessionAndReturnsRefreshTokenOnlyAsCookie() throws Exception {
        UUID accountId = createLoginAccount("STUDENT", IDENTIFIER);

        String responseBody = mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .header(HttpHeaders.USER_AGENT, "school-ui-integration-test")
                        .content(loginJson(IDENTIFIER, PASSWORD)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").isString())
                .andExpect(jsonPath("$.tokenType").value("Bearer"))
                .andExpect(jsonPath("$.expiresIn").value(600))
                .andExpect(header().string(HttpHeaders.SET_COOKIE, containsString("school_refresh=")))
                .andExpect(header().string(HttpHeaders.SET_COOKIE, containsString("HttpOnly")))
                .andExpect(header().string(HttpHeaders.SET_COOKIE, containsString("Secure")))
                .andExpect(header().string(HttpHeaders.SET_COOKIE, containsString("SameSite=Lax")))
                .andExpect(header().string(HttpHeaders.SET_COOKIE, containsString("Path=/api/auth")))
                .andExpect(content().string(not(containsString("refreshToken"))))
                .andReturn()
                .getResponse()
                .getContentAsString();

        String accessToken = JsonPath.read(responseBody, "$.accessToken");
        AccessTokenClaims claims = jwtTokenService.parse(accessToken);

        assertThat(claims.accountId()).isEqualTo(accountId);
        assertThat(count("auth_session", "account_id", accountId)).isEqualTo(1);
        assertThat(count("auth_refresh_token", "session_id", claims.sessionId())).isEqualTo(1);
        assertThat(eventCount(accountId, AuthenticationEventType.LOGIN_SUCCEEDED)).isEqualTo(1);
    }

    @Test
    void invalidPasswordReturnsGenericFailureAndCreatesNoSession() throws Exception {
        UUID accountId = createLoginAccount("STUDENT", IDENTIFIER);

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(loginJson(IDENTIFIER, "wrong password")))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("AUTHENTICATION_FAILED"))
                .andExpect(jsonPath("$.message").value("Authentication failed."))
                .andExpect(header().doesNotExist(HttpHeaders.SET_COOKIE));

        assertThat(count("auth_session", "account_id", accountId)).isZero();
        assertThat(eventCount(accountId, AuthenticationEventType.LOGIN_FAILED)).isEqualTo(1);
    }

    @Test
    void staffPasswordPhaseCreatesMfaChallengeInsteadOfSession() throws Exception {
        UUID accountId = createLoginAccount("STAFF", "staff.login@example.com");
        createMfaFactor(accountId);

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(loginJson("staff.login@example.com", PASSWORD)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("mfa_required"))
                .andExpect(jsonPath("$.challengeId").isString())
                .andExpect(jsonPath("$.expiresAt").isString())
                .andExpect(header().doesNotExist(HttpHeaders.SET_COOKIE));

        assertThat(count("auth_session", "account_id", accountId)).isZero();
        assertThat(count("auth_challenge", "account_id", accountId)).isEqualTo(1);
        assertThat(eventCount(accountId, AuthenticationEventType.LOGIN_MFA_REQUIRED)).isEqualTo(1);
    }

    @Test
    void activeStaffAccountWithoutMfaCannotBypassEnrollment() throws Exception {
        UUID accountId = createLoginAccount("STAFF", "staff.no-mfa@example.com");

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(loginJson("staff.no-mfa@example.com", PASSWORD)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value("MFA_ENROLLMENT_REQUIRED"))
                .andExpect(header().doesNotExist(HttpHeaders.SET_COOKIE));

        assertThat(count("auth_session", "account_id", accountId)).isZero();
        assertThat(eventCount(accountId, AuthenticationEventType.LOGIN_MFA_ENROLLMENT_REQUIRED))
                .isEqualTo(1);
    }

    @Test
    void rateLimitedIdentifierSkipsAuthentication() throws Exception {
        byte[] identifierHash = secureTokenService.hash(IDENTIFIER);
        byte[] sourceFingerprintHash = secureTokenService.hash("127.0.0.1\n");
        for (int attempt = 0; attempt < 5; attempt++) {
            insertAuthenticationFailure(identifierHash, sourceFingerprintHash);
        }

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(loginJson(IDENTIFIER, PASSWORD)))
                .andExpect(status().isTooManyRequests())
                .andExpect(header().string(HttpHeaders.RETRY_AFTER, "900"))
                .andExpect(jsonPath("$.code").value("LOGIN_RATE_LIMITED"));
    }

    private UUID createLoginAccount(String accountType, String identifier) {
        UUID accountId = UUID.randomUUID();
        Instant now = Instant.now();
        jdbcClient.sql("""
                        INSERT INTO user_account (
                            id, account_type, lifecycle_state, identity_verified_at,
                            authorization_version, credential_version, created_at, status_changed_at
                        ) VALUES (
                            :id, :accountType, 'ACTIVE', :now, 0, 0, :now, :now
                        )
                        """)
                .param("id", accountId)
                .param("accountType", accountType)
                .param("now", now.atOffset(ZoneOffset.UTC))
                .update();

        jdbcClient.sql("""
                        INSERT INTO account_contact (
                            id, account_id, contact_type, normalized_value, lifecycle_state,
                            is_login_identifier, verified_at, created_at
                        ) VALUES (
                            :id, :accountId, 'EMAIL', :identifier, 'ACTIVE', TRUE, :now, :now
                        )
                        """)
                .param("id", UUID.randomUUID())
                .param("accountId", accountId)
                .param("identifier", identifier)
                .param("now", now.atOffset(ZoneOffset.UTC))
                .update();

        jdbcClient.sql("""
                        INSERT INTO auth_credential (
                            id, account_id, credential_type, secret_hash, hash_algorithm,
                            lifecycle_state, credential_revision, created_at
                        ) VALUES (
                            :id, :accountId, 'PASSWORD', :secretHash, 'BCRYPT',
                            'ACTIVE', 0, :now
                        )
                        """)
                .param("id", UUID.randomUUID())
                .param("accountId", accountId)
                .param("secretHash", passwordEncoder.encode(PASSWORD))
                .param("now", now.atOffset(ZoneOffset.UTC))
                .update();
        return accountId;
    }

    private void createMfaFactor(UUID accountId) {
        Instant now = Instant.now();
        jdbcClient.sql("""
                        INSERT INTO mfa_factor (
                            id, account_id, factor_type, secret_reference,
                            lifecycle_state, enrolled_at, created_at
                        ) VALUES (
                            :id, :accountId, 'TOTP', :secretReference,
                            'ACTIVE', :now, :now
                        )
                        """)
                .param("id", UUID.randomUUID())
                .param("accountId", accountId)
                .param("secretReference", "test://mfa/" + accountId)
                .param("now", now.atOffset(ZoneOffset.UTC))
                .update();
    }

    private void insertAuthenticationFailure(byte[] identifierHash, byte[] sourceFingerprintHash) {
        jdbcClient.sql("""
                        INSERT INTO authentication_event (
                            id, event_type, identifier_hash, source_fingerprint_hash, occurred_at
                        ) VALUES (
                            :id, 'LOGIN_FAILED', :identifierHash, :sourceFingerprintHash, :occurredAt
                        )
                        """)
                .param("id", UUID.randomUUID())
                .param("identifierHash", identifierHash)
                .param("sourceFingerprintHash", sourceFingerprintHash)
                .param("occurredAt", Instant.now().atOffset(ZoneOffset.UTC))
                .update();
    }

    private long count(String table, String column, UUID id) {
        String sql = "SELECT COUNT(*) FROM " + table + " WHERE " + column + " = :id";
        return jdbcClient.sql(sql).param("id", id).query(Long.class).single();
    }

    private long eventCount(UUID accountId, AuthenticationEventType eventType) {
        return jdbcClient.sql("""
                        SELECT COUNT(*) FROM authentication_event
                        WHERE account_id = :accountId AND event_type = :eventType
                        """)
                .param("accountId", accountId)
                .param("eventType", eventType.name())
                .query(Long.class)
                .single();
    }

    private String loginJson(String identifier, String password) {
        return """
                {"identifier":"%s","password":"%s"}
                """.formatted(identifier, password);
    }
}
