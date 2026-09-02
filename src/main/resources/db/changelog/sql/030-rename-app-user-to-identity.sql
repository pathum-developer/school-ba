-- Rename m_app_user to m_identity, and t_user_role_assignment to
-- t_identity_role_assignment, together with every constraint, index, trigger,
-- function and column that carried the old name.
--
-- The table holds credentials, account state, and a link to a person. It holds no
-- person data at all: the actual users of this system are m_staff, m_learner and
-- m_platform_operator, each of which exists whether or not anyone can sign in as
-- them. Calling the login row a "user" invites exactly the confusion the person and
-- login split was built to remove.
--
-- Renamed completely rather than partially. A table called m_identity whose foreign
-- keys all say user_id would be more confusing than leaving the old name alone, so
-- the user_id columns on the assignment and refresh token tables move to identity_id
-- and the objects named after them follow.
--
-- Done now because there is no Java yet. The user package is still empty, so there is
-- no entity, repository or UserDetailsService to update. Once those exist the same
-- rename also touches DTOs, mappers, tests and authorization wiring.
--
-- Written as loops over the catalogue rather than one statement per object. That is
-- shorter than the fifty-odd explicit renames, and it is inherently re-runnable:
-- after the first run nothing matches the old names, so every loop is empty.

-- Tables.
DO $$
BEGIN
    IF to_regclass('public.m_app_user') IS NOT NULL AND to_regclass('public.m_identity') IS NOT NULL THEN
        RAISE EXCEPTION 'cannot rename public.m_app_user to public.m_identity because both tables exist';
    ELSIF to_regclass('public.m_app_user') IS NOT NULL THEN
        ALTER TABLE public.m_app_user RENAME TO m_identity;
    END IF;

    IF to_regclass('public.t_user_role_assignment') IS NOT NULL AND to_regclass('public.t_identity_role_assignment') IS NOT NULL THEN
        RAISE EXCEPTION 'cannot rename public.t_user_role_assignment to public.t_identity_role_assignment because both tables exist';
    ELSIF to_regclass('public.t_user_role_assignment') IS NOT NULL THEN
        ALTER TABLE public.t_user_role_assignment RENAME TO t_identity_role_assignment;
    END IF;
END
$$;

-- Columns. The grant and the refresh token both point at a login, not at a person.
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_schema = 'public' AND table_name = 't_identity_role_assignment' AND column_name = 'user_id') THEN
        ALTER TABLE public.t_identity_role_assignment RENAME COLUMN user_id TO identity_id;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_schema = 'public' AND table_name = 't_refresh_token' AND column_name = 'user_id') THEN
        ALTER TABLE public.t_refresh_token RENAME COLUMN user_id TO identity_id;
    END IF;
END
$$;

-- Constraints. Constraint-backed indexes are renamed with their constraint, so only
-- the standalone indexes need handling separately below.
DO $$
DECLARE
    target record;
BEGIN
    -- ck_app_user_*, fk_app_user_*, uk_app_user_*, pk_app_user
    FOR target IN
        SELECT class.relname AS table_name, con.conname AS old_name,
               replace(con.conname, 'app_user', 'identity') AS new_name
        FROM pg_constraint con
        JOIN pg_class class ON class.oid = con.conrelid
        JOIN pg_namespace space ON space.oid = class.relnamespace
        WHERE space.nspname = 'public' AND con.conname LIKE '%app\_user%'
    LOOP
        EXECUTE format('ALTER TABLE public.%I RENAME CONSTRAINT %I TO %I',
                       target.table_name, target.old_name, target.new_name);
    END LOOP;

    -- ck_user_role_assignment_*, fk_user_role_assignment_*, pk, uk
    FOR target IN
        SELECT class.relname AS table_name, con.conname AS old_name,
               replace(con.conname, 'user_role_assignment', 'identity_role_assignment') AS new_name
        FROM pg_constraint con
        JOIN pg_class class ON class.oid = con.conrelid
        JOIN pg_namespace space ON space.oid = class.relnamespace
        WHERE space.nspname = 'public' AND con.conname LIKE '%user\_role\_assignment%'
    LOOP
        EXECUTE format('ALTER TABLE public.%I RENAME CONSTRAINT %I TO %I',
                       target.table_name, target.old_name, target.new_name);
    END LOOP;

    -- Anything still named after the old column: the foreign keys onto the login.
    FOR target IN
        SELECT class.relname AS table_name, con.conname AS old_name,
               left(con.conname, length(con.conname) - 5) || '_identity' AS new_name
        FROM pg_constraint con
        JOIN pg_class class ON class.oid = con.conrelid
        JOIN pg_namespace space ON space.oid = class.relnamespace
        WHERE space.nspname = 'public'
          AND con.conname IN ('fk_identity_role_assignment_user', 'fk_refresh_token_user')
    LOOP
        EXECUTE format('ALTER TABLE public.%I RENAME CONSTRAINT %I TO %I',
                       target.table_name, target.old_name, target.new_name);
    END LOOP;
END
$$;

-- Standalone indexes.
DO $$
DECLARE
    target record;
