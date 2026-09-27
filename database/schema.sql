-- =============================================================================
-- MediScribe AI — Production PostgreSQL 16 Schema
-- =============================================================================
-- PostgreSQL 16 | Supabase Compatible | UUID PKs | 3NF | RLS-Ready
-- Generated: 2026-06-24
-- =============================================================================


-- =============================================================================
-- EXTENSIONS
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";        -- gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";       -- uuid_generate_v4() fallback
CREATE EXTENSION IF NOT EXISTS "pg_trgm";         -- Trigram fuzzy search on medicine names
CREATE EXTENSION IF NOT EXISTS "unaccent";        -- Accent-insensitive search (multilingual)
CREATE EXTENSION IF NOT EXISTS "btree_gin";       -- GIN indexes on scalar types


-- =============================================================================
-- SCHEMAS
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS auth_ext;   -- Extended auth (profiles) — avoids Supabase auth schema conflicts
CREATE SCHEMA IF NOT EXISTS rx;         -- Prescriptions
CREATE SCHEMA IF NOT EXISTS ocr;        -- OCR processing
CREATE SCHEMA IF NOT EXISTS med;        -- Medicine catalog
CREATE SCHEMA IF NOT EXISTS sched;      -- Medicine schedules
CREATE SCHEMA IF NOT EXISTS remind;     -- Reminders & dose logs
CREATE SCHEMA IF NOT EXISTS safety;     -- Drug interactions
CREATE SCHEMA IF NOT EXISTS i18n;       -- Multilingual explanations
CREATE SCHEMA IF NOT EXISTS care;       -- Caregiver support
CREATE SCHEMA IF NOT EXISTS notify;     -- Notification channels & logs


-- =============================================================================
-- ENUM TYPES
-- =============================================================================

-- User roles
CREATE TYPE public.user_role AS ENUM (
    'patient',
    'caregiver',
    'admin'
);

-- Prescription status
CREATE TYPE public.prescription_status AS ENUM (
    'active',
    'expired',
    'archived'
);

-- OCR job status
CREATE TYPE public.ocr_status AS ENUM (
    'queued',
    'processing',
    'completed',
    'failed'
);

-- Medicine dosage form
CREATE TYPE public.medicine_form AS ENUM (
    'tablet',
    'capsule',
    'syrup',
    'injection',
    'patch',
    'inhaler',
    'drops',
    'cream',
    'powder',
    'gel',
    'suppository',
    'other'
);

-- Administration route
CREATE TYPE public.admin_route AS ENUM (
    'oral',
    'topical',
    'intravenous',
    'intramuscular',
    'subcutaneous',
    'inhalation',
    'sublingual',
    'rectal',
    'ophthalmic',
    'otic',
    'nasal',
    'other'
);

-- Schedule recurrence
CREATE TYPE public.recurrence_type AS ENUM (
    'daily',
    'weekly',
    'monthly',
    'custom',
    'as_needed'
);

-- Reminder / dose log outcome
CREATE TYPE public.reminder_status AS ENUM (
    'pending',
    'sent',
    'acknowledged',
    'snoozed',
    'missed',
    'skipped'
);

CREATE TYPE public.dose_action AS ENUM (
    'taken',
    'skipped',
    'missed',
    'snoozed',
    'rescheduled'
);

-- Drug interaction severity
CREATE TYPE public.interaction_severity AS ENUM (
    'minor',
    'moderate',
    'major',
    'contraindicated'
);

CREATE TYPE public.evidence_level AS ENUM (
    'theoretical',
    'case_report',
    'clinical_study',
    'established'
);

-- Alert status
CREATE TYPE public.alert_status AS ENUM (
    'active',
    'acknowledged',
    'overridden',
    'resolved'
);

-- Caregiver relationship type
CREATE TYPE public.relationship_type AS ENUM (
    'spouse',
    'parent',
    'child',
    'sibling',
    'nurse',
    'doctor',
    'other'
);

-- Caregiver access level
CREATE TYPE public.access_level AS ENUM (
    'read',
    'write',
    'admin'
);

-- Caregiver relationship status
CREATE TYPE public.relationship_status AS ENUM (
    'pending',
    'active',
    'revoked',
    'expired'
);

-- Notification delivery status
CREATE TYPE public.notification_status AS ENUM (
    'queued',
    'sent',
    'delivered',
    'failed',
    'bounced'
);

-- Gender
CREATE TYPE public.gender_type AS ENUM (
    'male',
    'female',
    'other',
    'prefer_not_to_say'
);


-- =============================================================================
-- TRIGGER FUNCTION — auto-update updated_at
-- =============================================================================

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


-- =============================================================================
-- MODULE: AUTHENTICATION (auth_ext schema)
-- Note: auth.users is managed by Supabase. We extend it here.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- TABLE: auth_ext.user_profiles
-- ---------------------------------------------------------------------------
CREATE TABLE auth_ext.user_profiles (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID        NOT NULL UNIQUE,   -- FK → auth.users(id) — Supabase managed
    full_name           TEXT        NOT NULL,
    phone               TEXT        UNIQUE,            -- Unique phone per user for local auth
    hashed_password     TEXT,                          -- bcrypt hash for local (non-Supabase) auth
    locale              TEXT        NOT NULL DEFAULT 'en',
    role                public.user_role NOT NULL DEFAULT 'patient',
    date_of_birth       DATE,
    gender              public.gender_type,
    blood_group         TEXT,
    allergies           TEXT[]      NOT NULL DEFAULT '{}',
    chronic_conditions  TEXT[]      NOT NULL DEFAULT '{}',
    avatar_url          TEXT,
    is_active           BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_profile_phone_format
        CHECK (phone IS NULL OR phone ~ '^\+[1-9]\d{6,14}$'),
    CONSTRAINT chk_profile_locale_format
        CHECK (locale ~ '^[a-z]{2,3}(-[A-Z]{2,4})?$')
);

COMMENT ON TABLE  auth_ext.user_profiles IS 'Extended profile data for Supabase auth users.';
COMMENT ON COLUMN auth_ext.user_profiles.allergies IS 'Array of known allergen names or ICD-10 codes.';
COMMENT ON COLUMN auth_ext.user_profiles.chronic_conditions IS 'Array of chronic condition labels or ICD-10 codes.';

CREATE TRIGGER trg_user_profiles_updated_at
    BEFORE UPDATE ON auth_ext.user_profiles
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


-- =============================================================================
-- MODULE: MEDICINES (med schema)
-- =============================================================================

