-- Authentication and role-based authorization schema.
--
-- Scope model: a role is owned by exactly one scope (PLATFORM, SCHOOL or BRANCH),
-- and a grant of that role carries the same scope. A branch-owned role can only be
-- granted to a user who currently holds a membership in that branch, and can only
-- contain permissions whose max_scope_type reaches BRANCH. Both rules are enforced
-- by the constraints below, not only by application code.
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
-- Depends on the school and branch tables defined in
-- src/main/resources/db-data/school-schema.sql. Those are not repeated here.
--
-- The final section links learner logins to the learner table. It is guarded and
-- becomes a no-op until that table exists, so this file applies either way.
--
-- Reference document. The runtime schema is applied by Liquibase under
-- src/main/resources/db/changelog; keep this file aligned when that changes.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Composite foreign key target on the existing branch table. Lets dependent tables
-- reference (branch_id, school_id) as a pair, so a branch can never be paired with a
-- school that does not own it. Guarded because ADD CONSTRAINT has no IF NOT EXISTS.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'uk_branch_id_school') THEN
        ALTER TABLE branch ADD CONSTRAINT uk_branch_id_school UNIQUE (id, school_id);
    END IF;
END
$$;

-- Staff and platform identities. Credentials live here; permissions never do.
CREATE TABLE IF NOT EXISTS app_user (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid,                                       -- NULL only for platform staff
    username varchar(64) NOT NULL,
    email varchar(254) NOT NULL,
    password_hash varchar(255) NOT NULL,                  -- sized for the {bcrypt} / {argon2} prefix
    display_name varchar(160) NOT NULL,
    status varchar(32) DEFAULT 'ACTIVE' NOT NULL,
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
    -- Composite FK target. Lets staff_branch_membership prove that the user and the
    -- branch belong to the same school. Platform users (school_id NULL) fall out of
    -- that check under MATCH SIMPLE, which is why they can never join a branch.
    CONSTRAINT uk_app_user_id_school UNIQUE (id, school_id),
    CONSTRAINT uk_app_user_username UNIQUE (username),
    CONSTRAINT uk_app_user_email UNIQUE (email),
    CONSTRAINT ck_app_user_status CHECK (status IN ('ACTIVE', 'SUSPENDED', 'LOCKED', 'DISABLED')),
    CONSTRAINT ck_app_user_username_format CHECK (username ~ '^[a-z0-9]+(?:[._-][a-z0-9]+)*$'),
    CONSTRAINT ck_app_user_email_format CHECK (email ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$'),
    CONSTRAINT ck_app_user_password_hash_not_blank CHECK (btrim(password_hash) <> ''),
    CONSTRAINT ck_app_user_display_name_not_blank CHECK (btrim(display_name) <> ''),
    CONSTRAINT ck_app_user_authorization_version_non_negative CHECK (authorization_version >= 0),
    CONSTRAINT ck_app_user_failed_attempt_count_non_negative CHECK (failed_attempt_count >= 0),
    CONSTRAINT ck_app_user_timestamps CHECK (updated_at >= created_at)
);

CREATE INDEX IF NOT EXISTS ix_app_user_school
    ON app_user (school_id);

-- Which branches a staff member works at: zero, one, or many.
-- Membership grants nothing on its own. It is the precondition for holding a
-- branch-owned role, and deleting a row here revokes those roles by cascade.
CREATE TABLE IF NOT EXISTS staff_branch_membership (
    user_id uuid NOT NULL,
    branch_id uuid NOT NULL,
    school_id uuid NOT NULL,                              -- must match both the user's and the branch's school
    is_primary boolean DEFAULT false NOT NULL,            -- the staff member's home branch
    assigned_at timestamp DEFAULT now() NOT NULL,
    created_at timestamp DEFAULT now() NOT NULL,
    created_by varchar(20) DEFAULT 'system' NOT NULL,
    updated_at timestamp DEFAULT now() NOT NULL,
    updated_by varchar(20) DEFAULT 'system' NOT NULL,
    -- Composite FK target for user_role_assignment: a branch grant must name a
    -- (user_id, branch_id) pair that exists here.
    CONSTRAINT pk_staff_branch_membership PRIMARY KEY (user_id, branch_id),
    -- These two meet on school_id, so the user and the branch must share a school.
    CONSTRAINT fk_staff_branch_membership_user FOREIGN KEY (user_id, school_id) REFERENCES app_user (id, school_id) ON DELETE CASCADE,
    CONSTRAINT fk_staff_branch_membership_branch FOREIGN KEY (branch_id, school_id) REFERENCES branch (id, school_id) ON DELETE CASCADE,
    CONSTRAINT ck_staff_branch_membership_timestamps CHECK (updated_at >= created_at)
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_staff_branch_membership_primary_per_user
    ON staff_branch_membership (user_id)
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
    -- Three composite FK targets. Each lets a dependent table pin one facet of this
    -- role's identity: its scope, its school, its branch.
    CONSTRAINT uk_role_id_scope_type UNIQUE (id, scope_type),
    CONSTRAINT uk_role_id_school UNIQUE (id, school_id),
    CONSTRAINT uk_role_id_branch UNIQUE (id, branch_id),
    -- NULLS NOT DISTINCT is what lets every branch have its own 'instructor'
    -- while still blocking a duplicate within one branch.
    CONSTRAINT uk_role_code_per_owner UNIQUE NULLS NOT DISTINCT (code, school_id, branch_id),
    CONSTRAINT ck_role_scope_type CHECK (scope_type IN ('PLATFORM', 'SCHOOL', 'BRANCH')),
    -- Scope columns must match the declared scope_type. This is what guarantees a
    -- BRANCH role always has a branch for the assignment FKs to pin against.
    CONSTRAINT ck_role_scope_shape CHECK (
        (scope_type = 'PLATFORM' AND school_id IS NULL AND branch_id IS NULL)
        OR (scope_type = 'SCHOOL' AND school_id IS NOT NULL AND branch_id IS NULL)
        OR (scope_type = 'BRANCH' AND school_id IS NOT NULL AND branch_id IS NOT NULL)
    ),
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
    --   _membership   branch_id not null the user is a current member of that branch
    --
    -- Chained: a branch role forces scope_type BRANCH, the shape check then forces
    -- branch_id non-null, which forces it to equal the role's branch, which forces a
    -- membership row. Storing a role for staff of another branch is not possible.
    CONSTRAINT fk_user_role_assignment_role_scope FOREIGN KEY (role_id, scope_type) REFERENCES role (id, scope_type) ON DELETE CASCADE,
    CONSTRAINT fk_user_role_assignment_role_school FOREIGN KEY (role_id, school_id) REFERENCES role (id, school_id) ON DELETE CASCADE,
    CONSTRAINT fk_user_role_assignment_role_branch FOREIGN KEY (role_id, branch_id) REFERENCES role (id, branch_id) ON DELETE CASCADE,
    -- CASCADE here is the lifecycle rule: removing someone from a branch revokes
    -- their roles at that branch, with no second cleanup step to forget.
    CONSTRAINT fk_user_role_assignment_membership FOREIGN KEY (user_id, branch_id) REFERENCES staff_branch_membership (user_id, branch_id) ON DELETE CASCADE,
    CONSTRAINT uk_user_role_assignment_grant UNIQUE NULLS NOT DISTINCT (user_id, role_id, branch_id),
    CONSTRAINT ck_user_role_assignment_scope_type CHECK (scope_type IN ('PLATFORM', 'SCHOOL', 'BRANCH')),
    -- These two shape checks are load-bearing, not cosmetic: they guarantee the
    -- branch_id above is non-null for branch grants, so the FKs cannot be dodged
    -- by leaving it NULL and slipping past MATCH SIMPLE.
    CONSTRAINT ck_user_role_assignment_school_shape CHECK ((scope_type = 'PLATFORM') = (school_id IS NULL)),
    CONSTRAINT ck_user_role_assignment_branch_shape CHECK ((scope_type = 'BRANCH') = (branch_id IS NOT NULL)),
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
-- an increment made here.
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

-- ---------------------------------------------------------------------------
-- Learner logins.
--
-- A login is a learner's when it points at a learner row, and staff's when it does
-- not. There is no separate user_type column on purpose: a discriminator stored
-- independently of the link can drift out of agreement with it, so is_staff is
-- GENERATED from learner_id and PostgreSQL refuses to write it.
--
-- Keeping learners out of staff_branch_membership is what keeps them out of the
-- role system altogether. A branch-owned role can only be granted to a member of
-- that branch, so a user who cannot be a member cannot hold one, and no further
-- rule is needed to say so.
--
-- A learner's authority over their own record is ownership, not scope: grant it
-- through '-own' permissions (learner:read-own, lesson:read-own) resolved against
-- learner_id, rather than a fourth SELF scope every query would have to handle.
--
-- This section depends on the learner table, which does not exist yet -- the
-- learner package is still empty. It is guarded so this file applies cleanly
-- either way and takes effect as soon as learner lands. In Liquibase the same
-- thing is a separate changeset carrying a tableExists precondition.
--
-- Until then a learner login simply cannot be created, which is the safe failure.
-- The alternative -- adding learner_id now and its foreign key later -- leaves a
-- nullable tenant-crossing column open for however long it takes someone to
-- remember to close it.
--
-- Requires learner to carry UNIQUE (id, school_id) as a composite FK target, the
-- same pairing branch already provides.
-- ---------------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'learner' AND relkind = 'r') THEN
        RAISE NOTICE 'learner login link skipped: table "learner" does not exist yet';
        RETURN;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'uk_learner_id_school') THEN
        RAISE EXCEPTION 'learner must declare UNIQUE (id, school_id) as uk_learner_id_school '
                        'before app_user can reference it as a school-matched pair';
    END IF;

    ALTER TABLE app_user ADD COLUMN IF NOT EXISTS learner_id uuid;
    ALTER TABLE app_user ADD COLUMN IF NOT EXISTS is_staff boolean
        GENERATED ALWAYS AS (learner_id IS NULL) STORED;
    ALTER TABLE staff_branch_membership ADD COLUMN IF NOT EXISTS is_staff boolean DEFAULT true NOT NULL;

    -- One login per learner. Nullable, and SQL treats NULLs as distinct, so any
    -- number of staff rows share NULL while a learner can be claimed only once.
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'uk_app_user_learner') THEN
        ALTER TABLE app_user ADD CONSTRAINT uk_app_user_learner UNIQUE (learner_id);
    END IF;

    -- Composite FK target, so staff_branch_membership can require is_staff.
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'uk_app_user_id_is_staff') THEN
        ALTER TABLE app_user ADD CONSTRAINT uk_app_user_id_is_staff UNIQUE (id, is_staff);
    END IF;

    -- The learner must belong to the same school as the login.
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_app_user_learner') THEN
        ALTER TABLE app_user ADD CONSTRAINT fk_app_user_learner
            FOREIGN KEY (learner_id, school_id) REFERENCES learner (id, school_id) ON DELETE RESTRICT;
    END IF;

    -- Platform staff have no school, so they can never be learners.
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ck_app_user_learner_needs_school') THEN
        ALTER TABLE app_user ADD CONSTRAINT ck_app_user_learner_needs_school
            CHECK (learner_id IS NULL OR school_id IS NOT NULL);
    END IF;

    -- Pins the column to true, so the FK below can only match a staff app_user.
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ck_staff_branch_membership_is_staff') THEN
        ALTER TABLE staff_branch_membership ADD CONSTRAINT ck_staff_branch_membership_is_staff
            CHECK (is_staff);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_staff_branch_membership_is_staff') THEN
        ALTER TABLE staff_branch_membership ADD CONSTRAINT fk_staff_branch_membership_is_staff
            FOREIGN KEY (user_id, is_staff) REFERENCES app_user (id, is_staff);
    END IF;

    -- Staff are a small minority of rows once learners have logins. This keeps
    -- staff lookups off a table dominated by learners.
    CREATE INDEX IF NOT EXISTS ix_app_user_staff_by_school
        ON app_user (school_id) WHERE learner_id IS NULL;
END
$$;
