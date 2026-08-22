--liquibase formatted sql

--changeset elvencode:012-create-auth-login-indexes labels:administration
CREATE UNIQUE INDEX ux_account_contact_active_login_identifier
    ON account_contact (normalized_value)
    WHERE lifecycle_state = 'ACTIVE' AND is_login_identifier;

CREATE INDEX ix_authentication_event_login_failure_lookup
    ON authentication_event (
        identifier_hash,
        source_fingerprint_hash,
        occurred_at DESC
    )
    WHERE event_type = 'LOGIN_FAILED';