-- ---------------------------------------------------------------------------
-- TABLE: med.medicines
-- ---------------------------------------------------------------------------
CREATE TABLE med.medicines (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    name            TEXT        NOT NULL,
    generic_name    TEXT        NOT NULL,
    brand_name      TEXT,
    manufacturer    TEXT,
    drug_class      TEXT,
    form            public.medicine_form,
    strength        TEXT,
    unit            TEXT,
    is_otc          BOOLEAN     NOT NULL DEFAULT FALSE,
    is_controlled   BOOLEAN     NOT NULL DEFAULT FALSE,
    is_active       BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by      UUID,                              -- FK → auth.users(id)

    CONSTRAINT chk_medicines_name_notempty
        CHECK (TRIM(name) <> ''),
    CONSTRAINT chk_medicines_generic_notempty
        CHECK (TRIM(generic_name) <> '')
);

COMMENT ON TABLE  med.medicines IS 'Canonical, deduplicated medicine catalog (shared across all users).';
COMMENT ON COLUMN med.medicines.is_controlled IS 'TRUE if this is a scheduled/controlled substance.';

CREATE TRIGGER trg_medicines_updated_at
    BEFORE UPDATE ON med.medicines
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ---------------------------------------------------------------------------
-- TABLE: med.medicine_aliases
-- ---------------------------------------------------------------------------
CREATE TABLE med.medicine_aliases (
    id          UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
    medicine_id UUID    NOT NULL
                        REFERENCES med.medicines(id) ON DELETE CASCADE,
    alias       TEXT    NOT NULL,
    locale      TEXT    NOT NULL DEFAULT 'en',

    CONSTRAINT chk_alias_notempty CHECK (TRIM(alias) <> ''),
    CONSTRAINT uq_medicine_alias_locale UNIQUE (medicine_id, alias, locale)
);

COMMENT ON TABLE med.medicine_aliases IS 'Alternative names, spellings, and locale-specific aliases for medicines.';


-- =============================================================================
-- MODULE: MULTILINGUAL EXPLANATIONS (i18n schema)
-- (Defined early — referenced by notify.notification_templates)
-- =============================================================================

-- ---------------------------------------------------------------------------
-- TABLE: i18n.languages
-- ---------------------------------------------------------------------------
CREATE TABLE i18n.languages (
    id        UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
    code      TEXT    NOT NULL UNIQUE,    -- BCP-47: 'en', 'hi', 'ta', 'ar', 'fr'
    name      TEXT    NOT NULL,           -- English display name
    script    TEXT,                       -- 'Latin', 'Devanagari', 'Tamil', 'Arabic'
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT chk_language_code_format
        CHECK (code ~ '^[a-z]{2,3}(-[A-Z]{2,4})?$')
);

COMMENT ON TABLE i18n.languages IS 'Supported BCP-47 language codes for multilingual content.';

-- Seed core languages
INSERT INTO i18n.languages (code, name, script) VALUES
    ('en',    'English',    'Latin'),
    ('hi',    'Hindi',      'Devanagari'),
    ('ta',    'Tamil',      'Tamil'),
    ('te',    'Telugu',     'Telugu'),
    ('kn',    'Kannada',    'Kannada'),
    ('ml',    'Malayalam',  'Malayalam'),
    ('mr',    'Marathi',    'Devanagari'),
    ('bn',    'Bengali',    'Bengali'),
    ('gu',    'Gujarati',   'Gujarati'),
    ('pa',    'Punjabi',    'Gurmukhi'),
    ('ur',    'Urdu',       'Nastaliq'),
    ('ar',    'Arabic',     'Arabic'),
    ('fr',    'French',     'Latin'),
    ('de',    'German',     'Latin'),
    ('es',    'Spanish',    'Latin'),
    ('zh-CN', 'Chinese (Simplified)', 'Han')
ON CONFLICT (code) DO NOTHING;

-- ---------------------------------------------------------------------------
-- TABLE: i18n.medicine_explanations
-- ---------------------------------------------------------------------------
CREATE TABLE i18n.medicine_explanations (
    id                   UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    medicine_id          UUID        NOT NULL
                                     REFERENCES med.medicines(id) ON DELETE CASCADE,
    language_id          UUID        NOT NULL
                                     REFERENCES i18n.languages(id),
    usage_description    TEXT,
    side_effects         TEXT,
    precautions          TEXT,
    storage_instructions TEXT,
    is_verified          BOOLEAN     NOT NULL DEFAULT FALSE,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by           UUID,                              -- FK → auth.users(id)

    CONSTRAINT uq_medicine_explanation_lang
        UNIQUE (medicine_id, language_id)
);

COMMENT ON COLUMN i18n.medicine_explanations.is_verified
    IS 'TRUE if explanation has been reviewed by a medical professional.';

CREATE TRIGGER trg_medicine_explanations_updated_at
    BEFORE UPDATE ON i18n.medicine_explanations
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


-- =============================================================================
-- MODULE: PRESCRIPTIONS (rx schema)
-- =============================================================================

-- ---------------------------------------------------------------------------
-- TABLE: rx.prescriptions
-- ---------------------------------------------------------------------------
CREATE TABLE rx.prescriptions (
    id               UUID                     PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id          UUID                     NOT NULL,   -- FK → auth.users(id)
    caregiver_id     UUID,                               -- FK → auth.users(id) — uploaded by caregiver
    title            TEXT,
    doctor_name      TEXT,
    hospital_name    TEXT,
    prescribed_date  DATE,
    valid_until      DATE,
    status           public.prescription_status NOT NULL DEFAULT 'active',
    raw_notes        TEXT,
    created_at       TIMESTAMPTZ              NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ              NOT NULL DEFAULT NOW(),
    created_by       UUID,                               -- FK → auth.users(id)

    CONSTRAINT chk_prescription_dates
        CHECK (valid_until IS NULL OR prescribed_date IS NULL OR valid_until >= prescribed_date)
);

COMMENT ON TABLE rx.prescriptions IS 'Top-level prescription records belonging to a patient.';
COMMENT ON COLUMN rx.prescriptions.caregiver_id IS 'Set when a caregiver uploaded or created the prescription on behalf of the patient.';

CREATE TRIGGER trg_prescriptions_updated_at
    BEFORE UPDATE ON rx.prescriptions
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ---------------------------------------------------------------------------
-- TABLE: rx.prescription_images
-- ---------------------------------------------------------------------------
CREATE TABLE rx.prescription_images (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    prescription_id UUID        NOT NULL
                                REFERENCES rx.prescriptions(id) ON DELETE CASCADE,
    storage_path    TEXT        NOT NULL,
    mime_type       TEXT        NOT NULL,
    file_size_bytes INTEGER,
    page_number     INTEGER     NOT NULL DEFAULT 1,
    uploaded_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_image_page_positive   CHECK (page_number >= 1),
    CONSTRAINT chk_image_size_positive   CHECK (file_size_bytes IS NULL OR file_size_bytes > 0),
    CONSTRAINT chk_image_mime_type
        CHECK (mime_type IN ('image/jpeg','image/png','image/webp','image/heic','application/pdf'))
);

