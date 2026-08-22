--liquibase formatted sql

--changeset elvencode:001-create-administration-schema labels:administration
CREATE TABLE school_branch (
    id UUID PRIMARY KEY,
    code VARCHAR(100) NOT NULL UNIQUE,
    name VARCHAR(200) NOT NULL,
    lifecycle_state VARCHAR(16) NOT NULL DEFAULT 'ACTIVE',
    lifecycle_version BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status_changed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_school_branch_id CHECK (id <> '00000000-0000-0000-0000-000000000000'::uuid),
    CONSTRAINT ck_school_branch_state CHECK (lifecycle_state IN ('ACTIVE', 'INACTIVE')),
    CONSTRAINT ck_school_branch_lifecycle_version CHECK (lifecycle_version >= 0)
);

CREATE TABLE user_account (
    id UUID PRIMARY KEY,
    account_type VARCHAR(16) NOT NULL,
    lifecycle_state VARCHAR(32) NOT NULL DEFAULT 'PENDING_ACTIVATION',
    identity_verified_at TIMESTAMP WITH TIME ZONE,
    authorization_version BIGINT NOT NULL DEFAULT 0,
    credential_version BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status_changed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_user_account_id_type UNIQUE (id, account_type),
    CONSTRAINT ck_user_account_type CHECK (account_type IN ('STAFF', 'STUDENT')),
    CONSTRAINT ck_user_account_state CHECK (lifecycle_state IN ('PENDING_ACTIVATION', 'ACTIVE', 'INACTIVE')),
    CONSTRAINT ck_user_account_versions CHECK (authorization_version >= 0 AND credential_version >= 0)
);

CREATE TABLE account_contact (
    id UUID PRIMARY KEY,
    account_id UUID NOT NULL,
    contact_type VARCHAR(16) NOT NULL,
    normalized_value VARCHAR(320) NOT NULL,
    lifecycle_state VARCHAR(16) NOT NULL DEFAULT 'ACTIVE',
    is_login_identifier BOOLEAN NOT NULL DEFAULT FALSE,
    verified_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    retired_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT uq_account_contact_id_account UNIQUE (id, account_id),
    CONSTRAINT fk_account_contact_account FOREIGN KEY (account_id) REFERENCES user_account (id),
    CONSTRAINT ck_account_contact_type CHECK (contact_type IN ('EMAIL', 'MOBILE')),
    CONSTRAINT ck_account_contact_state CHECK (lifecycle_state IN ('ACTIVE', 'RETIRED')),
    CONSTRAINT ck_account_contact_retirement CHECK (
        (lifecycle_state = 'ACTIVE' AND retired_at IS NULL)
        OR (lifecycle_state = 'RETIRED' AND retired_at IS NOT NULL)
    ),
    CONSTRAINT ck_account_contact_login_identifier CHECK (
        NOT is_login_identifier
        OR (lifecycle_state = 'ACTIVE' AND verified_at IS NOT NULL)
    )
);

CREATE UNIQUE INDEX ux_account_contact_active_value
    ON account_contact (contact_type, normalized_value)
    WHERE lifecycle_state = 'ACTIVE';

CREATE INDEX ix_account_contact_login_lookup
    ON account_contact (contact_type, normalized_value)
    WHERE lifecycle_state = 'ACTIVE' AND is_login_identifier;

CREATE TABLE auth_credential (
    id UUID PRIMARY KEY,
    account_id UUID NOT NULL,
    credential_type VARCHAR(64) NOT NULL,
    secret_hash TEXT NOT NULL,
    hash_algorithm VARCHAR(64) NOT NULL,
    lifecycle_state VARCHAR(16) NOT NULL DEFAULT 'ACTIVE',
    credential_revision BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_used_at TIMESTAMP WITH TIME ZONE,
    revoked_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT fk_auth_credential_account FOREIGN KEY (account_id) REFERENCES user_account (id),
    CONSTRAINT ck_auth_credential_state CHECK (lifecycle_state IN ('ACTIVE', 'REVOKED')),
    CONSTRAINT ck_auth_credential_revocation CHECK (
        (lifecycle_state = 'ACTIVE' AND revoked_at IS NULL)
        OR (lifecycle_state = 'REVOKED' AND revoked_at IS NOT NULL)
    ),
    CONSTRAINT ck_auth_credential_revision CHECK (credential_revision >= 0)
);

CREATE UNIQUE INDEX ux_auth_credential_active_password
    ON auth_credential (account_id)
    WHERE lifecycle_state = 'ACTIVE' AND credential_type = 'PASSWORD';

CREATE TABLE mfa_factor (
    id UUID PRIMARY KEY,
    account_id UUID NOT NULL,
    factor_type VARCHAR(64) NOT NULL,
    encrypted_secret BYTEA,
    public_material BYTEA,
    secret_reference VARCHAR(255),
    key_reference VARCHAR(255),
    factor_metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    lifecycle_state VARCHAR(16) NOT NULL DEFAULT 'PENDING',
    enrolled_at TIMESTAMP WITH TIME ZONE,
    last_used_at TIMESTAMP WITH TIME ZONE,
    revoked_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_mfa_factor_id_account UNIQUE (id, account_id),
    CONSTRAINT fk_mfa_factor_account FOREIGN KEY (account_id) REFERENCES user_account (id),
    CONSTRAINT ck_mfa_factor_state CHECK (lifecycle_state IN ('PENDING', 'ACTIVE', 'REVOKED')),
    CONSTRAINT ck_mfa_factor_material CHECK (
        encrypted_secret IS NOT NULL
        OR public_material IS NOT NULL
        OR secret_reference IS NOT NULL
    ),
    CONSTRAINT ck_mfa_factor_enrollment CHECK (
        lifecycle_state <> 'ACTIVE' OR enrolled_at IS NOT NULL
    ),
    CONSTRAINT ck_mfa_factor_revocation CHECK (
        lifecycle_state <> 'REVOKED' OR revoked_at IS NOT NULL
    )
);

