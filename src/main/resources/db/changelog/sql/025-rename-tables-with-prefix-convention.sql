-- Rename physical tables to the project table-prefix convention.
--
-- Prefixes are intentionally limited to database table names. Domain classes,
-- DTOs, API resource names, and Java package names stay clean and unprefixed.

DO $$
BEGIN
    IF to_regclass('public.school') IS NOT NULL AND to_regclass('public.m_school') IS NOT NULL THEN
        RAISE EXCEPTION 'cannot rename public.school to public.m_school because both tables exist';
    ELSIF to_regclass('public.school') IS NOT NULL THEN
        ALTER TABLE public.school RENAME TO m_school;
    END IF;

    IF to_regclass('public.branch') IS NOT NULL AND to_regclass('public.m_branch') IS NOT NULL THEN
        RAISE EXCEPTION 'cannot rename public.branch to public.m_branch because both tables exist';
    ELSIF to_regclass('public.branch') IS NOT NULL THEN
        ALTER TABLE public.branch RENAME TO m_branch;
    END IF;

    IF to_regclass('public.learner') IS NOT NULL AND to_regclass('public.m_learner') IS NOT NULL THEN
        RAISE EXCEPTION 'cannot rename public.learner to public.m_learner because both tables exist';
    ELSIF to_regclass('public.learner') IS NOT NULL THEN
        ALTER TABLE public.learner RENAME TO m_learner;
    END IF;

    IF to_regclass('public.staff') IS NOT NULL AND to_regclass('public.m_staff') IS NOT NULL THEN
        RAISE EXCEPTION 'cannot rename public.staff to public.m_staff because both tables exist';
    ELSIF to_regclass('public.staff') IS NOT NULL THEN
        ALTER TABLE public.staff RENAME TO m_staff;
    END IF;

    IF to_regclass('public.platform_operator') IS NOT NULL AND to_regclass('public.m_platform_operator') IS NOT NULL THEN
        RAISE EXCEPTION 'cannot rename public.platform_operator to public.m_platform_operator because both tables exist';
    ELSIF to_regclass('public.platform_operator') IS NOT NULL THEN
        ALTER TABLE public.platform_operator RENAME TO m_platform_operator;
    END IF;

    IF to_regclass('public.app_user') IS NOT NULL AND to_regclass('public.m_app_user') IS NOT NULL THEN
        RAISE EXCEPTION 'cannot rename public.app_user to public.m_app_user because both tables exist';
    ELSIF to_regclass('public.app_user') IS NOT NULL THEN
        ALTER TABLE public.app_user RENAME TO m_app_user;
    END IF;

    IF to_regclass('public.role') IS NOT NULL AND to_regclass('public.m_role') IS NOT NULL THEN
        RAISE EXCEPTION 'cannot rename public.role to public.m_role because both tables exist';
    ELSIF to_regclass('public.role') IS NOT NULL THEN
        ALTER TABLE public.role RENAME TO m_role;
    END IF;

    IF to_regclass('public.school_contact_number') IS NOT NULL AND to_regclass('public.m_school_contact_number') IS NOT NULL THEN
        RAISE EXCEPTION 'cannot rename public.school_contact_number to public.m_school_contact_number because both tables exist';
    ELSIF to_regclass('public.school_contact_number') IS NOT NULL THEN
        ALTER TABLE public.school_contact_number RENAME TO m_school_contact_number;
    END IF;

    IF to_regclass('public.branch_contact_number') IS NOT NULL AND to_regclass('public.m_branch_contact_number') IS NOT NULL THEN
        RAISE EXCEPTION 'cannot rename public.branch_contact_number to public.m_branch_contact_number because both tables exist';
    ELSIF to_regclass('public.branch_contact_number') IS NOT NULL THEN
        ALTER TABLE public.branch_contact_number RENAME TO m_branch_contact_number;
    END IF;

    IF to_regclass('public.license_class') IS NOT NULL AND to_regclass('public.r_license_class') IS NOT NULL THEN
        RAISE EXCEPTION 'cannot rename public.license_class to public.r_license_class because both tables exist';
    ELSIF to_regclass('public.license_class') IS NOT NULL THEN
        ALTER TABLE public.license_class RENAME TO r_license_class;
    END IF;

    IF to_regclass('public.permission') IS NOT NULL AND to_regclass('public.r_permission') IS NOT NULL THEN
        RAISE EXCEPTION 'cannot rename public.permission to public.r_permission because both tables exist';
    ELSIF to_regclass('public.permission') IS NOT NULL THEN
        ALTER TABLE public.permission RENAME TO r_permission;
    END IF;

    IF to_regclass('public.branch_license_class') IS NOT NULL AND to_regclass('public.x_branch_license_class') IS NOT NULL THEN
        RAISE EXCEPTION 'cannot rename public.branch_license_class to public.x_branch_license_class because both tables exist';
    ELSIF to_regclass('public.branch_license_class') IS NOT NULL THEN
        ALTER TABLE public.branch_license_class RENAME TO x_branch_license_class;
    END IF;

    IF to_regclass('public.role_permission') IS NOT NULL AND to_regclass('public.x_role_permission') IS NOT NULL THEN
        RAISE EXCEPTION 'cannot rename public.role_permission to public.x_role_permission because both tables exist';
    ELSIF to_regclass('public.role_permission') IS NOT NULL THEN
        ALTER TABLE public.role_permission RENAME TO x_role_permission;
    END IF;

    IF to_regclass('public.staff_branch_membership') IS NOT NULL AND to_regclass('public.x_staff_branch_membership') IS NOT NULL THEN
        RAISE EXCEPTION 'cannot rename public.staff_branch_membership to public.x_staff_branch_membership because both tables exist';
    ELSIF to_regclass('public.staff_branch_membership') IS NOT NULL THEN
        ALTER TABLE public.staff_branch_membership RENAME TO x_staff_branch_membership;
    END IF;

    IF to_regclass('public.user_role_assignment') IS NOT NULL AND to_regclass('public.t_user_role_assignment') IS NOT NULL THEN
        RAISE EXCEPTION 'cannot rename public.user_role_assignment to public.t_user_role_assignment because both tables exist';
    ELSIF to_regclass('public.user_role_assignment') IS NOT NULL THEN
        ALTER TABLE public.user_role_assignment RENAME TO t_user_role_assignment;
    END IF;

    IF to_regclass('public.refresh_token') IS NOT NULL AND to_regclass('public.t_refresh_token') IS NOT NULL THEN
        RAISE EXCEPTION 'cannot rename public.refresh_token to public.t_refresh_token because both tables exist';
    ELSIF to_regclass('public.refresh_token') IS NOT NULL THEN
        ALTER TABLE public.refresh_token RENAME TO t_refresh_token;
    END IF;
