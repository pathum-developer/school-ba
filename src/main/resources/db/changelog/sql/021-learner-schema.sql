-- Learner domain schema.
--
-- A learner is a school-owned record of one person enrolled at the school. It
-- belongs to exactly one school and has exactly one current registered branch,
-- which must belong to that same school. Both rules are enforced by constraints
-- below rather than left to service code.
--
-- Depends on school and branch from src/main/resources/db-data/school-schema.sql.
-- Apply before docs/database/auth-rbac-schema.sql: that file's final section
-- activates learner logins only when this table already exists, and requires the
-- uk_learner_id_school pairing declared here.
--
-- Does not cover learner_branch_transfer from
-- docs/architecture/backend/domain-model.md. Transfers are a workflow layered on
-- this table and are not needed for authentication or authorization.
--
-- The identity and contact columns are an inference from the one line in the
-- domain model that calls for "identity and contact fields required to manage the
-- learner within the school". They are the minimum an enrolment needs; review them
-- against the real intake form before the Liquibase changeset is written.
--
-- Reference document. The runtime schema is applied by Liquibase under
-- src/main/resources/db/changelog; keep this file aligned when that changes.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Composite foreign key target on branch, so a learner's current branch can be
-- checked against the learner's own school as a pair. auth-rbac-schema.sql
-- declares the same constraint, so either file may be applied first.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'uk_branch_id_school') THEN
        ALTER TABLE branch ADD CONSTRAINT uk_branch_id_school UNIQUE (id, school_id);
    END IF;
END
$$;

CREATE TABLE IF NOT EXISTS learner (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,                              -- owning school; a learner is never shared
    current_branch_id uuid NOT NULL,                      -- exactly one at a time, in the same school
    learner_no varchar(32) NOT NULL,                      -- school-specific, unique within the school
    status varchar(32) DEFAULT 'ENROLLED' NOT NULL,
    full_name varchar(160) NOT NULL,
    national_id varchar(32),                              -- NIC; absent for a learner who has none yet
    date_of_birth date NOT NULL,                          -- drives licence class eligibility
    email varchar(254),                                   -- optional; a learner login does not require one
    phone_number varchar(32) NOT NULL,                    -- as entered
    phone_number_e164 varchar(16) NOT NULL,               -- normalized, for lookup and messaging
    address varchar(255),
    enrolled_on date DEFAULT CURRENT_DATE NOT NULL,
    created_at timestamp DEFAULT now() NOT NULL,
    created_by varchar(20) DEFAULT 'system' NOT NULL,
    updated_at timestamp DEFAULT now() NOT NULL,
    updated_by varchar(20) DEFAULT 'system' NOT NULL,
    CONSTRAINT pk_learner PRIMARY KEY (id),
    -- Required by auth-rbac-schema.sql: app_user references (learner_id, school_id)
    -- as a pair, so a login can never point at another school's learner.
    CONSTRAINT uk_learner_id_school UNIQUE (id, school_id),
    CONSTRAINT uk_learner_school_no UNIQUE (school_id, learner_no),
    -- Contact details are unique within the school, not across schools. The same
    -- person may enrol at two schools as two independent learner records, so a
    -- globally unique phone number would make the second enrolment impossible.
    CONSTRAINT uk_learner_school_phone UNIQUE (school_id, phone_number_e164),
    -- Email is optional. SQL treats NULLs as distinct, so any number of learners
    -- in one school may have no email while those that do have one are unique.
    CONSTRAINT uk_learner_school_email UNIQUE (school_id, email),
    CONSTRAINT fk_learner_school FOREIGN KEY (school_id) REFERENCES school (id) ON DELETE RESTRICT,
    -- The current branch must belong to the learner's own school. Pairing both
    -- columns is what makes a cross-school branch assignment unstorable.
    CONSTRAINT fk_learner_branch FOREIGN KEY (current_branch_id, school_id) REFERENCES branch (id, school_id) ON DELETE RESTRICT,
    CONSTRAINT ck_learner_status CHECK (status IN ('ENROLLED', 'ACTIVE', 'SUSPENDED', 'COMPLETED', 'WITHDRAWN')),
    CONSTRAINT ck_learner_no_format CHECK (learner_no ~ '^[A-Z0-9][A-Z0-9-]*$'),
    CONSTRAINT ck_learner_full_name_not_blank CHECK (btrim(full_name) <> ''),
    CONSTRAINT ck_learner_national_id_not_blank CHECK (national_id IS NULL OR btrim(national_id) <> ''),
    CONSTRAINT ck_learner_address_not_blank CHECK (address IS NULL OR btrim(address) <> ''),
    CONSTRAINT ck_learner_email_format CHECK (email IS NULL OR email ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$'),
    CONSTRAINT ck_learner_phone_format CHECK (phone_number ~ '^[0-9 +()-]+$'),
    CONSTRAINT ck_learner_phone_e164_format CHECK (phone_number_e164 ~ '^\+[1-9][0-9]{7,14}$'),
    -- A sanity range only. "Not in the future" cannot live here, because a CHECK
    -- constraint may not call CURRENT_DATE; that one stays an application rule.
    CONSTRAINT ck_learner_date_of_birth CHECK (date_of_birth BETWEEN DATE '1900-01-01' AND DATE '2100-01-01'),
    CONSTRAINT ck_learner_enrolled_on CHECK (enrolled_on >= DATE '1900-01-01'),
    CONSTRAINT ck_learner_timestamps CHECK (updated_at >= created_at)
);

-- Branch-scoped learner listing is the hot read: a branch user sees only the
-- learners currently registered at branches they are authorized for.
CREATE INDEX IF NOT EXISTS ix_learner_school_branch
    ON learner (school_id, current_branch_id);

-- Active learners are the common filter; withdrawn and completed rows accumulate.
CREATE INDEX IF NOT EXISTS ix_learner_school_active
    ON learner (school_id)
    WHERE status IN ('ENROLLED', 'ACTIVE');
