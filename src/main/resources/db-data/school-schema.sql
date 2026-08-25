CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS school (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code varchar(64) NOT NULL,
    name varchar(160) NOT NULL,
    short_name varchar(80) NOT NULL,
    established_year smallint NOT NULL,
    hotline_href varchar(64) NOT NULL,
    whatsapp_href varchar(128) NOT NULL,
    email varchar(254) NOT NULL,
    singleton_key boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by uuid DEFAULT '00000000-0000-0000-0000-000000000001'::uuid NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by uuid DEFAULT '00000000-0000-0000-0000-000000000001'::uuid NOT NULL,
    CONSTRAINT pk_school PRIMARY KEY (id),
    CONSTRAINT uk_school_code UNIQUE (code),
    CONSTRAINT uk_school_singleton UNIQUE (singleton_key),
    CONSTRAINT ck_school_singleton_key_true CHECK (singleton_key = true),
    CONSTRAINT ck_school_established_year CHECK (established_year IS NULL OR established_year BETWEEN 1800 AND 9999),
    CONSTRAINT ck_school_email_format CHECK (email IS NULL OR email ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$'),
    CONSTRAINT ck_school_code_format CHECK (code ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
    CONSTRAINT ck_school_name_not_blank CHECK (btrim(name) <> ''),
    CONSTRAINT ck_school_short_name_not_blank CHECK (btrim(short_name) <> ''),
    CONSTRAINT ck_school_hotline_href_format CHECK (hotline_href ~ '^tel:\+[1-9][0-9]{7,14}$'),
    CONSTRAINT ck_school_whatsapp_href_format CHECK (whatsapp_href ~ '^https://wa\.me/[1-9][0-9]{7,14}$'),
    CONSTRAINT ck_school_timestamps CHECK (updated_at >= created_at)
);

CREATE TABLE IF NOT EXISTS branch (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    code varchar(64) NOT NULL,
    name varchar(160) NOT NULL,
    branch_type varchar(32) DEFAULT 'BRANCH' NOT NULL,
    address varchar(255) NOT NULL,
    is_head_office boolean DEFAULT false NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by uuid DEFAULT '00000000-0000-0000-0000-000000000001'::uuid NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by uuid DEFAULT '00000000-0000-0000-0000-000000000001'::uuid NOT NULL,
    CONSTRAINT pk_branch PRIMARY KEY (id),
    CONSTRAINT fk_branch_school FOREIGN KEY (school_id) REFERENCES school (id) ON DELETE RESTRICT,
    CONSTRAINT uk_branch_school_code UNIQUE (school_id, code),
    CONSTRAINT ck_branch_type CHECK (branch_type IN ('BRANCH', 'YARD')),
    CONSTRAINT ck_branch_code_format CHECK (code ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
    CONSTRAINT ck_branch_name_not_blank CHECK (btrim(name) <> ''),
    CONSTRAINT ck_branch_address_not_blank CHECK (btrim(address) <> ''),
    CONSTRAINT ck_branch_timestamps CHECK (updated_at >= created_at)
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_branch_one_head_office_per_school
    ON branch (school_id)
    WHERE is_head_office;

CREATE TABLE IF NOT EXISTS license_class (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code varchar(64) NOT NULL,
    name varchar(120) NOT NULL,
    display_order integer NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by uuid DEFAULT '00000000-0000-0000-0000-000000000001'::uuid NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by uuid DEFAULT '00000000-0000-0000-0000-000000000001'::uuid NOT NULL,
    included_class_codes jsonb DEFAULT '[]'::jsonb NOT NULL,
    old_class_codes jsonb DEFAULT '[]'::jsonb NOT NULL,
    source_url varchar(512) NOT NULL,
    description text NOT NULL,
    CONSTRAINT pk_license_class PRIMARY KEY (id),
    CONSTRAINT uk_license_class_code UNIQUE (code),
    CONSTRAINT uk_license_class_display_order UNIQUE (display_order),
    CONSTRAINT ck_license_class_display_order_positive CHECK (display_order > 0),
    CONSTRAINT ck_license_class_code_format CHECK (code ~ '^[A-Z][A-Z0-9]*$'),
    CONSTRAINT ck_license_class_name_not_blank CHECK (btrim(name) <> ''),
    CONSTRAINT ck_license_class_description_not_blank CHECK (btrim(description) <> ''),
    CONSTRAINT ck_license_class_source_url_format CHECK (source_url ~ '^https?://.+'),
    CONSTRAINT ck_license_class_included_codes_array CHECK (jsonb_typeof(included_class_codes) = 'array'),
    CONSTRAINT ck_license_class_old_codes_array CHECK (jsonb_typeof(old_class_codes) = 'array'),
    CONSTRAINT ck_license_class_timestamps CHECK (updated_at >= created_at)
);

CREATE TABLE IF NOT EXISTS school_contact_number (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    contact_type varchar(32) DEFAULT 'GENERAL' NOT NULL,
    phone_number varchar(32) NOT NULL,
    phone_number_e164 varchar(16) NOT NULL,
    is_primary boolean DEFAULT false NOT NULL,
    display_order integer DEFAULT 1 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by uuid DEFAULT '00000000-0000-0000-0000-000000000001'::uuid NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by uuid DEFAULT '00000000-0000-0000-0000-000000000001'::uuid NOT NULL,
    CONSTRAINT pk_school_contact_number PRIMARY KEY (id),
    CONSTRAINT fk_school_contact_number_school FOREIGN KEY (school_id) REFERENCES school (id) ON DELETE CASCADE,
    CONSTRAINT uk_school_contact_number_school_phone UNIQUE (school_id, phone_number),
    CONSTRAINT uk_school_contact_number_school_display_order UNIQUE (school_id, display_order),
    CONSTRAINT ck_school_contact_number_type CHECK (contact_type IN ('GENERAL', 'HOTLINE', 'WHATSAPP')),
    CONSTRAINT ck_school_contact_number_display_order_positive CHECK (display_order > 0),
    CONSTRAINT ck_school_contact_number_phone_not_blank CHECK (btrim(phone_number) <> ''),
    CONSTRAINT ck_school_contact_number_phone_format CHECK (phone_number ~ '^[0-9 +()-]+$'),
    CONSTRAINT ck_school_contact_number_e164_format CHECK (phone_number_e164 ~ '^\+[1-9][0-9]{7,14}$'),
    CONSTRAINT ck_school_contact_number_timestamps CHECK (updated_at >= created_at)
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_school_contact_number_primary_per_school
    ON school_contact_number (school_id)
    WHERE is_primary;

CREATE TABLE IF NOT EXISTS branch_contact_number (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    branch_id uuid NOT NULL,
    contact_type varchar(32) DEFAULT 'GENERAL' NOT NULL,
    phone_number varchar(32) NOT NULL,
    phone_number_e164 varchar(16) NOT NULL,
    is_primary boolean DEFAULT false NOT NULL,
    display_order integer DEFAULT 1 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by uuid DEFAULT '00000000-0000-0000-0000-000000000001'::uuid NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by uuid DEFAULT '00000000-0000-0000-0000-000000000001'::uuid NOT NULL,
    CONSTRAINT pk_branch_contact_number PRIMARY KEY (id),
    CONSTRAINT fk_branch_contact_number_branch FOREIGN KEY (branch_id) REFERENCES branch (id) ON DELETE CASCADE,
    CONSTRAINT uk_branch_contact_number_branch_phone UNIQUE (branch_id, phone_number),
    CONSTRAINT uk_branch_contact_number_branch_display_order UNIQUE (branch_id, display_order),
    CONSTRAINT ck_branch_contact_number_type CHECK (contact_type IN ('GENERAL', 'HOTLINE', 'WHATSAPP')),
    CONSTRAINT ck_branch_contact_number_display_order_positive CHECK (display_order > 0),
    CONSTRAINT ck_branch_contact_number_phone_not_blank CHECK (btrim(phone_number) <> ''),
    CONSTRAINT ck_branch_contact_number_phone_format CHECK (phone_number ~ '^[0-9 +()-]+$'),
    CONSTRAINT ck_branch_contact_number_e164_format CHECK (phone_number_e164 ~ '^\+[1-9][0-9]{7,14}$'),
    CONSTRAINT ck_branch_contact_number_timestamps CHECK (updated_at >= created_at)
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_branch_contact_number_primary_per_branch
    ON branch_contact_number (branch_id)
    WHERE is_primary;

CREATE TABLE IF NOT EXISTS branch_license_class (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    branch_id uuid NOT NULL,
    license_class_id uuid NOT NULL,
    price_lkr numeric(12,2) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by uuid DEFAULT '00000000-0000-0000-0000-000000000001'::uuid NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by uuid DEFAULT '00000000-0000-0000-0000-000000000001'::uuid NOT NULL,
    CONSTRAINT pk_branch_license_class PRIMARY KEY (id),
    CONSTRAINT fk_branch_license_class_branch FOREIGN KEY (branch_id) REFERENCES branch (id) ON DELETE CASCADE,
    CONSTRAINT fk_branch_license_class_license_class FOREIGN KEY (license_class_id) REFERENCES license_class (id) ON DELETE RESTRICT,
    CONSTRAINT uk_branch_license_class_branch_license_class UNIQUE (branch_id, license_class_id),
    CONSTRAINT ck_branch_license_class_timestamps CHECK (updated_at >= created_at),
    CONSTRAINT ck_branch_license_class_price_lkr_positive CHECK (price_lkr > 0)
);
