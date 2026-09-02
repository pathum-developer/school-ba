-- Harden older branch-owned tables for multi-tenant school management.
--
-- These tables were already tenant-derived through branch_id, but storing the
-- owning school directly gives every branch-owned child row a tenant column that
-- can be indexed, audited, and protected with composite foreign keys.

ALTER TABLE public.branch_contact_number
    ADD COLUMN IF NOT EXISTS school_id uuid;

ALTER TABLE public.branch_license_class
    ADD COLUMN IF NOT EXISTS school_id uuid;

CREATE OR REPLACE FUNCTION public.tenant_set_school_id_from_branch()
    RETURNS trigger
    LANGUAGE plpgsql
AS $$
DECLARE
    branch_school_id uuid;
BEGIN
    SELECT branch.school_id
    INTO branch_school_id
    FROM public.branch branch
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
        RAISE EXCEPTION 'branch.school_id is immutable for tenant-owned branches';
    END IF;

    RETURN NEW;
END
$$;

DROP TRIGGER IF EXISTS tr_branch_school_id_immutable ON public.branch;

CREATE TRIGGER tr_branch_school_id_immutable
    BEFORE UPDATE OF school_id ON public.branch
    FOR EACH ROW
    EXECUTE FUNCTION public.tenant_prevent_branch_school_change();

DROP TRIGGER IF EXISTS tr_branch_contact_number_set_school_id ON public.branch_contact_number;

CREATE TRIGGER tr_branch_contact_number_set_school_id
    BEFORE INSERT OR UPDATE OF branch_id, school_id ON public.branch_contact_number
    FOR EACH ROW
    EXECUTE FUNCTION public.tenant_set_school_id_from_branch();

DROP TRIGGER IF EXISTS tr_branch_license_class_set_school_id ON public.branch_license_class;

CREATE TRIGGER tr_branch_license_class_set_school_id
    BEFORE INSERT OR UPDATE OF branch_id, school_id ON public.branch_license_class
    FOR EACH ROW
    EXECUTE FUNCTION public.tenant_set_school_id_from_branch();

UPDATE public.branch_contact_number contact
SET school_id = branch.school_id
FROM public.branch branch
WHERE branch.id = contact.branch_id
  AND contact.school_id IS DISTINCT FROM branch.school_id;

UPDATE public.branch_license_class offering
SET school_id = branch.school_id
FROM public.branch branch
WHERE branch.id = offering.branch_id
  AND offering.school_id IS DISTINCT FROM branch.school_id;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM public.branch_contact_number contact
        LEFT JOIN public.branch branch ON branch.id = contact.branch_id
        WHERE branch.id IS NULL
           OR contact.school_id IS NULL
           OR contact.school_id <> branch.school_id
    ) THEN
        RAISE EXCEPTION 'branch_contact_number contains rows whose school_id does not match branch.school_id';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM public.branch_license_class offering
        LEFT JOIN public.branch branch ON branch.id = offering.branch_id
        WHERE branch.id IS NULL
           OR offering.school_id IS NULL
           OR offering.school_id <> branch.school_id
    ) THEN
        RAISE EXCEPTION 'branch_license_class contains rows whose school_id does not match branch.school_id';
    END IF;
END
$$;

ALTER TABLE public.branch_contact_number
    ALTER COLUMN school_id SET NOT NULL;

ALTER TABLE public.branch_license_class
    ALTER COLUMN school_id SET NOT NULL;

ALTER TABLE public.branch_contact_number
    DROP CONSTRAINT IF EXISTS fk_branch_contact_number_branch;

ALTER TABLE public.branch_contact_number
    ADD CONSTRAINT fk_branch_contact_number_branch
    FOREIGN KEY (branch_id, school_id)
    REFERENCES public.branch (id, school_id)
    ON DELETE CASCADE;

ALTER TABLE public.branch_license_class
    DROP CONSTRAINT IF EXISTS fk_branch_license_class_branch;

ALTER TABLE public.branch_license_class
    ADD CONSTRAINT fk_branch_license_class_branch
    FOREIGN KEY (branch_id, school_id)
    REFERENCES public.branch (id, school_id)
    ON DELETE CASCADE;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'uk_school_contact_number_school_phone_e164'
    ) THEN
        ALTER TABLE public.school_contact_number
            ADD CONSTRAINT uk_school_contact_number_school_phone_e164
            UNIQUE (school_id, phone_number_e164);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'uk_branch_contact_number_school_branch_phone_e164'
    ) THEN
        ALTER TABLE public.branch_contact_number
            ADD CONSTRAINT uk_branch_contact_number_school_branch_phone_e164
            UNIQUE (school_id, branch_id, phone_number_e164);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'uk_branch_contact_number_school_branch_display_order'
    ) THEN
        ALTER TABLE public.branch_contact_number
            ADD CONSTRAINT uk_branch_contact_number_school_branch_display_order
            UNIQUE (school_id, branch_id, display_order);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'uk_branch_license_class_school_branch_license_class'
    ) THEN
        ALTER TABLE public.branch_license_class
            ADD CONSTRAINT uk_branch_license_class_school_branch_license_class
            UNIQUE (school_id, branch_id, license_class_id);
    END IF;
END
$$;

CREATE INDEX IF NOT EXISTS ix_branch_contact_number_school_branch
    ON public.branch_contact_number (school_id, branch_id);

CREATE INDEX IF NOT EXISTS ix_branch_license_class_school_branch
    ON public.branch_license_class (school_id, branch_id);