COMMENT ON TABLE rx.prescription_images IS 'Uploaded prescription images or PDF pages stored in Supabase Storage.';

-- ---------------------------------------------------------------------------
-- TABLE: rx.prescription_medicines  (junction: prescription × medicine)
-- ---------------------------------------------------------------------------
CREATE TABLE rx.prescription_medicines (
    id                   UUID               PRIMARY KEY DEFAULT gen_random_uuid(),
    prescription_id      UUID               NOT NULL
                                            REFERENCES rx.prescriptions(id) ON DELETE CASCADE,
    medicine_id          UUID               NOT NULL
                                            REFERENCES med.medicines(id),
    dosage               TEXT,
    frequency            TEXT,
    route                public.admin_route NOT NULL DEFAULT 'oral',
    instructions         TEXT,
    duration_days        INTEGER,
    start_date           DATE,
    end_date             DATE,
    quantity_prescribed  INTEGER,
    refills_allowed      INTEGER            NOT NULL DEFAULT 0,

    CONSTRAINT chk_rx_med_duration_positive   CHECK (duration_days IS NULL OR duration_days > 0),
    CONSTRAINT chk_rx_med_quantity_positive   CHECK (quantity_prescribed IS NULL OR quantity_prescribed > 0),
    CONSTRAINT chk_rx_med_refills_nonneg      CHECK (refills_allowed >= 0),
    CONSTRAINT chk_rx_med_dates
        CHECK (end_date IS NULL OR start_date IS NULL OR end_date >= start_date)
);

COMMENT ON TABLE rx.prescription_medicines IS 'Line items linking a prescription to specific medicines with dosage instructions.';

-- ---------------------------------------------------------------------------
-- TABLE: i18n.prescription_explanations
-- ---------------------------------------------------------------------------
CREATE TABLE i18n.prescription_explanations (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    prescription_id UUID        NOT NULL
                                REFERENCES rx.prescriptions(id) ON DELETE CASCADE,
    language_id     UUID        NOT NULL
                                REFERENCES i18n.languages(id),
    summary         TEXT,
    instructions    TEXT,
    is_ai_generated BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_prescription_explanation_lang
        UNIQUE (prescription_id, language_id)
);

COMMENT ON COLUMN i18n.prescription_explanations.is_ai_generated
    IS 'TRUE if content was generated by an LLM; FALSE if written/reviewed by a human.';

CREATE TRIGGER trg_prescription_explanations_updated_at
    BEFORE UPDATE ON i18n.prescription_explanations
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


-- =============================================================================
-- MODULE: OCR PROCESSING (ocr schema)
-- =============================================================================

-- ---------------------------------------------------------------------------
-- TABLE: ocr.ocr_jobs
-- ---------------------------------------------------------------------------
CREATE TABLE ocr.ocr_jobs (
    id                      UUID              PRIMARY KEY DEFAULT gen_random_uuid(),
    prescription_image_id   UUID              NOT NULL
                                              REFERENCES rx.prescription_images(id) ON DELETE CASCADE,
    user_id                 UUID              NOT NULL,   -- FK → auth.users(id)
    status                  public.ocr_status NOT NULL DEFAULT 'queued',
    engine_used             TEXT,
    confidence_score        REAL,
    raw_text                TEXT,
    structured_data         JSONB,
    error_message           TEXT,
    started_at              TIMESTAMPTZ,
    completed_at            TIMESTAMPTZ,
    created_at              TIMESTAMPTZ       NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_ocr_confidence_range
        CHECK (confidence_score IS NULL OR confidence_score BETWEEN 0 AND 1),
    CONSTRAINT chk_ocr_completed_after_started
        CHECK (completed_at IS NULL OR started_at IS NULL OR completed_at >= started_at)
);

COMMENT ON TABLE ocr.ocr_jobs IS 'OCR processing jobs for prescription images. Multiple attempts per image are allowed.';
COMMENT ON COLUMN ocr.ocr_jobs.structured_data IS 'Parsed JSON output: medicines, doses, frequencies extracted by OCR engine.';

-- ---------------------------------------------------------------------------
-- TABLE: ocr.ocr_corrections
-- ---------------------------------------------------------------------------
CREATE TABLE ocr.ocr_corrections (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    ocr_job_id      UUID        NOT NULL
                                REFERENCES ocr.ocr_jobs(id) ON DELETE CASCADE,
    corrected_by    UUID        NOT NULL,                -- FK → auth.users(id)
    original_text   TEXT        NOT NULL,
    corrected_text  TEXT        NOT NULL,
    corrected_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_ocr_correction_different
        CHECK (original_text <> corrected_text)
);

COMMENT ON TABLE ocr.ocr_corrections IS 'Human-in-the-loop corrections applied to OCR output.';


-- =============================================================================
-- MODULE: MEDICINE SCHEDULES (sched schema)
-- =============================================================================