CREATE TABLE auth_challenge (
    id UUID PRIMARY KEY,
    account_id UUID NOT NULL,
    mfa_factor_id UUID,
    challenge_type VARCHAR(64) NOT NULL,
    challenge_hash BYTEA NOT NULL UNIQUE,
    lifecycle_state VARCHAR(16) NOT NULL DEFAULT 'PENDING',
    attempt_count INTEGER NOT NULL DEFAULT 0,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    verified_at TIMESTAMP WITH TIME ZONE,
    consumed_at TIMESTAMP WITH TIME ZONE,
    invalidated_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_auth_challenge_account FOREIGN KEY (account_id) REFERENCES user_account (id),
    CONSTRAINT fk_auth_challenge_factor FOREIGN KEY (mfa_factor_id, account_id)
        REFERENCES mfa_factor (id, account_id),
    CONSTRAINT ck_auth_challenge_state CHECK (
        lifecycle_state IN ('PENDING', 'VERIFIED', 'CONSUMED', 'EXPIRED', 'INVALIDATED')
    ),
    CONSTRAINT ck_auth_challenge_attempts CHECK (attempt_count >= 0),
    CONSTRAINT ck_auth_challenge_expiry CHECK (expires_at > created_at)
);

CREATE INDEX ix_auth_challenge_pending_account
    ON auth_challenge (account_id, expires_at)
    WHERE lifecycle_state = 'PENDING';

CREATE TABLE auth_session (
    id UUID PRIMARY KEY,
    account_id UUID NOT NULL,
    session_family_id UUID NOT NULL,
    session_token_hash BYTEA NOT NULL UNIQUE,
    session_type VARCHAR(64) NOT NULL,
    lifecycle_state VARCHAR(16) NOT NULL DEFAULT 'ACTIVE',
    authorization_version BIGINT NOT NULL,
    credential_version BIGINT NOT NULL,
    authenticated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    mfa_authenticated_at TIMESTAMP WITH TIME ZONE,
    last_seen_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    idle_expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    absolute_expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    ended_at TIMESTAMP WITH TIME ZONE,
    end_reason VARCHAR(100),
    CONSTRAINT fk_auth_session_account FOREIGN KEY (account_id) REFERENCES user_account (id),
    CONSTRAINT ck_auth_session_state CHECK (lifecycle_state IN ('ACTIVE', 'REVOKED', 'EXPIRED', 'LOGGED_OUT')),
    CONSTRAINT ck_auth_session_versions CHECK (authorization_version >= 0 AND credential_version >= 0),
    CONSTRAINT ck_auth_session_expiry CHECK (
        idle_expires_at <= absolute_expires_at AND absolute_expires_at > authenticated_at
    ),
    CONSTRAINT ck_auth_session_end CHECK (
        (lifecycle_state = 'ACTIVE' AND ended_at IS NULL)
        OR (lifecycle_state <> 'ACTIVE' AND ended_at IS NOT NULL)
    )
);

CREATE INDEX ix_auth_session_active_account
    ON auth_session (account_id, last_seen_at)
    WHERE lifecycle_state = 'ACTIVE';

CREATE TABLE account_recovery_challenge (
    id UUID PRIMARY KEY,
    account_id UUID NOT NULL,
    recovery_type VARCHAR(64) NOT NULL,
    challenge_hash BYTEA NOT NULL UNIQUE,
    lifecycle_state VARCHAR(16) NOT NULL DEFAULT 'PENDING',
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    verified_at TIMESTAMP WITH TIME ZONE,
    consumed_at TIMESTAMP WITH TIME ZONE,
    invalidated_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_account_recovery_account FOREIGN KEY (account_id) REFERENCES user_account (id),
    CONSTRAINT ck_account_recovery_state CHECK (
        lifecycle_state IN ('PENDING', 'VERIFIED', 'CONSUMED', 'EXPIRED', 'INVALIDATED')
    ),
    CONSTRAINT ck_account_recovery_expiry CHECK (expires_at > created_at)
);

CREATE INDEX ix_account_recovery_pending_account
    ON account_recovery_challenge (account_id, expires_at)
    WHERE lifecycle_state = 'PENDING';