BEGIN
    FOR target IN
        SELECT indexname AS old_name,
               replace(replace(replace(indexname,
                   'user_role_assignment_user', 'identity_role_assignment_identity'),
                   'user_role_assignment', 'identity_role_assignment'),
                   'app_user', 'identity') AS new_name
        FROM pg_indexes
        WHERE schemaname = 'public'
          AND (indexname LIKE '%app\_user%' OR indexname LIKE '%user\_role\_assignment%')
    LOOP
        EXECUTE format('ALTER INDEX public.%I RENAME TO %I', target.old_name, target.new_name);
    END LOOP;

    IF to_regclass('public.ix_refresh_token_user_active') IS NOT NULL THEN
        ALTER INDEX public.ix_refresh_token_user_active RENAME TO ix_refresh_token_identity_active;
    END IF;
END
$$;

-- Triggers on the renamed assignment table. Dropped rather than renamed, because the
-- two functions they call are being replaced with differently named ones and a
-- trigger cannot be repointed in place.
DROP TRIGGER IF EXISTS tr_user_role_assignment_insert_bump_version ON public.t_identity_role_assignment;
DROP TRIGGER IF EXISTS tr_user_role_assignment_update_bump_version ON public.t_identity_role_assignment;
DROP TRIGGER IF EXISTS tr_user_role_assignment_delete_bump_version ON public.t_identity_role_assignment;

DROP FUNCTION IF EXISTS public.auth_bump_version_by_user();
DROP FUNCTION IF EXISTS public.auth_bump_version_by_user_change();

-- Grants changed: bump exactly the identities named in the changed rows.
CREATE OR REPLACE FUNCTION public.auth_bump_version_by_identity()
    RETURNS trigger
    LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE public.m_identity
    SET authorization_version = authorization_version + 1
    WHERE id IN (SELECT identity_id FROM changed_row);
    RETURN NULL;
END
$function$;

-- An update can move a grant between accounts, so both sides are bumped.
CREATE OR REPLACE FUNCTION public.auth_bump_version_by_identity_change()
    RETURNS trigger
    LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE public.m_identity
    SET authorization_version = authorization_version + 1
    WHERE id IN (SELECT identity_id FROM old_row
                 UNION
                 SELECT identity_id FROM new_row);
    RETURN NULL;
END
$function$;

-- The remaining five keep their names; only their bodies need the new table names.
CREATE OR REPLACE FUNCTION public.auth_bump_version_by_role()
    RETURNS trigger
    LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE public.m_identity
    SET authorization_version = authorization_version + 1
    WHERE id IN (SELECT assignment.identity_id
                 FROM public.t_identity_role_assignment assignment
                 WHERE assignment.role_id IN (SELECT role_id FROM changed_row));
    RETURN NULL;
END
$function$;

CREATE OR REPLACE FUNCTION public.auth_bump_version_by_role_change()
    RETURNS trigger
    LANGUAGE plpgsql
AS $function$
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
$function$;

CREATE OR REPLACE FUNCTION public.auth_disable_login_for_inactive_learner()
    RETURNS trigger
    LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE public.m_identity
    SET status = 'DISABLED',
        authorization_version = authorization_version + 1
    WHERE learner_id IN (SELECT id FROM new_row WHERE status NOT IN ('ENROLLED', 'ACTIVE'))
      AND status <> 'DISABLED';
    RETURN NULL;
END
$function$;

CREATE OR REPLACE FUNCTION public.auth_disable_login_for_inactive_staff()
    RETURNS trigger
    LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE public.m_identity
    SET status = 'DISABLED',
        authorization_version = authorization_version + 1
    WHERE staff_id IN (SELECT id FROM new_row WHERE employment_status NOT IN ('ACTIVE', 'ON_LEAVE'))
      AND status <> 'DISABLED';
    RETURN NULL;
END
$function$;

CREATE OR REPLACE FUNCTION public.auth_disable_login_for_inactive_operator()
    RETURNS trigger
    LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE public.m_identity
    SET status = 'DISABLED',
        authorization_version = authorization_version + 1
    WHERE platform_operator_id IN (SELECT id FROM new_row WHERE employment_status NOT IN ('ACTIVE', 'ON_LEAVE'))
      AND status <> 'DISABLED';
    RETURN NULL;
END
$function$;

CREATE OR REPLACE TRIGGER tr_identity_role_assignment_insert_bump_version
    AFTER INSERT ON public.t_identity_role_assignment
    REFERENCING NEW TABLE AS changed_row
    FOR EACH STATEMENT
    EXECUTE FUNCTION public.auth_bump_version_by_identity();

CREATE OR REPLACE TRIGGER tr_identity_role_assignment_update_bump_version
    AFTER UPDATE ON public.t_identity_role_assignment
    REFERENCING OLD TABLE AS old_row NEW TABLE AS new_row
    FOR EACH STATEMENT
    EXECUTE FUNCTION public.auth_bump_version_by_identity_change();

CREATE OR REPLACE TRIGGER tr_identity_role_assignment_delete_bump_version
    AFTER DELETE ON public.t_identity_role_assignment
    REFERENCING OLD TABLE AS changed_row
    FOR EACH STATEMENT
    EXECUTE FUNCTION public.auth_bump_version_by_identity();
