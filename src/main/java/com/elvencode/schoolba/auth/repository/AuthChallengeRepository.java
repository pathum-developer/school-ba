package com.elvencode.schoolba.auth.repository;

import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

import static com.elvencode.schoolba.auth.repository.JdbcTime.utc;

@Repository
public class AuthChallengeRepository {

    private final JdbcClient jdbcClient;

    public AuthChallengeRepository(JdbcClient jdbcClient) {
        this.jdbcClient = jdbcClient;
    }

    public void replacePendingLoginChallenge(
            UUID challengeId,
            UUID accountId,
            UUID factorId,
            byte[] challengeHash,
            Instant createdAt,
            Instant expiresAt
    ) {
        byte[] hash = Objects.requireNonNull(
                challengeHash,
                "challengeHash must not be null"
        ).clone();

        jdbcClient.sql("""
                        UPDATE auth_challenge
                        SET lifecycle_state = 'INVALIDATED', invalidated_at = :invalidatedAt
                        WHERE account_id = :accountId
                          AND challenge_type = 'LOGIN_MFA'
                          AND lifecycle_state = 'PENDING'
                        """)
                .param("invalidatedAt", utc(createdAt))
                .param("accountId", accountId)
                .update();

        jdbcClient.sql("""
                        INSERT INTO auth_challenge (
                            id, account_id, mfa_factor_id, challenge_type, challenge_hash,
                            lifecycle_state, attempt_count, expires_at, created_at
                        ) VALUES (
                            :id, :accountId, :factorId, 'LOGIN_MFA', :challengeHash,
                            'PENDING', 0, :expiresAt, :createdAt
                        )
                        """)
                .param("id", challengeId)
                .param("accountId", accountId)
                .param("factorId", factorId)
                .param("challengeHash", hash)
                .param("expiresAt", utc(expiresAt))
                .param("createdAt", utc(createdAt))
                .update();
    }
}
