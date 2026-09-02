-- Platform operator schema.
--
-- A platform operator is a person who runs the platform itself. They are not
-- employed by any school, which is exactly what separates them from staff, so this
-- table carries no school_id and nothing here is tenant-scoped.
--
-- It exists for the same reason staff and learner do: a person is not a login. An
-- operator can be recorded before access is granted and stays on record after it is
-- withdrawn, and with this table every login now points at a person rather than
-- carrying that person's details itself.
--
-- Employment status governs access. Leaving the active set disables the login
-- through a trigger declared in auth-rbac-schema.sql, matching the staff rule.
--
-- Depends on nothing. Apply before docs/database/auth-rbac-schema.sql, which
-- references it from app_user.
--
-- Reference document. The runtime schema is applied by Liquibase under
-- src/main/resources/db/changelog; keep this file aligned when that changes.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS platform_operator (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    employee_no varchar(32) NOT NULL,                     -- platform-wide; there is no school to scope it by
    full_name varchar(160) NOT NULL,                      -- legal name, not the login display name
    designation varchar(64) NOT NULL,                     -- a label, never a permission
    employment_status varchar(32) DEFAULT 'ACTIVE' NOT NULL,
    email varchar(254) NOT NULL,                          -- required; an operator is always reachable
    phone_number varchar(32),                             -- optional; email is the working channel
    phone_number_e164 varchar(16),
    joined_on date DEFAULT CURRENT_DATE NOT NULL,
    left_on date,                                         -- set when employment ends
    created_at timestamp DEFAULT now() NOT NULL,
    created_by varchar(20) DEFAULT 'system' NOT NULL,
    updated_at timestamp DEFAULT now() NOT NULL,
    updated_by varchar(20) DEFAULT 'system' NOT NULL,
    CONSTRAINT pk_platform_operator PRIMARY KEY (id),
    -- Unique across the platform rather than within a school, because unlike staff
    -- and learners an operator has no school to be scoped by.
    CONSTRAINT uk_platform_operator_employee_no UNIQUE (employee_no),
    CONSTRAINT uk_platform_operator_email UNIQUE (email),
    -- Mirrors the staff rule: constrained because access depends on it, while
    -- designation stays free text because nothing does.
    CONSTRAINT ck_platform_operator_employment_status CHECK (employment_status IN ('ACTIVE', 'ON_LEAVE', 'SUSPENDED', 'RESIGNED', 'TERMINATED')),
    CONSTRAINT ck_platform_operator_employee_no_format CHECK (employee_no ~ '^[A-Z0-9][A-Z0-9-]*$'),
    CONSTRAINT ck_platform_operator_full_name_not_blank CHECK (btrim(full_name) <> ''),
    CONSTRAINT ck_platform_operator_designation_not_blank CHECK (btrim(designation) <> ''),
    CONSTRAINT ck_platform_operator_email_format CHECK (email ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$'),
    CONSTRAINT ck_platform_operator_phone_format CHECK (phone_number IS NULL OR phone_number ~ '^[0-9 +()-]+$'),
    CONSTRAINT ck_platform_operator_phone_e164_format CHECK (phone_number_e164 IS NULL OR phone_number_e164 ~ '^\+[1-9][0-9]{7,14}$'),
    -- Both phone columns are present or both absent; a normalized number with no
    -- entered form, or the reverse, means one of the two was never written.
    CONSTRAINT ck_platform_operator_phone_pair CHECK ((phone_number IS NULL) = (phone_number_e164 IS NULL)),
    CONSTRAINT ck_platform_operator_joined_on CHECK (joined_on >= DATE '1900-01-01'),
    CONSTRAINT ck_platform_operator_left_on CHECK (left_on IS NULL OR left_on >= joined_on),
    -- A leaving date and a still-employed status contradict each other.
    CONSTRAINT ck_platform_operator_left_on_matches_status CHECK (left_on IS NULL OR employment_status IN ('RESIGNED', 'TERMINATED')),
    CONSTRAINT ck_platform_operator_timestamps CHECK (updated_at >= created_at)
);

-- Currently employed operators are the common filter; leavers accumulate.
CREATE INDEX IF NOT EXISTS ix_platform_operator_employed
    ON platform_operator (employment_status)
    WHERE employment_status IN ('ACTIVE', 'ON_LEAVE');
