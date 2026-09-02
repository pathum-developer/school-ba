--
-- PostgreSQL database dump
--

\restrict QoahUk9NLpB1ah1OBdkMGjitEcD6JRhENtnPYtJdGJ3YlePtEoqGPWoG2O6jIP0

-- Dumped from database version 17.10 (Debian 17.10-1.pgdg13+1)
-- Dumped by pg_dump version 17.10 (Debian 17.10-1.pgdg13+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA public;


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: auth_bump_version_by_role(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.auth_bump_version_by_role() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE public.m_app_user
    SET authorization_version = authorization_version + 1
    WHERE id IN (SELECT assignment.user_id
                 FROM public.t_user_role_assignment assignment
                 WHERE assignment.role_id IN (SELECT role_id FROM changed_row));
    RETURN NULL;
END
$$;


--
-- Name: auth_bump_version_by_role_change(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.auth_bump_version_by_role_change() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE public.m_app_user
    SET authorization_version = authorization_version + 1
    WHERE id IN (SELECT assignment.user_id
                 FROM public.t_user_role_assignment assignment
                 WHERE assignment.role_id IN (SELECT role_id FROM old_row
                                              UNION
                                              SELECT role_id FROM new_row));
    RETURN NULL;
END
$$;


--
-- Name: auth_bump_version_by_user(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.auth_bump_version_by_user() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE public.m_app_user
    SET authorization_version = authorization_version + 1
    WHERE id IN (SELECT user_id FROM changed_row);
    RETURN NULL;
END
$$;


--
-- Name: auth_bump_version_by_user_change(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.auth_bump_version_by_user_change() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE public.m_app_user
    SET authorization_version = authorization_version + 1
    WHERE id IN (SELECT user_id FROM old_row
                 UNION
                 SELECT user_id FROM new_row);
    RETURN NULL;
END
$$;


--
-- Name: auth_disable_login_for_inactive_learner(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.auth_disable_login_for_inactive_learner() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE public.m_app_user
    SET status = 'DISABLED',
        authorization_version = authorization_version + 1
    WHERE learner_id IN (SELECT id FROM new_row WHERE status NOT IN ('ENROLLED', 'ACTIVE'))
      AND status <> 'DISABLED';
    RETURN NULL;
END
$$;


--
-- Name: auth_disable_login_for_inactive_operator(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.auth_disable_login_for_inactive_operator() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE public.m_app_user
    SET status = 'DISABLED',
        authorization_version = authorization_version + 1
    WHERE platform_operator_id IN (SELECT id FROM new_row WHERE employment_status NOT IN ('ACTIVE', 'ON_LEAVE'))
      AND status <> 'DISABLED';
    RETURN NULL;
END
$$;


--
-- Name: auth_disable_login_for_inactive_staff(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.auth_disable_login_for_inactive_staff() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE public.m_app_user
    SET status = 'DISABLED',
        authorization_version = authorization_version + 1
    WHERE staff_id IN (SELECT id FROM new_row WHERE employment_status NOT IN ('ACTIVE', 'ON_LEAVE'))
      AND status <> 'DISABLED';
    RETURN NULL;
END
$$;


--
-- Name: tenant_prevent_branch_school_change(); Type: FUNCTION; Schema: public; Owner: -
--

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


--
-- Name: tenant_set_school_id_from_branch(); Type: FUNCTION; Schema: public; Owner: -
--

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


SET default_table_access_method = heap;

--
-- Name: m_app_user; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.m_app_user (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid,
    platform_operator_id uuid,
    staff_id uuid,
    learner_id uuid,
    is_staff boolean GENERATED ALWAYS AS ((learner_id IS NULL)) STORED,
    username character varying(64) NOT NULL,
    phone_number character varying(32) NOT NULL,
    phone_number_e164 character varying(16) NOT NULL,
    password_hash character varying(255),
    display_name character varying(160) NOT NULL,
    status character varying(32) DEFAULT 'PENDING_ACTIVATION'::character varying NOT NULL,
    authorization_version integer DEFAULT 0 NOT NULL,
    failed_attempt_count smallint DEFAULT 0 NOT NULL,
    locked_until timestamp without time zone,
    last_login_at timestamp without time zone,
    password_changed_at timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    created_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    CONSTRAINT ck_app_user_active_needs_password CHECK ((((status)::text <> 'ACTIVE'::text) OR (password_hash IS NOT NULL))),
    CONSTRAINT ck_app_user_authorization_version_non_negative CHECK ((authorization_version >= 0)),
    CONSTRAINT ck_app_user_display_name_not_blank CHECK ((btrim((display_name)::text) <> ''::text)),
    CONSTRAINT ck_app_user_failed_attempt_count_non_negative CHECK ((failed_attempt_count >= 0)),
    CONSTRAINT ck_app_user_learner_needs_school CHECK (((learner_id IS NULL) OR (school_id IS NOT NULL))),
    CONSTRAINT ck_app_user_operator_has_no_school CHECK (((platform_operator_id IS NULL) OR (school_id IS NULL))),
    CONSTRAINT ck_app_user_password_hash_not_blank CHECK (((password_hash IS NULL) OR (btrim((password_hash)::text) <> ''::text))),
    CONSTRAINT ck_app_user_phone_e164_format CHECK (((phone_number_e164)::text ~ '^\+[1-9][0-9]{7,14}$'::text)),
    CONSTRAINT ck_app_user_phone_format CHECK (((phone_number)::text ~ '^[0-9 +()-]+$'::text)),
    CONSTRAINT ck_app_user_single_person CHECK ((((((platform_operator_id IS NOT NULL))::integer + ((staff_id IS NOT NULL))::integer) + ((learner_id IS NOT NULL))::integer) = 1)),
    CONSTRAINT ck_app_user_staff_needs_school CHECK (((staff_id IS NULL) OR (school_id IS NOT NULL))),
    CONSTRAINT ck_app_user_status CHECK (((status)::text = ANY ((ARRAY['PENDING_ACTIVATION'::character varying, 'ACTIVE'::character varying, 'SUSPENDED'::character varying, 'LOCKED'::character varying, 'DISABLED'::character varying])::text[]))),
    CONSTRAINT ck_app_user_timestamps CHECK ((updated_at >= created_at)),
    CONSTRAINT ck_app_user_username_format CHECK (((username)::text ~ '^[a-z0-9]+(?:[._-][a-z0-9]+)*$'::text))
);


--
-- Name: m_branch; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.m_branch (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    code character varying(64) NOT NULL,
    name character varying(160) NOT NULL,
    branch_type character varying(32) DEFAULT 'BRANCH'::character varying NOT NULL,
    is_head_office boolean DEFAULT false NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    address character varying(255) NOT NULL,
    created_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    updated_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    CONSTRAINT ck_branch_address_not_blank CHECK ((btrim((address)::text) <> ''::text)),
    CONSTRAINT ck_branch_code_format CHECK (((code)::text ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'::text)),
    CONSTRAINT ck_branch_name_not_blank CHECK ((btrim((name)::text) <> ''::text)),
    CONSTRAINT ck_branch_timestamps CHECK ((updated_at >= created_at)),
    CONSTRAINT ck_branch_type CHECK (((branch_type)::text = ANY ((ARRAY['BRANCH'::character varying, 'YARD'::character varying])::text[])))
);


--
-- Name: m_branch_contact_number; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.m_branch_contact_number (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    branch_id uuid NOT NULL,
    contact_type character varying(32) DEFAULT 'GENERAL'::character varying NOT NULL,
    phone_number character varying(32) NOT NULL,
    phone_number_e164 character varying(16) NOT NULL,
    is_primary boolean DEFAULT false NOT NULL,
    display_order integer DEFAULT 1 NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    created_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    updated_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    school_id uuid NOT NULL,
    CONSTRAINT ck_branch_contact_number_display_order_positive CHECK ((display_order > 0)),
    CONSTRAINT ck_branch_contact_number_e164_format CHECK (((phone_number_e164)::text ~ '^\+[1-9][0-9]{7,14}$'::text)),
    CONSTRAINT ck_branch_contact_number_phone_format CHECK (((phone_number)::text ~ '^[0-9 +()-]+$'::text)),
    CONSTRAINT ck_branch_contact_number_phone_not_blank CHECK ((btrim((phone_number)::text) <> ''::text)),
    CONSTRAINT ck_branch_contact_number_timestamps CHECK ((updated_at >= created_at)),
    CONSTRAINT ck_branch_contact_number_type CHECK (((contact_type)::text = ANY ((ARRAY['GENERAL'::character varying, 'HOTLINE'::character varying, 'WHATSAPP'::character varying])::text[])))
);


--
-- Name: m_learner; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.m_learner (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    current_branch_id uuid NOT NULL,
    learner_no character varying(32) NOT NULL,
    status character varying(32) DEFAULT 'ENROLLED'::character varying NOT NULL,
    full_name character varying(160) NOT NULL,
    national_id character varying(32),
    date_of_birth date NOT NULL,
    email character varying(254),
    phone_number character varying(32) NOT NULL,
    phone_number_e164 character varying(16) NOT NULL,
    address character varying(255),
    enrolled_on date DEFAULT CURRENT_DATE NOT NULL,
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
    CONSTRAINT ck_learner_timestamps CHECK ((updated_at >= created_at))
);


--
-- Name: m_platform_operator; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.m_platform_operator (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    employee_no character varying(32) NOT NULL,
    full_name character varying(160) NOT NULL,
    designation character varying(64) NOT NULL,
    employment_status character varying(32) DEFAULT 'ACTIVE'::character varying NOT NULL,
    email character varying(254) NOT NULL,
    phone_number character varying(32) NOT NULL,
    phone_number_e164 character varying(16) NOT NULL,
    joined_on date DEFAULT CURRENT_DATE NOT NULL,
    left_on date,
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
    CONSTRAINT ck_platform_operator_timestamps CHECK ((updated_at >= created_at))
);


--
-- Name: m_role; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.m_role (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    scope_type character varying(32) NOT NULL,
    school_id uuid,
    branch_id uuid,
    assignable_to character varying(32) DEFAULT 'STAFF'::character varying NOT NULL,
    code character varying(64) NOT NULL,
    name character varying(160) NOT NULL,
    description character varying(255),
    is_system boolean DEFAULT false NOT NULL,
    is_assignable boolean DEFAULT true NOT NULL,
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
    CONSTRAINT ck_role_timestamps CHECK ((updated_at >= created_at))
);


--
-- Name: m_school; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.m_school (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(64) NOT NULL,
    name character varying(160) NOT NULL,
    short_name character varying(80) NOT NULL,
    established_year smallint NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    hotline_href character varying(64) NOT NULL,
    whatsapp_href character varying(128) NOT NULL,
    email character varying(254) NOT NULL,
    created_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    updated_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    tenant_status character varying(32) DEFAULT 'ACTIVE'::character varying NOT NULL,
    CONSTRAINT ck_school_code_format CHECK (((code)::text ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'::text)),
    CONSTRAINT ck_school_email_format CHECK (((email IS NULL) OR ((email)::text ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$'::text))),
    CONSTRAINT ck_school_established_year CHECK (((established_year IS NULL) OR ((established_year >= 1800) AND (established_year <= 9999)))),
    CONSTRAINT ck_school_hotline_href_format CHECK (((hotline_href)::text ~ '^tel:\+[1-9][0-9]{7,14}$'::text)),
    CONSTRAINT ck_school_name_not_blank CHECK ((btrim((name)::text) <> ''::text)),
    CONSTRAINT ck_school_short_name_not_blank CHECK ((btrim((short_name)::text) <> ''::text)),
    CONSTRAINT ck_school_tenant_status CHECK (((tenant_status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'SUSPENDED'::character varying, 'ARCHIVED'::character varying])::text[]))),
    CONSTRAINT ck_school_timestamps CHECK ((updated_at >= created_at)),
    CONSTRAINT ck_school_whatsapp_href_format CHECK (((whatsapp_href)::text ~ '^https://wa\.me/[1-9][0-9]{7,14}$'::text))
);


--
-- Name: m_school_contact_number; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.m_school_contact_number (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    contact_type character varying(32) DEFAULT 'GENERAL'::character varying NOT NULL,
    phone_number character varying(32) NOT NULL,
    phone_number_e164 character varying(16) NOT NULL,
    is_primary boolean DEFAULT false NOT NULL,
    display_order integer DEFAULT 1 NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    created_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    updated_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    CONSTRAINT ck_school_contact_number_display_order_positive CHECK ((display_order > 0)),
    CONSTRAINT ck_school_contact_number_e164_format CHECK (((phone_number_e164)::text ~ '^\+[1-9][0-9]{7,14}$'::text)),
    CONSTRAINT ck_school_contact_number_phone_format CHECK (((phone_number)::text ~ '^[0-9 +()-]+$'::text)),
    CONSTRAINT ck_school_contact_number_phone_not_blank CHECK ((btrim((phone_number)::text) <> ''::text)),
    CONSTRAINT ck_school_contact_number_timestamps CHECK ((updated_at >= created_at)),
    CONSTRAINT ck_school_contact_number_type CHECK (((contact_type)::text = ANY ((ARRAY['GENERAL'::character varying, 'HOTLINE'::character varying, 'WHATSAPP'::character varying])::text[])))
);


--
-- Name: m_staff; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.m_staff (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    employee_no character varying(32) NOT NULL,
    full_name character varying(160) NOT NULL,
    national_id character varying(32),
    date_of_birth date,
    designation character varying(64) NOT NULL,
    employment_status character varying(32) DEFAULT 'ACTIVE'::character varying NOT NULL,
    phone_number character varying(32) NOT NULL,
    phone_number_e164 character varying(16) NOT NULL,
    email character varying(254),
    address character varying(255),
    joined_on date DEFAULT CURRENT_DATE NOT NULL,
    left_on date,
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
    CONSTRAINT ck_staff_timestamps CHECK ((updated_at >= created_at))
);


--
-- Name: r_license_class; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.r_license_class (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(64) NOT NULL,
    name character varying(120) NOT NULL,
    display_order integer NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    included_class_codes jsonb DEFAULT '[]'::jsonb NOT NULL,
    old_class_codes jsonb DEFAULT '[]'::jsonb NOT NULL,
    source_url character varying(512) NOT NULL,
    description text NOT NULL,
    created_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    updated_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    CONSTRAINT ck_license_class_code_format CHECK (((code)::text ~ '^[A-Z][A-Z0-9]*$'::text)),
    CONSTRAINT ck_license_class_description_not_blank CHECK ((btrim(description) <> ''::text)),
    CONSTRAINT ck_license_class_display_order_positive CHECK ((display_order > 0)),
    CONSTRAINT ck_license_class_included_codes_array CHECK ((jsonb_typeof(included_class_codes) = 'array'::text)),
    CONSTRAINT ck_license_class_name_not_blank CHECK ((btrim((name)::text) <> ''::text)),
    CONSTRAINT ck_license_class_old_codes_array CHECK ((jsonb_typeof(old_class_codes) = 'array'::text)),
    CONSTRAINT ck_license_class_source_url_format CHECK (((source_url)::text ~ '^https?://.+'::text)),
    CONSTRAINT ck_license_class_timestamps CHECK ((updated_at >= created_at))
);


--
-- Name: r_permission; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.r_permission (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(64) NOT NULL,
    resource character varying(32) NOT NULL,
    action character varying(32) NOT NULL,
    max_scope_type character varying(32) NOT NULL,
    description character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    created_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    CONSTRAINT ck_permission_code_format CHECK (((code)::text ~ '^[a-z][a-z0-9-]*:[a-z][a-z0-9-]*$'::text)),
    CONSTRAINT ck_permission_code_matches_parts CHECK (((code)::text = (((resource)::text || ':'::text) || (action)::text))),
    CONSTRAINT ck_permission_description_not_blank CHECK ((btrim((description)::text) <> ''::text)),
    CONSTRAINT ck_permission_max_scope_type CHECK (((max_scope_type)::text = ANY ((ARRAY['PLATFORM'::character varying, 'SCHOOL'::character varying, 'BRANCH'::character varying])::text[]))),
    CONSTRAINT ck_permission_timestamps CHECK ((updated_at >= created_at))
);


--
-- Name: t_refresh_token; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.t_refresh_token (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    token_hash character varying(64) NOT NULL,
    jti uuid NOT NULL,
    issued_at timestamp without time zone DEFAULT now() NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    revoked_at timestamp without time zone,
    replaced_by_id uuid,
    user_agent character varying(255),
    ip_address inet,
    CONSTRAINT ck_refresh_token_expiry CHECK ((expires_at > issued_at)),
    CONSTRAINT ck_refresh_token_hash_format CHECK (((token_hash)::text ~ '^[0-9a-f]{64}$'::text)),
    CONSTRAINT ck_refresh_token_revoked CHECK (((revoked_at IS NULL) OR (revoked_at >= issued_at)))
);


--
-- Name: t_user_role_assignment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.t_user_role_assignment (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    role_id uuid NOT NULL,
    scope_type character varying(32) NOT NULL,
    school_id uuid,
    branch_id uuid,
    assignable_to character varying(32) DEFAULT 'STAFF'::character varying NOT NULL,
    is_staff boolean DEFAULT true NOT NULL,
    staff_id uuid,
    granted_by uuid NOT NULL,
    granted_at timestamp without time zone DEFAULT now() NOT NULL,
    expires_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    created_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    CONSTRAINT ck_user_role_assignment_assignable_to CHECK (((assignable_to)::text = ANY ((ARRAY['STAFF'::character varying, 'LEARNER'::character varying])::text[]))),
    CONSTRAINT ck_user_role_assignment_audience CHECK ((((assignable_to)::text = 'STAFF'::text) = is_staff)),
    CONSTRAINT ck_user_role_assignment_branch_needs_staff CHECK ((((scope_type)::text <> 'BRANCH'::text) OR (staff_id IS NOT NULL))),
    CONSTRAINT ck_user_role_assignment_branch_shape CHECK ((((scope_type)::text = 'BRANCH'::text) = (branch_id IS NOT NULL))),
    CONSTRAINT ck_user_role_assignment_expiry CHECK (((expires_at IS NULL) OR (expires_at > granted_at))),
    CONSTRAINT ck_user_role_assignment_school_shape CHECK ((((scope_type)::text = 'PLATFORM'::text) = (school_id IS NULL))),
    CONSTRAINT ck_user_role_assignment_scope_type CHECK (((scope_type)::text = ANY ((ARRAY['PLATFORM'::character varying, 'SCHOOL'::character varying, 'BRANCH'::character varying])::text[]))),
    CONSTRAINT ck_user_role_assignment_timestamps CHECK ((updated_at >= created_at))
);


--
-- Name: x_branch_license_class; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.x_branch_license_class (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    branch_id uuid NOT NULL,
    license_class_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    price_lkr numeric(12,2) NOT NULL,
    created_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    updated_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    school_id uuid NOT NULL,
    CONSTRAINT ck_branch_license_class_price_lkr_positive CHECK ((price_lkr > (0)::numeric)),
    CONSTRAINT ck_branch_license_class_timestamps CHECK ((updated_at >= created_at))
);


--
-- Name: x_role_permission; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.x_role_permission (
    role_id uuid NOT NULL,
    role_scope_type character varying(32) NOT NULL,
    permission_id uuid NOT NULL,
    permission_max_scope_type character varying(32) NOT NULL,
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
END))
);


--
-- Name: x_staff_branch_membership; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.x_staff_branch_membership (
    staff_id uuid NOT NULL,
    branch_id uuid NOT NULL,
    school_id uuid NOT NULL,
    is_primary boolean DEFAULT false NOT NULL,
    assigned_at timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    created_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_by character varying(20) DEFAULT 'system'::character varying NOT NULL,
    CONSTRAINT ck_staff_branch_membership_timestamps CHECK ((updated_at >= created_at))
);


--
-- Name: m_app_user pk_app_user; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_app_user
    ADD CONSTRAINT pk_app_user PRIMARY KEY (id);


--
-- Name: m_branch pk_branch; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_branch
    ADD CONSTRAINT pk_branch PRIMARY KEY (id);


--
-- Name: m_branch_contact_number pk_branch_contact_number; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_branch_contact_number
    ADD CONSTRAINT pk_branch_contact_number PRIMARY KEY (id);


--
-- Name: x_branch_license_class pk_branch_license_class; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.x_branch_license_class
    ADD CONSTRAINT pk_branch_license_class PRIMARY KEY (id);


--
-- Name: m_learner pk_learner; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_learner
    ADD CONSTRAINT pk_learner PRIMARY KEY (id);


--
-- Name: r_license_class pk_license_class; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.r_license_class
    ADD CONSTRAINT pk_license_class PRIMARY KEY (id);


--
-- Name: r_permission pk_permission; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.r_permission
    ADD CONSTRAINT pk_permission PRIMARY KEY (id);


--
-- Name: m_platform_operator pk_platform_operator; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_platform_operator
    ADD CONSTRAINT pk_platform_operator PRIMARY KEY (id);


--
-- Name: t_refresh_token pk_refresh_token; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_refresh_token
    ADD CONSTRAINT pk_refresh_token PRIMARY KEY (id);


--
-- Name: m_role pk_role; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_role
    ADD CONSTRAINT pk_role PRIMARY KEY (id);


--
-- Name: x_role_permission pk_role_permission; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.x_role_permission
    ADD CONSTRAINT pk_role_permission PRIMARY KEY (role_id, permission_id);


--
-- Name: m_school pk_school; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_school
    ADD CONSTRAINT pk_school PRIMARY KEY (id);


--
-- Name: m_school_contact_number pk_school_contact_number; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_school_contact_number
    ADD CONSTRAINT pk_school_contact_number PRIMARY KEY (id);


--
-- Name: m_staff pk_staff; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_staff
    ADD CONSTRAINT pk_staff PRIMARY KEY (id);


--
-- Name: x_staff_branch_membership pk_staff_branch_membership; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.x_staff_branch_membership
    ADD CONSTRAINT pk_staff_branch_membership PRIMARY KEY (staff_id, branch_id);


--
-- Name: t_user_role_assignment pk_user_role_assignment; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_user_role_assignment
    ADD CONSTRAINT pk_user_role_assignment PRIMARY KEY (id);


--
-- Name: m_app_user uk_app_user_id_is_staff; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_app_user
    ADD CONSTRAINT uk_app_user_id_is_staff UNIQUE (id, is_staff);


--
-- Name: m_app_user uk_app_user_id_school; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_app_user
    ADD CONSTRAINT uk_app_user_id_school UNIQUE (id, school_id);


--
-- Name: m_app_user uk_app_user_id_staff; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_app_user
    ADD CONSTRAINT uk_app_user_id_staff UNIQUE (id, staff_id);


--
-- Name: m_app_user uk_app_user_learner; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_app_user
    ADD CONSTRAINT uk_app_user_learner UNIQUE (learner_id);


--
-- Name: m_app_user uk_app_user_platform_operator; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_app_user
    ADD CONSTRAINT uk_app_user_platform_operator UNIQUE (platform_operator_id);


--
-- Name: m_app_user uk_app_user_staff; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_app_user
    ADD CONSTRAINT uk_app_user_staff UNIQUE (staff_id);


--
-- Name: m_app_user uk_app_user_username; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_app_user
    ADD CONSTRAINT uk_app_user_username UNIQUE (username);


--
-- Name: m_branch_contact_number uk_branch_contact_number_branch_display_order; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_branch_contact_number
    ADD CONSTRAINT uk_branch_contact_number_branch_display_order UNIQUE (branch_id, display_order);


--
-- Name: m_branch_contact_number uk_branch_contact_number_branch_phone; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_branch_contact_number
    ADD CONSTRAINT uk_branch_contact_number_branch_phone UNIQUE (branch_id, phone_number);


--
-- Name: m_branch_contact_number uk_branch_contact_number_school_branch_display_order; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_branch_contact_number
    ADD CONSTRAINT uk_branch_contact_number_school_branch_display_order UNIQUE (school_id, branch_id, display_order);


--
-- Name: m_branch_contact_number uk_branch_contact_number_school_branch_phone_e164; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_branch_contact_number
    ADD CONSTRAINT uk_branch_contact_number_school_branch_phone_e164 UNIQUE (school_id, branch_id, phone_number_e164);


--
-- Name: m_branch uk_branch_id_school; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_branch
    ADD CONSTRAINT uk_branch_id_school UNIQUE (id, school_id);


--
-- Name: x_branch_license_class uk_branch_license_class_branch_license_class; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.x_branch_license_class
    ADD CONSTRAINT uk_branch_license_class_branch_license_class UNIQUE (branch_id, license_class_id);


--
-- Name: x_branch_license_class uk_branch_license_class_school_branch_license_class; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.x_branch_license_class
    ADD CONSTRAINT uk_branch_license_class_school_branch_license_class UNIQUE (school_id, branch_id, license_class_id);


--
-- Name: m_branch uk_branch_school_code; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_branch
    ADD CONSTRAINT uk_branch_school_code UNIQUE (school_id, code);


--
-- Name: m_learner uk_learner_id_school; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_learner
    ADD CONSTRAINT uk_learner_id_school UNIQUE (id, school_id);


--
-- Name: m_learner uk_learner_school_email; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_learner
    ADD CONSTRAINT uk_learner_school_email UNIQUE (school_id, email);


--
-- Name: m_learner uk_learner_school_no; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_learner
    ADD CONSTRAINT uk_learner_school_no UNIQUE (school_id, learner_no);


--
-- Name: m_learner uk_learner_school_phone; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_learner
    ADD CONSTRAINT uk_learner_school_phone UNIQUE (school_id, phone_number_e164);


--
-- Name: r_license_class uk_license_class_code; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.r_license_class
    ADD CONSTRAINT uk_license_class_code UNIQUE (code);


--
-- Name: r_license_class uk_license_class_display_order; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.r_license_class
    ADD CONSTRAINT uk_license_class_display_order UNIQUE (display_order);


--
-- Name: r_permission uk_permission_code; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.r_permission
    ADD CONSTRAINT uk_permission_code UNIQUE (code);


--
-- Name: r_permission uk_permission_id_max_scope; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.r_permission
    ADD CONSTRAINT uk_permission_id_max_scope UNIQUE (id, max_scope_type);


--
-- Name: r_permission uk_permission_resource_action; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.r_permission
    ADD CONSTRAINT uk_permission_resource_action UNIQUE (resource, action);


--
-- Name: m_platform_operator uk_platform_operator_email; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_platform_operator
    ADD CONSTRAINT uk_platform_operator_email UNIQUE (email);


--
-- Name: m_platform_operator uk_platform_operator_employee_no; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_platform_operator
    ADD CONSTRAINT uk_platform_operator_employee_no UNIQUE (employee_no);


--
-- Name: m_platform_operator uk_platform_operator_phone; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_platform_operator
    ADD CONSTRAINT uk_platform_operator_phone UNIQUE (phone_number_e164);


--
-- Name: t_refresh_token uk_refresh_token_hash; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_refresh_token
    ADD CONSTRAINT uk_refresh_token_hash UNIQUE (token_hash);


--
-- Name: t_refresh_token uk_refresh_token_jti; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_refresh_token
    ADD CONSTRAINT uk_refresh_token_jti UNIQUE (jti);


--
-- Name: m_role uk_role_code_per_owner; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_role
    ADD CONSTRAINT uk_role_code_per_owner UNIQUE NULLS NOT DISTINCT (code, school_id, branch_id);


--
-- Name: m_role uk_role_id_assignable_to; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_role
    ADD CONSTRAINT uk_role_id_assignable_to UNIQUE (id, assignable_to);


--
-- Name: m_role uk_role_id_branch; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_role
    ADD CONSTRAINT uk_role_id_branch UNIQUE (id, branch_id);


--
-- Name: m_role uk_role_id_school; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_role
    ADD CONSTRAINT uk_role_id_school UNIQUE (id, school_id);


--
-- Name: m_role uk_role_id_scope_type; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_role
    ADD CONSTRAINT uk_role_id_scope_type UNIQUE (id, scope_type);


--
-- Name: m_school uk_school_code; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_school
    ADD CONSTRAINT uk_school_code UNIQUE (code);


--
-- Name: m_school_contact_number uk_school_contact_number_school_display_order; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_school_contact_number
    ADD CONSTRAINT uk_school_contact_number_school_display_order UNIQUE (school_id, display_order);


--
-- Name: m_school_contact_number uk_school_contact_number_school_phone; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_school_contact_number
    ADD CONSTRAINT uk_school_contact_number_school_phone UNIQUE (school_id, phone_number);


--
-- Name: m_school_contact_number uk_school_contact_number_school_phone_e164; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_school_contact_number
    ADD CONSTRAINT uk_school_contact_number_school_phone_e164 UNIQUE (school_id, phone_number_e164);


--
-- Name: m_staff uk_staff_id_school; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_staff
    ADD CONSTRAINT uk_staff_id_school UNIQUE (id, school_id);


--
-- Name: m_staff uk_staff_school_email; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_staff
    ADD CONSTRAINT uk_staff_school_email UNIQUE (school_id, email);


--
-- Name: m_staff uk_staff_school_employee_no; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_staff
    ADD CONSTRAINT uk_staff_school_employee_no UNIQUE (school_id, employee_no);


--
-- Name: m_staff uk_staff_school_phone; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_staff
    ADD CONSTRAINT uk_staff_school_phone UNIQUE (school_id, phone_number_e164);


--
-- Name: t_user_role_assignment uk_user_role_assignment_grant; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_user_role_assignment
    ADD CONSTRAINT uk_user_role_assignment_grant UNIQUE NULLS NOT DISTINCT (user_id, role_id, branch_id);


--
-- Name: ix_app_user_learner; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_app_user_learner ON public.m_app_user USING btree (learner_id) WHERE (learner_id IS NOT NULL);


--
-- Name: ix_app_user_school; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_app_user_school ON public.m_app_user USING btree (school_id);


--
-- Name: ix_app_user_staff_by_school; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_app_user_staff_by_school ON public.m_app_user USING btree (school_id) WHERE (learner_id IS NULL);


--
-- Name: ix_branch_contact_number_school_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_branch_contact_number_school_branch ON public.m_branch_contact_number USING btree (school_id, branch_id);


--
-- Name: ix_branch_license_class_school_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_branch_license_class_school_branch ON public.x_branch_license_class USING btree (school_id, branch_id);


--
-- Name: ix_learner_school_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_learner_school_active ON public.m_learner USING btree (school_id) WHERE ((status)::text = ANY ((ARRAY['ENROLLED'::character varying, 'ACTIVE'::character varying])::text[]));


--
-- Name: ix_learner_school_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_learner_school_branch ON public.m_learner USING btree (school_id, current_branch_id);


--
-- Name: ix_platform_operator_employed; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_platform_operator_employed ON public.m_platform_operator USING btree (employment_status) WHERE ((employment_status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'ON_LEAVE'::character varying])::text[]));


--
-- Name: ix_refresh_token_user_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_refresh_token_user_active ON public.t_refresh_token USING btree (user_id) WHERE (revoked_at IS NULL);


--
-- Name: ix_role_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_role_branch ON public.m_role USING btree (branch_id);


--
-- Name: ix_role_permission_permission; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_role_permission_permission ON public.x_role_permission USING btree (permission_id);


--
-- Name: ix_role_school; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_role_school ON public.m_role USING btree (school_id);


--
-- Name: ix_staff_branch_membership_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_staff_branch_membership_branch ON public.x_staff_branch_membership USING btree (branch_id);


--
-- Name: ix_staff_school_employed; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_staff_school_employed ON public.m_staff USING btree (school_id) WHERE ((employment_status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'ON_LEAVE'::character varying])::text[]));


--
-- Name: ix_user_role_assignment_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_user_role_assignment_role ON public.t_user_role_assignment USING btree (role_id);


--
-- Name: ix_user_role_assignment_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_user_role_assignment_user ON public.t_user_role_assignment USING btree (user_id);


--
-- Name: ux_app_user_school_phone; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_app_user_school_phone ON public.m_app_user USING btree (COALESCE(school_id, '00000000-0000-0000-0000-000000000000'::uuid), phone_number_e164);


--
-- Name: ux_branch_contact_number_primary_per_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_branch_contact_number_primary_per_branch ON public.m_branch_contact_number USING btree (branch_id) WHERE is_primary;


--
-- Name: ux_branch_one_head_office_per_school; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_branch_one_head_office_per_school ON public.m_branch USING btree (school_id) WHERE is_head_office;


--
-- Name: ux_school_contact_number_primary_per_school; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_school_contact_number_primary_per_school ON public.m_school_contact_number USING btree (school_id) WHERE is_primary;


--
-- Name: ux_staff_branch_membership_primary_per_staff; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_staff_branch_membership_primary_per_staff ON public.x_staff_branch_membership USING btree (staff_id) WHERE is_primary;


--
-- Name: m_branch_contact_number tr_branch_contact_number_set_school_id; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tr_branch_contact_number_set_school_id BEFORE INSERT OR UPDATE OF branch_id, school_id ON public.m_branch_contact_number FOR EACH ROW EXECUTE FUNCTION public.tenant_set_school_id_from_branch();


--
-- Name: x_branch_license_class tr_branch_license_class_set_school_id; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tr_branch_license_class_set_school_id BEFORE INSERT OR UPDATE OF branch_id, school_id ON public.x_branch_license_class FOR EACH ROW EXECUTE FUNCTION public.tenant_set_school_id_from_branch();


--
-- Name: m_branch tr_branch_school_id_immutable; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tr_branch_school_id_immutable BEFORE UPDATE OF school_id ON public.m_branch FOR EACH ROW EXECUTE FUNCTION public.tenant_prevent_branch_school_change();


--
-- Name: m_learner tr_learner_status_disables_login; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tr_learner_status_disables_login AFTER UPDATE ON public.m_learner REFERENCING NEW TABLE AS new_row FOR EACH STATEMENT EXECUTE FUNCTION public.auth_disable_login_for_inactive_learner();


--
-- Name: m_platform_operator tr_platform_operator_status_disables_login; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tr_platform_operator_status_disables_login AFTER UPDATE ON public.m_platform_operator REFERENCING NEW TABLE AS new_row FOR EACH STATEMENT EXECUTE FUNCTION public.auth_disable_login_for_inactive_operator();


--
-- Name: x_role_permission tr_role_permission_delete_bump_version; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tr_role_permission_delete_bump_version AFTER DELETE ON public.x_role_permission REFERENCING OLD TABLE AS changed_row FOR EACH STATEMENT EXECUTE FUNCTION public.auth_bump_version_by_role();


--
-- Name: x_role_permission tr_role_permission_insert_bump_version; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tr_role_permission_insert_bump_version AFTER INSERT ON public.x_role_permission REFERENCING NEW TABLE AS changed_row FOR EACH STATEMENT EXECUTE FUNCTION public.auth_bump_version_by_role();


--
-- Name: x_role_permission tr_role_permission_update_bump_version; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tr_role_permission_update_bump_version AFTER UPDATE ON public.x_role_permission REFERENCING OLD TABLE AS old_row NEW TABLE AS new_row FOR EACH STATEMENT EXECUTE FUNCTION public.auth_bump_version_by_role_change();


--
-- Name: m_staff tr_staff_status_disables_login; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tr_staff_status_disables_login AFTER UPDATE ON public.m_staff REFERENCING NEW TABLE AS new_row FOR EACH STATEMENT EXECUTE FUNCTION public.auth_disable_login_for_inactive_staff();


--
-- Name: t_user_role_assignment tr_user_role_assignment_delete_bump_version; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tr_user_role_assignment_delete_bump_version AFTER DELETE ON public.t_user_role_assignment REFERENCING OLD TABLE AS changed_row FOR EACH STATEMENT EXECUTE FUNCTION public.auth_bump_version_by_user();


--
-- Name: t_user_role_assignment tr_user_role_assignment_insert_bump_version; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tr_user_role_assignment_insert_bump_version AFTER INSERT ON public.t_user_role_assignment REFERENCING NEW TABLE AS changed_row FOR EACH STATEMENT EXECUTE FUNCTION public.auth_bump_version_by_user();


--
-- Name: t_user_role_assignment tr_user_role_assignment_update_bump_version; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tr_user_role_assignment_update_bump_version AFTER UPDATE ON public.t_user_role_assignment REFERENCING OLD TABLE AS old_row NEW TABLE AS new_row FOR EACH STATEMENT EXECUTE FUNCTION public.auth_bump_version_by_user_change();


--
-- Name: m_app_user fk_app_user_learner; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_app_user
    ADD CONSTRAINT fk_app_user_learner FOREIGN KEY (learner_id, school_id) REFERENCES public.m_learner(id, school_id) ON DELETE RESTRICT;


--
-- Name: m_app_user fk_app_user_platform_operator; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_app_user
    ADD CONSTRAINT fk_app_user_platform_operator FOREIGN KEY (platform_operator_id) REFERENCES public.m_platform_operator(id) ON DELETE RESTRICT;


--
-- Name: m_app_user fk_app_user_school; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_app_user
    ADD CONSTRAINT fk_app_user_school FOREIGN KEY (school_id) REFERENCES public.m_school(id) ON DELETE RESTRICT;


--
-- Name: m_app_user fk_app_user_staff; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_app_user
    ADD CONSTRAINT fk_app_user_staff FOREIGN KEY (staff_id, school_id) REFERENCES public.m_staff(id, school_id) ON DELETE RESTRICT;


--
-- Name: m_branch_contact_number fk_branch_contact_number_branch; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_branch_contact_number
    ADD CONSTRAINT fk_branch_contact_number_branch FOREIGN KEY (branch_id, school_id) REFERENCES public.m_branch(id, school_id) ON DELETE CASCADE;


--
-- Name: x_branch_license_class fk_branch_license_class_branch; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.x_branch_license_class
    ADD CONSTRAINT fk_branch_license_class_branch FOREIGN KEY (branch_id, school_id) REFERENCES public.m_branch(id, school_id) ON DELETE CASCADE;


--
-- Name: x_branch_license_class fk_branch_license_class_license_class; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.x_branch_license_class
    ADD CONSTRAINT fk_branch_license_class_license_class FOREIGN KEY (license_class_id) REFERENCES public.r_license_class(id) ON DELETE RESTRICT;


--
-- Name: m_branch fk_branch_school; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_branch
    ADD CONSTRAINT fk_branch_school FOREIGN KEY (school_id) REFERENCES public.m_school(id) ON DELETE RESTRICT;


--
-- Name: m_learner fk_learner_branch; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_learner
    ADD CONSTRAINT fk_learner_branch FOREIGN KEY (current_branch_id, school_id) REFERENCES public.m_branch(id, school_id) ON DELETE RESTRICT;


--
-- Name: m_learner fk_learner_school; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_learner
    ADD CONSTRAINT fk_learner_school FOREIGN KEY (school_id) REFERENCES public.m_school(id) ON DELETE RESTRICT;


--
-- Name: t_refresh_token fk_refresh_token_replaced_by; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_refresh_token
    ADD CONSTRAINT fk_refresh_token_replaced_by FOREIGN KEY (replaced_by_id) REFERENCES public.t_refresh_token(id) ON DELETE SET NULL;


--
-- Name: t_refresh_token fk_refresh_token_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_refresh_token
    ADD CONSTRAINT fk_refresh_token_user FOREIGN KEY (user_id) REFERENCES public.m_app_user(id) ON DELETE CASCADE;


--
-- Name: m_role fk_role_branch; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_role
    ADD CONSTRAINT fk_role_branch FOREIGN KEY (branch_id, school_id) REFERENCES public.m_branch(id, school_id) ON DELETE CASCADE;


--
-- Name: x_role_permission fk_role_permission_permission; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.x_role_permission
    ADD CONSTRAINT fk_role_permission_permission FOREIGN KEY (permission_id, permission_max_scope_type) REFERENCES public.r_permission(id, max_scope_type) ON DELETE RESTRICT;


--
-- Name: x_role_permission fk_role_permission_role; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.x_role_permission
    ADD CONSTRAINT fk_role_permission_role FOREIGN KEY (role_id, role_scope_type) REFERENCES public.m_role(id, scope_type) ON DELETE CASCADE;


--
-- Name: m_role fk_role_school; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_role
    ADD CONSTRAINT fk_role_school FOREIGN KEY (school_id) REFERENCES public.m_school(id) ON DELETE CASCADE;


--
-- Name: m_school_contact_number fk_school_contact_number_school; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_school_contact_number
    ADD CONSTRAINT fk_school_contact_number_school FOREIGN KEY (school_id) REFERENCES public.m_school(id) ON DELETE CASCADE;


--
-- Name: x_staff_branch_membership fk_staff_branch_membership_branch; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.x_staff_branch_membership
    ADD CONSTRAINT fk_staff_branch_membership_branch FOREIGN KEY (branch_id, school_id) REFERENCES public.m_branch(id, school_id) ON DELETE CASCADE;


--
-- Name: x_staff_branch_membership fk_staff_branch_membership_staff; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.x_staff_branch_membership
    ADD CONSTRAINT fk_staff_branch_membership_staff FOREIGN KEY (staff_id, school_id) REFERENCES public.m_staff(id, school_id) ON DELETE CASCADE;


--
-- Name: m_staff fk_staff_school; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.m_staff
    ADD CONSTRAINT fk_staff_school FOREIGN KEY (school_id) REFERENCES public.m_school(id) ON DELETE RESTRICT;


--
-- Name: t_user_role_assignment fk_user_role_assignment_audience; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_user_role_assignment
    ADD CONSTRAINT fk_user_role_assignment_audience FOREIGN KEY (role_id, assignable_to) REFERENCES public.m_role(id, assignable_to);


--
-- Name: t_user_role_assignment fk_user_role_assignment_granted_by; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_user_role_assignment
    ADD CONSTRAINT fk_user_role_assignment_granted_by FOREIGN KEY (granted_by) REFERENCES public.m_app_user(id) ON DELETE RESTRICT;


--
-- Name: t_user_role_assignment fk_user_role_assignment_is_staff; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_user_role_assignment
    ADD CONSTRAINT fk_user_role_assignment_is_staff FOREIGN KEY (user_id, is_staff) REFERENCES public.m_app_user(id, is_staff);


--
-- Name: t_user_role_assignment fk_user_role_assignment_membership; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_user_role_assignment
    ADD CONSTRAINT fk_user_role_assignment_membership FOREIGN KEY (staff_id, branch_id) REFERENCES public.x_staff_branch_membership(staff_id, branch_id) ON DELETE CASCADE;


--
-- Name: t_user_role_assignment fk_user_role_assignment_role_branch; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_user_role_assignment
    ADD CONSTRAINT fk_user_role_assignment_role_branch FOREIGN KEY (role_id, branch_id) REFERENCES public.m_role(id, branch_id) ON DELETE CASCADE;


--
-- Name: t_user_role_assignment fk_user_role_assignment_role_school; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_user_role_assignment
    ADD CONSTRAINT fk_user_role_assignment_role_school FOREIGN KEY (role_id, school_id) REFERENCES public.m_role(id, school_id) ON DELETE CASCADE;


--
-- Name: t_user_role_assignment fk_user_role_assignment_role_scope; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_user_role_assignment
    ADD CONSTRAINT fk_user_role_assignment_role_scope FOREIGN KEY (role_id, scope_type) REFERENCES public.m_role(id, scope_type) ON DELETE CASCADE;


--
-- Name: t_user_role_assignment fk_user_role_assignment_staff; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_user_role_assignment
    ADD CONSTRAINT fk_user_role_assignment_staff FOREIGN KEY (user_id, staff_id) REFERENCES public.m_app_user(id, staff_id);


--
-- Name: t_user_role_assignment fk_user_role_assignment_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_user_role_assignment
    ADD CONSTRAINT fk_user_role_assignment_user FOREIGN KEY (user_id) REFERENCES public.m_app_user(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict QoahUk9NLpB1ah1OBdkMGjitEcD6JRhENtnPYtJdGJ3YlePtEoqGPWoG2O6jIP0