CREATE TABLE staff_invitation (
    id UUID PRIMARY KEY,
    account_id UUID NOT NULL,
    account_type VARCHAR(16) NOT NULL DEFAULT 'STAFF',
    contact_id UUID NOT NULL,
    approved_identity JSONB NOT NULL DEFAULT '{}'::jsonb,
    token_hash BYTEA NOT NULL UNIQUE,
    lifecycle_state VARCHAR(16) NOT NULL DEFAULT 'PENDING',
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    redeemed_at TIMESTAMP WITH TIME ZONE,
    invalidated_at TIMESTAMP WITH TIME ZONE,
    issued_by_account_id UUID,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_staff_invitation_account FOREIGN KEY (account_id, account_type)
        REFERENCES user_account (id, account_type),
    CONSTRAINT fk_staff_invitation_contact FOREIGN KEY (contact_id, account_id)
        REFERENCES account_contact (id, account_id),
    CONSTRAINT fk_staff_invitation_issuer FOREIGN KEY (issued_by_account_id) REFERENCES user_account (id),
    CONSTRAINT ck_staff_invitation_account_type CHECK (account_type = 'STAFF'),
    CONSTRAINT ck_staff_invitation_state CHECK (
        lifecycle_state IN ('PENDING', 'REDEEMED', 'INVALIDATED', 'EXPIRED')
    ),
    CONSTRAINT ck_staff_invitation_expiry CHECK (expires_at > created_at)
);

CREATE UNIQUE INDEX ux_staff_invitation_pending_account
    ON staff_invitation (account_id)
    WHERE lifecycle_state = 'PENDING';

CREATE TABLE student_profile (
    id UUID PRIMARY KEY,
    owner_branch_id UUID NOT NULL,
    profile_status VARCHAR(32) NOT NULL DEFAULT 'REQUESTED',
    lifecycle_version BIGINT NOT NULL DEFAULT 0,
    status_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status_changed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_student_profile_branch FOREIGN KEY (owner_branch_id) REFERENCES school_branch (id),
    CONSTRAINT ck_student_profile_status CHECK (
        profile_status IN (
            'REQUESTED', 'REGISTERED', 'VERIFIED', 'ACTIVE', 'GRADUATED',
            'INACTIVE', 'SUSPENDED', 'TRANSFERRED_OUT'
        )
    ),
    CONSTRAINT ck_student_profile_version CHECK (lifecycle_version >= 0)
);

CREATE INDEX ix_student_profile_owner_branch ON student_profile (owner_branch_id);

CREATE TABLE student_contact (
    id UUID PRIMARY KEY,
    student_id UUID NOT NULL,
    contact_type VARCHAR(16) NOT NULL,
    normalized_value VARCHAR(320) NOT NULL,
    lifecycle_state VARCHAR(16) NOT NULL DEFAULT 'ACTIVE',
    verification_state VARCHAR(16) NOT NULL DEFAULT 'UNVERIFIED',
    is_portal_contact BOOLEAN NOT NULL DEFAULT FALSE,
    verified_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    retired_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT uq_student_contact_id_student UNIQUE (id, student_id),
    CONSTRAINT fk_student_contact_student FOREIGN KEY (student_id) REFERENCES student_profile (id),
    CONSTRAINT ck_student_contact_type CHECK (contact_type IN ('EMAIL', 'MOBILE')),
    CONSTRAINT ck_student_contact_state CHECK (lifecycle_state IN ('ACTIVE', 'RETIRED')),
    CONSTRAINT ck_student_contact_verification CHECK (verification_state IN ('UNVERIFIED', 'VERIFIED')),
    CONSTRAINT ck_student_contact_retirement CHECK (
        (lifecycle_state = 'ACTIVE' AND retired_at IS NULL)
        OR (lifecycle_state = 'RETIRED' AND retired_at IS NOT NULL)
    ),
    CONSTRAINT ck_student_contact_verified_at CHECK (
        (verification_state = 'UNVERIFIED' AND verified_at IS NULL)
        OR (verification_state = 'VERIFIED' AND verified_at IS NOT NULL)
    ),
    CONSTRAINT ck_student_contact_portal CHECK (
        NOT is_portal_contact
        OR (lifecycle_state = 'ACTIVE' AND verification_state = 'VERIFIED')
    )
);

CREATE INDEX ix_student_contact_active_student
    ON student_contact (student_id)
    WHERE lifecycle_state = 'ACTIVE';

CREATE TABLE authorization_permission (
    id UUID PRIMARY KEY,
    code VARCHAR(150) NOT NULL UNIQUE,
    permission_category VARCHAR(4) NOT NULL,
    is_control_plane BOOLEAN NOT NULL DEFAULT FALSE,
    seed_revision BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_authorization_permission_category CHECK (
        permission_category IN ('SC', 'BR', 'CO', 'ST')
    ),
    CONSTRAINT ck_authorization_permission_code_category CHECK (
        (permission_category = 'SC' AND LEFT(code, 3) = 'SC_')
        OR (permission_category = 'BR' AND LEFT(code, 3) = 'BR_')
        OR (permission_category = 'CO' AND LEFT(code, 3) = 'CO_')
        OR (permission_category = 'ST' AND LEFT(code, 3) = 'ST_')
    ),
    CONSTRAINT ck_authorization_permission_seed_revision CHECK (seed_revision >= 0)
);

CREATE TABLE authorization_permission_scope (
    permission_id UUID NOT NULL,
    scope VARCHAR(16) NOT NULL,
    is_delegable BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (permission_id, scope),
    CONSTRAINT fk_permission_scope_permission FOREIGN KEY (permission_id)
        REFERENCES authorization_permission (id),
    CONSTRAINT ck_permission_scope_scope CHECK (scope IN ('SCHOOL', 'BRANCH', 'SELF'))
);

