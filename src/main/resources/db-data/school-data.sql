INSERT INTO school (
    id,
    code,
    name,
    short_name,
    established_year,
    hotline_href,
    whatsapp_href,
    email,
    tenant_status
)
VALUES (
    '20000000-0000-0000-0000-000000000001',
    'elven',
    'Elven Driving School',
    'Elven',
    1950,
    'tel:+94771234567',
    'https://wa.me/94771234567',
    'hello@elvendriving.lk',
    'ACTIVE'
)
ON CONFLICT (code) DO UPDATE
SET name = EXCLUDED.name,
    short_name = EXCLUDED.short_name,
    established_year = EXCLUDED.established_year,
    hotline_href = EXCLUDED.hotline_href,
    whatsapp_href = EXCLUDED.whatsapp_href,
    email = EXCLUDED.email,
    tenant_status = EXCLUDED.tenant_status,
    updated_at = now();

INSERT INTO school_contact_number (
    id,
    school_id,
    contact_type,
    phone_number,
    phone_number_e164,
    is_primary,
    display_order
)
SELECT
    '20000000-0000-0000-0000-000000000002',
    id,
    'HOTLINE',
    '077 123 4567',
    '+94771234567',
    true,
    1
FROM school
WHERE code = 'elven'
ON CONFLICT (school_id, phone_number) DO UPDATE
SET contact_type = EXCLUDED.contact_type,
    phone_number_e164 = EXCLUDED.phone_number_e164,
    is_primary = EXCLUDED.is_primary,
    display_order = EXCLUDED.display_order,
    updated_at = now();

INSERT INTO branch (
    id,
    school_id,
    code,
    name,
    branch_type,
    is_head_office,
    address
)
SELECT
    branch_seed.id,
    s.id,
    branch_seed.code,
    branch_seed.name,
    branch_seed.branch_type,
    branch_seed.is_head_office,
    branch_seed.address
FROM (
    VALUES
        ('30000000-0000-0000-0000-000000000001'::uuid, 'rajagiriya', 'Rajagiriya', 'BRANCH', true, 'Cotta Road, Rajagiriya, Sri Lanka'),
        ('30000000-0000-0000-0000-000000000002'::uuid, 'wellawatte', 'Wellawatte', 'BRANCH', false, 'Galle Road, Colombo 06, Sri Lanka'),
        ('30000000-0000-0000-0000-000000000003'::uuid, 'battaramulla', 'Battaramulla', 'BRANCH', false, 'Pannipitiya Road, Battaramulla, Sri Lanka'),
        ('30000000-0000-0000-0000-000000000004'::uuid, 'kaduwela-yard', 'Kaduwela Training Yard', 'YARD', false, 'Avissawella Road, Kaduwela, Sri Lanka')
) AS branch_seed(id, code, name, branch_type, is_head_office, address)
CROSS JOIN school s
WHERE s.code = 'elven'
ON CONFLICT (school_id, code) DO UPDATE
SET name = EXCLUDED.name,
    branch_type = EXCLUDED.branch_type,
    is_head_office = EXCLUDED.is_head_office,
    address = EXCLUDED.address,
    is_active = true,
    updated_at = now();

INSERT INTO branch_contact_number (
    id,
    branch_id,
    contact_type,
    phone_number,
    phone_number_e164,
    is_primary,
    display_order
)
SELECT
    contact_seed.id,
    contact_seed.branch_id,
    contact_seed.contact_type,
    contact_seed.phone_number,
    contact_seed.phone_number_e164,
    contact_seed.is_primary,
    contact_seed.display_order
FROM (
    SELECT '30000000-0000-0000-0000-000000000011'::uuid, b.id, 'GENERAL', '077 480 1120', '+94774801120', true, 1 FROM branch b WHERE b.code = 'rajagiriya'
    UNION ALL
    SELECT '30000000-0000-0000-0000-000000000012'::uuid, b.id, 'GENERAL', '077 480 1121', '+94774801121', true, 1 FROM branch b WHERE b.code = 'wellawatte'
    UNION ALL
    SELECT '30000000-0000-0000-0000-000000000013'::uuid, b.id, 'GENERAL', '077 480 1122', '+94774801122', true, 1 FROM branch b WHERE b.code = 'battaramulla'
    UNION ALL
    SELECT '30000000-0000-0000-0000-000000000014'::uuid, b.id, 'GENERAL', '077 480 1123', '+94774801123', true, 1 FROM branch b WHERE b.code = 'kaduwela-yard'
) AS contact_seed(id, branch_id, contact_type, phone_number, phone_number_e164, is_primary, display_order)
ON CONFLICT (branch_id, phone_number) DO UPDATE
SET contact_type = EXCLUDED.contact_type,
    phone_number_e164 = EXCLUDED.phone_number_e164,
    is_primary = EXCLUDED.is_primary,
    display_order = EXCLUDED.display_order,
    updated_at = now();

