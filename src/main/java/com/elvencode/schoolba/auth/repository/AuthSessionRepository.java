package com.elvencode.schoolba.auth.repository;

import com.elvencode.schoolba.auth.entity.NewSession;
import com.elvencode.schoolba.auth.entity.SessionState;
import com.elvencode.schoolba.auth.enums.AccountType;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.util.Optional;
import java.util.UUID;

import static com.elvencode.schoolba.auth.repository.JdbcTime.utc;

@Repository
public class AuthSessionRepository {

    private final JdbcClient jdbcClient;

    public AuthSessionRepository(JdbcClient jdbcClient) {
        this.jdbcClient = jdbcClient;
    }

    public void create(NewSession session) {
        jdbcClient.sql("""
                        INSERT INTO auth_session (
                            id, account_id, session_family_id, session_token_hash, session_type,
                            lifecycle_state, authorization_version, credential_version,
                            authenticated_at, last_seen_at, idle_expires_at, absolute_expires_at
                        ) VALUES (
                            :id, :accountId, :familyId, :tokenHash, 'BROWSER',
                            'ACTIVE', :authorizationVersion, :credentialVersion,
                            :authenticatedAt, :authenticatedAt, :idleExpiresAt, :absoluteExpiresAt
                        )
                        """)
                .param("id", session.sessionId())
                .param("accountId", session.accountId())
                .param("familyId", session.sessionFamilyId())
                .param("tokenHash", session.refreshTokenHash())
                .param("authorizationVersion", session.authorizationVersion())
                .param("credentialVersion", session.credentialVersion())
                .param("authenticatedAt", utc(session.authenticatedAt()))
                .param("idleExpiresAt", utc(session.idleExpiresAt()))
                .param("absoluteExpiresAt", utc(session.absoluteExpiresAt()))
                .update();

        jdbcClient.sql("""
                        INSERT INTO auth_refresh_token (
                            id, session_id, token_hash, lifecycle_state, issued_at, expires_at
                        ) VALUES (
                            :id, :sessionId, :tokenHash, 'ACTIVE', :issuedAt, :expiresAt
                        )
                        """)
                .param("id", session.refreshTokenId())
                .param("sessionId", session.sessionId())
                .param("tokenHash", session.refreshTokenHash())
                .param("issuedAt", utc(session.authenticatedAt()))
                .param("expiresAt", utc(session.absoluteExpiresAt()))
                .update();
    }

    public Optional<SessionState> findSessionState(UUID sessionId) {
        return jdbcClient.sql("""
                        SELECT auth_session.id AS session_id,
                               auth_session.account_id,
                               account.account_type,
                               account.lifecycle_state AS account_lifecycle_state,
                               account.authorization_version AS account_authorization_version,
                               account.credential_version AS account_credential_version,
                               auth_session.lifecycle_state AS session_lifecycle_state,
                               auth_session.authorization_version AS session_authorization_version,
                               auth_session.credential_version AS session_credential_version,
                               auth_session.mfa_authenticated_at,
                               auth_session.idle_expires_at,
                               auth_session.absolute_expires_at
                        FROM auth_session
                        JOIN user_account account ON account.id = auth_session.account_id
                        WHERE auth_session.id = :sessionId
                        """)
                .param("sessionId", sessionId)
                .query(this::mapSessionState)
                .optional();
    }

    private SessionState mapSessionState(ResultSet resultSet, int rowNumber) throws SQLException {
        return new SessionState(
                resultSet.getObject("session_id", UUID.class),
                resultSet.getObject("account_id", UUID.class),
                AccountType.valueOf(resultSet.getString("account_type")),
                resultSet.getString("account_lifecycle_state"),
                resultSet.getLong("account_authorization_version"),
                resultSet.getLong("account_credential_version"),
                resultSet.getString("session_lifecycle_state"),
                resultSet.getLong("session_authorization_version"),
                resultSet.getLong("session_credential_version"),
                toInstant(resultSet.getObject("mfa_authenticated_at", OffsetDateTime.class)),
                resultSet.getObject("idle_expires_at", OffsetDateTime.class).toInstant(),
                resultSet.getObject("absolute_expires_at", OffsetDateTime.class).toInstant()
        );
    }

    private Instant toInstant(OffsetDateTime value) {
        return value == null ? null : value.toInstant();
    }
}
