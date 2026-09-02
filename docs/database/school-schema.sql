-- School database canonical schema
-- Creates the current School BA database schema in a fresh PostgreSQL database.
-- Run this file before docs/database/school-data.sql.

BEGIN;

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

CREATE SCHEMA IF NOT EXISTS public;
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;
COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';
COMMENT ON SCHEMA public IS 'standard public schema';

SET search_path = pg_catalog, public;
SET default_table_access_method = heap;

-- Tables

-- The tenant root. Every other school-owned row reaches a school through this table,
-- directly or through a branch.
CREATE TABLE public.m_school (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(64) NOT NULL,                                               -- stable public identifier used in URLs, never the UUID
    name character varying(160) NOT NULL,
    short_name character varying(80) NOT NULL,                                         -- compact display form for navigation and headers
    established_year smallint NOT NULL,                                                -- shown on the public profile
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    hotline_href character varying(64) NOT NULL,                                       -- tel: URI, used directly as a click-to-call link
    whatsapp_href character varying(128) NOT NULL,                                     -- https://wa.me/ link
    email character varying(254) NOT NULL,
    created_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    updated_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    tenant_status character varying(32) DEFAULT 'ACTIVE'::character varying NOT NULL,  -- ACTIVE | SUSPENDED | ARCHIVED; suspends the whole tenant
    CONSTRAINT ck_school_code_format CHECK (((code)::text ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'::text)),
    CONSTRAINT ck_school_email_format CHECK (((email IS NULL) OR ((email)::text ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$'::text))),
    CONSTRAINT ck_school_established_year CHECK (((established_year IS NULL) OR ((established_year >= 1800) AND (established_year <= 9999)))),
    CONSTRAINT ck_school_hotline_href_format CHECK (((hotline_href)::text ~ '^tel:\+[1-9][0-9]{7,14}$'::text)),
    CONSTRAINT ck_school_name_not_blank CHECK ((btrim((name)::text) <> ''::text)),
    CONSTRAINT ck_school_short_name_not_blank CHECK ((btrim((short_name)::text) <> ''::text)),
    CONSTRAINT ck_school_tenant_status CHECK (((tenant_status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'SUSPENDED'::character varying, 'ARCHIVED'::character varying])::text[]))),
    CONSTRAINT ck_school_timestamps CHECK ((updated_at >= created_at)),
    CONSTRAINT ck_school_whatsapp_href_format CHECK (((whatsapp_href)::text ~ '^https://wa\.me/[1-9][0-9]{7,14}$'::text)),
    CONSTRAINT pk_school PRIMARY KEY (id),
    CONSTRAINT uk_school_code UNIQUE (code)
);

-- Sri Lanka Department of Motor Traffic licence classes. Reference data: seeded by
-- migration, read by the public catalogue, never written at runtime.
CREATE TABLE public.r_license_class (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(64) NOT NULL,                                            -- DMT class code such as A1, B, CE; the public identifier
    name character varying(120) NOT NULL,
    display_order integer NOT NULL,                                                 -- fixed catalogue order, unique across classes
    is_active boolean DEFAULT true NOT NULL,                                        -- retired classes stay for historical records
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    included_class_codes jsonb DEFAULT '[]'::jsonb NOT NULL,                        -- classes this one also entitles the holder to drive
    old_class_codes jsonb DEFAULT '[]'::jsonb NOT NULL,                             -- superseded legacy codes this class replaced
    source_url character varying(512) NOT NULL,                                     -- the DMT page the definition was taken from
    description text NOT NULL,                                                      -- the official wording, quoted rather than paraphrased
    created_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    updated_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    CONSTRAINT ck_license_class_code_format CHECK (((code)::text ~ '^[A-Z][A-Z0-9]*$'::text)),
    CONSTRAINT ck_license_class_description_not_blank CHECK ((btrim(description) <> ''::text)),
    CONSTRAINT ck_license_class_display_order_positive CHECK ((display_order > 0)),
    CONSTRAINT ck_license_class_included_codes_array CHECK ((jsonb_typeof(included_class_codes) = 'array'::text)),
    CONSTRAINT ck_license_class_name_not_blank CHECK ((btrim((name)::text) <> ''::text)),
    CONSTRAINT ck_license_class_old_codes_array CHECK ((jsonb_typeof(old_class_codes) = 'array'::text)),
    CONSTRAINT ck_license_class_source_url_format CHECK (((source_url)::text ~ '^https?://.+'::text)),
    CONSTRAINT ck_license_class_timestamps CHECK ((updated_at >= created_at)),
    CONSTRAINT pk_license_class PRIMARY KEY (id),
    CONSTRAINT uk_license_class_code UNIQUE (code),
    CONSTRAINT uk_license_class_display_order UNIQUE (display_order)
);

-- The action catalogue. Reference data. Application code checks these codes and
-- never checks role names, so a role can be renamed without touching a check.
CREATE TABLE public.r_permission (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(64) NOT NULL,                                            -- 'learner:read'; the only thing application code checks
    resource character varying(32) NOT NULL,                                        -- 'learner'
    action character varying(32) NOT NULL,                                          -- 'read'
    max_scope_type character varying(32) NOT NULL,                                  -- deepest scope a role may hold this at; the privilege ceiling
    description character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    created_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    CONSTRAINT ck_permission_code_format CHECK (((code)::text ~ '^[a-z][a-z0-9-]*:[a-z][a-z0-9-]*$'::text)),
    CONSTRAINT ck_permission_code_matches_parts CHECK (((code)::text = (((resource)::text || ':'::text) || (action)::text))),
    CONSTRAINT ck_permission_description_not_blank CHECK ((btrim((description)::text) <> ''::text)),
    CONSTRAINT ck_permission_max_scope_type CHECK (((max_scope_type)::text = ANY ((ARRAY['PLATFORM'::character varying, 'SCHOOL'::character varying, 'BRANCH'::character varying])::text[]))),
    CONSTRAINT ck_permission_timestamps CHECK ((updated_at >= created_at)),
    CONSTRAINT pk_permission PRIMARY KEY (id),
    CONSTRAINT uk_permission_code UNIQUE (code),
    CONSTRAINT uk_permission_id_max_scope UNIQUE (id, max_scope_type),
    CONSTRAINT uk_permission_resource_action UNIQUE (resource, action)
);

-- A person who runs the platform itself, employed by no school. That absence of a
-- school is exactly what separates an operator from staff, so there is no school_id.
-- Exists whether or not the person has a login.
CREATE TABLE public.m_platform_operator (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    employee_no character varying(32) NOT NULL,                                            -- platform-wide, since there is no school to scope it by
    full_name character varying(160) NOT NULL,                                             -- legal name, as distinct from a login display name
    designation character varying(64) NOT NULL,                                            -- a label only; it grants no permission whatsoever
    employment_status character varying(32) DEFAULT 'ACTIVE'::character varying NOT NULL,  -- governs access; leaving the active set disables the login
    email character varying(254) NOT NULL,                                                 -- required; an operator is always reachable
    phone_number character varying(32) NOT NULL,                                           -- as entered
    phone_number_e164 character varying(16) NOT NULL,                                      -- normalized, for lookup and messaging
    joined_on date DEFAULT CURRENT_DATE NOT NULL,
    left_on date,                                                                          -- set when employment ends; only for RESIGNED or TERMINATED
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    created_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    CONSTRAINT ck_platform_operator_designation_not_blank CHECK ((btrim((designation)::text) <> ''::text)),
    CONSTRAINT ck_platform_operator_email_format CHECK (((email)::text ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$'::text)),
    CONSTRAINT ck_platform_operator_employee_no_format CHECK (((employee_no)::text ~ '^[A-Z0-9][A-Z0-9-]*$'::text)),
    CONSTRAINT ck_platform_operator_employment_status CHECK (((employment_status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'ON_LEAVE'::character varying, 'SUSPENDED'::character varying, 'RESIGNED'::character varying, 'TERMINATED'::character varying])::text[]))),
    CONSTRAINT ck_platform_operator_full_name_not_blank CHECK ((btrim((full_name)::text) <> ''::text)),
    CONSTRAINT ck_platform_operator_joined_on CHECK ((joined_on >= '1900-01-01'::date)),
    CONSTRAINT ck_platform_operator_left_on CHECK (((left_on IS NULL) OR (left_on >= joined_on))),
    CONSTRAINT ck_platform_operator_left_on_matches_status CHECK (((left_on IS NULL) OR ((employment_status)::text = ANY ((ARRAY['RESIGNED'::character varying, 'TERMINATED'::character varying])::text[])))),
    CONSTRAINT ck_platform_operator_phone_e164_format CHECK (((phone_number_e164)::text ~ '^\+[1-9][0-9]{7,14}$'::text)),
    CONSTRAINT ck_platform_operator_phone_format CHECK (((phone_number)::text ~ '^[0-9 +()-]+$'::text)),
    CONSTRAINT ck_platform_operator_timestamps CHECK ((updated_at >= created_at)),
    CONSTRAINT pk_platform_operator PRIMARY KEY (id),
    CONSTRAINT uk_platform_operator_email UNIQUE (email),
    CONSTRAINT uk_platform_operator_employee_no UNIQUE (employee_no),
    CONSTRAINT uk_platform_operator_phone UNIQUE (phone_number_e164)
);

-- A branch or yard of one school. Branches are the unit staff are assigned to and
-- learners are registered at.
CREATE TABLE public.m_branch (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,                                                         -- owning school; a branch belongs to exactly one
    code character varying(64) NOT NULL,                                             -- stable identifier unique within the school, e.g. 'rajagiriya'
    name character varying(160) NOT NULL,
    branch_type character varying(32) DEFAULT 'BRANCH'::character varying NOT NULL,  -- BRANCH | YARD
    is_head_office boolean DEFAULT false NOT NULL,                                   -- at most one per school, by partial unique index
    is_active boolean DEFAULT true NOT NULL,                                         -- soft deactivation; branches are not deleted
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    address character varying(255) NOT NULL,
    created_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    updated_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    CONSTRAINT ck_branch_address_not_blank CHECK ((btrim((address)::text) <> ''::text)),
    CONSTRAINT ck_branch_code_format CHECK (((code)::text ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'::text)),
    CONSTRAINT ck_branch_name_not_blank CHECK ((btrim((name)::text) <> ''::text)),
    CONSTRAINT ck_branch_timestamps CHECK ((updated_at >= created_at)),
    CONSTRAINT ck_branch_type CHECK (((branch_type)::text = ANY ((ARRAY['BRANCH'::character varying, 'YARD'::character varying])::text[]))),
    CONSTRAINT pk_branch PRIMARY KEY (id),
    CONSTRAINT uk_branch_id_school UNIQUE (id, school_id),
    CONSTRAINT uk_branch_school_code UNIQUE (school_id, code),
    CONSTRAINT fk_branch_school FOREIGN KEY (school_id) REFERENCES public.m_school(id) ON DELETE RESTRICT
);

-- Public contact numbers for a school, ordered for display on the catalogue site.
CREATE TABLE public.m_school_contact_number (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    contact_type character varying(32) DEFAULT 'GENERAL'::character varying NOT NULL,  -- GENERAL | HOTLINE | WHATSAPP
    phone_number character varying(32) NOT NULL,                                       -- as entered
    phone_number_e164 character varying(16) NOT NULL,                                  -- normalized, for lookup and messaging
    is_primary boolean DEFAULT false NOT NULL,                                         -- at most one per school, by partial unique index
    display_order integer DEFAULT 1 NOT NULL,                                          -- presentation order within the school
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    created_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    updated_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    CONSTRAINT ck_school_contact_number_display_order_positive CHECK ((display_order > 0)),
    CONSTRAINT ck_school_contact_number_e164_format CHECK (((phone_number_e164)::text ~ '^\+[1-9][0-9]{7,14}$'::text)),
    CONSTRAINT ck_school_contact_number_phone_format CHECK (((phone_number)::text ~ '^[0-9 +()-]+$'::text)),
    CONSTRAINT ck_school_contact_number_phone_not_blank CHECK ((btrim((phone_number)::text) <> ''::text)),
    CONSTRAINT ck_school_contact_number_timestamps CHECK ((updated_at >= created_at)),
    CONSTRAINT ck_school_contact_number_type CHECK (((contact_type)::text = ANY ((ARRAY['GENERAL'::character varying, 'HOTLINE'::character varying, 'WHATSAPP'::character varying])::text[]))),
    CONSTRAINT pk_school_contact_number PRIMARY KEY (id),
    CONSTRAINT uk_school_contact_number_school_display_order UNIQUE (school_id, display_order),
    CONSTRAINT uk_school_contact_number_school_phone UNIQUE (school_id, phone_number),
    CONSTRAINT uk_school_contact_number_school_phone_e164 UNIQUE (school_id, phone_number_e164),
    CONSTRAINT fk_school_contact_number_school FOREIGN KEY (school_id) REFERENCES public.m_school(id) ON DELETE CASCADE
);

-- A school-owned employment record. Kept separate from m_identity because a person
-- is not a login: a yard assistant can be on the payroll and assigned to a branch
-- with no system access at all.
CREATE TABLE public.m_staff (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,                                                               -- employing school; a staff record is never shared
    employee_no character varying(32) NOT NULL,                                            -- school-specific, unique within the school
    full_name character varying(160) NOT NULL,                                             -- legal name, as distinct from a login display name
    national_id character varying(32),                                                     -- NIC; optional
    date_of_birth date,
    designation character varying(64) NOT NULL,                                            -- 'Instructor', 'Registrar'; a label, never a permission
    employment_status character varying(32) DEFAULT 'ACTIVE'::character varying NOT NULL,  -- governs access; leaving the active set disables the login
    phone_number character varying(32) NOT NULL,                                           -- as entered
    phone_number_e164 character varying(16) NOT NULL,                                      -- normalized; unique within the school, not across schools
    email character varying(254),                                                          -- optional, unique within the school where present
    address character varying(255),
    joined_on date DEFAULT CURRENT_DATE NOT NULL,                                          -- employment start
    left_on date,                                                                          -- set when employment ends; only for RESIGNED or TERMINATED
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    created_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    CONSTRAINT ck_staff_address_not_blank CHECK (((address IS NULL) OR (btrim((address)::text) <> ''::text))),
    CONSTRAINT ck_staff_date_of_birth CHECK (((date_of_birth IS NULL) OR ((date_of_birth >= '1900-01-01'::date) AND (date_of_birth <= '2100-01-01'::date)))),
    CONSTRAINT ck_staff_designation_not_blank CHECK ((btrim((designation)::text) <> ''::text)),
    CONSTRAINT ck_staff_email_format CHECK (((email IS NULL) OR ((email)::text ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$'::text))),
    CONSTRAINT ck_staff_employee_no_format CHECK (((employee_no)::text ~ '^[A-Z0-9][A-Z0-9-]*$'::text)),
    CONSTRAINT ck_staff_employment_status CHECK (((employment_status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'ON_LEAVE'::character varying, 'SUSPENDED'::character varying, 'RESIGNED'::character varying, 'TERMINATED'::character varying])::text[]))),
    CONSTRAINT ck_staff_full_name_not_blank CHECK ((btrim((full_name)::text) <> ''::text)),
    CONSTRAINT ck_staff_joined_on CHECK ((joined_on >= '1900-01-01'::date)),
    CONSTRAINT ck_staff_left_on CHECK (((left_on IS NULL) OR (left_on >= joined_on))),
    CONSTRAINT ck_staff_left_on_matches_status CHECK (((left_on IS NULL) OR ((employment_status)::text = ANY ((ARRAY['RESIGNED'::character varying, 'TERMINATED'::character varying])::text[])))),
    CONSTRAINT ck_staff_national_id_not_blank CHECK (((national_id IS NULL) OR (btrim((national_id)::text) <> ''::text))),
    CONSTRAINT ck_staff_phone_e164_format CHECK (((phone_number_e164)::text ~ '^\+[1-9][0-9]{7,14}$'::text)),
    CONSTRAINT ck_staff_phone_format CHECK (((phone_number)::text ~ '^[0-9 +()-]+$'::text)),
    CONSTRAINT ck_staff_timestamps CHECK ((updated_at >= created_at)),
    CONSTRAINT pk_staff PRIMARY KEY (id),
    CONSTRAINT uk_staff_id_school UNIQUE (id, school_id),
    CONSTRAINT uk_staff_school_email UNIQUE (school_id, email),
    CONSTRAINT uk_staff_school_employee_no UNIQUE (school_id, employee_no),
    CONSTRAINT uk_staff_school_phone UNIQUE (school_id, phone_number_e164),
    CONSTRAINT fk_staff_school FOREIGN KEY (school_id) REFERENCES public.m_school(id) ON DELETE RESTRICT
);

-- Public contact numbers for a branch. Carries school_id so the branch reference can
-- be a school-matched pair rather than a bare id.
CREATE TABLE public.m_branch_contact_number (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    branch_id uuid NOT NULL,
    contact_type character varying(32) DEFAULT 'GENERAL'::character varying NOT NULL,  -- GENERAL | HOTLINE | WHATSAPP
    phone_number character varying(32) NOT NULL,                                       -- as entered
    phone_number_e164 character varying(16) NOT NULL,                                  -- normalized, for lookup and messaging
    is_primary boolean DEFAULT false NOT NULL,                                         -- at most one per branch, by partial unique index
    display_order integer DEFAULT 1 NOT NULL,                                          -- presentation order within the branch
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    created_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    updated_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    school_id uuid NOT NULL,                                                           -- denormalized so the branch FK can pair (branch_id, school_id)
    CONSTRAINT ck_branch_contact_number_display_order_positive CHECK ((display_order > 0)),
    CONSTRAINT ck_branch_contact_number_e164_format CHECK (((phone_number_e164)::text ~ '^\+[1-9][0-9]{7,14}$'::text)),
    CONSTRAINT ck_branch_contact_number_phone_format CHECK (((phone_number)::text ~ '^[0-9 +()-]+$'::text)),
    CONSTRAINT ck_branch_contact_number_phone_not_blank CHECK ((btrim((phone_number)::text) <> ''::text)),
    CONSTRAINT ck_branch_contact_number_timestamps CHECK ((updated_at >= created_at)),
    CONSTRAINT ck_branch_contact_number_type CHECK (((contact_type)::text = ANY ((ARRAY['GENERAL'::character varying, 'HOTLINE'::character varying, 'WHATSAPP'::character varying])::text[]))),
    CONSTRAINT pk_branch_contact_number PRIMARY KEY (id),
    CONSTRAINT uk_branch_contact_number_branch_display_order UNIQUE (branch_id, display_order),
    CONSTRAINT uk_branch_contact_number_branch_phone UNIQUE (branch_id, phone_number),
    CONSTRAINT uk_branch_contact_number_school_branch_display_order UNIQUE (school_id, branch_id, display_order),
    CONSTRAINT uk_branch_contact_number_school_branch_phone_e164 UNIQUE (school_id, branch_id, phone_number_e164),
    CONSTRAINT fk_branch_contact_number_branch FOREIGN KEY (branch_id, school_id) REFERENCES public.m_branch(id, school_id) ON DELETE CASCADE
);

-- A school-owned learner record. Belongs to exactly one school and is registered at
-- exactly one branch of that school at a time.
CREATE TABLE public.m_learner (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,                                                        -- owning school; a learner is never shared across schools
    current_branch_id uuid NOT NULL,                                                -- exactly one at a time, and always in the same school
    learner_no character varying(32) NOT NULL,                                      -- school-specific, unique within the school
    status character varying(32) DEFAULT 'ENROLLED'::character varying NOT NULL,    -- leaving ENROLLED or ACTIVE disables the login by trigger
    full_name character varying(160) NOT NULL,                                      -- legal name, as distinct from a login display name
    national_id character varying(32),                                              -- NIC; absent for a learner who has none yet
    date_of_birth date NOT NULL,                                                    -- drives licence class eligibility
    email character varying(254),                                                   -- optional; a learner login does not require one
    phone_number character varying(32) NOT NULL,                                    -- as entered
    phone_number_e164 character varying(16) NOT NULL,                               -- normalized; unique within the school, not across schools
    address character varying(255),
    enrolled_on date DEFAULT CURRENT_DATE NOT NULL,                                 -- enrolment date
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    created_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    CONSTRAINT ck_learner_address_not_blank CHECK (((address IS NULL) OR (btrim((address)::text) <> ''::text))),
    CONSTRAINT ck_learner_date_of_birth CHECK (((date_of_birth >= '1900-01-01'::date) AND (date_of_birth <= '2100-01-01'::date))),
    CONSTRAINT ck_learner_email_format CHECK (((email IS NULL) OR ((email)::text ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$'::text))),
    CONSTRAINT ck_learner_enrolled_on CHECK ((enrolled_on >= '1900-01-01'::date)),
    CONSTRAINT ck_learner_full_name_not_blank CHECK ((btrim((full_name)::text) <> ''::text)),
    CONSTRAINT ck_learner_national_id_not_blank CHECK (((national_id IS NULL) OR (btrim((national_id)::text) <> ''::text))),
    CONSTRAINT ck_learner_no_format CHECK (((learner_no)::text ~ '^[A-Z0-9][A-Z0-9-]*$'::text)),
    CONSTRAINT ck_learner_phone_e164_format CHECK (((phone_number_e164)::text ~ '^\+[1-9][0-9]{7,14}$'::text)),
    CONSTRAINT ck_learner_phone_format CHECK (((phone_number)::text ~ '^[0-9 +()-]+$'::text)),
    CONSTRAINT ck_learner_status CHECK (((status)::text = ANY ((ARRAY['ENROLLED'::character varying, 'ACTIVE'::character varying, 'SUSPENDED'::character varying, 'COMPLETED'::character varying, 'WITHDRAWN'::character varying])::text[]))),
    CONSTRAINT ck_learner_timestamps CHECK ((updated_at >= created_at)),
    CONSTRAINT pk_learner PRIMARY KEY (id),
    CONSTRAINT uk_learner_id_school UNIQUE (id, school_id),
    CONSTRAINT uk_learner_school_email UNIQUE (school_id, email),
    CONSTRAINT uk_learner_school_no UNIQUE (school_id, learner_no),
    CONSTRAINT uk_learner_school_phone UNIQUE (school_id, phone_number_e164),
    CONSTRAINT fk_learner_branch FOREIGN KEY (current_branch_id, school_id) REFERENCES public.m_branch(id, school_id) ON DELETE RESTRICT,
    CONSTRAINT fk_learner_school FOREIGN KEY (school_id) REFERENCES public.m_school(id) ON DELETE RESTRICT
);

-- Every identity that can sign in. Holds credentials and account state only; who the
-- person is lives in m_platform_operator, m_staff or m_learner, and exactly one of
-- those links is set.
CREATE TABLE public.m_identity (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid,                                                                         -- NULL only for a platform operator
    platform_operator_id uuid,                                                              -- set only for a platform login
    staff_id uuid,                                                                          -- set only for a staff login
    learner_id uuid,                                                                        -- set only for a learner login
    is_staff boolean GENERATED ALWAYS AS ((learner_id IS NULL)) STORED,                     -- generated: 'not a learner'. Platform operators count as staff here
    username character varying(64) NOT NULL,                                                -- the only login identifier; a learner's is system-generated
    phone_number character varying(32) NOT NULL,                                            -- as entered
    phone_number_e164 character varying(16) NOT NULL,                                       -- the account's recovery channel; unique per school
    password_hash character varying(255),                                                   -- absent until the account is activated
    display_name character varying(160) NOT NULL,                                           -- UI label; the person record is authoritative for the legal name
    status character varying(32) DEFAULT 'PENDING_ACTIVATION'::character varying NOT NULL,  -- PENDING_ACTIVATION until a password is set
    authorization_version integer DEFAULT 0 NOT NULL,                                       -- bumped by trigger on any grant change; evicts cached permissions
    failed_attempt_count smallint DEFAULT 0 NOT NULL,                                       -- reset on successful login
    locked_until timestamp without time zone,                                               -- NULL when the account is not locked out
    last_login_at timestamp without time zone,
    password_changed_at timestamp without time zone DEFAULT now() NOT NULL,                 -- drives password age policy
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    created_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    CONSTRAINT ck_identity_active_needs_password CHECK ((((status)::text <> 'ACTIVE'::text) OR (password_hash IS NOT NULL))),
    CONSTRAINT ck_identity_authorization_version_non_negative CHECK ((authorization_version >= 0)),
    CONSTRAINT ck_identity_display_name_not_blank CHECK ((btrim((display_name)::text) <> ''::text)),
    CONSTRAINT ck_identity_failed_attempt_count_non_negative CHECK ((failed_attempt_count >= 0)),
    CONSTRAINT ck_identity_learner_needs_school CHECK (((learner_id IS NULL) OR (school_id IS NOT NULL))),
    CONSTRAINT ck_identity_operator_has_no_school CHECK (((platform_operator_id IS NULL) OR (school_id IS NULL))),
    CONSTRAINT ck_identity_password_hash_not_blank CHECK (((password_hash IS NULL) OR (btrim((password_hash)::text) <> ''::text))),
    CONSTRAINT ck_identity_phone_e164_format CHECK (((phone_number_e164)::text ~ '^\+[1-9][0-9]{7,14}$'::text)),
    CONSTRAINT ck_identity_phone_format CHECK (((phone_number)::text ~ '^[0-9 +()-]+$'::text)),
    CONSTRAINT ck_identity_single_person CHECK ((((((platform_operator_id IS NOT NULL))::integer + ((staff_id IS NOT NULL))::integer) + ((learner_id IS NOT NULL))::integer) = 1)),
    CONSTRAINT ck_identity_staff_needs_school CHECK (((staff_id IS NULL) OR (school_id IS NOT NULL))),
    CONSTRAINT ck_identity_status CHECK (((status)::text = ANY ((ARRAY['PENDING_ACTIVATION'::character varying, 'ACTIVE'::character varying, 'SUSPENDED'::character varying, 'LOCKED'::character varying, 'DISABLED'::character varying])::text[]))),
    CONSTRAINT ck_identity_timestamps CHECK ((updated_at >= created_at)),
    CONSTRAINT ck_identity_username_format CHECK (((username)::text ~ '^[a-z0-9]+(?:[._-][a-z0-9]+)*$'::text)),
    CONSTRAINT pk_identity PRIMARY KEY (id),
    CONSTRAINT uk_identity_id_is_staff UNIQUE (id, is_staff),
    CONSTRAINT uk_identity_id_school UNIQUE (id, school_id),
    CONSTRAINT uk_identity_id_staff UNIQUE (id, staff_id),
    CONSTRAINT uk_identity_learner UNIQUE (learner_id),
    CONSTRAINT uk_identity_platform_operator UNIQUE (platform_operator_id),
    CONSTRAINT uk_identity_staff UNIQUE (staff_id),
    CONSTRAINT uk_identity_username UNIQUE (username),
    CONSTRAINT fk_identity_learner FOREIGN KEY (learner_id, school_id) REFERENCES public.m_learner(id, school_id) ON DELETE RESTRICT,
    CONSTRAINT fk_identity_platform_operator FOREIGN KEY (platform_operator_id) REFERENCES public.m_platform_operator(id) ON DELETE RESTRICT,
    CONSTRAINT fk_identity_school FOREIGN KEY (school_id) REFERENCES public.m_school(id) ON DELETE RESTRICT,
    CONSTRAINT fk_identity_staff FOREIGN KEY (staff_id, school_id) REFERENCES public.m_staff(id, school_id) ON DELETE RESTRICT
);

-- A named bundle of permissions owned by exactly one scope. There are no unowned
-- template roles: default roles for a new branch are created as real owned rows.
CREATE TABLE public.m_role (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    scope_type character varying(32) NOT NULL,                                        -- PLATFORM | SCHOOL | BRANCH; who the role is owned by
    school_id uuid,                                                                   -- NULL only when PLATFORM
    branch_id uuid,                                                                   -- NOT NULL only when BRANCH
    assignable_to character varying(32) DEFAULT 'STAFF'::character varying NOT NULL,  -- STAFF | LEARNER; a grant must match the kind of account
    code character varying(64) NOT NULL,                                              -- unique per owner, so every branch may have its own 'instructor'
    name character varying(160) NOT NULL,
    description character varying(255),
    is_system boolean DEFAULT false NOT NULL,                                         -- provisioned by migration; not user-editable
    is_assignable boolean DEFAULT true NOT NULL,                                      -- retire a role without deleting it
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    created_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    CONSTRAINT ck_role_assignable_to CHECK (((assignable_to)::text = ANY ((ARRAY['STAFF'::character varying, 'LEARNER'::character varying])::text[]))),
    CONSTRAINT ck_role_code_format CHECK (((code)::text ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'::text)),
    CONSTRAINT ck_role_description_not_blank CHECK (((description IS NULL) OR (btrim((description)::text) <> ''::text))),
    CONSTRAINT ck_role_learner_not_branch CHECK ((((assignable_to)::text = 'STAFF'::text) OR ((scope_type)::text <> 'BRANCH'::text))),
    CONSTRAINT ck_role_name_not_blank CHECK ((btrim((name)::text) <> ''::text)),
    CONSTRAINT ck_role_scope_shape CHECK (((((scope_type)::text = 'PLATFORM'::text) AND (school_id IS NULL) AND (branch_id IS NULL)) OR (((scope_type)::text = 'SCHOOL'::text) AND (school_id IS NOT NULL) AND (branch_id IS NULL)) OR (((scope_type)::text = 'BRANCH'::text) AND (school_id IS NOT NULL) AND (branch_id IS NOT NULL)))),
    CONSTRAINT ck_role_scope_type CHECK (((scope_type)::text = ANY ((ARRAY['PLATFORM'::character varying, 'SCHOOL'::character varying, 'BRANCH'::character varying])::text[]))),
    CONSTRAINT ck_role_timestamps CHECK ((updated_at >= created_at)),
    CONSTRAINT pk_role PRIMARY KEY (id),
    CONSTRAINT uk_role_code_per_owner UNIQUE NULLS NOT DISTINCT (code, school_id, branch_id),
    CONSTRAINT uk_role_id_assignable_to UNIQUE (id, assignable_to),
    CONSTRAINT uk_role_id_branch UNIQUE (id, branch_id),
    CONSTRAINT uk_role_id_school UNIQUE (id, school_id),
    CONSTRAINT uk_role_id_scope_type UNIQUE (id, scope_type),
    CONSTRAINT fk_role_branch FOREIGN KEY (branch_id, school_id) REFERENCES public.m_branch(id, school_id) ON DELETE CASCADE,
    CONSTRAINT fk_role_school FOREIGN KEY (school_id) REFERENCES public.m_school(id) ON DELETE CASCADE
);

-- Which licence classes a branch teaches, and what it charges for each.
CREATE TABLE public.x_branch_license_class (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    branch_id uuid NOT NULL,
    license_class_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    price_lkr numeric(12,2) NOT NULL,                                               -- exact decimal; never a floating point type for money
    created_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    updated_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    school_id uuid NOT NULL,                                                        -- denormalized so the branch FK can pair (branch_id, school_id)
    CONSTRAINT ck_branch_license_class_price_lkr_positive CHECK ((price_lkr > (0)::numeric)),
    CONSTRAINT ck_branch_license_class_timestamps CHECK ((updated_at >= created_at)),
    CONSTRAINT pk_branch_license_class PRIMARY KEY (id),
    CONSTRAINT uk_branch_license_class_branch_license_class UNIQUE (branch_id, license_class_id),
    CONSTRAINT uk_branch_license_class_school_branch_license_class UNIQUE (school_id, branch_id, license_class_id),
    CONSTRAINT fk_branch_license_class_branch FOREIGN KEY (branch_id, school_id) REFERENCES public.m_branch(id, school_id) ON DELETE CASCADE,
    CONSTRAINT fk_branch_license_class_license_class FOREIGN KEY (license_class_id) REFERENCES public.r_license_class(id) ON DELETE RESTRICT
);

-- Which permissions a role carries. Insert and delete only, never updated, which is
-- why it has no updated_at.
CREATE TABLE public.x_role_permission (
    role_id uuid NOT NULL,
    role_scope_type character varying(32) NOT NULL,                                 -- copy of m_role.scope_type, pinned by the FK below
    permission_id uuid NOT NULL,
    permission_max_scope_type character varying(32) NOT NULL,                       -- copy of r_permission.max_scope_type, likewise pinned
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    created_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    CONSTRAINT ck_role_permission_scope_depth CHECK ((
CASE role_scope_type
    WHEN 'PLATFORM'::text THEN 0
    WHEN 'SCHOOL'::text THEN 1
    WHEN 'BRANCH'::text THEN 2
    ELSE NULL::integer
END <=
CASE permission_max_scope_type
    WHEN 'PLATFORM'::text THEN 0
    WHEN 'SCHOOL'::text THEN 1
    WHEN 'BRANCH'::text THEN 2
    ELSE NULL::integer
END)),
    CONSTRAINT pk_role_permission PRIMARY KEY (role_id, permission_id),
    CONSTRAINT fk_role_permission_permission FOREIGN KEY (permission_id, permission_max_scope_type) REFERENCES public.r_permission(id, max_scope_type) ON DELETE RESTRICT,
    CONSTRAINT fk_role_permission_role FOREIGN KEY (role_id, role_scope_type) REFERENCES public.m_role(id, scope_type) ON DELETE CASCADE
);

-- Which branches a staff member works at: zero, one, or many. Keyed by the staff
-- member rather than the login, because where someone works holds without an account.
-- Grants nothing by itself; it is the precondition for holding a branch-owned role.
CREATE TABLE public.x_staff_branch_membership (
    staff_id uuid NOT NULL,                                                         -- the employed person, not their login
    branch_id uuid NOT NULL,
    school_id uuid NOT NULL,                                                        -- must match both the staff member's and the branch's school
    is_primary boolean DEFAULT false NOT NULL,                                      -- the home branch; at most one per staff member
    assigned_at timestamp without time zone DEFAULT now() NOT NULL,                 -- when the person started working at this branch
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    created_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    CONSTRAINT ck_staff_branch_membership_timestamps CHECK ((updated_at >= created_at)),
    CONSTRAINT pk_staff_branch_membership PRIMARY KEY (staff_id, branch_id),
    CONSTRAINT fk_staff_branch_membership_branch FOREIGN KEY (branch_id, school_id) REFERENCES public.m_branch(id, school_id) ON DELETE CASCADE,
    CONSTRAINT fk_staff_branch_membership_staff FOREIGN KEY (staff_id, school_id) REFERENCES public.m_staff(id, school_id) ON DELETE CASCADE
);

-- Rotating refresh tokens. Access tokens are short-lived and never stored.
CREATE TABLE public.t_refresh_token (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    identity_id uuid NOT NULL,                                         -- the account this token authenticates
    token_hash character varying(64) NOT NULL,                     -- sha-256 hex; the token itself is never stored
    jti uuid NOT NULL,                                             -- matches the JWT claim, for audit correlation
    issued_at timestamp without time zone DEFAULT now() NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    revoked_at timestamp without time zone,                        -- NULL while the token is live
    replaced_by_id uuid,                                           -- rotation chain; a reused parent signals theft
    user_agent character varying(255),                             -- recorded for session review
    ip_address inet,                                               -- recorded for session review
    CONSTRAINT ck_refresh_token_expiry CHECK ((expires_at > issued_at)),
    CONSTRAINT ck_refresh_token_hash_format CHECK (((token_hash)::text ~ '^[0-9a-f]{64}$'::text)),
    CONSTRAINT ck_refresh_token_revoked CHECK (((revoked_at IS NULL) OR (revoked_at >= issued_at))),
    CONSTRAINT pk_refresh_token PRIMARY KEY (id),
    CONSTRAINT uk_refresh_token_hash UNIQUE (token_hash),
    CONSTRAINT uk_refresh_token_jti UNIQUE (jti),
    CONSTRAINT fk_refresh_token_replaced_by FOREIGN KEY (replaced_by_id) REFERENCES public.t_refresh_token(id) ON DELETE SET NULL,
    CONSTRAINT fk_refresh_token_identity FOREIGN KEY (identity_id) REFERENCES public.m_identity(id) ON DELETE CASCADE
);

-- The scoped grant: this account holds this role, here.
CREATE TABLE public.t_identity_role_assignment (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    identity_id uuid NOT NULL,                                                            -- the account holding the grant
    role_id uuid NOT NULL,
    scope_type character varying(32) NOT NULL,                                        -- mirrors m_role.scope_type
    school_id uuid,                                                                   -- NULL only when PLATFORM
    branch_id uuid,                                                                   -- NOT NULL only when BRANCH
    assignable_to character varying(32) DEFAULT 'STAFF'::character varying NOT NULL,  -- mirrors m_role.assignable_to
    is_staff boolean DEFAULT true NOT NULL,                                           -- mirrors m_identity.is_staff
    staff_id uuid,                                                                    -- mirrors m_identity.staff_id; required for a branch grant
    granted_by uuid NOT NULL,                                                         -- a real FK, not the varchar audit column
    granted_at timestamp without time zone DEFAULT now() NOT NULL,                    -- when the grant was made
    expires_at timestamp without time zone,                                           -- NULL means the grant does not expire
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    created_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    CONSTRAINT ck_identity_role_assignment_assignable_to CHECK (((assignable_to)::text = ANY ((ARRAY['STAFF'::character varying, 'LEARNER'::character varying])::text[]))),
    CONSTRAINT ck_identity_role_assignment_audience CHECK ((((assignable_to)::text = 'STAFF'::text) = is_staff)),
    CONSTRAINT ck_identity_role_assignment_branch_needs_staff CHECK ((((scope_type)::text <> 'BRANCH'::text) OR (staff_id IS NOT NULL))),
    CONSTRAINT ck_identity_role_assignment_branch_shape CHECK ((((scope_type)::text = 'BRANCH'::text) = (branch_id IS NOT NULL))),
    CONSTRAINT ck_identity_role_assignment_expiry CHECK (((expires_at IS NULL) OR (expires_at > granted_at))),
    CONSTRAINT ck_identity_role_assignment_school_shape CHECK ((((scope_type)::text = 'PLATFORM'::text) = (school_id IS NULL))),
    CONSTRAINT ck_identity_role_assignment_scope_type CHECK (((scope_type)::text = ANY ((ARRAY['PLATFORM'::character varying, 'SCHOOL'::character varying, 'BRANCH'::character varying])::text[]))),
    CONSTRAINT ck_identity_role_assignment_timestamps CHECK ((updated_at >= created_at)),
    CONSTRAINT pk_identity_role_assignment PRIMARY KEY (id),
    CONSTRAINT uk_identity_role_assignment_grant UNIQUE NULLS NOT DISTINCT (identity_id, role_id, branch_id),
    CONSTRAINT fk_identity_role_assignment_audience FOREIGN KEY (role_id, assignable_to) REFERENCES public.m_role(id, assignable_to),
    CONSTRAINT fk_identity_role_assignment_granted_by FOREIGN KEY (granted_by) REFERENCES public.m_identity(id) ON DELETE RESTRICT,
    CONSTRAINT fk_identity_role_assignment_is_staff FOREIGN KEY (identity_id, is_staff) REFERENCES public.m_identity(id, is_staff),
    CONSTRAINT fk_identity_role_assignment_membership FOREIGN KEY (staff_id, branch_id) REFERENCES public.x_staff_branch_membership(staff_id, branch_id) ON DELETE CASCADE,
    CONSTRAINT fk_identity_role_assignment_role_branch FOREIGN KEY (role_id, branch_id) REFERENCES public.m_role(id, branch_id) ON DELETE CASCADE,
    CONSTRAINT fk_identity_role_assignment_role_school FOREIGN KEY (role_id, school_id) REFERENCES public.m_role(id, school_id) ON DELETE CASCADE,
    CONSTRAINT fk_identity_role_assignment_role_scope FOREIGN KEY (role_id, scope_type) REFERENCES public.m_role(id, scope_type) ON DELETE CASCADE,
    CONSTRAINT fk_identity_role_assignment_staff FOREIGN KEY (identity_id, staff_id) REFERENCES public.m_identity(id, staff_id),
    CONSTRAINT fk_identity_role_assignment_identity FOREIGN KEY (identity_id) REFERENCES public.m_identity(id) ON DELETE CASCADE
);

-- Indexes

CREATE INDEX ix_identity_learner ON public.m_identity USING btree (learner_id) WHERE (learner_id IS NOT NULL);
CREATE INDEX ix_identity_school ON public.m_identity USING btree (school_id);
CREATE INDEX ix_identity_staff_by_school ON public.m_identity USING btree (school_id) WHERE (learner_id IS NULL);
CREATE INDEX ix_branch_contact_number_school_branch ON public.m_branch_contact_number USING btree (school_id, branch_id);
CREATE INDEX ix_branch_license_class_school_branch ON public.x_branch_license_class USING btree (school_id, branch_id);
CREATE INDEX ix_learner_school_active ON public.m_learner USING btree (school_id) WHERE ((status)::text = ANY ((ARRAY['ENROLLED'::character varying, 'ACTIVE'::character varying])::text[]));
CREATE INDEX ix_learner_school_branch ON public.m_learner USING btree (school_id, current_branch_id);
CREATE INDEX ix_platform_operator_employed ON public.m_platform_operator USING btree (employment_status) WHERE ((employment_status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'ON_LEAVE'::character varying])::text[]));
CREATE INDEX ix_refresh_token_identity_active ON public.t_refresh_token USING btree (identity_id) WHERE (revoked_at IS NULL);
CREATE INDEX ix_role_branch ON public.m_role USING btree (branch_id);
CREATE INDEX ix_role_permission_permission ON public.x_role_permission USING btree (permission_id);
CREATE INDEX ix_role_school ON public.m_role USING btree (school_id);
CREATE INDEX ix_staff_branch_membership_branch ON public.x_staff_branch_membership USING btree (branch_id);
CREATE INDEX ix_staff_school_employed ON public.m_staff USING btree (school_id) WHERE ((employment_status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'ON_LEAVE'::character varying])::text[]));
CREATE INDEX ix_identity_role_assignment_role ON public.t_identity_role_assignment USING btree (role_id);
CREATE INDEX ix_identity_role_assignment_identity ON public.t_identity_role_assignment USING btree (identity_id);
CREATE UNIQUE INDEX ux_identity_school_phone ON public.m_identity USING btree (COALESCE(school_id, '00000000-0000-0000-0000-000000000000'::uuid), phone_number_e164);
CREATE UNIQUE INDEX ux_branch_contact_number_primary_per_branch ON public.m_branch_contact_number USING btree (branch_id) WHERE is_primary;
CREATE UNIQUE INDEX ux_branch_one_head_office_per_school ON public.m_branch USING btree (school_id) WHERE is_head_office;
CREATE UNIQUE INDEX ux_school_contact_number_primary_per_school ON public.m_school_contact_number USING btree (school_id) WHERE is_primary;
CREATE UNIQUE INDEX ux_staff_branch_membership_primary_per_staff ON public.x_staff_branch_membership USING btree (staff_id) WHERE is_primary;

-- Trigger functions

CREATE FUNCTION public.auth_bump_version_by_role() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE public.m_identity
    SET authorization_version = authorization_version + 1
    WHERE id IN (SELECT assignment.identity_id
                 FROM public.t_identity_role_assignment assignment
                 WHERE assignment.role_id IN (SELECT role_id FROM changed_row));
    RETURN NULL;
END
$$;

CREATE FUNCTION public.auth_bump_version_by_role_change() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE public.m_identity
    SET authorization_version = authorization_version + 1
    WHERE id IN (SELECT assignment.identity_id
                 FROM public.t_identity_role_assignment assignment
                 WHERE assignment.role_id IN (SELECT role_id FROM old_row
                                              UNION
                                              SELECT role_id FROM new_row));
    RETURN NULL;
END
$$;

CREATE FUNCTION public.auth_bump_version_by_identity() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE public.m_identity
    SET authorization_version = authorization_version + 1
    WHERE id IN (SELECT identity_id FROM changed_row);
    RETURN NULL;
END
$$;

CREATE FUNCTION public.auth_bump_version_by_identity_change() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE public.m_identity
    SET authorization_version = authorization_version + 1
    WHERE id IN (SELECT identity_id FROM old_row
                 UNION
                 SELECT identity_id FROM new_row);
    RETURN NULL;
END
$$;

CREATE FUNCTION public.auth_disable_login_for_inactive_learner() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE public.m_identity
    SET status = 'DISABLED',
        authorization_version = authorization_version + 1
    WHERE learner_id IN (SELECT id FROM new_row WHERE status NOT IN ('ENROLLED', 'ACTIVE'))
      AND status <> 'DISABLED';
    RETURN NULL;
END
$$;

CREATE FUNCTION public.auth_disable_login_for_inactive_operator() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE public.m_identity
    SET status = 'DISABLED',
        authorization_version = authorization_version + 1
    WHERE platform_operator_id IN (SELECT id FROM new_row WHERE employment_status NOT IN ('ACTIVE', 'ON_LEAVE'))
      AND status <> 'DISABLED';
    RETURN NULL;
END
$$;

CREATE FUNCTION public.auth_disable_login_for_inactive_staff() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE public.m_identity
    SET status = 'DISABLED',
        authorization_version = authorization_version + 1
    WHERE staff_id IN (SELECT id FROM new_row WHERE employment_status NOT IN ('ACTIVE', 'ON_LEAVE'))
      AND status <> 'DISABLED';
    RETURN NULL;
END
$$;

CREATE FUNCTION public.tenant_prevent_branch_school_change() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.school_id IS DISTINCT FROM OLD.school_id THEN
        RAISE EXCEPTION 'm_branch.school_id is immutable for tenant-owned branches';
    END IF;

    RETURN NEW;
END
$$;

CREATE FUNCTION public.tenant_set_school_id_from_branch() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    branch_school_id uuid;
BEGIN
    SELECT branch.school_id
    INTO branch_school_id
    FROM public.m_branch branch
    WHERE branch.id = NEW.branch_id;

    IF branch_school_id IS NULL THEN
        RAISE EXCEPTION 'branch % does not exist', NEW.branch_id;
    END IF;

    IF NEW.school_id IS NULL THEN
        NEW.school_id := branch_school_id;
    ELSIF NEW.school_id <> branch_school_id THEN
        RAISE EXCEPTION 'school_id % does not match branch % owner %',
            NEW.school_id, NEW.branch_id, branch_school_id;
    END IF;

    RETURN NEW;
END
$$;

-- Triggers

CREATE TRIGGER tr_branch_contact_number_set_school_id BEFORE INSERT OR UPDATE OF branch_id, school_id ON public.m_branch_contact_number FOR EACH ROW EXECUTE FUNCTION public.tenant_set_school_id_from_branch();
CREATE TRIGGER tr_branch_license_class_set_school_id BEFORE INSERT OR UPDATE OF branch_id, school_id ON public.x_branch_license_class FOR EACH ROW EXECUTE FUNCTION public.tenant_set_school_id_from_branch();
CREATE TRIGGER tr_branch_school_id_immutable BEFORE UPDATE OF school_id ON public.m_branch FOR EACH ROW EXECUTE FUNCTION public.tenant_prevent_branch_school_change();
CREATE TRIGGER tr_learner_status_disables_login AFTER UPDATE ON public.m_learner REFERENCING NEW TABLE AS new_row FOR EACH STATEMENT EXECUTE FUNCTION public.auth_disable_login_for_inactive_learner();
CREATE TRIGGER tr_platform_operator_status_disables_login AFTER UPDATE ON public.m_platform_operator REFERENCING NEW TABLE AS new_row FOR EACH STATEMENT EXECUTE FUNCTION public.auth_disable_login_for_inactive_operator();
CREATE TRIGGER tr_role_permission_delete_bump_version AFTER DELETE ON public.x_role_permission REFERENCING OLD TABLE AS changed_row FOR EACH STATEMENT EXECUTE FUNCTION public.auth_bump_version_by_role();
CREATE TRIGGER tr_role_permission_insert_bump_version AFTER INSERT ON public.x_role_permission REFERENCING NEW TABLE AS changed_row FOR EACH STATEMENT EXECUTE FUNCTION public.auth_bump_version_by_role();
CREATE TRIGGER tr_role_permission_update_bump_version AFTER UPDATE ON public.x_role_permission REFERENCING OLD TABLE AS old_row NEW TABLE AS new_row FOR EACH STATEMENT EXECUTE FUNCTION public.auth_bump_version_by_role_change();
CREATE TRIGGER tr_staff_status_disables_login AFTER UPDATE ON public.m_staff REFERENCING NEW TABLE AS new_row FOR EACH STATEMENT EXECUTE FUNCTION public.auth_disable_login_for_inactive_staff();
CREATE TRIGGER tr_identity_role_assignment_delete_bump_version AFTER DELETE ON public.t_identity_role_assignment REFERENCING OLD TABLE AS changed_row FOR EACH STATEMENT EXECUTE FUNCTION public.auth_bump_version_by_identity();
CREATE TRIGGER tr_identity_role_assignment_insert_bump_version AFTER INSERT ON public.t_identity_role_assignment REFERENCING NEW TABLE AS changed_row FOR EACH STATEMENT EXECUTE FUNCTION public.auth_bump_version_by_identity();
CREATE TRIGGER tr_identity_role_assignment_update_bump_version AFTER UPDATE ON public.t_identity_role_assignment REFERENCING OLD TABLE AS old_row NEW TABLE AS new_row FOR EACH STATEMENT EXECUTE FUNCTION public.auth_bump_version_by_identity_change();

COMMIT;
