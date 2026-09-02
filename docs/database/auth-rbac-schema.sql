-- Authentication and role-based authorization schema.
--
-- Scope model: a role is owned by exactly one scope (PLATFORM, SCHOOL or BRANCH),
-- and a grant of that role carries the same scope. A branch-owned role can only be
-- granted to a user who currently holds a membership in that branch, and can only
-- contain permissions whose max_scope_type reaches BRANCH. Both rules are enforced
-- by the constraints below, not only by application code.
--
-- A login is a learner's when it points at a learner row, and staff's when it does
-- not. Roles declare an audience of STAFF or LEARNER, and a grant must match the
-- kind of account it lands on, so a learner account can never hold a staff role.
--
-- Several unique constraints below exist only as composite foreign key targets.
-- They look redundant next to the primary key, but removing them breaks the chain
-- that makes cross-branch and cross-tenant grants unstorable.
--
-- Those composite foreign keys rely on PostgreSQL's default MATCH SIMPLE rule: a
-- foreign key with any NULL column is not checked. That is deliberate here. It lets
-- one column pair carry a rule that applies only at branch scope, while school and
-- platform rows (branch_id NULL) pass through untouched.
--
-- Every table carries the standard created_at / created_by / updated_at / updated_by
-- audit block used by the rest of the schema.
--
-- Apply order:
--   1. src/main/resources/db-data/school-schema.sql   school, branch
--   2. docs/database/learner-schema.sql               learner
--   3. docs/database/staff-schema.sql                 staff
--   4. this file
--
-- Reference document. The runtime schema is applied by Liquibase under
-- src/main/resources/db/changelog; keep this file aligned when that changes.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Prerequisites. app_user and the grant tables reference school, branch, learner and
-- staff as school-matched pairs, so those composite targets must already exist.
-- Checked up front to fail with something actionable rather than a bare "relation
-- does not exist" from the middle of the file.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'learner' AND relkind = 'r') THEN
        RAISE EXCEPTION 'apply docs/database/learner-schema.sql first: app_user references learner';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'staff' AND relkind = 'r') THEN
        RAISE EXCEPTION 'apply docs/database/staff-schema.sql first: app_user references staff';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'uk_learner_id_school') THEN
        RAISE EXCEPTION 'learner must declare UNIQUE (id, school_id) as uk_learner_id_school';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'uk_staff_id_school') THEN
        RAISE EXCEPTION 'staff must declare UNIQUE (id, school_id) as uk_staff_id_school';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'uk_branch_id_school') THEN
        RAISE EXCEPTION 'branch must declare UNIQUE (id, school_id) as uk_branch_id_school';
    END IF;
END
$$;

