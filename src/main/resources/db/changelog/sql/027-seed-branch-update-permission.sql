-- Adds branch:update to the permission catalogue.
--
-- A separate changeset rather than an edit to 026, which has already been applied.
--
-- Ceiling BRANCH, so a branch-owned role may carry it and a branch can maintain its
-- own descriptive details: name, address, type and contact numbers. That is only safe
-- because the dangerous state change is not part of it. Activating or deactivating a
-- branch, and moving the head office, live in branch:manage-status, which is capped at
-- SCHOOL. Had the two been one permission, the whole thing would have had to sit at
-- school scope and every routine address correction would have needed a school admin.
--
-- The branch code is immutable and is not covered here. It is a stable public
-- identifier that appears in URLs, so it is set once at creation and never edited.

INSERT INTO public.r_permission (id, code, resource, action, max_scope_type, description) VALUES
    ('40000000-0000-0000-0000-000000000006', 'branch:update', 'branch', 'update', 'BRANCH',
     'Update branch details such as name, address, type and contact numbers')
ON CONFLICT (code) DO UPDATE
SET resource = EXCLUDED.resource,
    action = EXCLUDED.action,
    max_scope_type = EXCLUDED.max_scope_type,
    description = EXCLUDED.description,
    updated_at = now(),
    updated_by = 'system';
