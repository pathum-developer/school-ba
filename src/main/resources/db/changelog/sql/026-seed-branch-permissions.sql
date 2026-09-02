-- Seeds the first entries in the permission catalogue: the actions needed to run
-- branches. r_permission is reference data, written by migration and never at
-- runtime, so this is the only place these codes are created.
--
-- max_scope_type is the deepest scope a role may hold the permission at, not a
-- privilege level. A permission capped at SCHOOL may sit in a platform or school
-- role but never in a branch-owned one; a permission capped at BRANCH may sit in
-- any of the three.
--
-- Note what is deliberately absent. There is no 'view branch staff' or 'view branch
-- details' permission, because 'branch' there is not part of the action: it is the
-- scope the role is granted at. staff:read held at branch scope reads the staff of
-- that branch, and the same code held at school scope reads all of them. Encoding
-- the scope into the permission name would need a second code for every level and
-- force every authorization check to know which one to ask for.

INSERT INTO public.r_permission (id, code, resource, action, max_scope_type, description) VALUES
    -- SCHOOL: a branch cannot create itself, so this has no meaning at branch scope.
    ('40000000-0000-0000-0000-000000000001', 'branch:create', 'branch', 'create', 'SCHOOL',
     'Create a branch or yard within the school'),

    -- SCHOOL: opening and closing a branch is the school''s decision, not the
    -- branch''s own. Capped here so a branch-owned role can never carry it.
    ('40000000-0000-0000-0000-000000000002', 'branch:manage-status', 'branch', 'manage-status', 'SCHOOL',
     'Activate or deactivate a branch, and set which branch is the head office'),

    -- BRANCH: which licence classes a branch teaches, and the price it charges for
    -- each. Reaches branch scope so a branch may manage its own offering.
    ('40000000-0000-0000-0000-000000000003', 'branch-license-class:manage', 'branch-license-class', 'manage', 'BRANCH',
     'Set which licence classes a branch offers and the price of each'),

    -- BRANCH: reads the staff of whichever branches the role is scoped to.
    ('40000000-0000-0000-0000-000000000004', 'staff:read', 'staff', 'read', 'BRANCH',
     'View staff records and their branch assignments'),

    -- BRANCH: reads whichever branches the role is scoped to.
    ('40000000-0000-0000-0000-000000000005', 'branch:read', 'branch', 'read', 'BRANCH',
     'View branch details, including contact numbers and licence class offerings')
ON CONFLICT (code) DO UPDATE
SET resource = EXCLUDED.resource,
    action = EXCLUDED.action,
    max_scope_type = EXCLUDED.max_scope_type,
    description = EXCLUDED.description,
    updated_at = now(),
    updated_by = 'system';