-- Every identity that can sign in: platform operators, school staff, and learners.
-- Credentials live here; permissions never do.
--
-- learner_id is the discriminator. There is no separate user_type column on purpose:
-- a discriminator stored independently of the link can drift out of agreement with
-- it, so is_staff is GENERATED from learner_id and PostgreSQL refuses to write it.
CREATE TABLE IF NOT EXISTS app_user (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid,                                       -- NULL only for a platform operator
    staff_id uuid,                                        -- set only for a staff login
    learner_id uuid,                                      -- set only for a learner login
    -- "not a learner", which is what the role audience rule turns on. Platform
    -- operators have neither link and count as staff for that purpose, so this is
    -- deliberately not defined as staff_id IS NOT NULL.
    is_staff boolean GENERATED ALWAYS AS (learner_id IS NULL) STORED,
    username varchar(64) NOT NULL,                        -- the only login identifier, staff and learner alike
    email varchar(254),                                   -- optional; a learner commonly has none
    password_hash varchar(255),                           -- absent until the account is activated
    display_name varchar(160) NOT NULL,
    status varchar(32) DEFAULT 'PENDING_ACTIVATION' NOT NULL,
    authorization_version integer DEFAULT 0 NOT NULL,     -- bumped on any grant change; evicts cached permissions
    failed_attempt_count smallint DEFAULT 0 NOT NULL,     -- reset on successful login
    locked_until timestamp,                               -- NULL when the account is not locked out
    last_login_at timestamp,
    password_changed_at timestamp DEFAULT now() NOT NULL, -- drives password age policy
    created_at timestamp DEFAULT now() NOT NULL,
    created_by varchar(20) DEFAULT 'system' NOT NULL,
    updated_at timestamp DEFAULT now() NOT NULL,
    updated_by varchar(20) DEFAULT 'system' NOT NULL,
    CONSTRAINT pk_app_user PRIMARY KEY (id),
    CONSTRAINT fk_app_user_school FOREIGN KEY (school_id) REFERENCES school (id) ON DELETE RESTRICT,
    -- The linked person must belong to the same school as the login.
    CONSTRAINT fk_app_user_learner FOREIGN KEY (learner_id, school_id) REFERENCES learner (id, school_id) ON DELETE RESTRICT,
    CONSTRAINT fk_app_user_staff FOREIGN KEY (staff_id, school_id) REFERENCES staff (id, school_id) ON DELETE RESTRICT,
    -- Composite FK target. Lets staff_branch_membership prove that the user and the
    -- branch belong to the same school. Platform users (school_id NULL) fall out of
    -- that check under MATCH SIMPLE, which is why they can never join a branch.
    CONSTRAINT uk_app_user_id_school UNIQUE (id, school_id),
    -- Composite FK target, so user_role_assignment can require that the account is
    -- not a learner before it may hold a staff-audience role.
    CONSTRAINT uk_app_user_id_is_staff UNIQUE (id, is_staff),
    -- Composite FK target, so a branch grant can be traced from the login to the
    -- staff member and on to that person's branch membership.
    CONSTRAINT uk_app_user_id_staff UNIQUE (id, staff_id),
    -- One login per person. Nullable, and SQL treats NULLs as distinct, so any
    -- number of rows share NULL while a given person can be claimed only once.
    CONSTRAINT uk_app_user_learner UNIQUE (learner_id),
    CONSTRAINT uk_app_user_staff UNIQUE (staff_id),
    -- Global, because it is what makes a single login endpoint possible: the sign-in
    -- request carries a username and nothing else, so it must resolve on its own.
    -- A learner username embeds the school code and is therefore collision-free by
    -- construction; staff usernames are administrator-chosen and are not.
    CONSTRAINT uk_app_user_username UNIQUE (username),
    CONSTRAINT ck_app_user_status CHECK (status IN ('PENDING_ACTIVATION', 'ACTIVE', 'SUSPENDED', 'LOCKED', 'DISABLED')),
    CONSTRAINT ck_app_user_username_format CHECK (username ~ '^[a-z0-9]+(?:[._-][a-z0-9]+)*$'),
    CONSTRAINT ck_app_user_email_format CHECK (email IS NULL OR email ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$'),
    CONSTRAINT ck_app_user_password_hash_not_blank CHECK (password_hash IS NULL OR btrim(password_hash) <> ''),
    -- Access is issued with no password and activated later, but an account must
    -- never be able to reach ACTIVE without one.
    CONSTRAINT ck_app_user_active_needs_password CHECK (status <> 'ACTIVE' OR password_hash IS NOT NULL),
    -- A platform operator has no school, so it can be neither a learner nor staff.
    CONSTRAINT ck_app_user_learner_needs_school CHECK (learner_id IS NULL OR school_id IS NOT NULL),
    CONSTRAINT ck_app_user_staff_needs_school CHECK (staff_id IS NULL OR school_id IS NOT NULL),
    -- A login belongs to a staff member or to a learner, never to both.
    CONSTRAINT ck_app_user_single_person CHECK (staff_id IS NULL OR learner_id IS NULL),
    CONSTRAINT ck_app_user_display_name_not_blank CHECK (btrim(display_name) <> ''),
    CONSTRAINT ck_app_user_authorization_version_non_negative CHECK (authorization_version >= 0),
    CONSTRAINT ck_app_user_failed_attempt_count_non_negative CHECK (failed_attempt_count >= 0),
    CONSTRAINT ck_app_user_timestamps CHECK (updated_at >= created_at)
);

CREATE INDEX IF NOT EXISTS ix_app_user_school
    ON app_user (school_id);

-- Staff are a small minority of rows once learners have logins. This keeps staff
-- lookups off a table dominated by learners.
CREATE INDEX IF NOT EXISTS ix_app_user_staff_by_school
    ON app_user (school_id)
    WHERE learner_id IS NULL;

-- Resolving a learner login to its learner record happens on every request that
-- evaluates an '-own' permission.
CREATE INDEX IF NOT EXISTS ix_app_user_learner
    ON app_user (learner_id)
    WHERE learner_id IS NOT NULL;

-- Email is unique within a school, case-insensitively, and only where present.
-- A plain unique constraint would not do: it would either forbid the many learners
-- who have no email, or make an address globally unique and so block the same
-- person from enrolling at a second school. Platform operators have no school and
-- are grouped under the nil UUID so they remain unique among themselves.
CREATE UNIQUE INDEX IF NOT EXISTS ux_app_user_school_email
    ON app_user (COALESCE(school_id, '00000000-0000-0000-0000-000000000000'::uuid), lower(email))
    WHERE email IS NOT NULL;

-- Which branches a staff member works at: zero, one, or many.
--
-- Keyed by staff member rather than by login, because where someone works is an
-- employment fact that holds whether or not they have system access. An instructor
-- with no account still belongs to a branch.
--
-- Membership grants nothing on its own. It is the precondition for holding a
-- branch-owned role, and deleting a row here revokes those roles by cascade.
--
-- Learners are barred structurally and need no flag to say so: this table
-- references staff, and a learner has no staff record to reference.
CREATE TABLE IF NOT EXISTS staff_branch_membership (
    staff_id uuid NOT NULL,
    branch_id uuid NOT NULL,
    school_id uuid NOT NULL,                              -- must match both the staff member's and the branch's school
    is_primary boolean DEFAULT false NOT NULL,            -- the staff member's home branch
    assigned_at timestamp DEFAULT now() NOT NULL,
    created_at timestamp DEFAULT now() NOT NULL,
    created_by varchar(20) DEFAULT 'system' NOT NULL,
    updated_at timestamp DEFAULT now() NOT NULL,
    updated_by varchar(20) DEFAULT 'system' NOT NULL,
    -- Composite FK target for user_role_assignment: a branch grant must name a
    -- (staff_id, branch_id) pair that exists here.
    CONSTRAINT pk_staff_branch_membership PRIMARY KEY (staff_id, branch_id),
    -- These two meet on school_id, so the person and the branch must share a school.
    CONSTRAINT fk_staff_branch_membership_staff FOREIGN KEY (staff_id, school_id) REFERENCES staff (id, school_id) ON DELETE CASCADE,
    CONSTRAINT fk_staff_branch_membership_branch FOREIGN KEY (branch_id, school_id) REFERENCES branch (id, school_id) ON DELETE CASCADE,
    CONSTRAINT ck_staff_branch_membership_timestamps CHECK (updated_at >= created_at)
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_staff_branch_membership_primary_per_staff
    ON staff_branch_membership (staff_id)
    WHERE is_primary;

CREATE INDEX IF NOT EXISTS ix_staff_branch_membership_branch
    ON staff_branch_membership (branch_id);

-- The action catalogue. Reference data, seeded by migration and never written at
-- runtime. Application code checks these codes; it never checks role names.
CREATE TABLE IF NOT EXISTS permission (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code varchar(64) NOT NULL,                            -- 'learner:read'
    resource varchar(32) NOT NULL,                        -- 'learner'
    action varchar(32) NOT NULL,                          -- 'read'
    max_scope_type varchar(32) NOT NULL,                  -- deepest scope a role may hold this at
    description varchar(255) NOT NULL,
    created_at timestamp DEFAULT now() NOT NULL,
    created_by varchar(20) DEFAULT 'system' NOT NULL,
    updated_at timestamp DEFAULT now() NOT NULL,
    updated_by varchar(20) DEFAULT 'system' NOT NULL,
    CONSTRAINT pk_permission PRIMARY KEY (id),
    CONSTRAINT uk_permission_code UNIQUE (code),
    CONSTRAINT uk_permission_resource_action UNIQUE (resource, action),
    -- Composite FK target for role_permission's privilege ceiling.
    CONSTRAINT uk_permission_id_max_scope UNIQUE (id, max_scope_type),
    CONSTRAINT ck_permission_max_scope_type CHECK (max_scope_type IN ('PLATFORM', 'SCHOOL', 'BRANCH')),
    CONSTRAINT ck_permission_code_format CHECK (code ~ '^[a-z][a-z0-9-]*:[a-z][a-z0-9-]*$'),
    -- Keeps the denormalized code honest against resource and action.
    CONSTRAINT ck_permission_code_matches_parts CHECK (code = resource || ':' || action),
    CONSTRAINT ck_permission_description_not_blank CHECK (btrim(description) <> ''),
    CONSTRAINT ck_permission_timestamps CHECK (updated_at >= created_at)
);

-- A named bundle of permissions, owned by exactly one scope.
-- There are no unowned template roles: a BRANCH row with a NULL branch_id would
-- break the composite FK chain in user_role_assignment. Default roles for a new
-- branch are materialized as real owned rows at branch-creation time.
CREATE TABLE IF NOT EXISTS role (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    scope_type varchar(32) NOT NULL,                      -- PLATFORM | SCHOOL | BRANCH
    school_id uuid,                                       -- NULL only when PLATFORM
    branch_id uuid,                                       -- NOT NULL only when BRANCH
    assignable_to varchar(32) DEFAULT 'STAFF' NOT NULL,   -- STAFF | LEARNER
    code varchar(64) NOT NULL,                            -- unique per owner, not globally
    name varchar(160) NOT NULL,
    description varchar(255),
    is_system boolean DEFAULT false NOT NULL,             -- provisioned; not user-editable
    is_assignable boolean DEFAULT true NOT NULL,          -- retire a role without deleting it
    created_at timestamp DEFAULT now() NOT NULL,
    created_by varchar(20) DEFAULT 'system' NOT NULL,
    updated_at timestamp DEFAULT now() NOT NULL,
    updated_by varchar(20) DEFAULT 'system' NOT NULL,
    CONSTRAINT pk_role PRIMARY KEY (id),
    CONSTRAINT fk_role_school FOREIGN KEY (school_id) REFERENCES school (id) ON DELETE CASCADE,
    -- A branch role's branch must belong to the same school as the role.
    CONSTRAINT fk_role_branch FOREIGN KEY (branch_id, school_id) REFERENCES branch (id, school_id) ON DELETE CASCADE,
    -- Four composite FK targets. Each lets user_role_assignment pin one facet of
    -- this role's identity: its scope, its school, its branch, its audience.
    CONSTRAINT uk_role_id_scope_type UNIQUE (id, scope_type),
    CONSTRAINT uk_role_id_school UNIQUE (id, school_id),
    CONSTRAINT uk_role_id_branch UNIQUE (id, branch_id),
    CONSTRAINT uk_role_id_assignable_to UNIQUE (id, assignable_to),
    -- NULLS NOT DISTINCT is what lets every branch have its own 'instructor'
    -- while still blocking a duplicate within one branch.
    CONSTRAINT uk_role_code_per_owner UNIQUE NULLS NOT DISTINCT (code, school_id, branch_id),
    CONSTRAINT ck_role_scope_type CHECK (scope_type IN ('PLATFORM', 'SCHOOL', 'BRANCH')),
    CONSTRAINT ck_role_assignable_to CHECK (assignable_to IN ('STAFF', 'LEARNER')),
    -- Scope columns must match the declared scope_type. This is what guarantees a
    -- BRANCH role always has a branch for the assignment FKs to pin against.
    CONSTRAINT ck_role_scope_shape CHECK (
        (scope_type = 'PLATFORM' AND school_id IS NULL AND branch_id IS NULL)
        OR (scope_type = 'SCHOOL' AND school_id IS NOT NULL AND branch_id IS NULL)
        OR (scope_type = 'BRANCH' AND school_id IS NOT NULL AND branch_id IS NOT NULL)
    ),
    -- A learner role can never be branch-owned. Learners hold no branch membership,
    -- so such a role would be grantable to nobody; better to refuse to create it
    -- than to leave a role that silently cannot be used.
    CONSTRAINT ck_role_learner_not_branch CHECK (assignable_to = 'STAFF' OR scope_type <> 'BRANCH'),
    CONSTRAINT ck_role_code_format CHECK (code ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
    CONSTRAINT ck_role_name_not_blank CHECK (btrim(name) <> ''),
    CONSTRAINT ck_role_description_not_blank CHECK (description IS NULL OR btrim(description) <> ''),
    CONSTRAINT ck_role_timestamps CHECK (updated_at >= created_at)
);

CREATE INDEX IF NOT EXISTS ix_role_school
    ON role (school_id);

CREATE INDEX IF NOT EXISTS ix_role_branch
    ON role (branch_id);

-- Which permissions a role carries. Insert and delete only, never updated, so it
-- has no updated_at and maps as a join table rather than an auditable entity.
CREATE TABLE IF NOT EXISTS role_permission (
    role_id uuid NOT NULL,
    role_scope_type varchar(32) NOT NULL,                 -- copy of role.scope_type, pinned by the FK below
    permission_id uuid NOT NULL,
    permission_max_scope_type varchar(32) NOT NULL,       -- copy of permission.max_scope_type, likewise pinned
    created_at timestamp DEFAULT now() NOT NULL,
    created_by varchar(20) DEFAULT 'system' NOT NULL,
    CONSTRAINT pk_role_permission PRIMARY KEY (role_id, permission_id),
    -- These two FKs are what stop the denormalized scope columns above from lying.
    CONSTRAINT fk_role_permission_role FOREIGN KEY (role_id, role_scope_type) REFERENCES role (id, scope_type) ON DELETE CASCADE,
    CONSTRAINT fk_role_permission_permission FOREIGN KEY (permission_id, permission_max_scope_type) REFERENCES permission (id, max_scope_type) ON DELETE RESTRICT,
    -- The privilege ceiling. A branch-owned role cannot contain a permission that
    -- only reaches school or platform scope, whatever the service layer does.
    -- Ranks: PLATFORM = 0 (broadest), SCHOOL = 1, BRANCH = 2 (narrowest).
    CONSTRAINT ck_role_permission_scope_depth CHECK (
        CASE role_scope_type WHEN 'PLATFORM' THEN 0 WHEN 'SCHOOL' THEN 1 WHEN 'BRANCH' THEN 2 END
        <= CASE permission_max_scope_type WHEN 'PLATFORM' THEN 0 WHEN 'SCHOOL' THEN 1 WHEN 'BRANCH' THEN 2 END
    )
);

CREATE INDEX IF NOT EXISTS ix_role_permission_permission
    ON role_permission (permission_id);

-- The scoped grant: this user holds this role, here.
CREATE TABLE IF NOT EXISTS user_role_assignment (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    role_id uuid NOT NULL,
    scope_type varchar(32) NOT NULL,                      -- mirrors role.scope_type
    school_id uuid,                                       -- NULL only when PLATFORM
    branch_id uuid,                                       -- NOT NULL only when BRANCH
    assignable_to varchar(32) DEFAULT 'STAFF' NOT NULL,   -- mirrors role.assignable_to
    is_staff boolean DEFAULT true NOT NULL,               -- mirrors app_user.is_staff
    staff_id uuid,                                        -- mirrors app_user.staff_id; required for a branch grant
    granted_by uuid NOT NULL,                             -- real FK, not the varchar audit column
    granted_at timestamp DEFAULT now() NOT NULL,
    expires_at timestamp,                                 -- NULL means the grant does not expire
    created_at timestamp DEFAULT now() NOT NULL,
    created_by varchar(20) DEFAULT 'system' NOT NULL,
    updated_at timestamp DEFAULT now() NOT NULL,
    updated_by varchar(20) DEFAULT 'system' NOT NULL,
    CONSTRAINT pk_user_role_assignment PRIMARY KEY (id),
    CONSTRAINT fk_user_role_assignment_user FOREIGN KEY (user_id) REFERENCES app_user (id) ON DELETE CASCADE,
    -- RESTRICT, not CASCADE: who granted a role is authorization evidence and must
    -- outlive attempts to delete the granter.
    CONSTRAINT fk_user_role_assignment_granted_by FOREIGN KEY (granted_by) REFERENCES app_user (id) ON DELETE RESTRICT,
    --
    -- The four constraints below are split deliberately rather than combined into one
    -- wide composite FK. Under MATCH SIMPLE a single wide FK would be skipped whenever
    -- any column is NULL, so a school-scope row (branch_id NULL) would escape checking
    -- entirely. Split, each one covers a different case:
    --
    --   _role_scope   always enforced    grant scope equals the role's own scope
    --   _role_school  school_id not null grant school equals the role's school
    --   _role_branch  branch_id not null grant branch equals the role's branch
    --   _staff        staff_id not null  the staff_id below is the account's own
    --   _membership   staff_id not null  that staff member works at that branch
    --
    -- Chained: a branch role forces scope_type BRANCH, the shape checks then force
    -- branch_id and staff_id non-null, which force the branch to equal the role's
    -- branch and the staff member to be the account's own, which forces a membership
    -- row. Storing a branch role for someone who does not work there is not possible.
    CONSTRAINT fk_user_role_assignment_role_scope FOREIGN KEY (role_id, scope_type) REFERENCES role (id, scope_type) ON DELETE CASCADE,
    CONSTRAINT fk_user_role_assignment_role_school FOREIGN KEY (role_id, school_id) REFERENCES role (id, school_id) ON DELETE CASCADE,
    CONSTRAINT fk_user_role_assignment_role_branch FOREIGN KEY (role_id, branch_id) REFERENCES role (id, branch_id) ON DELETE CASCADE,
    -- Pins staff_id to the staff member the account actually belongs to.
    CONSTRAINT fk_user_role_assignment_staff FOREIGN KEY (user_id, staff_id) REFERENCES app_user (id, staff_id),
    -- CASCADE here is the lifecycle rule: removing someone from a branch revokes
    -- their roles at that branch, with no second cleanup step to forget.
    CONSTRAINT fk_user_role_assignment_membership FOREIGN KEY (staff_id, branch_id) REFERENCES staff_branch_membership (staff_id, branch_id) ON DELETE CASCADE,
    --
    -- Audience. These two pin the columns above to their sources: the audience to the
    -- role's own, and is_staff to what the account actually is. With both honest, the
    -- check that they agree is what makes a staff role on a learner, or a learner role
    -- on staff, unstorable.
    CONSTRAINT fk_user_role_assignment_audience FOREIGN KEY (role_id, assignable_to) REFERENCES role (id, assignable_to),
    CONSTRAINT fk_user_role_assignment_is_staff FOREIGN KEY (user_id, is_staff) REFERENCES app_user (id, is_staff),
    CONSTRAINT ck_user_role_assignment_audience CHECK ((assignable_to = 'STAFF') = is_staff),
    CONSTRAINT uk_user_role_assignment_grant UNIQUE NULLS NOT DISTINCT (user_id, role_id, branch_id),
    CONSTRAINT ck_user_role_assignment_scope_type CHECK (scope_type IN ('PLATFORM', 'SCHOOL', 'BRANCH')),
    CONSTRAINT ck_user_role_assignment_assignable_to CHECK (assignable_to IN ('STAFF', 'LEARNER')),
    -- These three shape checks are load-bearing, not cosmetic: they guarantee the
    -- branch_id and staff_id above are non-null for branch grants, so neither FK can
    -- be dodged by leaving a column NULL and slipping past MATCH SIMPLE.
    CONSTRAINT ck_user_role_assignment_school_shape CHECK ((scope_type = 'PLATFORM') = (school_id IS NULL)),
    CONSTRAINT ck_user_role_assignment_branch_shape CHECK ((scope_type = 'BRANCH') = (branch_id IS NOT NULL)),
    CONSTRAINT ck_user_role_assignment_branch_needs_staff CHECK (scope_type <> 'BRANCH' OR staff_id IS NOT NULL),
    CONSTRAINT ck_user_role_assignment_expiry CHECK (expires_at IS NULL OR expires_at > granted_at),
    CONSTRAINT ck_user_role_assignment_timestamps CHECK (updated_at >= created_at)
);

-- Resolving a user's effective permissions runs on every request.
CREATE INDEX IF NOT EXISTS ix_user_role_assignment_user
    ON user_role_assignment (user_id);

-- Finding every holder of a role, to invalidate their cache when it is edited.
CREATE INDEX IF NOT EXISTS ix_user_role_assignment_role
    ON user_role_assignment (role_id);

-- Rotating refresh tokens. Access tokens stay short-lived and are not stored.
CREATE TABLE IF NOT EXISTS refresh_token (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    token_hash varchar(64) NOT NULL,                      -- sha-256 hex; the token itself is never stored
    jti uuid NOT NULL,                                    -- matches the JWT claim, for audit correlation
    issued_at timestamp DEFAULT now() NOT NULL,
    expires_at timestamp NOT NULL,
    revoked_at timestamp,                                 -- NULL while the token is live
    replaced_by_id uuid,                                  -- rotation chain; a reused parent signals theft
    user_agent varchar(255),
    ip_address inet,
    CONSTRAINT pk_refresh_token PRIMARY KEY (id),
    CONSTRAINT fk_refresh_token_user FOREIGN KEY (user_id) REFERENCES app_user (id) ON DELETE CASCADE,
    CONSTRAINT fk_refresh_token_replaced_by FOREIGN KEY (replaced_by_id) REFERENCES refresh_token (id) ON DELETE SET NULL,
    CONSTRAINT uk_refresh_token_hash UNIQUE (token_hash),
    CONSTRAINT uk_refresh_token_jti UNIQUE (jti),
    CONSTRAINT ck_refresh_token_hash_format CHECK (token_hash ~ '^[0-9a-f]{64}$'),
    CONSTRAINT ck_refresh_token_expiry CHECK (expires_at > issued_at),
    CONSTRAINT ck_refresh_token_revoked CHECK (revoked_at IS NULL OR revoked_at >= issued_at)
);

-- Partial index: revoked rows are kept for audit but never looked up by user.
CREATE INDEX IF NOT EXISTS ix_refresh_token_user_active
    ON refresh_token (user_id)
    WHERE revoked_at IS NULL;

-- ---------------------------------------------------------------------------
-- Keeping app_user.authorization_version honest.
--
-- Each cached permission set is stamped with the version it was built from, and a
-- request compares that stamp against the row here before trusting the cache. A
-- grant change that fails to bump the version is therefore silent stale authority:
-- nothing errors, the user simply keeps access they no longer have. That is too
-- important to depend on service code remembering, so the database does it.
--
-- Statement-level triggers with transition tables, so granting a role to a whole
-- branch or rewriting a role's permission set costs one set-based UPDATE rather
-- than one per row. The version is a change counter, not a sequence: only equality
-- against the cached stamp is ever compared, so skipped values are harmless.
--
-- Deliberately not triggered here, because each is already covered:
--   staff_branch_membership  removing a membership cascades its branch grants away,
--                            which fires the user_role_assignment delete trigger
--   role deletion            cascades to the same trigger
--   app_user.status          read alongside authorization_version on every request,
--                            so suspending an account needs no version change
--
-- Note for the JPA mapping: authorization_version must be insertable = false and
-- updatable = false, or an entity write holding a stale value will silently undo
-- an increment made here. The same applies to is_staff, which is generated.
-- ---------------------------------------------------------------------------

-- Grants changed: bump exactly the users named in the changed rows.
CREATE OR REPLACE FUNCTION auth_bump_version_by_user()
    RETURNS trigger
    LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE app_user
    SET authorization_version = authorization_version + 1
    WHERE id IN (SELECT user_id FROM changed_row);
    RETURN NULL;
END
$$;

-- An update can move a grant between users, so both sides are bumped.
CREATE OR REPLACE FUNCTION auth_bump_version_by_user_change()
    RETURNS trigger
    LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE app_user
    SET authorization_version = authorization_version + 1
    WHERE id IN (SELECT user_id FROM old_row
                 UNION
                 SELECT user_id FROM new_row);
    RETURN NULL;
END
$$;

-- A role's permission set changed: bump every holder of that role.
CREATE OR REPLACE FUNCTION auth_bump_version_by_role()
    RETURNS trigger
    LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE app_user
    SET authorization_version = authorization_version + 1
    WHERE id IN (SELECT assignment.user_id
                 FROM user_role_assignment assignment
                 WHERE assignment.role_id IN (SELECT role_id FROM changed_row));
    RETURN NULL;
END
$$;

CREATE OR REPLACE FUNCTION auth_bump_version_by_role_change()
    RETURNS trigger
    LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE app_user
    SET authorization_version = authorization_version + 1
    WHERE id IN (SELECT assignment.user_id
                 FROM user_role_assignment assignment
                 WHERE assignment.role_id IN (SELECT role_id FROM old_row
                                              UNION
                                              SELECT role_id FROM new_row));
    RETURN NULL;
END
$$;

-- A learner who is no longer enrolled must not be able to sign in. Leaving that to
-- the withdrawal service is the same trap as the version bump: nothing fails when
-- it is forgotten, the account simply keeps working.
--
-- Disable only, never re-enable. An account may also have been disabled by an
-- administrator for its own reasons, and re-enrolment must not quietly undo that.
-- Restoring access stays a deliberate action.
CREATE OR REPLACE FUNCTION auth_disable_login_for_inactive_learner()
    RETURNS trigger
    LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE app_user
    SET status = 'DISABLED',
        authorization_version = authorization_version + 1
    WHERE learner_id IN (SELECT id FROM new_row WHERE status NOT IN ('ENROLLED', 'ACTIVE'))
      AND status <> 'DISABLED';
    RETURN NULL;
END
$$;

-- The same rule for staff, and it matters more here: a terminated employee who can
-- still sign in is a worse outcome than a withdrawn learner who can. On leave still
-- counts as employed, so it keeps access.
CREATE OR REPLACE FUNCTION auth_disable_login_for_inactive_staff()
    RETURNS trigger
    LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE app_user
    SET status = 'DISABLED',
        authorization_version = authorization_version + 1
    WHERE staff_id IN (SELECT id FROM new_row WHERE employment_status NOT IN ('ACTIVE', 'ON_LEAVE'))
      AND status <> 'DISABLED';
    RETURN NULL;
END
$$;

-- One trigger per event: PostgreSQL does not allow transition tables on a trigger
-- registered for more than one event.
CREATE OR REPLACE TRIGGER tr_user_role_assignment_insert_bump_version
    AFTER INSERT ON user_role_assignment
    REFERENCING NEW TABLE AS changed_row
    FOR EACH STATEMENT
    EXECUTE FUNCTION auth_bump_version_by_user();

CREATE OR REPLACE TRIGGER tr_user_role_assignment_update_bump_version
    AFTER UPDATE ON user_role_assignment
    REFERENCING OLD TABLE AS old_row NEW TABLE AS new_row
    FOR EACH STATEMENT
    EXECUTE FUNCTION auth_bump_version_by_user_change();

CREATE OR REPLACE TRIGGER tr_user_role_assignment_delete_bump_version
    AFTER DELETE ON user_role_assignment
    REFERENCING OLD TABLE AS changed_row
    FOR EACH STATEMENT
    EXECUTE FUNCTION auth_bump_version_by_user();

CREATE OR REPLACE TRIGGER tr_role_permission_insert_bump_version
    AFTER INSERT ON role_permission
    REFERENCING NEW TABLE AS changed_row
    FOR EACH STATEMENT
    EXECUTE FUNCTION auth_bump_version_by_role();

CREATE OR REPLACE TRIGGER tr_role_permission_update_bump_version
    AFTER UPDATE ON role_permission
    REFERENCING OLD TABLE AS old_row NEW TABLE AS new_row
    FOR EACH STATEMENT
    EXECUTE FUNCTION auth_bump_version_by_role_change();

CREATE OR REPLACE TRIGGER tr_role_permission_delete_bump_version
    AFTER DELETE ON role_permission
    REFERENCING OLD TABLE AS changed_row
    FOR EACH STATEMENT
    EXECUTE FUNCTION auth_bump_version_by_role();

-- Withdrawal or completion disables the learner's login.
CREATE OR REPLACE TRIGGER tr_learner_status_disables_login
    AFTER UPDATE ON learner
    REFERENCING NEW TABLE AS new_row
    FOR EACH STATEMENT
    EXECUTE FUNCTION auth_disable_login_for_inactive_learner();

-- Suspension, resignation or termination disables the staff member's login.
CREATE OR REPLACE TRIGGER tr_staff_status_disables_login
    AFTER UPDATE ON staff
    REFERENCING NEW TABLE AS new_row
    FOR EACH STATEMENT
    EXECUTE FUNCTION auth_disable_login_for_inactive_staff();
