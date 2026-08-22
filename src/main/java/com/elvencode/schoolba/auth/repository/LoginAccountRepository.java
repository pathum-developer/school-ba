package com.elvencode.schoolba.auth.repository;

import com.elvencode.schoolba.auth.entity.LoginAccount;
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
public class LoginAccountRepository {

    private static final String FIND_BY_LOGIN_IDENTIFIER = """
            SELECT account.id AS account_id,
                   account.account_type,
                   account.lifecycle_state,
                   account.identity_verified_at,
                   account.authorization_version,
                   account.credential_version,
                   credential.secret_hash,
                   credential.hash_algorithm
            FROM account_contact contact
            JOIN user_account account ON account.id = contact.account_id
            JOIN auth_credential credential ON credential.account_id = account.id
            WHERE contact.normalized_value = :identifier
              AND contact.lifecycle_state = 'ACTIVE'
              AND contact.is_login_identifier = TRUE
              AND contact.verified_at IS NOT NULL
              AND credential.credential_type = 'PASSWORD'
              AND credential.lifecycle_state = 'ACTIVE'
            """;

    private final JdbcClient jdbcClient;

    public LoginAccountRepository(JdbcClient jdbcClient) {
        this.jdbcClient = jdbcClient;
    }

    public Optional<LoginAccount> findByLoginIdentifier(String normalizedIdentifier) {
        return jdbcClient.sql(FIND_BY_LOGIN_IDENTIFIER)
                .param("identifier", normalizedIdentifier)
                .query(this::mapLoginAccount)
                .optional();
    }

    public void markPasswordUsed(UUID accountId, Instant usedAt) {
        jdbcClient.sql("""
                        UPDATE auth_credential
                        SET last_used_at = :usedAt
                        WHERE account_id = :accountId
                          AND credential_type = 'PASSWORD'
                          AND lifecycle_state = 'ACTIVE'
                        """)
                .param("usedAt", utc(usedAt))
                .param("accountId", accountId)
                .update();
    }

    private LoginAccount mapLoginAccount(ResultSet resultSet, int rowNumber) throws SQLException {
        OffsetDateTime verifiedAt = resultSet.getObject("identity_verified_at", OffsetDateTime.class);
        return new LoginAccount(
                resultSet.getObject("account_id", UUID.class),
                AccountType.valueOf(resultSet.getString("account_type")),
                resultSet.getString("lifecycle_state"),
                verifiedAt == null ? null : verifiedAt.toInstant(),
                resultSet.getLong("authorization_version"),
                resultSet.getLong("credential_version"),
                resultSet.getString("secret_hash"),
                resultSet.getString("hash_algorithm")
        );
    }
}
