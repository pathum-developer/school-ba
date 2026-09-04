-- Creates the branch super admin role and gives it every permission a branch-scoped
-- role is allowed to hold.
--
-- One role per branch, not one shared role, for the same reason school-super-admin has
-- one per school: m_role is owned, and ck_role_scope_shape requires a BRANCH row to
-- name both its school and its branch. A branch created later needs its own copy,
-- provisioned when the branch is created.
--
-- Selected from m_branch rather than listing the three branches, so this seeds whatever
-- branches exist and stays correct if one is renamed. The role code repeats across
-- branches without collision because uk_role_code_per_owner is (code, school_id,
-- branch_id): every branch may have its own 'branch-super-admin', just as every branch
-- may have its own 'instructor'.
--
-- assignable_to is STAFF, and not by choice. ck_role_learner_not_branch forbids a
-- branch-scoped role from being assignable to learners at all, which is what keeps a
-- learner login out of every branch-owned role.
--
-- The permission set is filtered to max_scope_type = 'BRANCH', which is the whole of
-- what ck_role_permission_scope_depth permits here: a BRANCH role ranks 2, so it may
-- only hold permissions whose ceiling also ranks 2. Anything capped at SCHOOL or
-- PLATFORM is refused by the database, so this filter states the rule the constraint
-- would enforce anyway.
--
-- What that excludes today, and why it is right rather than an oversight:
--   branch:create        -- a branch cannot create branches; there is nothing to scope
--                           such a grant to.
--   branch:manage-status -- deactivating a branch, or moving the head office, is the
--                           school's decision. A branch super admin who could close
--                           their own branch, or promote it to head office, would be
--                           acting outside the branch they administer.
-- So "branch super admin" means super within one branch's day-to-day operation, not
-- power over the branch's existence.
--
-- Consequence worth knowing, the same one 028 carries: because the set is selected,
-- a permission added later at BRANCH ceiling is granted to every branch super admin on
-- the next run rather than being an explicit decision. That is arguably the definition
-- of the role -- a BRANCH ceiling means precisely "safe to delegate to a branch" -- but
-- replace the SELECT with a literal list if each addition should be deliberate.
--
-- This grants the role to nobody. Creating a role and assigning it are separate steps,
-- and an assignment additionally requires the staff member to currently work at that
-- branch.

INSERT INTO public.m_role (scope_type, school_id, branch_id, assignable_to, code, name, description, is_system, is_assignable)
SELECT 'BRANCH', branch.school_id, branch.id, 'STAFF', 'branch-super-admin', 'Branch Super Admin',
       'Full administrative access within one branch', true, true
FROM public.m_branch branch
ON CONFLICT ON CONSTRAINT uk_role_code_per_owner DO UPDATE
SET name = EXCLUDED.name,
    description = EXCLUDED.description,
    is_system = EXCLUDED.is_system,
    is_assignable = EXCLUDED.is_assignable,
    updated_at = now(),
    updated_by = 'system';

INSERT INTO public.x_role_permission (role_id, role_scope_type, permission_id, permission_max_scope_type)
SELECT role.id, role.scope_type, permission.id, permission.max_scope_type
FROM public.m_role role
CROSS JOIN public.r_permission permission
WHERE role.code = 'branch-super-admin'
  AND role.scope_type = 'BRANCH'
  AND permission.max_scope_type = 'BRANCH'
ON CONFLICT (role_id, permission_id) DO NOTHING;
