-- Staff domain schema.
--
-- A staff member is a school-owned record of one person employed by the school. It
-- is deliberately separate from app_user, for the same reason learner is: a person
-- exists whether or not they can sign in. A yard assistant or an office cleaner is
-- on the payroll and works at a branch but has no business holding a system account,
-- and folding staff data into the login table would mean minting a credentialed
-- account for them just to have somewhere to record the person.
--
-- Designation is a human resources label and grants nothing. What a staff member may
-- do comes only from the roles granted to their login. Employment status, by
-- contrast, does govern access: leaving the active set disables the login through a
-- trigger declared in auth-rbac-schema.sql.
--
-- Depends on school from src/main/resources/db-data/school-schema.sql.
-- Apply before docs/database/auth-rbac-schema.sql, which references staff from
-- app_user and from staff_branch_membership.
--
-- The identity and contact columns are the minimum an employment record needs.
-- Review them against the real personnel file before the Liquibase changeset is
-- written; payroll and statutory fields are deliberately not modelled here.
--
-- Reference document. The runtime schema is applied by Liquibase under
-- src/main/resources/db/changelog; keep this file aligned when that changes.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS staff (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,                              -- employing school; a staff record is never shared
    employee_no varchar(32) NOT NULL,                     -- school-specific, unique within the school
    full_name varchar(160) NOT NULL,                      -- legal name, not the login display name
    national_id varchar(32),
    date_of_birth date,
    designation varchar(64) NOT NULL,                     -- 'Instructor', 'Registrar'; a label, never a permission
    employment_status varchar(32) DEFAULT 'ACTIVE' NOT NULL,
    phone_number varchar(32) NOT NULL,                    -- as entered
    phone_number_e164 varchar(16) NOT NULL,               -- normalized, for lookup and messaging
    email varchar(254),                                   -- optional
    address varchar(255),
    joined_on date DEFAULT CURRENT_DATE NOT NULL,
    left_on date,                                         -- set when employment ends
    created_at timestamp DEFAULT now() NOT NULL,
    created_by varchar(20) DEFAULT 'system' NOT NULL,
    updated_at timestamp DEFAULT now() NOT NULL,
    updated_by varchar(20) DEFAULT 'system' NOT NULL,
    CONSTRAINT pk_staff PRIMARY KEY (id),
    -- Composite FK target. app_user pairs (staff_id, school_id) so a login can never
    -- point at another school's employee, and staff_branch_membership pairs
    -- (staff_id, school_id) so nobody is assigned outside their own school.
    CONSTRAINT uk_staff_id_school UNIQUE (id, school_id),
    CONSTRAINT uk_staff_school_employee_no UNIQUE (school_id, employee_no),
    -- Contact details are unique within the school, not across schools, matching the
    -- learner rule: the same person may be employed by two schools as two records.
    CONSTRAINT uk_staff_school_phone UNIQUE (school_id, phone_number_e164),
    -- Email is optional. SQL treats NULLs as distinct, so any number of staff in one
    -- school may have none while those that do have one are unique.
    CONSTRAINT uk_staff_school_email UNIQUE (school_id, email),
    CONSTRAINT fk_staff_school FOREIGN KEY (school_id) REFERENCES school (id) ON DELETE RESTRICT,
    -- Constrained because the system acts on it: anything outside ACTIVE and ON_LEAVE
    -- disables the login. Designation is left free text because nothing depends on it,
    -- and pinning job titles in a check would mean a migration per new title.
    CONSTRAINT ck_staff_employment_status CHECK (employment_status IN ('ACTIVE', 'ON_LEAVE', 'SUSPENDED', 'RESIGNED', 'TERMINATED')),
    CONSTRAINT ck_staff_employee_no_format CHECK (employee_no ~ '^[A-Z0-9][A-Z0-9-]*$'),
    CONSTRAINT ck_staff_full_name_not_blank CHECK (btrim(full_name) <> ''),
    CONSTRAINT ck_staff_designation_not_blank CHECK (btrim(designation) <> ''),
    CONSTRAINT ck_staff_national_id_not_blank CHECK (national_id IS NULL OR btrim(national_id) <> ''),
    CONSTRAINT ck_staff_address_not_blank CHECK (address IS NULL OR btrim(address) <> ''),
    CONSTRAINT ck_staff_email_format CHECK (email IS NULL OR email ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$'),
    CONSTRAINT ck_staff_phone_format CHECK (phone_number ~ '^[0-9 +()-]+$'),
    CONSTRAINT ck_staff_phone_e164_format CHECK (phone_number_e164 ~ '^\+[1-9][0-9]{7,14}$'),
    -- A sanity range only. "Not in the future" cannot live here, because a CHECK
    -- constraint may not call CURRENT_DATE; that one stays an application rule.
    CONSTRAINT ck_staff_date_of_birth CHECK (date_of_birth IS NULL OR date_of_birth BETWEEN DATE '1900-01-01' AND DATE '2100-01-01'),
    CONSTRAINT ck_staff_joined_on CHECK (joined_on >= DATE '1900-01-01'),
    CONSTRAINT ck_staff_left_on CHECK (left_on IS NULL OR left_on >= joined_on),
    -- A leaving date and a still-employed status contradict each other.
    CONSTRAINT ck_staff_left_on_matches_status CHECK (left_on IS NULL OR employment_status IN ('RESIGNED', 'TERMINATED')),
    CONSTRAINT ck_staff_timestamps CHECK (updated_at >= created_at)
);

-- Currently employed staff are the common filter; leavers accumulate.
CREATE INDEX IF NOT EXISTS ix_staff_school_employed
    ON staff (school_id)
    WHERE employment_status IN ('ACTIVE', 'ON_LEAVE');
