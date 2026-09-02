-- Creates the school super admin role and gives it every permission a school-scoped
-- role is allowed to hold.
--
-- One role per school, not one shared role. m_role is school-owned, so a SCHOOL
-- scoped row must name its school. That is the same reason there are no unowned
-- template roles: a role with a null owner would break the composite foreign key
-- chain that ties a grant to the role it names. A school created later therefore
-- needs its own copy, provisioned when the school is created.
--
-- is_system marks it as provisioned by migration and not user-editable, so a school
-- administrator cannot weaken or delete the role that grants their own access.
--
-- The permission set is selected rather than listed, filtered by the ceiling: a
-- SCHOOL role may hold permissions capped at SCHOOL or BRANCH, never at PLATFORM.
-- Writing the filter instead of six literal codes means the ceiling rule cannot be
-- got wrong here, and the database would refuse the row anyway if it were.
--
-- Consequence worth knowing: because the set is selected, re-running this against a
-- catalogue that has grown will grant the new permissions too. That is bounded, since
-- the ceiling keeps a school role away from anything platform-level, but it does mean
-- a permission added later is granted to every school super admin rather than being
-- an explicit decision. Replace the SELECT with a literal list if that is not wanted.

INSERT INTO public.m_role (scope_type, school_id, branch_id, assignable_to, code, name, description, is_system, is_assignable)
SELECT 'SCHOOL', school.id, NULL, 'STAFF', 'school-super-admin', 'School Super Admin',
       'Full administrative access within one school', true, true
FROM public.m_school school
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
WHERE role.code = 'school-super-admin'
  AND role.scope_type = 'SCHOOL'
  AND permission.max_scope_type IN ('SCHOOL', 'BRANCH')
ON CONFLICT (role_id, permission_id) DO NOTHING;