INSERT INTO license_class (
    id,
    code,
    name,
    display_order,
    included_class_codes,
    old_class_codes,
    source_url,
    description
)
VALUES
    (
        '10000000-0000-0000-0000-000000000001',
        'A1',
        'Light motor cycle',
        1,
        '["G1"]'::jsonb,
        '["D"]'::jsonb,
        'https://dmt.gov.lk/index.php?option=com_content&view=article&id=46&Itemid=163&lang=en',
        'Light motor cycles of which Engine Capacity does not exceeds 100CC'
    ),
    (
        '10000000-0000-0000-0000-000000000002',
        'A',
        'Motorcycle',
        2,
        '["A1", "G1"]'::jsonb,
        '["D"]'::jsonb,
        'https://dmt.gov.lk/index.php?option=com_content&view=article&id=46&Itemid=163&lang=en',
        'Motorcycles of which Engine capacity exceeds 100CC'
    ),
    (
        '10000000-0000-0000-0000-000000000003',
        'B1',
        'Motor tricycle or light van',
        3,
        '["G1"]'::jsonb,
        '["E", "F"]'::jsonb,
        'https://dmt.gov.lk/index.php?option=com_content&view=article&id=46&Itemid=163&lang=en',
        'Motor Tricycle or van of which tare does not exceed 500kg and Gross vehicle weight does not exceed 1000 kg: Motor vehicle in this class include an invalid carriage'
    ),
    (
        '10000000-0000-0000-0000-000000000004',
        'B',
        'Dual purpose motor vehicle',
        4,
        '["G1"]'::jsonb,
        '["C", "C1"]'::jsonb,
        'https://dmt.gov.lk/index.php?option=com_content&view=article&id=46&Itemid=163&lang=en',
        'Dual purpose Motor vehicle of which Gross Vehicle Weight does not exceed 3500kg and the seating capacity does not exceed 9 seats inclusive of the driver’s seat, which may be combined with a trailer of which maximum authorized tare does not exceed 750kg: Motor vehicle in this class include and invalid carriage and all cars where the seating capacity does not exceed 9 seats inclusive of the Driver’s seat.'
    ),
    (
        '10000000-0000-0000-0000-000000000005',
        'C1',
        'Light motor lorry',
        5,
        '["B", "G1"]'::jsonb,
        '["B1"]'::jsonb,
        'https://dmt.gov.lk/index.php?option=com_content&view=article&id=46&Itemid=163&lang=en',
        'Light Motor Lorry – Motor Lorry of which Gross Vehicle Weight exceeds 3500 kg and does not exceed 17000kg: Motor vehicles in this class may be combined with a trailer having maximum authorized tare which does not exceed 750kg: Motor vehicles of this class include a motor ambulance and motor hearses.'
    ),
    (
        '10000000-0000-0000-0000-000000000006',
        'C',
        'Motor lorry',
        6,
        '["C1", "B", "J", "G", "G1"]'::jsonb,
        '["B"]'::jsonb,
        'https://dmt.gov.lk/index.php?option=com_content&view=article&id=46&Itemid=163&lang=en',
        'Motor Lorry of which Gross vehicle Weight is more than 1700kg; may be combine with a trailer having a maximum authorized tare which does not exceed 750kg'
    ),
    (
        '10000000-0000-0000-0000-000000000007',
        'CE',
        'Heavy motor lorry with trailer',
        7,
        '["C", "C1", "B", "B1", "G", "G1", "J"]'::jsonb,
        '["B"]'::jsonb,
        'https://dmt.gov.lk/index.php?option=com_content&view=article&id=46&Itemid=163&lang=en',
        'Heavy Motor Lorry; combination of motor lorry and trailer (s) including articulated vehicles and its trailer (s) of which maximum authorized tare of the trailer exceeds 750kg and gross vehicle weight exceeds 3500kg'
    ),
    (
        '10000000-0000-0000-0000-000000000008',
        'D1',
        'Light motor coach',
        8,
        '["C1", "B", "B1", "G", "G1"]'::jsonb,
        '["A1"]'::jsonb,
        'https://dmt.gov.lk/index.php?option=com_content&view=article&id=46&Itemid=163&lang=en',
        'Light Motor Coach- Motor vehicles used for the carriage of persons and having seating capacity of not less than 9 seats and not more than 33 seats inclusive of the driver’s seat; motor vehicle in this class may be combined with a trailer having a maximum authorized tare which does not exceed 750kg'
    ),
    (
        '10000000-0000-0000-0000-000000000009',
        'D',
        'Motor coach',
        9,
        '["D1", "C", "C1", "B", "B1", "G", "G1", "J"]'::jsonb,
        '["A"]'::jsonb,
        'https://dmt.gov.lk/index.php?option=com_content&view=article&id=46&Itemid=163&lang=en',
        'Motor Coach where the seating capacity does not exceed 33 seats inclusive of the driver’s seat; motor vehicles in this class may be combined with a trailer having a maximum authorized tare which does not exceed 750kg'
    ),
    (
        '10000000-0000-0000-0000-000000000010',
        'DE',
        'Heavy motor coach with trailer',
        10,
        '["D", "D1", "C", "C1", "CE", "B", "B1", "G", "G1", "J"]'::jsonb,
        '[]'::jsonb,
        'https://dmt.gov.lk/index.php?option=com_content&view=article&id=46&Itemid=163&lang=en',
        'Heavy Motor Coach – Combination of motor coach having a seating capacity of 33 seats inclusive of the driver’s seat and it’s trailer having maximum authorized tare exceeding 750kg or a combination of two motor coaches'
    ),
    (
        '10000000-0000-0000-0000-000000000011',
        'G1',
        'Hand tractor',
        11,
        '[]'::jsonb,
        '["G1"]'::jsonb,
        'https://dmt.gov.lk/index.php?option=com_content&view=article&id=46&Itemid=163&lang=en',
        'Hand Tractors - Two Wheel Tractor with a Trailer'
    ),
    (
        '10000000-0000-0000-0000-000000000012',
        'G',
        'Agricultural land vehicle',
        12,
        '["G1"]'::jsonb,
        '["G"]'::jsonb,
        'https://dmt.gov.lk/index.php?option=com_content&view=article&id=46&Itemid=163&lang=en',
        'Land Vehicle - Agricultural Land Vehicle with or without a trailer'
    ),
    (
        '10000000-0000-0000-0000-000000000013',
        'J',
        'Special purpose vehicle',
        13,
        '["G1"]'::jsonb,
        '[]'::jsonb,
        'https://dmt.gov.lk/index.php?option=com_content&view=article&id=46&Itemid=163&lang=en',
        'Special purpose Vehicle, Vehicle used for construction, loading & unloading excluding motor lorries, light motor lorries and heavy motor lorries, equipped with construction equipment and equipment for loading and unloading goods'
    )
