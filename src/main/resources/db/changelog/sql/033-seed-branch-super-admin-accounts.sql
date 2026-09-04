-- A branch super admin for each of the Elven school's branches: a staff record, a
-- branch membership, a login, and the branch's own branch-super-admin role granted
-- to it.
--
-- LOCAL AND DEMO ONLY. Runs in the "demo" context, not "reference", for the same
-- reason as 029: the passwords below are committed to this repository, so any
-- environment that loads this has three publicly known branch administrators.
-- To load it locally, run with LIQUIBASE_CONTEXTS=reference,demo.
--
-- Depends on 029, which creates elven_super. That account is the granter here, which
-- is the realistic chain: a school super admin is who hands out branch roles. If 029
-- has not run, the final statement inserts nothing rather than failing, so check the
-- grant count after loading.
--
-- Usernames follow br_super_<first three letters of the branch code>, and are computed
-- with left(branch.code, 3) rather than typed, so the rule is enforced here rather
-- than restated. That yields br_super_bat, br_super_raj and br_super_wel. Usernames are
-- stored lower case because ck_identity_username_format allows nothing else; sign-in
-- should fold the entered value, so typing BR_SUPER_BAT works.
--
-- Passwords are <first three letters>_Super@123, as bcrypt cost 10 to match the
-- BCryptPasswordEncoder in SchoolSecurityConfig. Written as literals rather than
-- generated with gen_salt so the seed is deterministic and every database gets the
-- same rows. Each hash was verified against Spring Security's own BCrypt.
--
-- Four steps, in this order because each is the previous one's precondition. The
-- membership must exist before the grant: a branch-scoped assignment carries a
-- foreign key to (staff_id, branch_id) in x_staff_branch_membership, which is what
-- makes a branch role impossible to hold without working at that branch, and what
-- revokes it automatically if the person stops.

-- 1. The employment records. Each exists independently of its login, like every staff
--    record, and is a Branch Manager rather than an administrator: designation is a
--    human resources label and grants nothing on its own.
WITH seed (branch_code, staff_id, employee_no, full_name, national_id, date_of_birth,
           phone_number, phone_number_e164, email, address) AS (
    VALUES
        ('battaramulla', '60000000-0000-0000-0000-000000000002'::uuid, 'E-0002', 'Bhathiya Rathnayake',
         '198703451V', DATE '1987-03-12', '077 480 1201', '+94774801201',
         'bhathiya.rathnayake@elvendriving.lk', 'Pelawatte Road, Battaramulla, Sri Lanka'),
        ('rajagiriya',   '60000000-0000-0000-0000-000000000003'::uuid, 'E-0003', 'Rajitha Jayasuriya',
         '199118762V', DATE '1991-07-25', '077 480 1202', '+94774801202',
         'rajitha.jayasuriya@elvendriving.lk', 'Nawala Road, Rajagiriya, Sri Lanka'),
        ('wellawatte',   '60000000-0000-0000-0000-000000000004'::uuid, 'E-0004', 'Wasana Ellepola',
         '198934517V', DATE '1989-11-04', '077 480 1203', '+94774801203',
         'wasana.ellepola@elvendriving.lk', 'Galle Road, Wellawatte, Sri Lanka')
)
INSERT INTO public.m_staff (
    id, school_id, employee_no, full_name, national_id, date_of_birth, designation,
    employment_status, phone_number, phone_number_e164, email, address, joined_on
)
SELECT seed.staff_id, branch.school_id, seed.employee_no, seed.full_name, seed.national_id,
       seed.date_of_birth, 'Branch Manager', 'ACTIVE', seed.phone_number,
       seed.phone_number_e164, seed.email, seed.address, DATE '2026-02-01'
FROM seed
JOIN public.m_branch branch ON branch.code = seed.branch_code
ON CONFLICT ON CONSTRAINT uk_staff_school_employee_no DO NOTHING;