CREATE TABLE authorization_role (
    id UUID PRIMARY KEY,
    code VARCHAR(100) NOT NULL UNIQUE,
    display_name VARCHAR(200) NOT NULL,
    role_kind VARCHAR(16) NOT NULL,
    system_role_type VARCHAR(32),
    account_type VARCHAR(16) NOT NULL,
    scope VARCHAR(16) NOT NULL,
    branch_id UUID,
    scope_branch_key UUID NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
    lifecycle_state VARCHAR(16) NOT NULL DEFAULT 'ACTIVE',
    policy_revision BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    inactivated_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT uq_authorization_role_id_scope UNIQUE (id, scope),
    CONSTRAINT uq_authorization_role_assignment_key UNIQUE (id, account_type, scope, scope_branch_key),
    CONSTRAINT fk_authorization_role_branch FOREIGN KEY (branch_id) REFERENCES school_branch (id),
    CONSTRAINT ck_authorization_role_kind CHECK (role_kind IN ('ORDINARY', 'SYSTEM')),
    CONSTRAINT ck_authorization_role_account_type CHECK (account_type IN ('STAFF', 'STUDENT')),
    CONSTRAINT ck_authorization_role_scope CHECK (scope IN ('SCHOOL', 'BRANCH', 'SELF')),
    CONSTRAINT ck_authorization_role_state CHECK (lifecycle_state IN ('ACTIVE', 'INACTIVE')),
    CONSTRAINT ck_authorization_role_branch_key CHECK (
        (scope = 'BRANCH' AND branch_id IS NOT NULL AND scope_branch_key = branch_id)
        OR (
            scope IN ('SCHOOL', 'SELF')
            AND branch_id IS NULL
            AND scope_branch_key = '00000000-0000-0000-0000-000000000000'::uuid
        )
    ),
    CONSTRAINT ck_authorization_role_kind_shape CHECK (
        (role_kind = 'ORDINARY'
            AND system_role_type IS NULL
            AND account_type = 'STAFF'
            AND scope IN ('SCHOOL', 'BRANCH'))
        OR (role_kind = 'SYSTEM' AND (
            (system_role_type = 'SCHOOL_SUPER_ADMIN'
                AND account_type = 'STAFF'
                AND scope = 'SCHOOL')
            OR (system_role_type = 'BRANCH_SUPER_ADMIN'
                AND account_type = 'STAFF'
                AND scope = 'BRANCH')
            OR (system_role_type = 'STUDENT_DEFAULT'
                AND account_type = 'STUDENT'
                AND scope = 'SELF')
        ))
    ),
    CONSTRAINT ck_authorization_role_lifecycle CHECK (
        (lifecycle_state = 'ACTIVE' AND inactivated_at IS NULL)
        OR (lifecycle_state = 'INACTIVE' AND inactivated_at IS NOT NULL)
    ),
    CONSTRAINT ck_authorization_role_system_active CHECK (
        role_kind <> 'SYSTEM' OR lifecycle_state = 'ACTIVE'
    ),
    CONSTRAINT ck_authorization_role_policy_revision CHECK (policy_revision >= 0)
);

CREATE UNIQUE INDEX ux_authorization_role_school_super_admin
    ON authorization_role (system_role_type)
    WHERE system_role_type = 'SCHOOL_SUPER_ADMIN';

CREATE UNIQUE INDEX ux_authorization_role_student_default
    ON authorization_role (system_role_type)
    WHERE system_role_type = 'STUDENT_DEFAULT';

CREATE UNIQUE INDEX ux_authorization_role_branch_super_admin
    ON authorization_role (branch_id)
    WHERE system_role_type = 'BRANCH_SUPER_ADMIN';

CREATE TABLE authorization_role_permission (
    role_id UUID NOT NULL,
    permission_id UUID NOT NULL,
    role_scope VARCHAR(16) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (role_id, permission_id),
    CONSTRAINT uq_role_permission_scope UNIQUE (role_id, permission_id, role_scope),
    CONSTRAINT fk_role_permission_role FOREIGN KEY (role_id, role_scope)
        REFERENCES authorization_role (id, scope),
    CONSTRAINT fk_role_permission_permission_scope FOREIGN KEY (permission_id, role_scope)
        REFERENCES authorization_permission_scope (permission_id, scope)
);

CREATE TABLE authorization_role_delegated_permission (
    role_id UUID NOT NULL,
    permission_id UUID NOT NULL,
    role_scope VARCHAR(16) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (role_id, permission_id),
    CONSTRAINT fk_role_delegated_permission_role_permission
        FOREIGN KEY (role_id, permission_id, role_scope)
        REFERENCES authorization_role_permission (role_id, permission_id, role_scope)
);