-- ---------------------------------------------------------------------------
-- TABLE: sched.medicine_schedules
-- ---------------------------------------------------------------------------
CREATE TABLE sched.medicine_schedules (
    id                        UUID                    PRIMARY KEY DEFAULT gen_random_uuid(),
    prescription_medicine_id  UUID                    NOT NULL
                                                      REFERENCES rx.prescription_medicines(id) ON DELETE CASCADE,
    user_id                   UUID                    NOT NULL,   -- FK → auth.users(id)
    schedule_name             TEXT,
    recurrence_type           public.recurrence_type  NOT NULL DEFAULT 'daily',
    recurrence_rule           JSONB,
    dose_time                 TIME WITHOUT TIME ZONE,
    dose_amount               TEXT,
    is_active                 BOOLEAN                 NOT NULL DEFAULT TRUE,
    created_at                TIMESTAMPTZ             NOT NULL DEFAULT NOW(),
    updated_at                TIMESTAMPTZ             NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE sched.medicine_schedules IS 'Repeating dose schedules generated from a prescription medicine line item.';
COMMENT ON COLUMN sched.medicine_schedules.recurrence_rule IS 'RFC 5545 RRULE subset as JSON, e.g. {freq:"weekly", byday:["MO","WE","FR"]}.';

CREATE TRIGGER trg_medicine_schedules_updated_at
    BEFORE UPDATE ON sched.medicine_schedules
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ---------------------------------------------------------------------------
-- TABLE: sched.schedule_exceptions
-- ---------------------------------------------------------------------------
CREATE TABLE sched.schedule_exceptions (
    id                   UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    medicine_schedule_id UUID        NOT NULL
                                     REFERENCES sched.medicine_schedules(id) ON DELETE CASCADE,
    exception_date       DATE        NOT NULL,
    reason               TEXT,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_schedule_exception_date
        UNIQUE (medicine_schedule_id, exception_date)
);

COMMENT ON TABLE sched.schedule_exceptions IS 'Specific dates on which a scheduled dose should be skipped.';


-- =============================================================================
-- MODULE: REMINDERS (remind schema)
-- =============================================================================

-- ---------------------------------------------------------------------------
-- TABLE: remind.reminders
-- ---------------------------------------------------------------------------
CREATE TABLE remind.reminders (
    id                   UUID                   PRIMARY KEY DEFAULT gen_random_uuid(),
    medicine_schedule_id UUID                   NOT NULL
                                                REFERENCES sched.medicine_schedules(id) ON DELETE CASCADE,
    user_id              UUID                   NOT NULL,   -- FK → auth.users(id)
    scheduled_at         TIMESTAMPTZ            NOT NULL,
    status               public.reminder_status NOT NULL DEFAULT 'pending',
    snooze_count         INTEGER                NOT NULL DEFAULT 0,
    snoozed_until        TIMESTAMPTZ,
    acknowledged_at      TIMESTAMPTZ,
    created_at           TIMESTAMPTZ            NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ            NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_reminder_snooze_nonneg CHECK (snooze_count >= 0),
    CONSTRAINT chk_reminder_snooze_consistency
        CHECK (snoozed_until IS NULL OR status = 'snoozed')
);

COMMENT ON TABLE remind.reminders IS 'Individual reminder instances generated from a medicine schedule occurrence.';

CREATE TRIGGER trg_reminders_updated_at
    BEFORE UPDATE ON remind.reminders
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ---------------------------------------------------------------------------
-- TABLE: remind.dose_logs
-- ---------------------------------------------------------------------------
CREATE TABLE remind.dose_logs (
    id                   UUID              PRIMARY KEY DEFAULT gen_random_uuid(),
    reminder_id          UUID
                                           REFERENCES remind.reminders(id) ON DELETE SET NULL,
    user_id              UUID              NOT NULL,   -- FK → auth.users(id)
    medicine_schedule_id UUID              NOT NULL
                                           REFERENCES sched.medicine_schedules(id),
    action               public.dose_action NOT NULL,
    action_at            TIMESTAMPTZ        NOT NULL DEFAULT NOW(),
    notes                TEXT
);

COMMENT ON TABLE remind.dose_logs IS 'Immutable record of every dose outcome — taken, missed, skipped, etc.';
COMMENT ON COLUMN remind.dose_logs.reminder_id IS 'NULL for manually logged doses not triggered by a reminder.';


-- =============================================================================
-- MODULE: DRUG INTERACTIONS (safety schema)
-- =============================================================================

-- ---------------------------------------------------------------------------
-- TABLE: safety.drug_interactions
-- ---------------------------------------------------------------------------
CREATE TABLE safety.drug_interactions (
    id                UUID                       PRIMARY KEY DEFAULT gen_random_uuid(),
    medicine_a_id     UUID                       NOT NULL
                                                 REFERENCES med.medicines(id),
    medicine_b_id     UUID                       NOT NULL
                                                 REFERENCES med.medicines(id),
    severity          public.interaction_severity NOT NULL,
    interaction_type  TEXT,
    mechanism         TEXT,
    clinical_effect   TEXT,
    management        TEXT,
    evidence_level    public.evidence_level       NOT NULL DEFAULT 'theoretical',
    source_reference  TEXT,
    created_at        TIMESTAMPTZ                NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ                NOT NULL DEFAULT NOW(),
    created_by        UUID,                               -- FK → auth.users(id)

    -- Prevent duplicate bidirectional pairs
    CONSTRAINT uq_drug_interaction_pair
        UNIQUE (
            LEAST(medicine_a_id::TEXT, medicine_b_id::TEXT),
            GREATEST(medicine_a_id::TEXT, medicine_b_id::TEXT)
        ),
    -- No self-interaction
    CONSTRAINT chk_drug_interaction_no_self
        CHECK (medicine_a_id <> medicine_b_id)
);

COMMENT ON TABLE safety.drug_interactions IS 'Bidirectional drug-drug interaction catalog. Pair uniqueness enforced via LEAST/GREATEST.';
COMMENT ON COLUMN safety.drug_interactions.mechanism IS 'Pharmacokinetic or pharmacodynamic mechanism description.';

CREATE TRIGGER trg_drug_interactions_updated_at
    BEFORE UPDATE ON safety.drug_interactions
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ---------------------------------------------------------------------------
-- TABLE: safety.user_interaction_alerts
-- ---------------------------------------------------------------------------
CREATE TABLE safety.user_interaction_alerts (
    id                   UUID                  PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id              UUID                  NOT NULL,   -- FK → auth.users(id)
    drug_interaction_id  UUID                  NOT NULL
                                               REFERENCES safety.drug_interactions(id),
    prescription_id      UUID
                                               REFERENCES rx.prescriptions(id) ON DELETE SET NULL,
    status               public.alert_status   NOT NULL DEFAULT 'active',
    override_reason      TEXT,
    alerted_at           TIMESTAMPTZ           NOT NULL DEFAULT NOW(),
    acknowledged_at      TIMESTAMPTZ,

    CONSTRAINT chk_alert_override_requires_reason
        CHECK (status <> 'overridden' OR override_reason IS NOT NULL),
    CONSTRAINT chk_alert_acknowledged_timestamp
        CHECK (acknowledged_at IS NULL OR status IN ('acknowledged', 'overridden', 'resolved'))
);

COMMENT ON TABLE safety.user_interaction_alerts IS 'Per-user alerts raised when co-prescribed medicines have a known interaction.';


-- =============================================================================
-- MODULE: CAREGIVER SUPPORT (care schema)
-- =============================================================================

-- ---------------------------------------------------------------------------
-- TABLE: care.caregiver_relationships
-- ---------------------------------------------------------------------------
CREATE TABLE care.caregiver_relationships (
    id                  UUID                        PRIMARY KEY DEFAULT gen_random_uuid(),
    caregiver_user_id   UUID                        NOT NULL,   -- FK → auth.users(id)
    patient_user_id     UUID                        NOT NULL,   -- FK → auth.users(id)
    relationship_type   public.relationship_type    NOT NULL,
    access_level        public.access_level         NOT NULL DEFAULT 'read',
    status              public.relationship_status  NOT NULL DEFAULT 'pending',
    invited_at          TIMESTAMPTZ                 NOT NULL DEFAULT NOW(),
    accepted_at         TIMESTAMPTZ,
    revoked_at          TIMESTAMPTZ,
    created_at          TIMESTAMPTZ                 NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_caregiver_patient_pair
        UNIQUE (caregiver_user_id, patient_user_id),
    CONSTRAINT chk_caregiver_no_self_link
        CHECK (caregiver_user_id <> patient_user_id),
    CONSTRAINT chk_caregiver_accepted_after_invited
        CHECK (accepted_at IS NULL OR accepted_at >= invited_at),
    CONSTRAINT chk_caregiver_revoked_after_accepted
        CHECK (revoked_at IS NULL OR accepted_at IS NULL OR revoked_at >= accepted_at)
);

COMMENT ON TABLE care.caregiver_relationships IS 'Tracks caregiver–patient relationships with access control levels.';

-- ---------------------------------------------------------------------------
-- TABLE: care.caregiver_activity_logs
-- ---------------------------------------------------------------------------
CREATE TABLE care.caregiver_activity_logs (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    caregiver_user_id   UUID        NOT NULL,   -- FK → auth.users(id)
    patient_user_id     UUID        NOT NULL,   -- FK → auth.users(id)
    action_type         TEXT        NOT NULL,
    resource_type       TEXT,
    resource_id         UUID,
    metadata            JSONB,
    performed_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_caregiver_activity_action_notempty
        CHECK (TRIM(action_type) <> '')
);

COMMENT ON TABLE care.caregiver_activity_logs IS 'Immutable audit log of all actions a caregiver performs on behalf of a patient.';
COMMENT ON COLUMN care.caregiver_activity_logs.action_type IS 'e.g. view_prescription, mark_dose_taken, upload_prescription, update_schedule.';


-- =============================================================================
-- MODULE: NOTIFICATION LOGS (notify schema)
-- =============================================================================

-- ---------------------------------------------------------------------------
-- TABLE: notify.notification_channels
-- ---------------------------------------------------------------------------
CREATE TABLE notify.notification_channels (
    id        UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
    name      TEXT    NOT NULL UNIQUE,
    provider  TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT chk_channel_name_notempty CHECK (TRIM(name) <> '')
);

COMMENT ON TABLE notify.notification_channels IS 'Supported delivery channels: push, sms, email, whatsapp, in_app.';

-- Seed default channels
INSERT INTO notify.notification_channels (name, provider) VALUES
    ('push',      'FCM'),
    ('sms',       'Twilio'),
    ('email',     'Resend'),
    ('whatsapp',  'Meta'),
    ('in_app',    'internal')
ON CONFLICT (name) DO NOTHING;

-- ---------------------------------------------------------------------------
-- TABLE: notify.notification_templates
-- ---------------------------------------------------------------------------
CREATE TABLE notify.notification_templates (
    id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    channel_id    UUID        NOT NULL
                              REFERENCES notify.notification_channels(id),
    language_id   UUID        NOT NULL
                              REFERENCES i18n.languages(id),
    event_type    TEXT        NOT NULL,
    subject       TEXT,
    body_template TEXT        NOT NULL,
    is_active     BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_notification_template_unique
        UNIQUE (channel_id, language_id, event_type),
    CONSTRAINT chk_template_event_notempty
        CHECK (TRIM(event_type) <> ''),
    CONSTRAINT chk_template_body_notempty
        CHECK (TRIM(body_template) <> '')
);

COMMENT ON TABLE notify.notification_templates IS 'Handlebars/Mustache message templates keyed by channel × language × event type.';
COMMENT ON COLUMN notify.notification_templates.event_type IS 'e.g. dose_reminder, interaction_alert, prescription_expiry, caregiver_invite.';

CREATE TRIGGER trg_notification_templates_updated_at
    BEFORE UPDATE ON notify.notification_templates
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ---------------------------------------------------------------------------
-- TABLE: notify.notification_logs
-- ---------------------------------------------------------------------------
CREATE TABLE notify.notification_logs (
    id                  UUID                       PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID                       NOT NULL,   -- FK → auth.users(id)
    reminder_id         UUID
                                                   REFERENCES remind.reminders(id) ON DELETE SET NULL,
    channel_id          UUID                       NOT NULL
                                                   REFERENCES notify.notification_channels(id),
    template_id         UUID
                                                   REFERENCES notify.notification_templates(id) ON DELETE SET NULL,
    event_type          TEXT                       NOT NULL,
    recipient_address   TEXT                       NOT NULL,
    status              public.notification_status NOT NULL DEFAULT 'queued',
    provider_message_id TEXT,
    error_message       TEXT,
    retry_count         INTEGER                    NOT NULL DEFAULT 0,
    sent_at             TIMESTAMPTZ,
    delivered_at        TIMESTAMPTZ,
    failed_at           TIMESTAMPTZ,
    created_at          TIMESTAMPTZ                NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_notif_retry_nonneg CHECK (retry_count >= 0),
    CONSTRAINT chk_notif_event_notempty CHECK (TRIM(event_type) <> ''),
    CONSTRAINT chk_notif_recipient_notempty CHECK (TRIM(recipient_address) <> '')
)
PARTITION BY RANGE (created_at);   -- Time-based partitioning for scale

COMMENT ON TABLE notify.notification_logs IS 'Immutable delivery log for every notification sent through any channel.';
COMMENT ON COLUMN notify.notification_logs.recipient_address IS 'Tokenized/hashed PII: device token, masked phone, or masked email.';

-- Create initial partitions (quarterly)
CREATE TABLE notify.notification_logs_2026_q1
    PARTITION OF notify.notification_logs
    FOR VALUES FROM ('2026-01-01') TO ('2026-04-01');

CREATE TABLE notify.notification_logs_2026_q2
    PARTITION OF notify.notification_logs
    FOR VALUES FROM ('2026-04-01') TO ('2026-07-01');

CREATE TABLE notify.notification_logs_2026_q3
    PARTITION OF notify.notification_logs
    FOR VALUES FROM ('2026-07-01') TO ('2026-10-01');

CREATE TABLE notify.notification_logs_2026_q4
    PARTITION OF notify.notification_logs
    FOR VALUES FROM ('2026-10-01') TO ('2027-01-01');

CREATE TABLE notify.notification_logs_2027_q1
    PARTITION OF notify.notification_logs
    FOR VALUES FROM ('2027-01-01') TO ('2027-04-01');

CREATE TABLE notify.notification_logs_default
    PARTITION OF notify.notification_logs DEFAULT;


-- =============================================================================
-- INDEXES
-- =============================================================================

-- ── auth_ext ─────────────────────────────────────────────────────────────────
CREATE INDEX idx_user_profiles_user_id
    ON auth_ext.user_profiles(user_id);

CREATE INDEX idx_user_profiles_role
    ON auth_ext.user_profiles(role)
    WHERE is_active = TRUE;

-- ── med ───────────────────────────────────────────────────────────────────────
-- Full-text search on medicine name + generic name
CREATE INDEX idx_medicines_name_fts
    ON med.medicines
    USING GIN (to_tsvector('english', COALESCE(name,'') || ' ' || COALESCE(generic_name,'') || ' ' || COALESCE(brand_name,'')));

-- Trigram search for fuzzy medicine lookup
CREATE INDEX idx_medicines_name_trgm
    ON med.medicines
    USING GIN (name gin_trgm_ops);

CREATE INDEX idx_medicines_active
    ON med.medicines(is_active)
    WHERE is_active = TRUE;

CREATE INDEX idx_medicine_aliases_lookup
    ON med.medicine_aliases(lower(alias), locale);

CREATE INDEX idx_medicine_aliases_medicine
    ON med.medicine_aliases(medicine_id);

-- ── rx ────────────────────────────────────────────────────────────────────────
CREATE INDEX idx_prescriptions_user_status
    ON rx.prescriptions(user_id, status);

CREATE INDEX idx_prescriptions_valid_until
    ON rx.prescriptions(valid_until)
    WHERE status = 'active';

CREATE INDEX idx_prescriptions_caregiver
    ON rx.prescriptions(caregiver_id)
    WHERE caregiver_id IS NOT NULL;

CREATE INDEX idx_prescription_images_prescription
    ON rx.prescription_images(prescription_id);

CREATE INDEX idx_rx_medicines_prescription
    ON rx.prescription_medicines(prescription_id);

CREATE INDEX idx_rx_medicines_medicine
    ON rx.prescription_medicines(medicine_id);

-- ── ocr ───────────────────────────────────────────────────────────────────────
-- Worker polling: fetch queued/processing jobs
CREATE INDEX idx_ocr_jobs_status_queue
    ON ocr.ocr_jobs(status, created_at)
    WHERE status IN ('queued', 'processing');

CREATE INDEX idx_ocr_jobs_image
    ON ocr.ocr_jobs(prescription_image_id);

CREATE INDEX idx_ocr_jobs_user
    ON ocr.ocr_jobs(user_id);

-- GIN index for searching structured OCR output
CREATE INDEX idx_ocr_jobs_structured_data
    ON ocr.ocr_jobs
    USING GIN (structured_data);

CREATE INDEX idx_ocr_corrections_job
    ON ocr.ocr_corrections(ocr_job_id);

-- ── sched ─────────────────────────────────────────────────────────────────────
-- Reminder engine: active schedules per user
CREATE INDEX idx_schedules_user_active
    ON sched.medicine_schedules(user_id, is_active)
    WHERE is_active = TRUE;

CREATE INDEX idx_schedules_prescription_medicine
    ON sched.medicine_schedules(prescription_medicine_id);

CREATE INDEX idx_schedule_exceptions_lookup
    ON sched.schedule_exceptions(medicine_schedule_id, exception_date);

-- ── remind ────────────────────────────────────────────────────────────────────
-- Cron worker: upcoming reminders
CREATE INDEX idx_reminders_scheduled_pending
    ON remind.reminders(scheduled_at, status)
    WHERE status IN ('pending', 'snoozed');

CREATE INDEX idx_reminders_user_timeline
    ON remind.reminders(user_id, scheduled_at DESC);

CREATE INDEX idx_reminders_schedule
    ON remind.reminders(medicine_schedule_id);

-- Dose history for adherence dashboards
CREATE INDEX idx_dose_logs_user_timeline
    ON remind.dose_logs(user_id, action_at DESC);

CREATE INDEX idx_dose_logs_schedule_timeline
    ON remind.dose_logs(medicine_schedule_id, action_at DESC);

CREATE INDEX idx_dose_logs_reminder
    ON remind.dose_logs(reminder_id)
    WHERE reminder_id IS NOT NULL;

-- ── safety ────────────────────────────────────────────────────────────────────
-- O(1) bidirectional pair lookup
CREATE INDEX idx_drug_interactions_pair
    ON safety.drug_interactions(
        LEAST(medicine_a_id::TEXT, medicine_b_id::TEXT),
        GREATEST(medicine_a_id::TEXT, medicine_b_id::TEXT)
    );

CREATE INDEX idx_drug_interactions_severity
    ON safety.drug_interactions(severity);

CREATE INDEX idx_user_alerts_user_status
    ON safety.user_interaction_alerts(user_id, status)
    WHERE status = 'active';

CREATE INDEX idx_user_alerts_prescription
    ON safety.user_interaction_alerts(prescription_id)
    WHERE prescription_id IS NOT NULL;

-- ── i18n ──────────────────────────────────────────────────────────────────────
CREATE INDEX idx_medicine_explanations_medicine
    ON i18n.medicine_explanations(medicine_id);

CREATE INDEX idx_medicine_explanations_lang
    ON i18n.medicine_explanations(language_id);

CREATE INDEX idx_prescription_explanations_prescription
    ON i18n.prescription_explanations(prescription_id);

-- ── care ──────────────────────────────────────────────────────────────────────
-- Look up all patients for a caregiver
CREATE INDEX idx_caregiver_by_caregiver
    ON care.caregiver_relationships(caregiver_user_id, status);

-- Look up all caregivers for a patient
CREATE INDEX idx_caregiver_by_patient
    ON care.caregiver_relationships(patient_user_id, status);

CREATE INDEX idx_caregiver_activity_patient_time
    ON care.caregiver_activity_logs(patient_user_id, performed_at DESC);

CREATE INDEX idx_caregiver_activity_caregiver_time
    ON care.caregiver_activity_logs(caregiver_user_id, performed_at DESC);

-- GIN index on metadata JSON for flexible queries
CREATE INDEX idx_caregiver_activity_metadata
    ON care.caregiver_activity_logs
    USING GIN (metadata)
    WHERE metadata IS NOT NULL;

-- ── notify ────────────────────────────────────────────────────────────────────
CREATE INDEX idx_notif_logs_user_event
    ON notify.notification_logs(user_id, event_type, created_at DESC);

-- Worker: retry queue
CREATE INDEX idx_notif_logs_status_queue
    ON notify.notification_logs(status, created_at)
    WHERE status IN ('queued', 'sent');

CREATE INDEX idx_notif_logs_reminder
    ON notify.notification_logs(reminder_id)
    WHERE reminder_id IS NOT NULL;


-- =============================================================================
-- ROW LEVEL SECURITY (RLS)
-- =============================================================================

-- ── auth_ext.user_profiles ───────────────────────────────────────────────────
ALTER TABLE auth_ext.user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_own_profile_select"
    ON auth_ext.user_profiles FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "users_own_profile_insert"
    ON auth_ext.user_profiles FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_own_profile_update"
    ON auth_ext.user_profiles FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- ── rx.prescriptions ─────────────────────────────────────────────────────────
ALTER TABLE rx.prescriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "patient_own_prescriptions"
    ON rx.prescriptions FOR ALL
    USING (user_id = auth.uid());

CREATE POLICY "caregiver_read_prescriptions"
    ON rx.prescriptions FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM care.caregiver_relationships cr
            WHERE cr.patient_user_id = rx.prescriptions.user_id
              AND cr.caregiver_user_id = auth.uid()
              AND cr.status = 'active'
        )
    );

