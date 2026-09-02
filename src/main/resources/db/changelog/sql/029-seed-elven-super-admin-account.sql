-- Bootstrap administrator for the Elven school: a staff record, a login, and the
-- school super admin role granted to it.
--
-- LOCAL AND DEMO ONLY. This changeset runs in the "demo" context, not "reference",
-- so it does not execute under the default context configured in
-- application.properties. That is deliberate: the password below is committed to the
-- repository, so any environment that runs this has a publicly known administrator
-- account. Production needs a different bootstrap, such as an operator-created
-- account activated through the normal pending-activation flow.
--
-- To load it locally, run with LIQUIBASE_CONTEXTS=reference,demo.
--
-- The username is stored lowercase as elven_super, because usernames are constrained
-- to lowercase by ck_app_user_username_format. Sign-in should fold the entered value
-- to lower case, so typing ELVEN_SUPER works. Storing one canonical form is what
-- stops two accounts differing only by case.
--
-- The password hash is bcrypt cost 10, matching the BCryptPasswordEncoder configured
-- in SchoolSecurityConfig. It is written as a literal rather than generated with
-- gen_salt so the seed is deterministic and the same row appears in every database.
-- The plaintext is ElvenSuper@123.

-- The employee record. Exists independently of the login, like every staff record.
INSERT INTO public.m_staff (
    id, school_id, employee_no, full_name, national_id, date_of_birth, designation,
    employment_status, phone_number, phone_number_e164, email, address, joined_on
)
SELECT '60000000-0000-0000-0000-000000000001', school.id, 'E-0001', 'Elven Super Admin',
       '199012345678', DATE '1990-05-15', 'School Administrator', 'ACTIVE',
       '077 480 1100', '+94774801100', 'super.admin@elvendriving.lk',
       'Cotta Road, Rajagiriya, Sri Lanka', DATE '2026-01-01'
FROM public.m_school school
WHERE school.code = 'elven'
ON CONFLICT ON CONSTRAINT uk_staff_school_employee_no DO NOTHING;

-- The login. status ACTIVE requires a password to already be set, which it is, so
-- this account skips the pending-activation step that a real one would go through.
INSERT INTO public.m_app_user (
    id, school_id, platform_operator_id, staff_id, learner_id, username,
    phone_number, phone_number_e164, password_hash, display_name, status
)
SELECT '70000000-0000-0000-0000-000000000001', staff.school_id, NULL, staff.id, NULL, 'elven_super',
       '077 480 1100', '+94774801100',
       '$2a$10$OfnRkLUdXhruJgcKC3I2NO536UZBvxBuQVoE9bPBRU09rluycVyXi',
       'Elven Super Admin', 'ACTIVE'
FROM public.m_staff staff
WHERE staff.id = '60000000-0000-0000-0000-000000000001'
ON CONFLICT ON CONSTRAINT uk_app_user_username DO NOTHING;

-- The grant. granted_by points at the account itself, which is the bootstrap case:
-- the first administrator has nobody above them to be granted by, and granted_by is
-- NOT NULL because every later grant must name a real granter.
INSERT INTO public.t_user_role_assignment (
    user_id, role_id, scope_type, school_id, branch_id, assignable_to, is_staff,
    staff_id, granted_by
)
SELECT app_user.id, role.id, 'SCHOOL', role.school_id, NULL, role.assignable_to, app_user.is_staff,
       app_user.staff_id, app_user.id
FROM public.m_app_user app_user
JOIN public.m_role role
  ON role.school_id = app_user.school_id
 AND role.code = 'school-super-admin'
 AND role.scope_type = 'SCHOOL'
WHERE app_user.username = 'elven_super'
ON CONFLICT ON CONSTRAINT uk_user_role_assignment_grant DO NOTHING;