CREATE TABLE staff_branch_assignment (
    id UUID PRIMARY KEY,
    account_id UUID NOT NULL,
    account_type VARCHAR(16) NOT NULL DEFAULT 'STAFF',
    branch_id UUID NOT NULL,
    lifecycle_state VARCHAR(16) NOT NULL DEFAULT 'ACTIVE',
    assigned_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP WITH TIME ZONE,
    end_reason TEXT,
    assigned_by_account_id UUID,
    CONSTRAINT uq_staff_branch_assignment_key UNIQUE (id, account_id, branch_id),
    CONSTRAINT fk_staff_branch_assignment_account FOREIGN KEY (account_id, account_type)
        REFERENCES user_account (id, account_type),
    CONSTRAINT fk_staff_branch_assignment_branch FOREIGN KEY (branch_id) REFERENCES school_branch (id),
    CONSTRAINT fk_staff_branch_assignment_actor FOREIGN KEY (assigned_by_account_id) REFERENCES user_account (id),
    CONSTRAINT ck_staff_branch_assignment_account_type CHECK (account_type = 'STAFF'),
    CONSTRAINT ck_staff_branch_assignment_state CHECK (lifecycle_state IN ('ACTIVE', 'ENDED')),
    CONSTRAINT ck_staff_branch_assignment_end CHECK (
        (lifecycle_state = 'ACTIVE' AND ended_at IS NULL)
        OR (lifecycle_state = 'ENDED' AND ended_at IS NOT NULL)
    )
);

CREATE UNIQUE INDEX ux_staff_branch_assignment_active
    ON staff_branch_assignment (account_id, branch_id)
    WHERE lifecycle_state = 'ACTIVE';

CREATE TABLE authorization_role_assignment (
    id UUID PRIMARY KEY,
    account_id UUID NOT NULL,
    account_type VARCHAR(16) NOT NULL,
    role_id UUID NOT NULL,
    scope VARCHAR(16) NOT NULL,
    branch_id UUID,
    scope_branch_key UUID NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
    staff_branch_assignment_id UUID,
    lifecycle_state VARCHAR(16) NOT NULL DEFAULT 'ACTIVE',
    assigned_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP WITH TIME ZONE,
    end_reason TEXT,
    assigned_by_account_id UUID,
    CONSTRAINT fk_role_assignment_account FOREIGN KEY (account_id, account_type)
        REFERENCES user_account (id, account_type),
    CONSTRAINT fk_role_assignment_role FOREIGN KEY (role_id, account_type, scope, scope_branch_key)
        REFERENCES authorization_role (id, account_type, scope, scope_branch_key),
    CONSTRAINT fk_role_assignment_staff_branch FOREIGN KEY (staff_branch_assignment_id, account_id, branch_id)
        REFERENCES staff_branch_assignment (id, account_id, branch_id),
    CONSTRAINT fk_role_assignment_actor FOREIGN KEY (assigned_by_account_id) REFERENCES user_account (id),
    CONSTRAINT ck_role_assignment_account_type CHECK (account_type IN ('STAFF', 'STUDENT')),
    CONSTRAINT ck_role_assignment_scope CHECK (scope IN ('SCHOOL', 'BRANCH', 'SELF')),
    CONSTRAINT ck_role_assignment_shape CHECK (
        (scope = 'BRANCH'
            AND branch_id IS NOT NULL
            AND scope_branch_key = branch_id
            AND staff_branch_assignment_id IS NOT NULL)
        OR (scope IN ('SCHOOL', 'SELF')
            AND branch_id IS NULL
            AND scope_branch_key = '00000000-0000-0000-0000-000000000000'::uuid
            AND staff_branch_assignment_id IS NULL)
    ),
    CONSTRAINT ck_role_assignment_state CHECK (lifecycle_state IN ('ACTIVE', 'ENDED')),
    CONSTRAINT ck_role_assignment_end CHECK (
        (lifecycle_state = 'ACTIVE' AND ended_at IS NULL)
        OR (lifecycle_state = 'ENDED' AND ended_at IS NOT NULL)
    )
);

CREATE UNIQUE INDEX ux_role_assignment_active_grant
    ON authorization_role_assignment (account_id, role_id, scope, scope_branch_key)
    WHERE lifecycle_state = 'ACTIVE';

CREATE INDEX ix_role_assignment_active_account
    ON authorization_role_assignment (account_id, scope, scope_branch_key)
    WHERE lifecycle_state = 'ACTIVE';

CREATE TABLE student_account_link (
    id UUID PRIMARY KEY,
    student_id UUID NOT NULL,
    account_id UUID NOT NULL,
    account_type VARCHAR(16) NOT NULL DEFAULT 'STUDENT',
    lifecycle_state VARCHAR(16) NOT NULL DEFAULT 'ACTIVE',
    linked_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP WITH TIME ZONE,
    end_reason TEXT,
    linked_by_account_id UUID,
    CONSTRAINT fk_student_account_link_student FOREIGN KEY (student_id) REFERENCES student_profile (id),
    CONSTRAINT fk_student_account_link_account FOREIGN KEY (account_id, account_type)
        REFERENCES user_account (id, account_type),
    CONSTRAINT fk_student_account_link_actor FOREIGN KEY (linked_by_account_id) REFERENCES user_account (id),
    CONSTRAINT ck_student_account_link_account_type CHECK (account_type = 'STUDENT'),
    CONSTRAINT ck_student_account_link_state CHECK (lifecycle_state IN ('ACTIVE', 'ENDED')),
    CONSTRAINT ck_student_account_link_end CHECK (
        (lifecycle_state = 'ACTIVE' AND ended_at IS NULL)
        OR (lifecycle_state = 'ENDED' AND ended_at IS NOT NULL)
    )
);

CREATE UNIQUE INDEX ux_student_account_link_active_student
    ON student_account_link (student_id)
    WHERE lifecycle_state = 'ACTIVE';