CREATE POLICY "caregiver_write_prescriptions"
    ON rx.prescriptions FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM care.caregiver_relationships cr
            WHERE cr.patient_user_id = rx.prescriptions.user_id
              AND cr.caregiver_user_id = auth.uid()
              AND cr.status = 'active'
              AND cr.access_level IN ('write', 'admin')
        )
    );

-- ── sched.medicine_schedules ──────────────────────────────────────────────────
ALTER TABLE sched.medicine_schedules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "patient_own_schedules"
    ON sched.medicine_schedules FOR ALL
    USING (user_id = auth.uid());

CREATE POLICY "caregiver_read_schedules"
    ON sched.medicine_schedules FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM care.caregiver_relationships cr
            WHERE cr.patient_user_id = sched.medicine_schedules.user_id
              AND cr.caregiver_user_id = auth.uid()
              AND cr.status = 'active'
        )
    );

-- ── remind.reminders ─────────────────────────────────────────────────────────
ALTER TABLE remind.reminders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "patient_own_reminders"
    ON remind.reminders FOR ALL
    USING (user_id = auth.uid());

CREATE POLICY "caregiver_read_reminders"
    ON remind.reminders FOR SELECT
    USING (
        EXISTS (
            SELECT 1
            FROM care.caregiver_relationships cr
            WHERE cr.patient_user_id = remind.reminders.user_id
              AND cr.caregiver_user_id = auth.uid()
              AND cr.status = 'active'
        )
    );

