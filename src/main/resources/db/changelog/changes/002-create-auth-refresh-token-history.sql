--liquibase formatted sql

--changeset elvencode:011-create-auth-refresh-token-history labels:administration
CREATE TABLE auth_refresh_token (
    id UUID PRIMARY KEY,
    session_id UUID NOT NULL,
    token_hash BYTEA NOT NULL UNIQUE,
    lifecycle_state VARCHAR(16) NOT NULL DEFAULT 'ACTIVE',
    issued_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    replaced_at TIMESTAMP WITH TIME ZONE,
    revoked_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT fk_auth_refresh_token_session
        FOREIGN KEY (session_id) REFERENCES auth_session (id),
    CONSTRAINT ck_auth_refresh_token_state CHECK (
        lifecycle_state IN ('ACTIVE', 'REPLACED', 'REVOKED', 'EXPIRED')
    ),
    CONSTRAINT ck_auth_refresh_token_expiry CHECK (expires_at > issued_at),
    CONSTRAINT ck_auth_refresh_token_lifecycle CHECK (
        (lifecycle_state = 'ACTIVE' AND replaced_at IS NULL AND revoked_at IS NULL)
        OR (lifecycle_state = 'REPLACED' AND replaced_at IS NOT NULL AND revoked_at IS NULL)
        OR (lifecycle_state = 'REVOKED' AND revoked_at IS NOT NULL)
        OR (lifecycle_state = 'EXPIRED' AND replaced_at IS NULL AND revoked_at IS NULL)
    )
);

CREATE UNIQUE INDEX ux_auth_refresh_token_active_session
    ON auth_refresh_token (session_id)
    WHERE lifecycle_state = 'ACTIVE';

CREATE INDEX ix_auth_refresh_token_session_state
    ON auth_refresh_token (session_id, lifecycle_state, expires_at);
