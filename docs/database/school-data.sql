-- School database seed data
-- Run after docs/database/school-schema.sql.
-- Seed statements are idempotent and safe to re-run.

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET client_min_messages = warning;

BEGIN;

-- m_school
INSERT INTO public.m_school (id, code, name, short_name, established_year, created_at, updated_at, hotline_href, whatsapp_href, email, created_by, updated_by, tenant_status) VALUES
	('20000000-0000-0000-0000-000000000001', 'elven', 'Elven Driving School', 'Elven', 1950, '2026-08-27 14:50:12.114374', '2026-08-27 14:50:12.114374', 'tel:+94771234567', 'https://wa.me/94771234567', 'hello@elvendriving.lk', 'system', 'system', 'ACTIVE') ON CONFLICT DO NOTHING;

-- m_branch
INSERT INTO public.m_branch (id, school_id, code, name, branch_type, is_head_office, is_active, created_at, updated_at, address, created_by, updated_by) VALUES
	('30000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 'rajagiriya', 'Rajagiriya', 'BRANCH', true, true, '2026-08-27 14:50:12.367369', '2026-08-27 14:50:12.367369', 'Cotta Road, Rajagiriya, Sri Lanka', 'system', 'system'),
	('30000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000001', 'wellawatte', 'Wellawatte', 'BRANCH', false, true, '2026-08-27 14:50:12.367369', '2026-08-27 14:50:12.367369', 'Galle Road, Colombo 06, Sri Lanka', 'system', 'system'),
	('30000000-0000-0000-0000-000000000003', '20000000-0000-0000-0000-000000000001', 'battaramulla', 'Battaramulla', 'BRANCH', false, true, '2026-08-27 14:50:12.367369', '2026-08-27 14:50:12.367369', 'Pannipitiya Road, Battaramulla, Sri Lanka', 'system', 'system'),
	('cbd1a06d-4c89-40cf-a59d-2c6410d89d92', '20000000-0000-0000-0000-000000000001', 'petta', 'petta', 'BRANCH', false, true, '2026-08-31 13:40:04.640733', '2026-08-31 19:10:04.046464', 'Cotta Road, petta, Sri Lanka', 'System Generate', 'system') ON CONFLICT DO NOTHING;

-- m_branch_contact_number
INSERT INTO public.m_branch_contact_number (id, branch_id, contact_type, phone_number, phone_number_e164, is_primary, display_order, created_at, updated_at, created_by, updated_by, school_id) VALUES
	('30000000-0000-0000-0000-000000000011', '30000000-0000-0000-0000-000000000001', 'GENERAL', '077 480 1120', '+94774801120', true, 1, '2026-08-27 14:50:12.367369', '2026-08-27 14:50:12.367369', 'system', 'system', '20000000-0000-0000-0000-000000000001'),
	('30000000-0000-0000-0000-000000000012', '30000000-0000-0000-0000-000000000002', 'GENERAL', '077 480 1121', '+94774801121', true, 1, '2026-08-27 14:50:12.367369', '2026-08-27 14:50:12.367369', 'system', 'system', '20000000-0000-0000-0000-000000000001'),
	('30000000-0000-0000-0000-000000000013', '30000000-0000-0000-0000-000000000003', 'GENERAL', '077 480 1122', '+94774801122', true, 1, '2026-08-27 14:50:12.367369', '2026-08-27 14:50:12.367369', 'system', 'system', '20000000-0000-0000-0000-000000000001'),
	('db000692-f7a7-4e64-91e8-0d6c024414b5', 'cbd1a06d-4c89-40cf-a59d-2c6410d89d92', 'GENERAL', '077 367 1120', '+94774759520', true, 1, '2026-08-31 13:40:04.663205', '2026-08-31 19:10:04.046464', 'System Generate', 'system', '20000000-0000-0000-0000-000000000001') ON CONFLICT DO NOTHING;

-- m_school_contact_number
INSERT INTO public.m_school_contact_number (id, school_id, contact_type, phone_number, phone_number_e164, is_primary, display_order, created_at, updated_at, created_by, updated_by) VALUES
	('20000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000001', 'HOTLINE', '077 123 4567', '+94771234567', true, 1, '2026-08-27 14:50:12.114374', '2026-08-27 14:50:12.114374', 'system', 'system') ON CONFLICT DO NOTHING;

-- r_license_class
INSERT INTO public.r_license_class (id, code, name, display_order, is_active, created_at, updated_at, included_class_codes, old_class_codes, source_url, description, created_by, updated_by) VALUES
	('dcffe559-f09a-4bc2-b2de-01f3e2728fc6', 'A1', 'Light motor cycle', 1, true, '2026-08-27 14:50:11.283197', '2026-08-27 14:50:11.689781', '["G1"]', '["D"]', 'https://dmt.gov.lk/index.php?option=com_content&view=article&id=46&Itemid=163&lang=en', 'Light motor cycles of which Engine Capacity does not exceeds 100CC', 'system', 'system'),
	('2935e370-b6d3-4e7a-98c3-6cbb1bfc5fee', 'A', 'Motorcycle', 2, true, '2026-08-27 14:50:11.283197', '2026-08-27 14:50:11.689781', '["A1", "G1"]', '["D"]', 'https://dmt.gov.lk/index.php?option=com_content&view=article&id=46&Itemid=163&lang=en', 'Motorcycles of which Engine capacity exceeds 100CC', 'system', 'system'),
	('ba608626-5d7c-4bab-8b60-6ad6f5241c59', 'B1', 'Motor tricycle or light van', 3, true, '2026-08-27 14:50:11.283197', '2026-08-27 14:50:11.689781', '["G1"]', '["E", "F"]', 'https://dmt.gov.lk/index.php?option=com_content&view=article&id=46&Itemid=163&lang=en', 'Motor Tricycle or van of which tare does not exceed 500kg and Gross vehicle weight does not exceed 1000 kg: Motor vehicle in this class include an invalid carriage', 'system', 'system'),
	('099dc286-9fd2-4600-9cb9-db747300998e', 'B', 'Dual purpose motor vehicle', 4, true, '2026-08-27 14:50:11.283197', '2026-08-27 14:50:11.689781', '["G1"]', '["C", "C1"]', 'https://dmt.gov.lk/index.php?option=com_content&view=article&id=46&Itemid=163&lang=en', 'Dual purpose Motor vehicle of which Gross Vehicle Weight does not exceed 3500kg and the seating capacity does not exceed 9 seats inclusive of the driver’s seat, which may be combined with a trailer of which maximum authorized tare does not exceed 750kg: Motor vehicle in this class include and invalid carriage and all cars where the seating capacity does not exceed 9 seats inclusive of the Driver’s seat.', 'system', 'system'),
	('3d7b68f6-5884-41ce-9cd8-14ebde6bb119', 'C1', 'Light motor lorry', 5, true, '2026-08-27 14:50:11.283197', '2026-08-27 14:50:11.689781', '["B", "G1"]', '["B1"]', 'https://dmt.gov.lk/index.php?option=com_content&view=article&id=46&Itemid=163&lang=en', 'Light Motor Lorry – Motor Lorry of which Gross Vehicle Weight exceeds 3500 kg and does not exceed 17000kg: Motor vehicles in this class may be combined with a trailer having maximum authorized tare which does not exceed 750kg: Motor vehicles of this class include a motor ambulance and motor hearses.', 'system', 'system'),
	('3701f559-5097-4324-b3c4-11f0cfb3614a', 'C', 'Motor lorry', 6, true, '2026-08-27 14:50:11.283197', '2026-08-27 14:50:11.689781', '["C1", "B", "J", "G", "G1"]', '["B"]', 'https://dmt.gov.lk/index.php?option=com_content&view=article&id=46&Itemid=163&lang=en', 'Motor Lorry of which Gross vehicle Weight is more than 1700kg; may be combine with a trailer having a maximum authorized tare which does not exceed 750kg', 'system', 'system'),
	('8320d921-6c2a-4b62-9655-acc681350f75', 'CE', 'Heavy motor lorry with trailer', 7, true, '2026-08-27 14:50:11.283197', '2026-08-27 14:50:11.689781', '["C", "C1", "B", "B1", "G", "G1", "J"]', '["B"]', 'https://dmt.gov.lk/index.php?option=com_content&view=article&id=46&Itemid=163&lang=en', 'Heavy Motor Lorry; combination of motor lorry and trailer (s) including articulated vehicles and its trailer (s) of which maximum authorized tare of the trailer exceeds 750kg and gross vehicle weight exceeds 3500kg', 'system', 'system'),
	('df295df8-6d91-408a-89a1-da3c69cd2c0d', 'D1', 'Light motor coach', 8, true, '2026-08-27 14:50:11.283197', '2026-08-27 14:50:11.689781', '["C1", "B", "B1", "G", "G1"]', '["A1"]', 'https://dmt.gov.lk/index.php?option=com_content&view=article&id=46&Itemid=163&lang=en', 'Light Motor Coach- Motor vehicles used for the carriage of persons and having seating capacity of not less than 9 seats and not more than 33 seats inclusive of the driver’s seat; motor vehicle in this class may be combined with a trailer having a maximum authorized tare which does not exceed 750kg', 'system', 'system'),
	('8c91f2bd-a6c0-4177-ada6-ff582e85bf76', 'D', 'Motor coach', 9, true, '2026-08-27 14:50:11.283197', '2026-08-27 14:50:11.689781', '["D1", "C", "C1", "B", "B1", "G", "G1", "J"]', '["A"]', 'https://dmt.gov.lk/index.php?option=com_content&view=article&id=46&Itemid=163&lang=en', 'Motor Coach where the seating capacity does not exceed 33 seats inclusive of the driver’s seat; motor vehicles in this class may be combined with a trailer having a maximum authorized tare which does not exceed 750kg', 'system', 'system'),
	('3ff3524d-c729-475c-9991-e17f203fda99', 'DE', 'Heavy motor coach with trailer', 10, true, '2026-08-27 14:50:11.283197', '2026-08-27 14:50:11.689781', '["D", "D1", "C", "C1", "CE", "B", "B1", "G", "G1", "J"]', '[]', 'https://dmt.gov.lk/index.php?option=com_content&view=article&id=46&Itemid=163&lang=en', 'Heavy Motor Coach – Combination of motor coach having a seating capacity of 33 seats inclusive of the driver’s seat and it’s trailer having maximum authorized tare exceeding 750kg or a combination of two motor coaches', 'system', 'system'),
	('b619bab6-1c1a-4fc5-8f01-3c2e0dfa018e', 'G1', 'Hand tractor', 11, true, '2026-08-27 14:50:11.283197', '2026-08-27 14:50:11.689781', '[]', '["G1"]', 'https://dmt.gov.lk/index.php?option=com_content&view=article&id=46&Itemid=163&lang=en', 'Hand Tractors - Two Wheel Tractor with a Trailer', 'system', 'system'),
	('3b66a60e-8be1-49f1-a139-c1d74f5f6da6', 'G', 'Agricultural land vehicle', 12, true, '2026-08-27 14:50:11.283197', '2026-08-27 14:50:11.689781', '["G1"]', '["G"]', 'https://dmt.gov.lk/index.php?option=com_content&view=article&id=46&Itemid=163&lang=en', 'Land Vehicle - Agricultural Land Vehicle with or without a trailer', 'system', 'system'),
	('87278e0b-7b25-4860-ae58-29c32be0b6ed', 'J', 'Special purpose vehicle', 13, true, '2026-08-27 14:50:11.283197', '2026-08-27 14:50:11.689781', '["G1"]', '[]', 'https://dmt.gov.lk/index.php?option=com_content&view=article&id=46&Itemid=163&lang=en', 'Special purpose Vehicle, Vehicle used for construction, loading & unloading excluding motor lorries, light motor lorries and heavy motor lorries, equipped with construction equipment and equipment for loading and unloading goods', 'system', 'system') ON CONFLICT DO NOTHING;

-- x_branch_license_class
INSERT INTO public.x_branch_license_class (id, branch_id, license_class_id, created_at, price_lkr, created_by, updated_by, updated_at, school_id) VALUES
	('0a274d82-ebea-4a74-943f-c464116f3a4b', '30000000-0000-0000-0000-000000000002', 'dcffe559-f09a-4bc2-b2de-01f3e2728fc6', '2026-08-27 14:50:12.367369', 17500.00, 'system', 'system', '2026-08-27 14:50:12.861183', '20000000-0000-0000-0000-000000000001'),
	('5a144e72-f883-431e-b134-ca17bcc22eec', '30000000-0000-0000-0000-000000000001', 'dcffe559-f09a-4bc2-b2de-01f3e2728fc6', '2026-08-27 14:50:12.367369', 18000.00, 'system', 'system', '2026-08-27 14:50:12.861183', '20000000-0000-0000-0000-000000000001'),
	('3dcc0d4d-a6ca-45f7-b901-89d5c77ed716', '30000000-0000-0000-0000-000000000002', '2935e370-b6d3-4e7a-98c3-6cbb1bfc5fee', '2026-08-27 14:50:12.367369', 25500.00, 'system', 'system', '2026-08-27 14:50:12.861183', '20000000-0000-0000-0000-000000000001'),
	('546fcd6e-e9d5-4ba5-aa26-548c375fb58a', '30000000-0000-0000-0000-000000000001', '2935e370-b6d3-4e7a-98c3-6cbb1bfc5fee', '2026-08-27 14:50:12.367369', 26000.00, 'system', 'system', '2026-08-27 14:50:12.861183', '20000000-0000-0000-0000-000000000001'),
	('b5a8cc21-8bed-4b7c-9afc-28e0f5c118cf', '30000000-0000-0000-0000-000000000002', 'ba608626-5d7c-4bab-8b60-6ad6f5241c59', '2026-08-27 14:50:12.367369', 29000.00, 'system', 'system', '2026-08-27 14:50:12.861183', '20000000-0000-0000-0000-000000000001'),
	('aae4ddd4-1088-40aa-b01c-eaf2bfc9ef08', '30000000-0000-0000-0000-000000000001', 'ba608626-5d7c-4bab-8b60-6ad6f5241c59', '2026-08-27 14:50:12.367369', 30000.00, 'system', 'system', '2026-08-27 14:50:12.861183', '20000000-0000-0000-0000-000000000001'),
	('a42003b9-d5ee-429a-9008-01a960e50f7f', '30000000-0000-0000-0000-000000000003', '099dc286-9fd2-4600-9cb9-db747300998e', '2026-08-27 14:50:12.367369', 47000.00, 'system', 'system', '2026-08-27 14:50:12.861183', '20000000-0000-0000-0000-000000000001'),
	('e79498f6-4bf4-401c-8da0-9d776744c363', '30000000-0000-0000-0000-000000000002', '099dc286-9fd2-4600-9cb9-db747300998e', '2026-08-27 14:50:12.367369', 46000.00, 'system', 'system', '2026-08-27 14:50:12.861183', '20000000-0000-0000-0000-000000000001'),
	('53a4f10a-9624-4b46-b999-3881bc82d30c', '30000000-0000-0000-0000-000000000001', '099dc286-9fd2-4600-9cb9-db747300998e', '2026-08-27 14:50:12.367369', 48000.00, 'system', 'system', '2026-08-27 14:50:12.861183', '20000000-0000-0000-0000-000000000001'),
	('1ea76f1c-bfa6-4476-b5f2-1380e6032a28', '30000000-0000-0000-0000-000000000001', '3d7b68f6-5884-41ce-9cd8-14ebde6bb119', '2026-08-27 14:50:12.367369', 72000.00, 'system', 'system', '2026-08-27 14:50:12.861183', '20000000-0000-0000-0000-000000000001'),
	('80f92882-a3a1-455a-8da5-b42ddbe1fb00', '30000000-0000-0000-0000-000000000003', '3701f559-5097-4324-b3c4-11f0cfb3614a', '2026-08-27 14:50:12.367369', 94000.00, 'system', 'system', '2026-08-27 14:50:12.861183', '20000000-0000-0000-0000-000000000001'),
	('345970ca-45cd-431e-907b-f3a15477905e', '30000000-0000-0000-0000-000000000001', '3701f559-5097-4324-b3c4-11f0cfb3614a', '2026-08-27 14:50:12.367369', 96000.00, 'system', 'system', '2026-08-27 14:50:12.861183', '20000000-0000-0000-0000-000000000001'),
	('d48ed537-e35c-4b54-9abf-012074e4a1ab', '30000000-0000-0000-0000-000000000003', '8320d921-6c2a-4b62-9655-acc681350f75', '2026-08-27 14:50:12.367369', 106000.00, 'system', 'system', '2026-08-27 14:50:12.861183', '20000000-0000-0000-0000-000000000001'),
	('8ce7e73c-39e9-4cf5-bc2a-5a59c5c96e8a', '30000000-0000-0000-0000-000000000001', '8320d921-6c2a-4b62-9655-acc681350f75', '2026-08-27 14:50:12.367369', 108000.00, 'system', 'system', '2026-08-27 14:50:12.861183', '20000000-0000-0000-0000-000000000001'),
	('51f47e9c-6c0a-4882-ae56-78d9cc7db056', '30000000-0000-0000-0000-000000000001', 'df295df8-6d91-408a-89a1-da3c69cd2c0d', '2026-08-27 14:50:12.367369', 90000.00, 'system', 'system', '2026-08-27 14:50:12.861183', '20000000-0000-0000-0000-000000000001'),
	('8fefa01e-4932-465c-8bb2-f2d06990ba51', '30000000-0000-0000-0000-000000000002', 'b619bab6-1c1a-4fc5-8f01-3c2e0dfa018e', '2026-08-27 14:50:12.367369', 22000.00, 'system', 'system', '2026-08-27 14:50:12.861183', '20000000-0000-0000-0000-000000000001'),
	('d5eba66f-eed1-498a-8e58-436dfb9de0f1', '30000000-0000-0000-0000-000000000002', '87278e0b-7b25-4860-ae58-29c32be0b6ed', '2026-08-27 14:50:12.367369', 65000.00, 'system', 'system', '2026-08-27 14:50:12.861183', '20000000-0000-0000-0000-000000000001') ON CONFLICT DO NOTHING;

-- r_permission
-- The action catalogue. max_scope_type is the deepest scope a role may hold the
-- permission at, not a privilege level: capped at SCHOOL it may sit in a platform or
-- school role but never a branch-owned one; capped at BRANCH it may sit in any.
--
-- There is deliberately no 'view branch staff' or 'view branch details' code. The
-- word branch there is the scope the role is granted at, not part of the action, so
-- staff:read at branch scope reads that branch's staff and the same code at school
-- scope reads all of them.
INSERT INTO public.r_permission (id, code, resource, action, max_scope_type, description) VALUES
	('40000000-0000-0000-0000-000000000001', 'branch:create', 'branch', 'create', 'SCHOOL', 'Create a branch or yard within the school'),
	('40000000-0000-0000-0000-000000000002', 'branch:manage-status', 'branch', 'manage-status', 'SCHOOL', 'Activate or deactivate a branch, and set which branch is the head office'),
	('40000000-0000-0000-0000-000000000003', 'branch-license-class:manage', 'branch-license-class', 'manage', 'BRANCH', 'Set which licence classes a branch offers and the price of each'),
	('40000000-0000-0000-0000-000000000004', 'staff:read', 'staff', 'read', 'BRANCH', 'View staff records and their branch assignments'),
	('40000000-0000-0000-0000-000000000005', 'branch:read', 'branch', 'read', 'BRANCH', 'View branch details, including contact numbers and licence class offerings'),
	('40000000-0000-0000-0000-000000000006', 'branch:update', 'branch', 'update', 'BRANCH', 'Update branch details such as name, address, type and contact numbers')
ON CONFLICT (code) DO UPDATE
SET resource = EXCLUDED.resource,
	action = EXCLUDED.action,
	max_scope_type = EXCLUDED.max_scope_type,
	description = EXCLUDED.description,
	updated_at = now(),
	updated_by = 'system';

-- m_role
-- One school super admin role per school. m_role is school-owned, so a SCHOOL scoped
-- row must name its school; there is no shared template role. is_system marks it as
-- provisioned by migration, so a school administrator cannot weaken or delete the
-- role that grants their own access.
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

-- x_role_permission
-- Every permission a school-scoped role is allowed to hold: capped at SCHOOL or
-- BRANCH, never PLATFORM. Selected rather than listed so the ceiling rule cannot be
-- got wrong, at the cost of granting any later permission to this role on re-run.
INSERT INTO public.x_role_permission (role_id, role_scope_type, permission_id, permission_max_scope_type)
SELECT role.id, role.scope_type, permission.id, permission.max_scope_type
FROM public.m_role role
CROSS JOIN public.r_permission permission
WHERE role.code = 'school-super-admin'
	AND role.scope_type = 'SCHOOL'
	AND permission.max_scope_type IN ('SCHOOL', 'BRANCH')
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- LOCAL AND DEMO ONLY, BELOW THIS LINE
--
-- The bootstrap administrator. Its password is committed to this repository, so any
-- environment loaded with it has a publicly known administrator account. Under
-- Liquibase this lives in the "demo" context and does not run by default; running
-- this file by hand loads it unconditionally, which is what you want on a local
-- database and never what you want anywhere else.
--
-- Username elven_super, password ElvenSuper@123.
-- ---------------------------------------------------------------------------

-- m_staff
INSERT INTO public.m_staff (id, school_id, employee_no, full_name, national_id, date_of_birth, designation, employment_status, phone_number, phone_number_e164, email, address, joined_on)
SELECT '60000000-0000-0000-0000-000000000001', school.id, 'E-0001', 'Elven Super Admin',
	'199012345678', DATE '1990-05-15', 'School Administrator', 'ACTIVE',
	'077 480 1100', '+94774801100', 'super.admin@elvendriving.lk',
	'Cotta Road, Rajagiriya, Sri Lanka', DATE '2026-01-01'
FROM public.m_school school
WHERE school.code = 'elven'
ON CONFLICT ON CONSTRAINT uk_staff_school_employee_no DO NOTHING;

-- m_identity
-- Stored lowercase because usernames are constrained to lower case; sign-in should
-- fold the entered value, so typing ELVEN_SUPER works. Hash is bcrypt cost 10.
INSERT INTO public.m_identity (id, school_id, platform_operator_id, staff_id, learner_id, username, phone_number, phone_number_e164, password_hash, display_name, status)
SELECT '70000000-0000-0000-0000-000000000001', staff.school_id, NULL, staff.id, NULL, 'elven_super',
	'077 480 1100', '+94774801100',
	'$2a$10$OfnRkLUdXhruJgcKC3I2NO536UZBvxBuQVoE9bPBRU09rluycVyXi',
	'Elven Super Admin', 'ACTIVE'
FROM public.m_staff staff
WHERE staff.id = '60000000-0000-0000-0000-000000000001'
ON CONFLICT ON CONSTRAINT uk_identity_username DO NOTHING;

-- t_identity_role_assignment
-- granted_by points at the account itself: the first administrator has nobody above
-- them, and granted_by is NOT NULL because every later grant must name a real granter.
INSERT INTO public.t_identity_role_assignment (identity_id, role_id, scope_type, school_id, branch_id, assignable_to, is_staff, staff_id, granted_by)
SELECT identity.id, role.id, 'SCHOOL', role.school_id, NULL, role.assignable_to, identity.is_staff,
	identity.staff_id, identity.id
FROM public.m_identity identity
JOIN public.m_role role
	ON role.school_id = identity.school_id
	AND role.code = 'school-super-admin'
	AND role.scope_type = 'SCHOOL'
WHERE identity.username = 'elven_super'
ON CONFLICT ON CONSTRAINT uk_identity_role_assignment_grant DO NOTHING;

COMMIT;