ON CONFLICT (code) DO UPDATE
SET name = EXCLUDED.name,
    display_order = EXCLUDED.display_order,
    included_class_codes = EXCLUDED.included_class_codes,
    old_class_codes = EXCLUDED.old_class_codes,
    source_url = EXCLUDED.source_url,
    description = EXCLUDED.description,
    updated_at = now();

INSERT INTO branch_license_class (branch_id, license_class_id, price_lkr)
SELECT b.id, lc.id, offering.price_lkr
FROM (
    VALUES
        ('rajagiriya', 'A1', 18000),
        ('rajagiriya', 'A', 26000),
        ('rajagiriya', 'B1', 30000),
        ('rajagiriya', 'B', 48000),
        ('rajagiriya', 'C1', 72000),
        ('rajagiriya', 'C', 96000),
        ('rajagiriya', 'CE', 108000),
        ('rajagiriya', 'D1', 90000),
        ('wellawatte', 'A1', 17500),
        ('wellawatte', 'A', 25500),
        ('wellawatte', 'B1', 29000),
        ('wellawatte', 'B', 46000),
        ('wellawatte', 'G1', 22000),
        ('wellawatte', 'J', 65000),
        ('battaramulla', 'B', 47000),
        ('battaramulla', 'C', 94000),
        ('battaramulla', 'CE', 106000),
        ('kaduwela-yard', 'A', 24000),
        ('kaduwela-yard', 'G1', 20000),
        ('kaduwela-yard', 'G', 36000)
) AS offering(branch_code, license_class_code, price_lkr)
JOIN branch b ON b.code = offering.branch_code
JOIN license_class lc ON lc.code = offering.license_class_code
ON CONFLICT (branch_id, license_class_id) DO UPDATE
SET price_lkr = EXCLUDED.price_lkr;