-- ── remind.dose_logs ─────────────────────────────────────────────────────────
ALTER TABLE remind.dose_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "patient_own_dose_logs"
    ON remind.dose_logs FOR ALL
    USING (user_id = auth.uid());

CREATE POLICY "caregiver_read_dose_logs"
    ON remind.dose_logs FOR SELECT
    USING (
        EXISTS (
            SELECT 1
            FROM care.caregiver_relationships cr
            WHERE cr.patient_user_id = remind.dose_logs.user_id
              AND cr.caregiver_user_id = auth.uid()
              AND cr.status = 'active'
        )
    );

-- ── safety.user_interaction_alerts ───────────────────────────────────────────
ALTER TABLE safety.user_interaction_alerts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "patient_own_alerts"
    ON safety.user_interaction_alerts FOR ALL
    USING (user_id = auth.uid());

-- ── notify.notification_logs ─────────────────────────────────────────────────
ALTER TABLE notify.notification_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "patient_own_notification_logs"
    ON notify.notification_logs FOR SELECT
    USING (user_id = auth.uid());

-- ── care.caregiver_relationships ─────────────────────────────────────────────
ALTER TABLE care.caregiver_relationships ENABLE ROW LEVEL SECURITY;

CREATE POLICY "caregiver_see_own_relationships"
    ON care.caregiver_relationships FOR SELECT
    USING (caregiver_user_id = auth.uid() OR patient_user_id = auth.uid());

