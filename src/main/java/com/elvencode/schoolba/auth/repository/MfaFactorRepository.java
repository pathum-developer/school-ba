package com.elvencode.schoolba.auth.repository;

import com.elvencode.schoolba.auth.entity.MfaFactor;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public class MfaFactorRepository {

    private final JdbcClient jdbcClient;

    public MfaFactorRepository(JdbcClient jdbcClient) {
        this.jdbcClient = jdbcClient;
    }

    public Optional<MfaFactor> findActiveFactor(UUID accountId) {
        return jdbcClient.sql("""
                        SELECT id, factor_type
                        FROM mfa_factor
                        WHERE account_id = :accountId
                          AND lifecycle_state = 'ACTIVE'
                        ORDER BY created_at
                        LIMIT 1
                        """)
                .param("accountId", accountId)
                .query((resultSet, rowNumber) -> new MfaFactor(
                        resultSet.getObject("id", UUID.class),
                        resultSet.getString("factor_type")
                ))
                .optional();
    }
}