-- 2. The branch memberships. is_primary marks the home branch, at most one per staff
--    member. school_id is set by trigger from the branch, so it cannot disagree.
WITH posting (staff_id, branch_code) AS (
    VALUES
        ('60000000-0000-0000-0000-000000000002'::uuid, 'battaramulla'),
        ('60000000-0000-0000-0000-000000000003'::uuid, 'rajagiriya'),
        ('60000000-0000-0000-0000-000000000004'::uuid, 'wellawatte')
)
INSERT INTO public.x_staff_branch_membership (staff_id, branch_id, school_id, is_primary)
SELECT posting.staff_id, branch.id, branch.school_id, true
FROM posting
JOIN public.m_branch branch ON branch.code = posting.branch_code
ON CONFLICT ON CONSTRAINT pk_staff_branch_membership DO NOTHING;

-- 3. The logins. status ACTIVE requires a password already set, which these have, so
--    they skip the pending-activation step a real account would go through. The
--    contact details are copied from the staff record because these are demo accounts
--    for one person; on a real account the login's number is its own fact and may
--    legitimately differ from the employment record's.
WITH credential (staff_id, identity_id, password_hash) AS (
    VALUES
        ('60000000-0000-0000-0000-000000000002'::uuid, '70000000-0000-0000-0000-000000000002'::uuid,
         '$2a$10$CfUtM017gpB2kF/xUXBKneAMJ0Qgb6/2bVFP0Tiz9IbiP/MWugWPq'),  -- bat_Super@123
        ('60000000-0000-0000-0000-000000000003'::uuid, '70000000-0000-0000-0000-000000000003'::uuid,
         '$2a$10$bo6NcCKkDciDVFLD0m7FwegIqSWEzSgnn3fq3Jb9khnG0r0eIz/pe'),  -- raj_Super@123
        ('60000000-0000-0000-0000-000000000004'::uuid, '70000000-0000-0000-0000-000000000004'::uuid,
         '$2a$10$awFZ8zT9PBMzYObgz4S/teKJO3A.rpGUcSYiKLmOPi5L0HpZTFmMm')   -- wel_Super@123
)
INSERT INTO public.m_identity (
    id, school_id, platform_operator_id, staff_id, learner_id, username,
    phone_number, phone_number_e164, password_hash, display_name, status
)
SELECT credential.identity_id, staff.school_id, NULL, staff.id, NULL,
       'br_super_' || left(branch.code, 3),
       staff.phone_number, staff.phone_number_e164, credential.password_hash,
       staff.full_name, 'ACTIVE'
FROM credential
JOIN public.m_staff staff ON staff.id = credential.staff_id
JOIN public.x_staff_branch_membership membership
  ON membership.staff_id = staff.id AND membership.is_primary
JOIN public.m_branch branch ON branch.id = membership.branch_id
ON CONFLICT ON CONSTRAINT uk_identity_username DO NOTHING;

-- 4. The grants. Each login receives the branch-super-admin role belonging to the one
--    branch its staff member works at, resolved through the membership rather than
--    named, so a login can never be handed another branch's role here. granted_by is
--    elven_super: unlike 029, which had to grant to itself because it was the first
--    account, there is now a school administrator to be the granter.
INSERT INTO public.t_identity_role_assignment (
    identity_id, role_id, scope_type, school_id, branch_id, assignable_to, is_staff,
    staff_id, granted_by
)
SELECT identity.id, role.id, 'BRANCH', role.school_id, role.branch_id, role.assignable_to,
       identity.is_staff, identity.staff_id, granter.id
FROM public.m_identity identity
JOIN public.x_staff_branch_membership membership
  ON membership.staff_id = identity.staff_id AND membership.is_primary
JOIN public.m_role role
  ON role.branch_id = membership.branch_id
 AND role.code = 'branch-super-admin'
 AND role.scope_type = 'BRANCH'
JOIN public.m_identity granter ON granter.username = 'elven_super'
WHERE identity.username IN ('br_super_bat', 'br_super_raj', 'br_super_wel')
ON CONFLICT ON CONSTRAINT uk_identity_role_assignment_grant DO NOTHING;