CREATE POLICY "patient_manage_relationships"
    ON care.caregiver_relationships FOR ALL
    USING (patient_user_id = auth.uid());

-- ── med.medicines (public read) ───────────────────────────────────────────────
ALTER TABLE med.medicines ENABLE ROW LEVEL SECURITY;

CREATE POLICY "authenticated_read_medicines"
    ON med.medicines FOR SELECT
    TO authenticated
    USING (is_active = TRUE);

-- ── safety.drug_interactions (public read) ───────────────────────────────────
ALTER TABLE safety.drug_interactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "authenticated_read_interactions"
    ON safety.drug_interactions FOR SELECT
    TO authenticated
    USING (TRUE);

-- ── i18n (public read) ────────────────────────────────────────────────────────
ALTER TABLE i18n.languages             ENABLE ROW LEVEL SECURITY;
ALTER TABLE i18n.medicine_explanations ENABLE ROW LEVEL SECURITY;
ALTER TABLE i18n.prescription_explanations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "public_read_languages"
    ON i18n.languages FOR SELECT USING (is_active = TRUE);

CREATE POLICY "authenticated_read_medicine_explanations"
    ON i18n.medicine_explanations FOR SELECT TO authenticated USING (TRUE);

CREATE POLICY "patient_own_prescription_explanations"
    ON i18n.prescription_explanations FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM rx.prescriptions p
            WHERE p.id = i18n.prescription_explanations.prescription_id
              AND p.user_id = auth.uid()
        )
    );


-- =============================================================================
-- UTILITY TRIGGERS
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Auto-create user_profile row when a new Supabase auth user signs up
-- Attach this trigger on the auth.users table via Supabase dashboard or:
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO auth_ext.user_profiles (user_id, full_name, locale, role)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'locale', 'en'),
        COALESCE((NEW.raw_user_meta_data->>'role')::public.user_role, 'patient')
    )
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$;

-- Wire to Supabase auth schema (run via Supabase SQL Editor with elevated privileges)
-- CREATE TRIGGER on_auth_user_created
--     AFTER INSERT ON auth.users
--     FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- ---------------------------------------------------------------------------
-- Auto-close expired prescriptions (call via pg_cron or Supabase Edge Function)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.expire_prescriptions()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    affected INTEGER;
BEGIN
    UPDATE rx.prescriptions
    SET    status = 'expired',
           updated_at = NOW()
    WHERE  status = 'active'
      AND  valid_until < CURRENT_DATE;

    GET DIAGNOSTICS affected = ROW_COUNT;
    RETURN affected;
