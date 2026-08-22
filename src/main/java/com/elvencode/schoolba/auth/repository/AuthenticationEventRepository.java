package com.elvencode.schoolba.auth.repository;

import com.elvencode.schoolba.auth.enums.AuthenticationEventType;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

import java.sql.Types;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

import static com.elvencode.schoolba.auth.repository.JdbcTime.utc;

@Repository
public class AuthenticationEventRepository {

    private final JdbcClient jdbcClient;

    public AuthenticationEventRepository(JdbcClient jdbcClient) {
        this.jdbcClient = jdbcClient;
    }

    public long countRecentFailures(
            byte[] identifierHash,
            byte[] sourceFingerprintHash,
            Instant since
    ) {
        byte[] safeIdentifierHash = Objects.requireNonNull(
                identifierHash,
                "identifierHash must not be null"
        ).clone();
        byte[] safeSourceFingerprintHash = Objects.requireNonNull(
                sourceFingerprintHash,
                "sourceFingerprintHash must not be null"
        ).clone();

        Long count = jdbcClient.sql("""
                        SELECT COUNT(*)
                        FROM authentication_event
                        WHERE identifier_hash = :identifierHash
                          AND source_fingerprint_hash = :sourceFingerprintHash
                          AND event_type = 'LOGIN_FAILED'
                          AND occurred_at >= :since
                        """)
                .param("identifierHash", safeIdentifierHash)
                .param("sourceFingerprintHash", safeSourceFingerprintHash)
                .param("since", utc(since))
                .query(Long.class)
                .single();
        return count;
    }

    public void record(
            AuthenticationEventType eventType,
            UUID accountId,
            UUID sessionId,
            byte[] identifierHash,
            byte[] sourceFingerprintHash,
            Instant occurredAt
    ) {
        byte[] safeIdentifierHash = identifierHash == null ? null : identifierHash.clone();
        byte[] safeSourceFingerprintHash = sourceFingerprintHash == null
                ? null
                : sourceFingerprintHash.clone();

        jdbcClient.sql("""
                        INSERT INTO authentication_event (
                            id, account_id, session_id, event_type, identifier_hash,
                            source_fingerprint_hash, occurred_at
                        ) VALUES (
                            :id, :accountId, :sessionId, :eventType, :identifierHash,
                            :sourceFingerprintHash, :occurredAt
                        )
                        """)
                .param("id", UUID.randomUUID())
                .param("accountId", accountId, Types.OTHER)
                .param("sessionId", sessionId, Types.OTHER)
                .param("eventType", eventType.name())
                .param("identifierHash", safeIdentifierHash)
                .param("sourceFingerprintHash", safeSourceFingerprintHash)
                .param("occurredAt", utc(occurredAt))
                .update();
    }
}
