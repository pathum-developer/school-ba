--
-- PostgreSQL database dump
--

\restrict hKSacTL0HKCvdmmkRUUEgydzkJu6pa0HNJVoPrTrPQzPxpLJpX3I8Y0p9loZzKY

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
-- Name: administration_enforce_account_immutability(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.administration_enforce_account_immutability() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.account_type IS DISTINCT FROM OLD.account_type THEN
        RAISE EXCEPTION 'account type is immutable';
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: administration_enforce_role_assignment_immutability(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.administration_enforce_role_assignment_immutability() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: administration_enforce_role_immutability(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.administration_enforce_role_immutability() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: administration_enforce_staff_branch_assignment_immutability(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.administration_enforce_staff_branch_assignment_immutability() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: administration_enforce_student_account_link_immutability(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.administration_enforce_student_account_link_immutability() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: administration_reject_append_only_mutation(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.administration_reject_append_only_mutation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    RAISE EXCEPTION 'append-only records cannot be updated or deleted';
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: account_contact; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.account_contact (
    id uuid NOT NULL,
    account_id uuid NOT NULL,
    contact_type character varying(16) NOT NULL,
    normalized_value character varying(320) NOT NULL,
    lifecycle_state character varying(16) DEFAULT 'ACTIVE'::character varying NOT NULL,
    is_login_identifier boolean DEFAULT false NOT NULL,
    verified_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    retired_at timestamp with time zone,
    CONSTRAINT ck_account_contact_login_identifier CHECK (((NOT is_login_identifier) OR (((lifecycle_state)::text = 'ACTIVE'::text) AND (verified_at IS NOT NULL)))),
    CONSTRAINT ck_account_contact_retirement CHECK (((((lifecycle_state)::text = 'ACTIVE'::text) AND (retired_at IS NULL)) OR (((lifecycle_state)::text = 'RETIRED'::text) AND (retired_at IS NOT NULL)))),
    CONSTRAINT ck_account_contact_state CHECK (((lifecycle_state)::text = ANY ((ARRAY['ACTIVE'::character varying, 'RETIRED'::character varying])::text[]))),
    CONSTRAINT ck_account_contact_type CHECK (((contact_type)::text = ANY ((ARRAY['EMAIL'::character varying, 'MOBILE'::character varying])::text[])))
);


--
-- Name: account_recovery_challenge; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.account_recovery_challenge (
    id uuid NOT NULL,
    account_id uuid NOT NULL,
    recovery_type character varying(64) NOT NULL,
    challenge_hash bytea NOT NULL,
    lifecycle_state character varying(16) DEFAULT 'PENDING'::character varying NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    verified_at timestamp with time zone,
    consumed_at timestamp with time zone,
    invalidated_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT ck_account_recovery_expiry CHECK ((expires_at > created_at)),
    CONSTRAINT ck_account_recovery_state CHECK (((lifecycle_state)::text = ANY ((ARRAY['PENDING'::character varying, 'VERIFIED'::character varying, 'CONSUMED'::character varying, 'EXPIRED'::character varying, 'INVALIDATED'::character varying])::text[])))
);


--
-- Name: audit_chain_state; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_chain_state (
    chain_key character varying(64) NOT NULL,
    head_sequence bigint DEFAULT 0 NOT NULL,
    head_event_hash bytea,
    lock_version bigint DEFAULT 0 NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT ck_audit_chain_state_head CHECK ((((head_sequence = 0) AND (head_event_hash IS NULL)) OR ((head_sequence > 0) AND (head_event_hash IS NOT NULL)))),
    CONSTRAINT ck_audit_chain_state_version CHECK ((lock_version >= 0))
);


--
-- Name: auth_challenge; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auth_challenge (
    id uuid NOT NULL,
    account_id uuid NOT NULL,
    mfa_factor_id uuid,
    challenge_type character varying(64) NOT NULL,
    challenge_hash bytea NOT NULL,
    lifecycle_state character varying(16) DEFAULT 'PENDING'::character varying NOT NULL,
    attempt_count integer DEFAULT 0 NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    verified_at timestamp with time zone,
    consumed_at timestamp with time zone,
    invalidated_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT ck_auth_challenge_attempts CHECK ((attempt_count >= 0)),
    CONSTRAINT ck_auth_challenge_expiry CHECK ((expires_at > created_at)),
    CONSTRAINT ck_auth_challenge_state CHECK (((lifecycle_state)::text = ANY ((ARRAY['PENDING'::character varying, 'VERIFIED'::character varying, 'CONSUMED'::character varying, 'EXPIRED'::character varying, 'INVALIDATED'::character varying])::text[])))
);


--
-- Name: auth_credential; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auth_credential (
    id uuid NOT NULL,
    account_id uuid NOT NULL,
    credential_type character varying(64) NOT NULL,
    secret_hash text NOT NULL,
    hash_algorithm character varying(64) NOT NULL,
    lifecycle_state character varying(16) DEFAULT 'ACTIVE'::character varying NOT NULL,
    credential_revision bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_used_at timestamp with time zone,
    revoked_at timestamp with time zone,
    CONSTRAINT ck_auth_credential_revision CHECK ((credential_revision >= 0)),
    CONSTRAINT ck_auth_credential_revocation CHECK (((((lifecycle_state)::text = 'ACTIVE'::text) AND (revoked_at IS NULL)) OR (((lifecycle_state)::text = 'REVOKED'::text) AND (revoked_at IS NOT NULL)))),
    CONSTRAINT ck_auth_credential_state CHECK (((lifecycle_state)::text = ANY ((ARRAY['ACTIVE'::character varying, 'REVOKED'::character varying])::text[])))
);


--
-- Name: auth_session; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auth_session (
    id uuid NOT NULL,
    account_id uuid NOT NULL,
    session_family_id uuid NOT NULL,
    session_token_hash bytea NOT NULL,
    session_type character varying(64) NOT NULL,
    lifecycle_state character varying(16) DEFAULT 'ACTIVE'::character varying NOT NULL,
    authorization_version bigint NOT NULL,
    credential_version bigint NOT NULL,
    authenticated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    mfa_authenticated_at timestamp with time zone,
    last_seen_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    idle_expires_at timestamp with time zone NOT NULL,
    absolute_expires_at timestamp with time zone NOT NULL,
    ended_at timestamp with time zone,
    end_reason character varying(100),
    CONSTRAINT ck_auth_session_end CHECK (((((lifecycle_state)::text = 'ACTIVE'::text) AND (ended_at IS NULL)) OR (((lifecycle_state)::text <> 'ACTIVE'::text) AND (ended_at IS NOT NULL)))),
    CONSTRAINT ck_auth_session_expiry CHECK (((idle_expires_at <= absolute_expires_at) AND (absolute_expires_at > authenticated_at))),
    CONSTRAINT ck_auth_session_state CHECK (((lifecycle_state)::text = ANY ((ARRAY['ACTIVE'::character varying, 'REVOKED'::character varying, 'EXPIRED'::character varying, 'LOGGED_OUT'::character varying])::text[]))),
    CONSTRAINT ck_auth_session_versions CHECK (((authorization_version >= 0) AND (credential_version >= 0)))
);


--
-- Name: authentication_event; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.authentication_event (
    id uuid NOT NULL,
    account_id uuid,
    session_id uuid,
    event_type character varying(100) NOT NULL,
    identifier_hash bytea,
    source_fingerprint_hash bytea,
    event_metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    occurred_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: authorization_permission; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.authorization_permission (
    id uuid NOT NULL,
    code character varying(150) NOT NULL,
    permission_category character varying(4) NOT NULL,
    is_control_plane boolean DEFAULT false NOT NULL,
    seed_revision bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT ck_authorization_permission_category CHECK (((permission_category)::text = ANY ((ARRAY['SC'::character varying, 'BR'::character varying, 'CO'::character varying, 'ST'::character varying])::text[]))),
    CONSTRAINT ck_authorization_permission_code_category CHECK (((((permission_category)::text = 'SC'::text) AND ("left"((code)::text, 3) = 'SC_'::text)) OR (((permission_category)::text = 'BR'::text) AND ("left"((code)::text, 3) = 'BR_'::text)) OR (((permission_category)::text = 'CO'::text) AND ("left"((code)::text, 3) = 'CO_'::text)) OR (((permission_category)::text = 'ST'::text) AND ("left"((code)::text, 3) = 'ST_'::text)))),
    CONSTRAINT ck_authorization_permission_seed_revision CHECK ((seed_revision >= 0))
);


--
-- Name: authorization_permission_scope; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.authorization_permission_scope (
    permission_id uuid NOT NULL,
    scope character varying(16) NOT NULL,
    is_delegable boolean DEFAULT false NOT NULL,
    permission_category character varying(4) NOT NULL,
    CONSTRAINT ck_permission_scope_category CHECK (((((permission_category)::text = 'SC'::text) AND ((scope)::text = 'SCHOOL'::text)) OR (((permission_category)::text = 'BR'::text) AND ((scope)::text = 'BRANCH'::text)) OR (((permission_category)::text = 'CO'::text) AND ((scope)::text = ANY ((ARRAY['SCHOOL'::character varying, 'BRANCH'::character varying])::text[]))) OR (((permission_category)::text = 'ST'::text) AND ((scope)::text = 'SELF'::text)))),
    CONSTRAINT ck_permission_scope_scope CHECK (((scope)::text = ANY ((ARRAY['SCHOOL'::character varying, 'BRANCH'::character varying, 'SELF'::character varying])::text[])))
);


--
-- Name: authorization_role; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.authorization_role (
    id uuid NOT NULL,
    code character varying(100) NOT NULL,
    display_name character varying(200) NOT NULL,
    role_kind character varying(16) NOT NULL,
    system_role_type character varying(32),
    account_type character varying(16) NOT NULL,
    scope character varying(16) NOT NULL,
    branch_id uuid,
    scope_branch_key uuid DEFAULT '00000000-0000-0000-0000-000000000000'::uuid NOT NULL,
    lifecycle_state character varying(16) DEFAULT 'ACTIVE'::character varying NOT NULL,
    policy_revision bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    inactivated_at timestamp with time zone,
    CONSTRAINT ck_authorization_role_account_type CHECK (((account_type)::text = ANY ((ARRAY['STAFF'::character varying, 'STUDENT'::character varying])::text[]))),
    CONSTRAINT ck_authorization_role_branch_key CHECK (((((scope)::text = 'BRANCH'::text) AND (branch_id IS NOT NULL) AND (scope_branch_key = branch_id)) OR (((scope)::text = ANY ((ARRAY['SCHOOL'::character varying, 'SELF'::character varying])::text[])) AND (branch_id IS NULL) AND (scope_branch_key = '00000000-0000-0000-0000-000000000000'::uuid)))),
    CONSTRAINT ck_authorization_role_kind CHECK (((role_kind)::text = ANY ((ARRAY['ORDINARY'::character varying, 'SYSTEM'::character varying])::text[]))),
    CONSTRAINT ck_authorization_role_kind_shape CHECK (((((role_kind)::text = 'ORDINARY'::text) AND (system_role_type IS NULL) AND ((account_type)::text = 'STAFF'::text) AND ((scope)::text = ANY ((ARRAY['SCHOOL'::character varying, 'BRANCH'::character varying])::text[]))) OR (((role_kind)::text = 'SYSTEM'::text) AND ((((system_role_type)::text = 'SCHOOL_SUPER_ADMIN'::text) AND ((account_type)::text = 'STAFF'::text) AND ((scope)::text = 'SCHOOL'::text)) OR (((system_role_type)::text = 'BRANCH_SUPER_ADMIN'::text) AND ((account_type)::text = 'STAFF'::text) AND ((scope)::text = 'BRANCH'::text)) OR (((system_role_type)::text = 'STUDENT_DEFAULT'::text) AND ((account_type)::text = 'STUDENT'::text) AND ((scope)::text = 'SELF'::text)))))),
    CONSTRAINT ck_authorization_role_lifecycle CHECK (((((lifecycle_state)::text = 'ACTIVE'::text) AND (inactivated_at IS NULL)) OR (((lifecycle_state)::text = 'INACTIVE'::text) AND (inactivated_at IS NOT NULL)))),
    CONSTRAINT ck_authorization_role_policy_revision CHECK ((policy_revision >= 0)),
    CONSTRAINT ck_authorization_role_scope CHECK (((scope)::text = ANY ((ARRAY['SCHOOL'::character varying, 'BRANCH'::character varying, 'SELF'::character varying])::text[]))),
    CONSTRAINT ck_authorization_role_state CHECK (((lifecycle_state)::text = ANY ((ARRAY['ACTIVE'::character varying, 'INACTIVE'::character varying])::text[]))),
    CONSTRAINT ck_authorization_role_system_active CHECK ((((role_kind)::text <> 'SYSTEM'::text) OR ((lifecycle_state)::text = 'ACTIVE'::text)))
);


--
-- Name: authorization_role_assignment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.authorization_role_assignment (
    id uuid NOT NULL,
    account_id uuid NOT NULL,
    account_type character varying(16) NOT NULL,
    role_id uuid NOT NULL,
    scope character varying(16) NOT NULL,
    branch_id uuid,
    scope_branch_key uuid DEFAULT '00000000-0000-0000-0000-000000000000'::uuid NOT NULL,
    staff_branch_assignment_id uuid,
    lifecycle_state character varying(16) DEFAULT 'ACTIVE'::character varying NOT NULL,
    assigned_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ended_at timestamp with time zone,
    end_reason text,
    assigned_by_account_id uuid,
    CONSTRAINT ck_role_assignment_account_type CHECK (((account_type)::text = ANY ((ARRAY['STAFF'::character varying, 'STUDENT'::character varying])::text[]))),
    CONSTRAINT ck_role_assignment_end CHECK (((((lifecycle_state)::text = 'ACTIVE'::text) AND (ended_at IS NULL)) OR (((lifecycle_state)::text = 'ENDED'::text) AND (ended_at IS NOT NULL)))),
    CONSTRAINT ck_role_assignment_scope CHECK (((scope)::text = ANY ((ARRAY['SCHOOL'::character varying, 'BRANCH'::character varying, 'SELF'::character varying])::text[]))),
    CONSTRAINT ck_role_assignment_shape CHECK (((((scope)::text = 'BRANCH'::text) AND (branch_id IS NOT NULL) AND (scope_branch_key = branch_id) AND (staff_branch_assignment_id IS NOT NULL)) OR (((scope)::text = ANY ((ARRAY['SCHOOL'::character varying, 'SELF'::character varying])::text[])) AND (branch_id IS NULL) AND (scope_branch_key = '00000000-0000-0000-0000-000000000000'::uuid) AND (staff_branch_assignment_id IS NULL)))),
    CONSTRAINT ck_role_assignment_state CHECK (((lifecycle_state)::text = ANY ((ARRAY['ACTIVE'::character varying, 'ENDED'::character varying])::text[])))
);


--
-- Name: authorization_role_delegated_permission; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.authorization_role_delegated_permission (
    role_id uuid NOT NULL,
    permission_id uuid NOT NULL,
    role_scope character varying(16) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    permission_is_delegable boolean DEFAULT true NOT NULL,
    CONSTRAINT ck_role_delegated_permission_delegable CHECK (permission_is_delegable)
);


--
-- Name: authorization_role_permission; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.authorization_role_permission (
    role_id uuid NOT NULL,
    permission_id uuid NOT NULL,
    role_scope character varying(16) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: databasechangelog; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.databasechangelog (
    id character varying(255) NOT NULL,
    author character varying(255) NOT NULL,
    filename character varying(255) NOT NULL,
    dateexecuted timestamp without time zone NOT NULL,
    orderexecuted integer NOT NULL,
    exectype character varying(10) NOT NULL,
    md5sum character varying(35),
    description character varying(255),
    comments character varying(255),
    tag character varying(255),
    liquibase character varying(20),
    contexts character varying(255),
    labels character varying(255),
    deployment_id character varying(10)
);


--
-- Name: databasechangeloglock; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.databasechangeloglock (
    id integer NOT NULL,
    locked boolean NOT NULL,
    lockgranted timestamp without time zone,
    lockedby character varying(255)
);


--
-- Name: mfa_factor; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mfa_factor (
    id uuid NOT NULL,
    account_id uuid NOT NULL,
    factor_type character varying(64) NOT NULL,
    encrypted_secret bytea,
    public_material bytea,
    secret_reference character varying(255),
    key_reference character varying(255),
    factor_metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    lifecycle_state character varying(16) DEFAULT 'PENDING'::character varying NOT NULL,
    enrolled_at timestamp with time zone,
    last_used_at timestamp with time zone,
    revoked_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT ck_mfa_factor_enrollment CHECK ((((lifecycle_state)::text <> 'ACTIVE'::text) OR (enrolled_at IS NOT NULL))),
    CONSTRAINT ck_mfa_factor_material CHECK (((encrypted_secret IS NOT NULL) OR (public_material IS NOT NULL) OR (secret_reference IS NOT NULL))),
    CONSTRAINT ck_mfa_factor_revocation CHECK ((((lifecycle_state)::text <> 'REVOKED'::text) OR (revoked_at IS NOT NULL))),
    CONSTRAINT ck_mfa_factor_state CHECK (((lifecycle_state)::text = ANY ((ARRAY['PENDING'::character varying, 'ACTIVE'::character varying, 'REVOKED'::character varying])::text[])))
);


--
-- Name: school_branch; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.school_branch (
    id uuid NOT NULL,
    code character varying(100) NOT NULL,
    name character varying(200) NOT NULL,
    lifecycle_state character varying(16) DEFAULT 'ACTIVE'::character varying NOT NULL,
    lifecycle_version bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    status_changed_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT ck_school_branch_id CHECK ((id <> '00000000-0000-0000-0000-000000000000'::uuid)),
    CONSTRAINT ck_school_branch_lifecycle_version CHECK ((lifecycle_version >= 0)),
    CONSTRAINT ck_school_branch_state CHECK (((lifecycle_state)::text = ANY ((ARRAY['ACTIVE'::character varying, 'INACTIVE'::character varying])::text[])))
);


--
-- Name: security_audit_event; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.security_audit_event (
    event_sequence bigint NOT NULL,
    id uuid NOT NULL,
    chain_key character varying(64) NOT NULL,
    previous_event_hash bytea,
    event_hash bytea NOT NULL,
    actor_principal_type character varying(16) NOT NULL,
    actor_principal_id uuid,
    action character varying(150) NOT NULL,
    target_type character varying(100) NOT NULL,
    target_id uuid,
    reason text,
    before_state jsonb,
    after_state jsonb,
    event_metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    occurred_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT ck_security_audit_event_actor CHECK (((((actor_principal_type)::text = 'SYSTEM'::text) AND (actor_principal_id IS NULL)) OR (((actor_principal_type)::text = ANY ((ARRAY['USER'::character varying, 'SERVICE'::character varying])::text[])) AND (actor_principal_id IS NOT NULL))))
);


--
-- Name: security_audit_event_event_sequence_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.security_audit_event ALTER COLUMN event_sequence ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.security_audit_event_event_sequence_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: service_identity; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_identity (
    id uuid NOT NULL,
    code character varying(100) NOT NULL,
    display_name character varying(200) NOT NULL,
    scope character varying(16) NOT NULL,
    branch_id uuid,
    scope_branch_key uuid DEFAULT '00000000-0000-0000-0000-000000000000'::uuid NOT NULL,
    lifecycle_state character varying(16) DEFAULT 'ACTIVE'::character varying NOT NULL,
    authorization_version bigint DEFAULT 0 NOT NULL,
    policy_revision bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    inactivated_at timestamp with time zone,
    CONSTRAINT ck_service_identity_branch_key CHECK (((((scope)::text = 'BRANCH'::text) AND (branch_id IS NOT NULL) AND (scope_branch_key = branch_id)) OR (((scope)::text = 'SCHOOL'::text) AND (branch_id IS NULL) AND (scope_branch_key = '00000000-0000-0000-0000-000000000000'::uuid)))),
    CONSTRAINT ck_service_identity_inactivation CHECK (((((lifecycle_state)::text = 'ACTIVE'::text) AND (inactivated_at IS NULL)) OR (((lifecycle_state)::text = 'INACTIVE'::text) AND (inactivated_at IS NOT NULL)))),
    CONSTRAINT ck_service_identity_scope CHECK (((scope)::text = ANY ((ARRAY['SCHOOL'::character varying, 'BRANCH'::character varying])::text[]))),
    CONSTRAINT ck_service_identity_state CHECK (((lifecycle_state)::text = ANY ((ARRAY['ACTIVE'::character varying, 'INACTIVE'::character varying])::text[]))),
    CONSTRAINT ck_service_identity_versions CHECK (((authorization_version >= 0) AND (policy_revision >= 0)))
);


--
-- Name: service_identity_credential; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_identity_credential (
    id uuid NOT NULL,
    service_identity_id uuid NOT NULL,
    secret_hash text NOT NULL,
    hash_algorithm character varying(64) NOT NULL,
    credential_revision bigint DEFAULT 0 NOT NULL,
    lifecycle_state character varying(16) DEFAULT 'ACTIVE'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_used_at timestamp with time zone,
    revoked_at timestamp with time zone,
    CONSTRAINT ck_service_identity_credential_revision CHECK ((credential_revision >= 0)),
    CONSTRAINT ck_service_identity_credential_revocation CHECK (((((lifecycle_state)::text = 'ACTIVE'::text) AND (revoked_at IS NULL)) OR (((lifecycle_state)::text = 'REVOKED'::text) AND (revoked_at IS NOT NULL)))),
    CONSTRAINT ck_service_identity_credential_state CHECK (((lifecycle_state)::text = ANY ((ARRAY['ACTIVE'::character varying, 'REVOKED'::character varying])::text[])))
);


--
-- Name: service_identity_permission; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_identity_permission (
    service_identity_id uuid NOT NULL,
    permission_id uuid NOT NULL,
    scope character varying(16) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: staff_branch_assignment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.staff_branch_assignment (
    id uuid NOT NULL,
    account_id uuid NOT NULL,
    account_type character varying(16) DEFAULT 'STAFF'::character varying NOT NULL,
    branch_id uuid NOT NULL,
    lifecycle_state character varying(16) DEFAULT 'ACTIVE'::character varying NOT NULL,
    assigned_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ended_at timestamp with time zone,
    end_reason text,
    assigned_by_account_id uuid,
    CONSTRAINT ck_staff_branch_assignment_account_type CHECK (((account_type)::text = 'STAFF'::text)),
    CONSTRAINT ck_staff_branch_assignment_end CHECK (((((lifecycle_state)::text = 'ACTIVE'::text) AND (ended_at IS NULL)) OR (((lifecycle_state)::text = 'ENDED'::text) AND (ended_at IS NOT NULL)))),
    CONSTRAINT ck_staff_branch_assignment_state CHECK (((lifecycle_state)::text = ANY ((ARRAY['ACTIVE'::character varying, 'ENDED'::character varying])::text[])))
);


--
-- Name: staff_invitation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.staff_invitation (
    id uuid NOT NULL,
    account_id uuid NOT NULL,
    account_type character varying(16) DEFAULT 'STAFF'::character varying NOT NULL,
    contact_id uuid NOT NULL,
    approved_identity jsonb DEFAULT '{}'::jsonb NOT NULL,
    token_hash bytea NOT NULL,
    lifecycle_state character varying(16) DEFAULT 'PENDING'::character varying NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    redeemed_at timestamp with time zone,
    invalidated_at timestamp with time zone,
    issued_by_account_id uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT ck_staff_invitation_account_type CHECK (((account_type)::text = 'STAFF'::text)),
    CONSTRAINT ck_staff_invitation_expiry CHECK ((expires_at > created_at)),
    CONSTRAINT ck_staff_invitation_state CHECK (((lifecycle_state)::text = ANY ((ARRAY['PENDING'::character varying, 'REDEEMED'::character varying, 'INVALIDATED'::character varying, 'EXPIRED'::character varying])::text[])))
);


--
-- Name: student_account_link; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.student_account_link (
    id uuid NOT NULL,
    student_id uuid NOT NULL,
    account_id uuid NOT NULL,
    account_type character varying(16) DEFAULT 'STUDENT'::character varying NOT NULL,
    lifecycle_state character varying(16) DEFAULT 'ACTIVE'::character varying NOT NULL,
    linked_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ended_at timestamp with time zone,
    end_reason text,
    linked_by_account_id uuid,
    CONSTRAINT ck_student_account_link_account_type CHECK (((account_type)::text = 'STUDENT'::text)),
    CONSTRAINT ck_student_account_link_end CHECK (((((lifecycle_state)::text = 'ACTIVE'::text) AND (ended_at IS NULL)) OR (((lifecycle_state)::text = 'ENDED'::text) AND (ended_at IS NOT NULL)))),
    CONSTRAINT ck_student_account_link_state CHECK (((lifecycle_state)::text = ANY ((ARRAY['ACTIVE'::character varying, 'ENDED'::character varying])::text[])))
);


--
-- Name: student_contact; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.student_contact (
    id uuid NOT NULL,
    student_id uuid NOT NULL,
    contact_type character varying(16) NOT NULL,
    normalized_value character varying(320) NOT NULL,
    lifecycle_state character varying(16) DEFAULT 'ACTIVE'::character varying NOT NULL,
    verification_state character varying(16) DEFAULT 'UNVERIFIED'::character varying NOT NULL,
    is_portal_contact boolean DEFAULT false NOT NULL,
    verified_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    retired_at timestamp with time zone,
    CONSTRAINT ck_student_contact_portal CHECK (((NOT is_portal_contact) OR (((lifecycle_state)::text = 'ACTIVE'::text) AND ((verification_state)::text = 'VERIFIED'::text)))),
    CONSTRAINT ck_student_contact_retirement CHECK (((((lifecycle_state)::text = 'ACTIVE'::text) AND (retired_at IS NULL)) OR (((lifecycle_state)::text = 'RETIRED'::text) AND (retired_at IS NOT NULL)))),
    CONSTRAINT ck_student_contact_state CHECK (((lifecycle_state)::text = ANY ((ARRAY['ACTIVE'::character varying, 'RETIRED'::character varying])::text[]))),
    CONSTRAINT ck_student_contact_type CHECK (((contact_type)::text = ANY ((ARRAY['EMAIL'::character varying, 'MOBILE'::character varying])::text[]))),
    CONSTRAINT ck_student_contact_verification CHECK (((verification_state)::text = ANY ((ARRAY['UNVERIFIED'::character varying, 'VERIFIED'::character varying])::text[]))),
    CONSTRAINT ck_student_contact_verified_at CHECK (((((verification_state)::text = 'UNVERIFIED'::text) AND (verified_at IS NULL)) OR (((verification_state)::text = 'VERIFIED'::text) AND (verified_at IS NOT NULL))))
);


--
-- Name: student_portal_invitation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.student_portal_invitation (
    id uuid NOT NULL,
    student_id uuid NOT NULL,
    contact_id uuid NOT NULL,
    invitation_purpose character varying(16) DEFAULT 'INITIAL'::character varying NOT NULL,
    token_hash bytea NOT NULL,
    lifecycle_state character varying(16) DEFAULT 'PENDING'::character varying NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    redeemed_at timestamp with time zone,
    invalidated_at timestamp with time zone,
    issued_by_account_id uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT ck_student_portal_invitation_expiry CHECK ((expires_at > created_at)),
    CONSTRAINT ck_student_portal_invitation_purpose CHECK (((invitation_purpose)::text = ANY ((ARRAY['INITIAL'::character varying, 'REASSIGNMENT'::character varying])::text[]))),
    CONSTRAINT ck_student_portal_invitation_state CHECK (((lifecycle_state)::text = ANY ((ARRAY['PENDING'::character varying, 'REDEEMED'::character varying, 'INVALIDATED'::character varying, 'EXPIRED'::character varying])::text[])))
);


--
-- Name: student_profile; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.student_profile (
    id uuid NOT NULL,
    owner_branch_id uuid NOT NULL,
    profile_status character varying(32) DEFAULT 'REQUESTED'::character varying NOT NULL,
    lifecycle_version bigint DEFAULT 0 NOT NULL,
    status_reason text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    status_changed_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT ck_student_profile_status CHECK (((profile_status)::text = ANY ((ARRAY['REQUESTED'::character varying, 'REGISTERED'::character varying, 'VERIFIED'::character varying, 'ACTIVE'::character varying, 'GRADUATED'::character varying, 'INACTIVE'::character varying, 'SUSPENDED'::character varying, 'TRANSFERRED_OUT'::character varying])::text[]))),
    CONSTRAINT ck_student_profile_version CHECK ((lifecycle_version >= 0))
);


--
-- Name: user_account; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_account (
    id uuid NOT NULL,
    account_type character varying(16) NOT NULL,
    lifecycle_state character varying(32) DEFAULT 'PENDING_ACTIVATION'::character varying NOT NULL,
    identity_verified_at timestamp with time zone,
    authorization_version bigint DEFAULT 0 NOT NULL,
    credential_version bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    status_changed_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT ck_user_account_state CHECK (((lifecycle_state)::text = ANY ((ARRAY['PENDING_ACTIVATION'::character varying, 'ACTIVE'::character varying, 'INACTIVE'::character varying])::text[]))),
    CONSTRAINT ck_user_account_type CHECK (((account_type)::text = ANY ((ARRAY['STAFF'::character varying, 'STUDENT'::character varying])::text[]))),
    CONSTRAINT ck_user_account_versions CHECK (((authorization_version >= 0) AND (credential_version >= 0)))
);


--
-- Name: account_contact account_contact_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_contact
    ADD CONSTRAINT account_contact_pkey PRIMARY KEY (id);


--
-- Name: account_recovery_challenge account_recovery_challenge_challenge_hash_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_recovery_challenge
    ADD CONSTRAINT account_recovery_challenge_challenge_hash_key UNIQUE (challenge_hash);


--
-- Name: account_recovery_challenge account_recovery_challenge_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_recovery_challenge
    ADD CONSTRAINT account_recovery_challenge_pkey PRIMARY KEY (id);


--
-- Name: audit_chain_state audit_chain_state_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_chain_state
    ADD CONSTRAINT audit_chain_state_pkey PRIMARY KEY (chain_key);


--
-- Name: auth_challenge auth_challenge_challenge_hash_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_challenge
    ADD CONSTRAINT auth_challenge_challenge_hash_key UNIQUE (challenge_hash);


--
-- Name: auth_challenge auth_challenge_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_challenge
    ADD CONSTRAINT auth_challenge_pkey PRIMARY KEY (id);


--
-- Name: auth_credential auth_credential_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_credential
    ADD CONSTRAINT auth_credential_pkey PRIMARY KEY (id);


--
-- Name: auth_session auth_session_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_session
    ADD CONSTRAINT auth_session_pkey PRIMARY KEY (id);


--
-- Name: auth_session auth_session_session_token_hash_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_session
    ADD CONSTRAINT auth_session_session_token_hash_key UNIQUE (session_token_hash);


--
-- Name: authentication_event authentication_event_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authentication_event
    ADD CONSTRAINT authentication_event_pkey PRIMARY KEY (id);


--
-- Name: authorization_permission authorization_permission_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authorization_permission
    ADD CONSTRAINT authorization_permission_code_key UNIQUE (code);


--
-- Name: authorization_permission authorization_permission_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authorization_permission
    ADD CONSTRAINT authorization_permission_pkey PRIMARY KEY (id);


--
-- Name: authorization_permission_scope authorization_permission_scope_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authorization_permission_scope
    ADD CONSTRAINT authorization_permission_scope_pkey PRIMARY KEY (permission_id, scope);


--
-- Name: authorization_role_assignment authorization_role_assignment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authorization_role_assignment
    ADD CONSTRAINT authorization_role_assignment_pkey PRIMARY KEY (id);


--
-- Name: authorization_role authorization_role_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authorization_role
    ADD CONSTRAINT authorization_role_code_key UNIQUE (code);


--
-- Name: authorization_role_delegated_permission authorization_role_delegated_permission_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authorization_role_delegated_permission
    ADD CONSTRAINT authorization_role_delegated_permission_pkey PRIMARY KEY (role_id, permission_id);


--
-- Name: authorization_role_permission authorization_role_permission_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authorization_role_permission
    ADD CONSTRAINT authorization_role_permission_pkey PRIMARY KEY (role_id, permission_id);


--
-- Name: authorization_role authorization_role_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authorization_role
    ADD CONSTRAINT authorization_role_pkey PRIMARY KEY (id);


--
-- Name: databasechangeloglock databasechangeloglock_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.databasechangeloglock
    ADD CONSTRAINT databasechangeloglock_pkey PRIMARY KEY (id);


--
-- Name: mfa_factor mfa_factor_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mfa_factor
    ADD CONSTRAINT mfa_factor_pkey PRIMARY KEY (id);


--
-- Name: school_branch school_branch_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_branch
    ADD CONSTRAINT school_branch_code_key UNIQUE (code);


--
-- Name: school_branch school_branch_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_branch
    ADD CONSTRAINT school_branch_pkey PRIMARY KEY (id);


--
-- Name: security_audit_event security_audit_event_event_hash_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.security_audit_event
    ADD CONSTRAINT security_audit_event_event_hash_key UNIQUE (event_hash);


--
-- Name: security_audit_event security_audit_event_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.security_audit_event
    ADD CONSTRAINT security_audit_event_id_key UNIQUE (id);


--
-- Name: security_audit_event security_audit_event_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.security_audit_event
    ADD CONSTRAINT security_audit_event_pkey PRIMARY KEY (event_sequence);


--
-- Name: service_identity service_identity_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_identity
    ADD CONSTRAINT service_identity_code_key UNIQUE (code);


--
-- Name: service_identity_credential service_identity_credential_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_identity_credential
    ADD CONSTRAINT service_identity_credential_pkey PRIMARY KEY (id);


--
-- Name: service_identity_permission service_identity_permission_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_identity_permission
    ADD CONSTRAINT service_identity_permission_pkey PRIMARY KEY (service_identity_id, permission_id);


--
-- Name: service_identity service_identity_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_identity
    ADD CONSTRAINT service_identity_pkey PRIMARY KEY (id);


--
-- Name: staff_branch_assignment staff_branch_assignment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_branch_assignment
    ADD CONSTRAINT staff_branch_assignment_pkey PRIMARY KEY (id);


--
-- Name: staff_invitation staff_invitation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_invitation
    ADD CONSTRAINT staff_invitation_pkey PRIMARY KEY (id);


--
-- Name: staff_invitation staff_invitation_token_hash_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_invitation
    ADD CONSTRAINT staff_invitation_token_hash_key UNIQUE (token_hash);


--
-- Name: student_account_link student_account_link_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_account_link
    ADD CONSTRAINT student_account_link_pkey PRIMARY KEY (id);


--
-- Name: student_contact student_contact_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_contact
    ADD CONSTRAINT student_contact_pkey PRIMARY KEY (id);


--
-- Name: student_portal_invitation student_portal_invitation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_portal_invitation
    ADD CONSTRAINT student_portal_invitation_pkey PRIMARY KEY (id);


--
-- Name: student_portal_invitation student_portal_invitation_token_hash_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_portal_invitation
    ADD CONSTRAINT student_portal_invitation_token_hash_key UNIQUE (token_hash);


--
-- Name: student_profile student_profile_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_profile
    ADD CONSTRAINT student_profile_pkey PRIMARY KEY (id);


--
-- Name: account_contact uq_account_contact_id_account; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_contact
    ADD CONSTRAINT uq_account_contact_id_account UNIQUE (id, account_id);


--
-- Name: authorization_permission uq_authorization_permission_id_category; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authorization_permission
    ADD CONSTRAINT uq_authorization_permission_id_category UNIQUE (id, permission_category);


--
-- Name: authorization_role uq_authorization_role_assignment_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authorization_role
    ADD CONSTRAINT uq_authorization_role_assignment_key UNIQUE (id, account_type, scope, scope_branch_key);


--
-- Name: authorization_role uq_authorization_role_id_scope; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authorization_role
    ADD CONSTRAINT uq_authorization_role_id_scope UNIQUE (id, scope);


--
-- Name: mfa_factor uq_mfa_factor_id_account; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mfa_factor
    ADD CONSTRAINT uq_mfa_factor_id_account UNIQUE (id, account_id);


--
-- Name: authorization_permission_scope uq_permission_scope_delegation; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authorization_permission_scope
    ADD CONSTRAINT uq_permission_scope_delegation UNIQUE (permission_id, scope, is_delegable);


--
-- Name: authorization_role_permission uq_role_permission_scope; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authorization_role_permission
    ADD CONSTRAINT uq_role_permission_scope UNIQUE (role_id, permission_id, role_scope);


--
-- Name: service_identity uq_service_identity_id_scope; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_identity
    ADD CONSTRAINT uq_service_identity_id_scope UNIQUE (id, scope);


--
-- Name: staff_branch_assignment uq_staff_branch_assignment_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_branch_assignment
    ADD CONSTRAINT uq_staff_branch_assignment_key UNIQUE (id, account_id, branch_id);


--
-- Name: student_contact uq_student_contact_id_student; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_contact
    ADD CONSTRAINT uq_student_contact_id_student UNIQUE (id, student_id);


--
-- Name: user_account uq_user_account_id_type; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_account
    ADD CONSTRAINT uq_user_account_id_type UNIQUE (id, account_type);


--
-- Name: user_account user_account_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_account
    ADD CONSTRAINT user_account_pkey PRIMARY KEY (id);


--
-- Name: ix_account_contact_login_lookup; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_account_contact_login_lookup ON public.account_contact USING btree (contact_type, normalized_value) WHERE (((lifecycle_state)::text = 'ACTIVE'::text) AND is_login_identifier);


--
-- Name: ix_account_recovery_pending_account; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_account_recovery_pending_account ON public.account_recovery_challenge USING btree (account_id, expires_at) WHERE ((lifecycle_state)::text = 'PENDING'::text);


--
-- Name: ix_auth_challenge_pending_account; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_auth_challenge_pending_account ON public.auth_challenge USING btree (account_id, expires_at) WHERE ((lifecycle_state)::text = 'PENDING'::text);


--
-- Name: ix_auth_session_active_account; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_auth_session_active_account ON public.auth_session USING btree (account_id, last_seen_at) WHERE ((lifecycle_state)::text = 'ACTIVE'::text);


--
-- Name: ix_authentication_event_account_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_authentication_event_account_time ON public.authentication_event USING btree (account_id, occurred_at DESC);


--
-- Name: ix_role_assignment_active_account; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_role_assignment_active_account ON public.authorization_role_assignment USING btree (account_id, scope, scope_branch_key) WHERE ((lifecycle_state)::text = 'ACTIVE'::text);


--
-- Name: ix_security_audit_event_actor_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_security_audit_event_actor_time ON public.security_audit_event USING btree (actor_principal_type, actor_principal_id, occurred_at DESC);


--
-- Name: ix_security_audit_event_target_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_security_audit_event_target_time ON public.security_audit_event USING btree (target_type, target_id, occurred_at DESC);


--
-- Name: ix_student_contact_active_student; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_student_contact_active_student ON public.student_contact USING btree (student_id) WHERE ((lifecycle_state)::text = 'ACTIVE'::text);


--
-- Name: ix_student_profile_owner_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_student_profile_owner_branch ON public.student_profile USING btree (owner_branch_id);


--
-- Name: ux_account_contact_active_value; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_account_contact_active_value ON public.account_contact USING btree (contact_type, normalized_value) WHERE ((lifecycle_state)::text = 'ACTIVE'::text);


--
-- Name: ux_auth_credential_active_password; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_auth_credential_active_password ON public.auth_credential USING btree (account_id) WHERE (((lifecycle_state)::text = 'ACTIVE'::text) AND ((credential_type)::text = 'PASSWORD'::text));


--
-- Name: ux_authorization_role_branch_super_admin; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_authorization_role_branch_super_admin ON public.authorization_role USING btree (branch_id) WHERE ((system_role_type)::text = 'BRANCH_SUPER_ADMIN'::text);


--
-- Name: ux_authorization_role_school_super_admin; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_authorization_role_school_super_admin ON public.authorization_role USING btree (system_role_type) WHERE ((system_role_type)::text = 'SCHOOL_SUPER_ADMIN'::text);


--
-- Name: ux_authorization_role_student_default; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_authorization_role_student_default ON public.authorization_role USING btree (system_role_type) WHERE ((system_role_type)::text = 'STUDENT_DEFAULT'::text);


--
-- Name: ux_role_assignment_active_grant; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_role_assignment_active_grant ON public.authorization_role_assignment USING btree (account_id, role_id, scope, scope_branch_key) WHERE ((lifecycle_state)::text = 'ACTIVE'::text);


--
-- Name: ux_service_identity_credential_active; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_service_identity_credential_active ON public.service_identity_credential USING btree (service_identity_id) WHERE ((lifecycle_state)::text = 'ACTIVE'::text);


--
-- Name: ux_staff_branch_assignment_active; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_staff_branch_assignment_active ON public.staff_branch_assignment USING btree (account_id, branch_id) WHERE ((lifecycle_state)::text = 'ACTIVE'::text);


--
-- Name: ux_staff_invitation_pending_account; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_staff_invitation_pending_account ON public.staff_invitation USING btree (account_id) WHERE ((lifecycle_state)::text = 'PENDING'::text);


--
-- Name: ux_student_account_link_active_account; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_student_account_link_active_account ON public.student_account_link USING btree (account_id) WHERE ((lifecycle_state)::text = 'ACTIVE'::text);


--
-- Name: ux_student_account_link_active_student; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_student_account_link_active_student ON public.student_account_link USING btree (student_id) WHERE ((lifecycle_state)::text = 'ACTIVE'::text);


--
-- Name: ux_student_portal_invitation_pending_student; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_student_portal_invitation_pending_student ON public.student_portal_invitation USING btree (student_id) WHERE ((lifecycle_state)::text = 'PENDING'::text);


--
-- Name: authentication_event tr_authentication_event_append_only; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tr_authentication_event_append_only BEFORE DELETE OR UPDATE ON public.authentication_event FOR EACH ROW EXECUTE FUNCTION public.administration_reject_append_only_mutation();


--
-- Name: authorization_permission tr_authorization_permission_append_only; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tr_authorization_permission_append_only BEFORE DELETE OR UPDATE ON public.authorization_permission FOR EACH ROW EXECUTE FUNCTION public.administration_reject_append_only_mutation();


--
-- Name: authorization_permission_scope tr_authorization_permission_scope_append_only; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tr_authorization_permission_scope_append_only BEFORE DELETE OR UPDATE ON public.authorization_permission_scope FOR EACH ROW EXECUTE FUNCTION public.administration_reject_append_only_mutation();


--
-- Name: authorization_role tr_authorization_role_immutable_binding; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tr_authorization_role_immutable_binding BEFORE UPDATE ON public.authorization_role FOR EACH ROW EXECUTE FUNCTION public.administration_enforce_role_immutability();


--
-- Name: authorization_role_assignment tr_role_assignment_immutable_binding; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tr_role_assignment_immutable_binding BEFORE UPDATE ON public.authorization_role_assignment FOR EACH ROW EXECUTE FUNCTION public.administration_enforce_role_assignment_immutability();


--
-- Name: security_audit_event tr_security_audit_event_append_only; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tr_security_audit_event_append_only BEFORE DELETE OR UPDATE ON public.security_audit_event FOR EACH ROW EXECUTE FUNCTION public.administration_reject_append_only_mutation();


--
-- Name: staff_branch_assignment tr_staff_branch_assignment_immutable_binding; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tr_staff_branch_assignment_immutable_binding BEFORE UPDATE ON public.staff_branch_assignment FOR EACH ROW EXECUTE FUNCTION public.administration_enforce_staff_branch_assignment_immutability();


--
-- Name: student_account_link tr_student_account_link_immutable_binding; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tr_student_account_link_immutable_binding BEFORE UPDATE ON public.student_account_link FOR EACH ROW EXECUTE FUNCTION public.administration_enforce_student_account_link_immutability();


--
-- Name: user_account tr_user_account_immutable_type; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tr_user_account_immutable_type BEFORE UPDATE ON public.user_account FOR EACH ROW EXECUTE FUNCTION public.administration_enforce_account_immutability();


--
-- Name: account_contact fk_account_contact_account; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_contact
    ADD CONSTRAINT fk_account_contact_account FOREIGN KEY (account_id) REFERENCES public.user_account(id);


--
-- Name: account_recovery_challenge fk_account_recovery_account; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_recovery_challenge
    ADD CONSTRAINT fk_account_recovery_account FOREIGN KEY (account_id) REFERENCES public.user_account(id);


--
-- Name: auth_challenge fk_auth_challenge_account; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_challenge
    ADD CONSTRAINT fk_auth_challenge_account FOREIGN KEY (account_id) REFERENCES public.user_account(id);


--
-- Name: auth_challenge fk_auth_challenge_factor; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_challenge
    ADD CONSTRAINT fk_auth_challenge_factor FOREIGN KEY (mfa_factor_id, account_id) REFERENCES public.mfa_factor(id, account_id);


--
-- Name: auth_credential fk_auth_credential_account; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_credential
    ADD CONSTRAINT fk_auth_credential_account FOREIGN KEY (account_id) REFERENCES public.user_account(id);


--
-- Name: auth_session fk_auth_session_account; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_session
    ADD CONSTRAINT fk_auth_session_account FOREIGN KEY (account_id) REFERENCES public.user_account(id);


--
-- Name: authentication_event fk_authentication_event_account; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authentication_event
    ADD CONSTRAINT fk_authentication_event_account FOREIGN KEY (account_id) REFERENCES public.user_account(id);


--
-- Name: authentication_event fk_authentication_event_session; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authentication_event
    ADD CONSTRAINT fk_authentication_event_session FOREIGN KEY (session_id) REFERENCES public.auth_session(id);


--
-- Name: authorization_role fk_authorization_role_branch; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authorization_role
    ADD CONSTRAINT fk_authorization_role_branch FOREIGN KEY (branch_id) REFERENCES public.school_branch(id);


--
-- Name: mfa_factor fk_mfa_factor_account; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mfa_factor
    ADD CONSTRAINT fk_mfa_factor_account FOREIGN KEY (account_id) REFERENCES public.user_account(id);


--
-- Name: authorization_permission_scope fk_permission_scope_category; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authorization_permission_scope
    ADD CONSTRAINT fk_permission_scope_category FOREIGN KEY (permission_id, permission_category) REFERENCES public.authorization_permission(id, permission_category);


--
-- Name: authorization_permission_scope fk_permission_scope_permission; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authorization_permission_scope
    ADD CONSTRAINT fk_permission_scope_permission FOREIGN KEY (permission_id) REFERENCES public.authorization_permission(id);


--
-- Name: authorization_role_assignment fk_role_assignment_account; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authorization_role_assignment
    ADD CONSTRAINT fk_role_assignment_account FOREIGN KEY (account_id, account_type) REFERENCES public.user_account(id, account_type);


--
-- Name: authorization_role_assignment fk_role_assignment_actor; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authorization_role_assignment
    ADD CONSTRAINT fk_role_assignment_actor FOREIGN KEY (assigned_by_account_id) REFERENCES public.user_account(id);


--
-- Name: authorization_role_assignment fk_role_assignment_role; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authorization_role_assignment
    ADD CONSTRAINT fk_role_assignment_role FOREIGN KEY (role_id, account_type, scope, scope_branch_key) REFERENCES public.authorization_role(id, account_type, scope, scope_branch_key);


--
-- Name: authorization_role_assignment fk_role_assignment_staff_branch; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authorization_role_assignment
    ADD CONSTRAINT fk_role_assignment_staff_branch FOREIGN KEY (staff_branch_assignment_id, account_id, branch_id) REFERENCES public.staff_branch_assignment(id, account_id, branch_id);


--
-- Name: authorization_role_delegated_permission fk_role_delegated_permission_delegable; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authorization_role_delegated_permission
    ADD CONSTRAINT fk_role_delegated_permission_delegable FOREIGN KEY (permission_id, role_scope, permission_is_delegable) REFERENCES public.authorization_permission_scope(permission_id, scope, is_delegable);


--
-- Name: authorization_role_delegated_permission fk_role_delegated_permission_role_permission; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authorization_role_delegated_permission
    ADD CONSTRAINT fk_role_delegated_permission_role_permission FOREIGN KEY (role_id, permission_id, role_scope) REFERENCES public.authorization_role_permission(role_id, permission_id, role_scope);


--
-- Name: authorization_role_permission fk_role_permission_permission_scope; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authorization_role_permission
    ADD CONSTRAINT fk_role_permission_permission_scope FOREIGN KEY (permission_id, role_scope) REFERENCES public.authorization_permission_scope(permission_id, scope);


--
-- Name: authorization_role_permission fk_role_permission_role; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authorization_role_permission
    ADD CONSTRAINT fk_role_permission_role FOREIGN KEY (role_id, role_scope) REFERENCES public.authorization_role(id, scope);


--
-- Name: security_audit_event fk_security_audit_event_chain; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.security_audit_event
    ADD CONSTRAINT fk_security_audit_event_chain FOREIGN KEY (chain_key) REFERENCES public.audit_chain_state(chain_key);


--
-- Name: service_identity fk_service_identity_branch; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_identity
    ADD CONSTRAINT fk_service_identity_branch FOREIGN KEY (branch_id) REFERENCES public.school_branch(id);


--
-- Name: service_identity_credential fk_service_identity_credential_identity; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_identity_credential
    ADD CONSTRAINT fk_service_identity_credential_identity FOREIGN KEY (service_identity_id) REFERENCES public.service_identity(id);


--
-- Name: service_identity_permission fk_service_identity_permission_identity; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_identity_permission
    ADD CONSTRAINT fk_service_identity_permission_identity FOREIGN KEY (service_identity_id, scope) REFERENCES public.service_identity(id, scope);


--
-- Name: service_identity_permission fk_service_identity_permission_scope; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_identity_permission
    ADD CONSTRAINT fk_service_identity_permission_scope FOREIGN KEY (permission_id, scope) REFERENCES public.authorization_permission_scope(permission_id, scope);


--
-- Name: staff_branch_assignment fk_staff_branch_assignment_account; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_branch_assignment
    ADD CONSTRAINT fk_staff_branch_assignment_account FOREIGN KEY (account_id, account_type) REFERENCES public.user_account(id, account_type);


--
-- Name: staff_branch_assignment fk_staff_branch_assignment_actor; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_branch_assignment
    ADD CONSTRAINT fk_staff_branch_assignment_actor FOREIGN KEY (assigned_by_account_id) REFERENCES public.user_account(id);


--
-- Name: staff_branch_assignment fk_staff_branch_assignment_branch; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_branch_assignment
    ADD CONSTRAINT fk_staff_branch_assignment_branch FOREIGN KEY (branch_id) REFERENCES public.school_branch(id);


--
-- Name: staff_invitation fk_staff_invitation_account; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_invitation
    ADD CONSTRAINT fk_staff_invitation_account FOREIGN KEY (account_id, account_type) REFERENCES public.user_account(id, account_type);


--
-- Name: staff_invitation fk_staff_invitation_contact; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_invitation
    ADD CONSTRAINT fk_staff_invitation_contact FOREIGN KEY (contact_id, account_id) REFERENCES public.account_contact(id, account_id);


--
-- Name: staff_invitation fk_staff_invitation_issuer; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_invitation
    ADD CONSTRAINT fk_staff_invitation_issuer FOREIGN KEY (issued_by_account_id) REFERENCES public.user_account(id);


--
-- Name: student_account_link fk_student_account_link_account; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_account_link
    ADD CONSTRAINT fk_student_account_link_account FOREIGN KEY (account_id, account_type) REFERENCES public.user_account(id, account_type);


--
-- Name: student_account_link fk_student_account_link_actor; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_account_link
    ADD CONSTRAINT fk_student_account_link_actor FOREIGN KEY (linked_by_account_id) REFERENCES public.user_account(id);


--
-- Name: student_account_link fk_student_account_link_student; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_account_link
    ADD CONSTRAINT fk_student_account_link_student FOREIGN KEY (student_id) REFERENCES public.student_profile(id);


--
-- Name: student_contact fk_student_contact_student; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_contact
    ADD CONSTRAINT fk_student_contact_student FOREIGN KEY (student_id) REFERENCES public.student_profile(id);


--
-- Name: student_portal_invitation fk_student_portal_invitation_actor; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_portal_invitation
    ADD CONSTRAINT fk_student_portal_invitation_actor FOREIGN KEY (issued_by_account_id) REFERENCES public.user_account(id);


--
-- Name: student_portal_invitation fk_student_portal_invitation_contact; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_portal_invitation
    ADD CONSTRAINT fk_student_portal_invitation_contact FOREIGN KEY (contact_id, student_id) REFERENCES public.student_contact(id, student_id);


--
-- Name: student_portal_invitation fk_student_portal_invitation_student; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_portal_invitation
    ADD CONSTRAINT fk_student_portal_invitation_student FOREIGN KEY (student_id) REFERENCES public.student_profile(id);


--
-- Name: student_profile fk_student_profile_branch; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_profile
    ADD CONSTRAINT fk_student_profile_branch FOREIGN KEY (owner_branch_id) REFERENCES public.school_branch(id);


--
-- PostgreSQL database dump complete
--

\unrestrict hKSacTL0HKCvdmmkRUUEgydzkJu6pa0HNJVoPrTrPQzPxpLJpX3I8Y0p9loZzKY