END
$$;

CREATE OR REPLACE FUNCTION public.auth_bump_version_by_user()
    RETURNS trigger
    LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE public.m_app_user
    SET authorization_version = authorization_version + 1
    WHERE id IN (SELECT user_id FROM changed_row);
    RETURN NULL;
END
$$;

CREATE OR REPLACE FUNCTION public.auth_bump_version_by_user_change()
    RETURNS trigger
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

CREATE OR REPLACE FUNCTION public.auth_bump_version_by_role()
    RETURNS trigger
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

CREATE OR REPLACE FUNCTION public.auth_bump_version_by_role_change()
    RETURNS trigger
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

CREATE OR REPLACE FUNCTION public.auth_disable_login_for_inactive_learner()
    RETURNS trigger
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

CREATE OR REPLACE FUNCTION public.auth_disable_login_for_inactive_staff()
    RETURNS trigger
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

CREATE OR REPLACE FUNCTION public.auth_disable_login_for_inactive_operator()
    RETURNS trigger
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

CREATE OR REPLACE FUNCTION public.tenant_set_school_id_from_branch()
    RETURNS trigger
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

CREATE OR REPLACE FUNCTION public.tenant_prevent_branch_school_change()
    RETURNS trigger
    LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.school_id IS DISTINCT FROM OLD.school_id THEN
        RAISE EXCEPTION 'm_branch.school_id is immutable for tenant-owned branches';
    END IF;

    RETURN NEW;
END
$$;