CREATE UNIQUE INDEX ux_student_account_link_active_account
    ON student_account_link (account_id)
    WHERE lifecycle_state = 'ACTIVE';

CREATE TABLE student_portal_invitation (
    id UUID PRIMARY KEY,
    student_id UUID NOT NULL,
    contact_id UUID NOT NULL,
    invitation_purpose VARCHAR(16) NOT NULL DEFAULT 'INITIAL',
    token_hash BYTEA NOT NULL UNIQUE,
    lifecycle_state VARCHAR(16) NOT NULL DEFAULT 'PENDING',
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    redeemed_at TIMESTAMP WITH TIME ZONE,
    invalidated_at TIMESTAMP WITH TIME ZONE,
    issued_by_account_id UUID,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_student_portal_invitation_student FOREIGN KEY (student_id) REFERENCES student_profile (id),
    CONSTRAINT fk_student_portal_invitation_contact FOREIGN KEY (contact_id, student_id)
        REFERENCES student_contact (id, student_id),
    CONSTRAINT fk_student_portal_invitation_actor FOREIGN KEY (issued_by_account_id) REFERENCES user_account (id),
    CONSTRAINT ck_student_portal_invitation_purpose CHECK (invitation_purpose IN ('INITIAL', 'REASSIGNMENT')),
    CONSTRAINT ck_student_portal_invitation_state CHECK (
        lifecycle_state IN ('PENDING', 'REDEEMED', 'INVALIDATED', 'EXPIRED')
    ),
    CONSTRAINT ck_student_portal_invitation_expiry CHECK (expires_at > created_at)
);

CREATE UNIQUE INDEX ux_student_portal_invitation_pending_student
    ON student_portal_invitation (student_id)
    WHERE lifecycle_state = 'PENDING';

CREATE TABLE service_identity (
    id UUID PRIMARY KEY,
    code VARCHAR(100) NOT NULL UNIQUE,
    display_name VARCHAR(200) NOT NULL,
    scope VARCHAR(16) NOT NULL,
    branch_id UUID,
    scope_branch_key UUID NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
    lifecycle_state VARCHAR(16) NOT NULL DEFAULT 'ACTIVE',
    authorization_version BIGINT NOT NULL DEFAULT 0,
    policy_revision BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    inactivated_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT uq_service_identity_id_scope UNIQUE (id, scope),
    CONSTRAINT fk_service_identity_branch FOREIGN KEY (branch_id) REFERENCES school_branch (id),
    CONSTRAINT ck_service_identity_scope CHECK (scope IN ('SCHOOL', 'BRANCH')),
    CONSTRAINT ck_service_identity_branch_key CHECK (
        (scope = 'BRANCH' AND branch_id IS NOT NULL AND scope_branch_key = branch_id)
        OR (scope = 'SCHOOL'
            AND branch_id IS NULL
            AND scope_branch_key = '00000000-0000-0000-0000-000000000000'::uuid)
    ),
    CONSTRAINT ck_service_identity_state CHECK (lifecycle_state IN ('ACTIVE', 'INACTIVE')),
    CONSTRAINT ck_service_identity_inactivation CHECK (
        (lifecycle_state = 'ACTIVE' AND inactivated_at IS NULL)
        OR (lifecycle_state = 'INACTIVE' AND inactivated_at IS NOT NULL)
    ),
    CONSTRAINT ck_service_identity_versions CHECK (authorization_version >= 0 AND policy_revision >= 0)
);

CREATE TABLE service_identity_permission (
    service_identity_id UUID NOT NULL,
    permission_id UUID NOT NULL,
    scope VARCHAR(16) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (service_identity_id, permission_id),
    CONSTRAINT fk_service_identity_permission_identity FOREIGN KEY (service_identity_id, scope)
        REFERENCES service_identity (id, scope),
    CONSTRAINT fk_service_identity_permission_scope FOREIGN KEY (permission_id, scope)
        REFERENCES authorization_permission_scope (permission_id, scope)
);

CREATE TABLE service_identity_credential (
    id UUID PRIMARY KEY,
    service_identity_id UUID NOT NULL,
    secret_hash TEXT NOT NULL,
    hash_algorithm VARCHAR(64) NOT NULL,
    credential_revision BIGINT NOT NULL DEFAULT 0,
    lifecycle_state VARCHAR(16) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_used_at TIMESTAMP WITH TIME ZONE,
    revoked_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT fk_service_identity_credential_identity FOREIGN KEY (service_identity_id)
        REFERENCES service_identity (id),
    CONSTRAINT ck_service_identity_credential_state CHECK (lifecycle_state IN ('ACTIVE', 'REVOKED')),
    CONSTRAINT ck_service_identity_credential_revocation CHECK (
        (lifecycle_state = 'ACTIVE' AND revoked_at IS NULL)
        OR (lifecycle_state = 'REVOKED' AND revoked_at IS NOT NULL)
    ),
    CONSTRAINT ck_service_identity_credential_revision CHECK (credential_revision >= 0)
);

CREATE UNIQUE INDEX ux_service_identity_credential_active
    ON service_identity_credential (service_identity_id)
    WHERE lifecycle_state = 'ACTIVE';