END;
$$;


-- ---------------------------------------------------------------------------
-- Enforce caregiver relationship must exist before caregiver can touch Rx
-- (belt-and-suspenders beyond RLS — fires at data layer)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION rx.validate_caregiver_relationship()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF NEW.caregiver_id IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1 FROM care.caregiver_relationships cr
            WHERE cr.caregiver_user_id = NEW.caregiver_id
              AND cr.patient_user_id   = NEW.user_id
              AND cr.status            = 'active'
        ) THEN
            RAISE EXCEPTION
                'caregiver_id % has no active relationship with patient %',
                NEW.caregiver_id, NEW.user_id
            USING ERRCODE = 'foreign_key_violation';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_prescriptions_validate_caregiver
    BEFORE INSERT OR UPDATE OF caregiver_id ON rx.prescriptions
    FOR EACH ROW EXECUTE FUNCTION rx.validate_caregiver_relationship();


-- ---------------------------------------------------------------------------
-- Prevent scheduling reminders on exception dates
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION remind.block_exception_date_reminder()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM sched.schedule_exceptions se
        WHERE se.medicine_schedule_id = NEW.medicine_schedule_id
          AND se.exception_date = NEW.scheduled_at::DATE
    ) THEN
        RAISE EXCEPTION
            'Cannot create reminder on exception date % for schedule %',
            NEW.scheduled_at::DATE, NEW.medicine_schedule_id
        USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_reminders_block_exception_dates
    BEFORE INSERT ON remind.reminders
    FOR EACH ROW EXECUTE FUNCTION remind.block_exception_date_reminder();


-- =============================================================================
-- VIEWS  (convenience / Supabase API surface)
-- =============================================================================

-- Active schedules with medicine info for the reminder engine
CREATE OR REPLACE VIEW sched.v_active_schedules AS
SELECT
    ms.id                       AS schedule_id,
    ms.user_id,
    ms.dose_time,
    ms.dose_amount,
    ms.recurrence_type,
    ms.recurrence_rule,
    pm.dosage,
    pm.route,
    pm.instructions,
    m.name                      AS medicine_name,
    m.generic_name,
    m.form,
    p.id                        AS prescription_id,
    p.doctor_name,
    p.valid_until
FROM sched.medicine_schedules ms
JOIN rx.prescription_medicines pm ON pm.id = ms.prescription_medicine_id
JOIN med.medicines              m  ON m.id  = pm.medicine_id
JOIN rx.prescriptions           p  ON p.id  = pm.prescription_id
WHERE ms.is_active = TRUE
  AND p.status     = 'active'
  AND (p.valid_until IS NULL OR p.valid_until >= CURRENT_DATE);

COMMENT ON VIEW sched.v_active_schedules IS
    'Denormalized view used by the reminder engine to build daily reminder queues.';

-- Patient adherence summary
CREATE OR REPLACE VIEW remind.v_adherence_summary AS
SELECT
    dl.user_id,
    dl.medicine_schedule_id,
    DATE_TRUNC('week', dl.action_at)            AS week_start,
    COUNT(*) FILTER (WHERE dl.action = 'taken')  AS taken_count,
    COUNT(*) FILTER (WHERE dl.action = 'missed') AS missed_count,
    COUNT(*) FILTER (WHERE dl.action = 'skipped')AS skipped_count,
    COUNT(*)                                     AS total_count,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE dl.action = 'taken') / NULLIF(COUNT(*), 0),
        1
    )                                            AS adherence_pct
FROM remind.dose_logs dl
GROUP BY dl.user_id, dl.medicine_schedule_id, DATE_TRUNC('week', dl.action_at);

COMMENT ON VIEW remind.v_adherence_summary IS
    'Weekly medication adherence statistics per user per schedule.';


-- =============================================================================
-- GRANTS  (Supabase role model)
-- =============================================================================

-- anon role: no access to patient data
REVOKE ALL ON ALL TABLES IN SCHEMA rx     FROM anon;
REVOKE ALL ON ALL TABLES IN SCHEMA sched  FROM anon;
REVOKE ALL ON ALL TABLES IN SCHEMA remind FROM anon;
REVOKE ALL ON ALL TABLES IN SCHEMA safety FROM anon;
REVOKE ALL ON ALL TABLES IN SCHEMA care   FROM anon;
REVOKE ALL ON ALL TABLES IN SCHEMA notify FROM anon;
REVOKE ALL ON ALL TABLES IN SCHEMA ocr    FROM anon;

-- Public read-only reference data for anon
GRANT SELECT ON i18n.languages         TO anon;

-- authenticated role
GRANT USAGE ON SCHEMA auth_ext, rx, ocr, med, sched, remind, safety, i18n, care, notify TO authenticated;

GRANT SELECT, INSERT, UPDATE, DELETE ON auth_ext.user_profiles         TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON rx.prescriptions               TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON rx.prescription_images         TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON rx.prescription_medicines      TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON ocr.ocr_jobs                   TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON ocr.ocr_corrections            TO authenticated;
GRANT SELECT                         ON med.medicines                  TO authenticated;
GRANT SELECT                         ON med.medicine_aliases           TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON sched.medicine_schedules       TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON sched.schedule_exceptions      TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON remind.reminders               TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON remind.dose_logs               TO authenticated;
GRANT SELECT                         ON safety.drug_interactions       TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON safety.user_interaction_alerts TO authenticated;
GRANT SELECT                         ON i18n.languages                 TO authenticated;
GRANT SELECT                         ON i18n.medicine_explanations     TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON i18n.prescription_explanations TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON care.caregiver_relationships   TO authenticated;
GRANT SELECT, INSERT                  ON care.caregiver_activity_logs  TO authenticated;
GRANT SELECT                         ON notify.notification_logs       TO authenticated;
GRANT SELECT                         ON notify.notification_channels   TO authenticated;
GRANT SELECT                         ON notify.notification_templates  TO authenticated;

-- service_role: full access (used by backend / Edge Functions)
GRANT ALL ON ALL TABLES IN SCHEMA auth_ext, rx, ocr, med, sched, remind, safety, i18n, care, notify TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA auth_ext, rx, ocr, med, sched, remind, safety, i18n, care, notify TO service_role;


-- =============================================================================
-- END OF SCHEMA
-- =============================================================================
