-- Adds branch-license-class:read to the permission catalogue, and grants it to the
-- school super admin role.
--
-- A separate changeset rather than an edit to 026 and 028, which have already been
-- applied.
--
-- Why this is not already covered by branch:read. Reading a branch and reading its
-- price list are different decisions. The offering carries what the branch charges
-- for each licence class, which is commercially sensitive in a way that an address
-- and a telephone number are not, so a role that may look up a branch is not
-- automatically a role that may see its pricing. Splitting the read is what makes
-- granting one without the other possible.
--
-- branch:read had claimed the licence class offering in its description, which would
-- now describe the same access twice. Its description is corrected below so the two
-- codes do not overlap. Only the wording changes; no access moves, because
-- descriptions are documentation and never consulted by an authorization check.
--
-- Ceiling BRANCH, matching branch-license-class:manage. A branch that may set its own
-- offering must be able to read it, and a branch-owned role would be unable to hold a
-- read capped any shallower than the write it accompanies.
--
-- This covers the offering, not the catalogue. r_license_class is the Department of
-- Motor Traffic's list of classes: platform-wide reference data, identical for every
-- school, and not gated by a permission.

INSERT INTO public.r_permission (id, code, resource, action, max_scope_type, description) VALUES
    ('40000000-0000-0000-0000-000000000007', 'branch-license-class:read', 'branch-license-class', 'read', 'BRANCH',
     'View the licence classes a branch offers and the price of each')
ON CONFLICT (code) DO UPDATE
SET resource = EXCLUDED.resource,
    action = EXCLUDED.action,
    max_scope_type = EXCLUDED.max_scope_type,
    description = EXCLUDED.description,
    updated_at = now(),
    updated_by = 'system';

-- Narrow branch:read now that the offering has a code of its own. Guarded on the
-- current text so a re-run touches nothing.
UPDATE public.r_permission
SET description = 'View branch details, including address and contact numbers',
    updated_at = now(),
    updated_by = 'system'
WHERE code = 'branch:read'
  AND description <> 'View branch details, including address and contact numbers';

-- Grant it to every school super admin. 028 selected the whole permission set by
-- ceiling, but it has already run and will not run again, so the new code has to be
-- granted here. Named explicitly rather than re-running that select, so this changeset
-- grants what it says it grants and nothing else the catalogue may have gained since.
INSERT INTO public.x_role_permission (role_id, role_scope_type, permission_id, permission_max_scope_type)
SELECT role.id, role.scope_type, permission.id, permission.max_scope_type
FROM public.m_role role
CROSS JOIN public.r_permission permission
WHERE role.code = 'school-super-admin'
  AND role.scope_type = 'SCHOOL'
  AND permission.code = 'branch-license-class:read'
ON CONFLICT (role_id, permission_id) DO NOTHING;