CREATE TABLE authentication_event (
    id UUID PRIMARY KEY,
    account_id UUID,
    session_id UUID,
    event_type VARCHAR(100) NOT NULL,
    identifier_hash BYTEA,
    source_fingerprint_hash BYTEA,
    event_metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    occurred_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_authentication_event_account FOREIGN KEY (account_id) REFERENCES user_account (id),
    CONSTRAINT fk_authentication_event_session FOREIGN KEY (session_id) REFERENCES auth_session (id)
);

CREATE INDEX ix_authentication_event_account_time
    ON authentication_event (account_id, occurred_at DESC);

CREATE TABLE audit_chain_state (
    chain_key VARCHAR(64) PRIMARY KEY,
    head_sequence BIGINT NOT NULL DEFAULT 0,
    head_event_hash BYTEA,
    lock_version BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_audit_chain_state_head CHECK (
        (head_sequence = 0 AND head_event_hash IS NULL)
        OR (head_sequence > 0 AND head_event_hash IS NOT NULL)
    ),
    CONSTRAINT ck_audit_chain_state_version CHECK (lock_version >= 0)
);

INSERT INTO audit_chain_state (chain_key) VALUES ('ADMINISTRATION');

CREATE TABLE security_audit_event (
    event_sequence BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id UUID NOT NULL UNIQUE,
    chain_key VARCHAR(64) NOT NULL,
    previous_event_hash BYTEA,
    event_hash BYTEA NOT NULL UNIQUE,
    actor_principal_type VARCHAR(16) NOT NULL,
    actor_principal_id UUID,
    action VARCHAR(150) NOT NULL,
    target_type VARCHAR(100) NOT NULL,
    target_id UUID,
    reason TEXT,
    before_state JSONB,
    after_state JSONB,
    event_metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    occurred_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_security_audit_event_chain FOREIGN KEY (chain_key) REFERENCES audit_chain_state (chain_key),
    CONSTRAINT ck_security_audit_event_actor CHECK (
        (actor_principal_type = 'SYSTEM' AND actor_principal_id IS NULL)
        OR (actor_principal_type IN ('USER', 'SERVICE') AND actor_principal_id IS NOT NULL)
    )
);

CREATE INDEX ix_security_audit_event_target_time
    ON security_audit_event (target_type, target_id, occurred_at DESC);

CREATE INDEX ix_security_audit_event_actor_time
    ON security_audit_event (actor_principal_type, actor_principal_id, occurred_at DESC);

--changeset elvencode:002-create-append-only-trigger-function labels:administration splitStatements:false
CREATE OR REPLACE FUNCTION administration_reject_append_only_mutation()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $function$
BEGIN
    RAISE EXCEPTION 'append-only records cannot be updated or deleted';
END;
$function$;

--changeset elvencode:003-create-account-immutability-trigger-function labels:administration splitStatements:false
CREATE OR REPLACE FUNCTION administration_enforce_account_immutability()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $function$
BEGIN
    IF NEW.account_type IS DISTINCT FROM OLD.account_type THEN
        RAISE EXCEPTION 'account type is immutable';
    END IF;

    RETURN NEW;
END;
$function$;

--changeset elvencode:004-create-role-immutability-trigger-function labels:administration splitStatements:false
CREATE OR REPLACE FUNCTION administration_enforce_role_immutability()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $function$
BEGIN
    IF NEW.role_kind IS DISTINCT FROM OLD.role_kind
        OR NEW.system_role_type IS DISTINCT FROM OLD.system_role_type
        OR NEW.account_type IS DISTINCT FROM OLD.account_type
        OR NEW.scope IS DISTINCT FROM OLD.scope
        OR NEW.branch_id IS DISTINCT FROM OLD.branch_id
        OR NEW.scope_branch_key IS DISTINCT FROM OLD.scope_branch_key THEN
        RAISE EXCEPTION 'role identity, scope, and branch binding are immutable';
    END IF;

    IF OLD.lifecycle_state = 'INACTIVE' AND NEW.lifecycle_state <> 'INACTIVE' THEN
        RAISE EXCEPTION 'inactive roles cannot be reactivated';
    END IF;

    IF OLD.role_kind = 'SYSTEM'
        AND (NEW.code IS DISTINCT FROM OLD.code OR NEW.display_name IS DISTINCT FROM OLD.display_name) THEN
        RAISE EXCEPTION 'protected system role identifiers are immutable';
    END IF;

    RETURN NEW;
END;
$function$;

--changeset elvencode:005-create-staff-branch-assignment-trigger-function labels:administration splitStatements:false
CREATE OR REPLACE FUNCTION administration_enforce_staff_branch_assignment_immutability()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $function$
BEGIN
    IF NEW.account_id IS DISTINCT FROM OLD.account_id
        OR NEW.account_type IS DISTINCT FROM OLD.account_type
        OR NEW.branch_id IS DISTINCT FROM OLD.branch_id THEN
        RAISE EXCEPTION 'staff branch assignment binding is immutable';
    END IF;

    IF OLD.lifecycle_state = 'ENDED' AND NEW.lifecycle_state <> 'ENDED' THEN
        RAISE EXCEPTION 'ended staff branch assignments cannot be reactivated';
    END IF;

    RETURN NEW;
END;
$function$;

--changeset elvencode:006-create-role-assignment-trigger-function labels:administration splitStatements:false
CREATE OR REPLACE FUNCTION administration_enforce_role_assignment_immutability()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $function$
BEGIN
    IF NEW.account_id IS DISTINCT FROM OLD.account_id
        OR NEW.account_type IS DISTINCT FROM OLD.account_type
        OR NEW.role_id IS DISTINCT FROM OLD.role_id
        OR NEW.scope IS DISTINCT FROM OLD.scope
        OR NEW.branch_id IS DISTINCT FROM OLD.branch_id
        OR NEW.scope_branch_key IS DISTINCT FROM OLD.scope_branch_key
        OR NEW.staff_branch_assignment_id IS DISTINCT FROM OLD.staff_branch_assignment_id THEN
        RAISE EXCEPTION 'role assignment binding is immutable';
    END IF;

    IF OLD.lifecycle_state = 'ENDED' AND NEW.lifecycle_state <> 'ENDED' THEN
        RAISE EXCEPTION 'ended role assignments cannot be reactivated';
    END IF;

    RETURN NEW;
END;
$function$;

--changeset elvencode:007-create-student-link-trigger-function labels:administration splitStatements:false
CREATE OR REPLACE FUNCTION administration_enforce_student_account_link_immutability()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $function$
BEGIN
    IF NEW.student_id IS DISTINCT FROM OLD.student_id
        OR NEW.account_id IS DISTINCT FROM OLD.account_id
        OR NEW.account_type IS DISTINCT FROM OLD.account_type THEN
        RAISE EXCEPTION 'student account link binding is immutable';
    END IF;

    IF OLD.lifecycle_state = 'ENDED' AND NEW.lifecycle_state <> 'ENDED' THEN
        RAISE EXCEPTION 'ended student account links cannot be reactivated';
    END IF;

    RETURN NEW;
END;
$function$;

--changeset elvencode:008-register-administration-triggers labels:administration
CREATE TRIGGER tr_user_account_immutable_type
    BEFORE UPDATE ON user_account
    FOR EACH ROW EXECUTE FUNCTION administration_enforce_account_immutability();

CREATE TRIGGER tr_authorization_role_immutable_binding
    BEFORE UPDATE ON authorization_role
    FOR EACH ROW EXECUTE FUNCTION administration_enforce_role_immutability();

CREATE TRIGGER tr_staff_branch_assignment_immutable_binding
    BEFORE UPDATE ON staff_branch_assignment
    FOR EACH ROW EXECUTE FUNCTION administration_enforce_staff_branch_assignment_immutability();

CREATE TRIGGER tr_role_assignment_immutable_binding
    BEFORE UPDATE ON authorization_role_assignment
    FOR EACH ROW EXECUTE FUNCTION administration_enforce_role_assignment_immutability();

CREATE TRIGGER tr_student_account_link_immutable_binding
    BEFORE UPDATE ON student_account_link
    FOR EACH ROW EXECUTE FUNCTION administration_enforce_student_account_link_immutability();

CREATE TRIGGER tr_authentication_event_append_only
    BEFORE UPDATE OR DELETE ON authentication_event
    FOR EACH ROW EXECUTE FUNCTION administration_reject_append_only_mutation();

CREATE TRIGGER tr_security_audit_event_append_only
    BEFORE UPDATE OR DELETE ON security_audit_event
    FOR EACH ROW EXECUTE FUNCTION administration_reject_append_only_mutation();

--changeset elvencode:009-enforce-permission-scope-and-delegation labels:administration
ALTER TABLE authorization_permission
    ADD CONSTRAINT uq_authorization_permission_id_category UNIQUE (id, permission_category);

ALTER TABLE authorization_permission_scope
    ADD COLUMN permission_category VARCHAR(4) NOT NULL;

ALTER TABLE authorization_permission_scope
    ADD CONSTRAINT fk_permission_scope_category FOREIGN KEY (permission_id, permission_category)
        REFERENCES authorization_permission (id, permission_category),
    ADD CONSTRAINT ck_permission_scope_category CHECK (
        (permission_category = 'SC' AND scope = 'SCHOOL')
        OR (permission_category = 'BR' AND scope = 'BRANCH')
        OR (permission_category = 'CO' AND scope IN ('SCHOOL', 'BRANCH'))
        OR (permission_category = 'ST' AND scope = 'SELF')
    ),
    ADD CONSTRAINT uq_permission_scope_delegation UNIQUE (permission_id, scope, is_delegable);

ALTER TABLE authorization_role_delegated_permission
    ADD COLUMN permission_is_delegable BOOLEAN NOT NULL DEFAULT TRUE,
    ADD CONSTRAINT ck_role_delegated_permission_delegable CHECK (permission_is_delegable),
    ADD CONSTRAINT fk_role_delegated_permission_delegable
        FOREIGN KEY (permission_id, role_scope, permission_is_delegable)
        REFERENCES authorization_permission_scope (permission_id, scope, is_delegable);

--changeset elvencode:010-protect-permission-catalogue labels:administration
CREATE TRIGGER tr_authorization_permission_append_only
    BEFORE UPDATE OR DELETE ON authorization_permission
    FOR EACH ROW EXECUTE FUNCTION administration_reject_append_only_mutation();

CREATE TRIGGER tr_authorization_permission_scope_append_only
    BEFORE UPDATE OR DELETE ON authorization_permission_scope
    FOR EACH ROW EXECUTE FUNCTION administration_reject_append_only_mutation();
