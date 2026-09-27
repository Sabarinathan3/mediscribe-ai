-- =============================================================================
-- MediScribe AI — Row Level Security (RLS) Policies
-- =============================================================================
-- PostgreSQL 16 | Supabase Compatible
-- Roles: patient · caregiver · admin
--
-- Strategy:
--   • Patients    → see/modify ONLY their own rows
--   • Caregivers  → see/modify rows belonging to patients they are linked to
--                   (care.caregiver_relationships.status = 'active')
--                   write access gated by access_level IN ('write','admin')
--   • Admins      → full unrestricted access via a helper function
--
-- Pattern:
--   Every policy calls auth.uid() — Supabase's current JWT subject.
--   Role is read from auth_ext.user_profiles.role for the current user.
--   A SECURITY DEFINER helper avoids infinite recursion in RLS checks.
-- =============================================================================


-- =============================================================================
-- HELPER FUNCTIONS  (SECURITY DEFINER — bypass RLS for internal checks)
-- =============================================================================

-- Returns the role of the currently authenticated user
CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS public.user_role
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT role
    FROM   auth_ext.user_profiles
    WHERE  user_id = auth.uid()
    LIMIT  1;
$$;

-- Returns TRUE if the current user is an admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT COALESCE(
        (SELECT role = 'admin'
         FROM   auth_ext.user_profiles
         WHERE  user_id = auth.uid()
         LIMIT  1),
        false
    );
$$;

-- Returns TRUE if current user (caregiver) has an active relationship with target patient
CREATE OR REPLACE FUNCTION public.is_caregiver_of(patient_id UUID)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM   care.caregiver_relationships
        WHERE  caregiver_user_id = auth.uid()
          AND  patient_user_id   = patient_id
          AND  status            = 'active'
    );
$$;

-- Returns TRUE if caregiver has write-level (or admin-level) access to the patient
CREATE OR REPLACE FUNCTION public.caregiver_can_write(patient_id UUID)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM   care.caregiver_relationships
        WHERE  caregiver_user_id = auth.uid()
          AND  patient_user_id   = patient_id
          AND  status            = 'active'
          AND  access_level      IN ('write', 'admin')
    );
$$;

-- Returns TRUE if caregiver has admin-level access to the patient
CREATE OR REPLACE FUNCTION public.caregiver_is_admin_of(patient_id UUID)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM   care.caregiver_relationships
        WHERE  caregiver_user_id = auth.uid()
          AND  patient_user_id   = patient_id
          AND  status            = 'active'
          AND  access_level      = 'admin'
    );
$$;


-- =============================================================================
-- SECTION 1 — auth_ext.user_profiles
-- =============================================================================

ALTER TABLE auth_ext.user_profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies before re-creating
DROP POLICY IF EXISTS "profile_select_own"      ON auth_ext.user_profiles;
DROP POLICY IF EXISTS "profile_select_caregiver" ON auth_ext.user_profiles;
DROP POLICY IF EXISTS "profile_select_admin"    ON auth_ext.user_profiles;
DROP POLICY IF EXISTS "profile_insert_own"      ON auth_ext.user_profiles;
DROP POLICY IF EXISTS "profile_update_own"      ON auth_ext.user_profiles;
DROP POLICY IF EXISTS "profile_update_admin"    ON auth_ext.user_profiles;
DROP POLICY IF EXISTS "profile_delete_admin"    ON auth_ext.user_profiles;

-- PATIENT: read own profile
CREATE POLICY "profile_select_own"
    ON auth_ext.user_profiles
    FOR SELECT
    USING (user_id = auth.uid());

-- CAREGIVER: read profile of assigned patients (for name/locale display)
CREATE POLICY "profile_select_caregiver"
    ON auth_ext.user_profiles
    FOR SELECT
    USING (public.is_caregiver_of(user_id));

-- ADMIN: read any profile
CREATE POLICY "profile_select_admin"
    ON auth_ext.user_profiles
    FOR SELECT
    USING (public.is_admin());

-- PATIENT: insert own profile (on signup)
CREATE POLICY "profile_insert_own"
    ON auth_ext.user_profiles
    FOR INSERT
    WITH CHECK (user_id = auth.uid());

-- PATIENT: update own profile
CREATE POLICY "profile_update_own"
    ON auth_ext.user_profiles
    FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- ADMIN: update any profile (e.g. role promotion)
CREATE POLICY "profile_update_admin"
    ON auth_ext.user_profiles
    FOR UPDATE
    USING (public.is_admin());

-- ADMIN: delete/deactivate any profile
CREATE POLICY "profile_delete_admin"
    ON auth_ext.user_profiles
    FOR DELETE
    USING (public.is_admin());


-- =============================================================================
-- SECTION 2 — rx.prescriptions
-- =============================================================================

ALTER TABLE rx.prescriptions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "rx_select_patient"   ON rx.prescriptions;
DROP POLICY IF EXISTS "rx_select_caregiver" ON rx.prescriptions;
DROP POLICY IF EXISTS "rx_select_admin"     ON rx.prescriptions;
DROP POLICY IF EXISTS "rx_insert_patient"   ON rx.prescriptions;
DROP POLICY IF EXISTS "rx_insert_caregiver" ON rx.prescriptions;
DROP POLICY IF EXISTS "rx_insert_admin"     ON rx.prescriptions;
DROP POLICY IF EXISTS "rx_update_patient"   ON rx.prescriptions;
DROP POLICY IF EXISTS "rx_update_caregiver" ON rx.prescriptions;
DROP POLICY IF EXISTS "rx_update_admin"     ON rx.prescriptions;
DROP POLICY IF EXISTS "rx_delete_patient"   ON rx.prescriptions;
DROP POLICY IF EXISTS "rx_delete_admin"     ON rx.prescriptions;

-- PATIENT: full access to own prescriptions
CREATE POLICY "rx_select_patient"
    ON rx.prescriptions FOR SELECT
    USING (user_id = auth.uid());

-- CAREGIVER: read prescriptions of assigned patients
CREATE POLICY "rx_select_caregiver"
    ON rx.prescriptions FOR SELECT
    USING (public.is_caregiver_of(user_id));

-- ADMIN: read all
CREATE POLICY "rx_select_admin"
    ON rx.prescriptions FOR SELECT
    USING (public.is_admin());

-- PATIENT: create own prescriptions
CREATE POLICY "rx_insert_patient"
    ON rx.prescriptions FOR INSERT
    WITH CHECK (user_id = auth.uid());

-- CAREGIVER: create prescriptions on behalf of assigned patient (write+)
CREATE POLICY "rx_insert_caregiver"
    ON rx.prescriptions FOR INSERT
    WITH CHECK (public.caregiver_can_write(user_id));

-- ADMIN: create prescriptions for anyone
CREATE POLICY "rx_insert_admin"
    ON rx.prescriptions FOR INSERT
    WITH CHECK (public.is_admin());

-- PATIENT: update own prescriptions
CREATE POLICY "rx_update_patient"
    ON rx.prescriptions FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- CAREGIVER: update prescriptions of assigned patients (write+)
CREATE POLICY "rx_update_caregiver"
    ON rx.prescriptions FOR UPDATE
    USING (public.caregiver_can_write(user_id))
    WITH CHECK (public.caregiver_can_write(user_id));

-- ADMIN: update any
CREATE POLICY "rx_update_admin"
    ON rx.prescriptions FOR UPDATE
    USING (public.is_admin());

-- PATIENT: soft-delete own prescriptions (archive)
CREATE POLICY "rx_delete_patient"
    ON rx.prescriptions FOR DELETE
    USING (user_id = auth.uid());

-- ADMIN: hard-delete any
CREATE POLICY "rx_delete_admin"
    ON rx.prescriptions FOR DELETE
    USING (public.is_admin());


-- =============================================================================
-- SECTION 3 — rx.prescription_images
-- =============================================================================

ALTER TABLE rx.prescription_images ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "rx_img_select_patient"   ON rx.prescription_images;
DROP POLICY IF EXISTS "rx_img_select_caregiver" ON rx.prescription_images;
DROP POLICY IF EXISTS "rx_img_select_admin"     ON rx.prescription_images;
DROP POLICY IF EXISTS "rx_img_insert_patient"   ON rx.prescription_images;
DROP POLICY IF EXISTS "rx_img_insert_caregiver" ON rx.prescription_images;
DROP POLICY IF EXISTS "rx_img_insert_admin"     ON rx.prescription_images;
DROP POLICY IF EXISTS "rx_img_delete_patient"   ON rx.prescription_images;
DROP POLICY IF EXISTS "rx_img_delete_admin"     ON rx.prescription_images;

-- PATIENT
CREATE POLICY "rx_img_select_patient"
    ON rx.prescription_images FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM rx.prescriptions p
            WHERE p.id = rx.prescription_images.prescription_id
              AND p.user_id = auth.uid()
        )
    );

-- CAREGIVER
CREATE POLICY "rx_img_select_caregiver"
    ON rx.prescription_images FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM rx.prescriptions p
            WHERE p.id = rx.prescription_images.prescription_id
              AND public.is_caregiver_of(p.user_id)
        )
    );

-- ADMIN
CREATE POLICY "rx_img_select_admin"
    ON rx.prescription_images FOR SELECT
    USING (public.is_admin());

-- PATIENT insert
CREATE POLICY "rx_img_insert_patient"
    ON rx.prescription_images FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM rx.prescriptions p
            WHERE p.id = rx.prescription_images.prescription_id
              AND p.user_id = auth.uid()
        )
    );

-- CAREGIVER insert (write+)
CREATE POLICY "rx_img_insert_caregiver"
    ON rx.prescription_images FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM rx.prescriptions p
            WHERE p.id = rx.prescription_images.prescription_id
              AND public.caregiver_can_write(p.user_id)
        )
    );

-- ADMIN insert
CREATE POLICY "rx_img_insert_admin"
    ON rx.prescription_images FOR INSERT
    WITH CHECK (public.is_admin());

-- PATIENT delete own
CREATE POLICY "rx_img_delete_patient"
    ON rx.prescription_images FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM rx.prescriptions p
            WHERE p.id = rx.prescription_images.prescription_id
              AND p.user_id = auth.uid()
        )
    );

-- ADMIN delete
CREATE POLICY "rx_img_delete_admin"
    ON rx.prescription_images FOR DELETE
    USING (public.is_admin());


-- =============================================================================
-- SECTION 4 — rx.prescription_medicines
-- =============================================================================

ALTER TABLE rx.prescription_medicines ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "rx_med_select_patient"   ON rx.prescription_medicines;
DROP POLICY IF EXISTS "rx_med_select_caregiver" ON rx.prescription_medicines;
DROP POLICY IF EXISTS "rx_med_select_admin"     ON rx.prescription_medicines;
DROP POLICY IF EXISTS "rx_med_insert_patient"   ON rx.prescription_medicines;
DROP POLICY IF EXISTS "rx_med_insert_caregiver" ON rx.prescription_medicines;
DROP POLICY IF EXISTS "rx_med_insert_admin"     ON rx.prescription_medicines;
DROP POLICY IF EXISTS "rx_med_update_patient"   ON rx.prescription_medicines;
DROP POLICY IF EXISTS "rx_med_update_caregiver" ON rx.prescription_medicines;
DROP POLICY IF EXISTS "rx_med_update_admin"     ON rx.prescription_medicines;
DROP POLICY IF EXISTS "rx_med_delete_patient"   ON rx.prescription_medicines;
DROP POLICY IF EXISTS "rx_med_delete_admin"     ON rx.prescription_medicines;

CREATE POLICY "rx_med_select_patient"
    ON rx.prescription_medicines FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM rx.prescriptions p
            WHERE p.id = rx.prescription_medicines.prescription_id
              AND p.user_id = auth.uid()
        )
    );

CREATE POLICY "rx_med_select_caregiver"
    ON rx.prescription_medicines FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM rx.prescriptions p
            WHERE p.id = rx.prescription_medicines.prescription_id
              AND public.is_caregiver_of(p.user_id)
        )
    );

CREATE POLICY "rx_med_select_admin"
    ON rx.prescription_medicines FOR SELECT
    USING (public.is_admin());

CREATE POLICY "rx_med_insert_patient"
    ON rx.prescription_medicines FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM rx.prescriptions p
            WHERE p.id = rx.prescription_medicines.prescription_id
              AND p.user_id = auth.uid()
        )
    );

CREATE POLICY "rx_med_insert_caregiver"
    ON rx.prescription_medicines FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM rx.prescriptions p
            WHERE p.id = rx.prescription_medicines.prescription_id
              AND public.caregiver_can_write(p.user_id)
        )
    );

CREATE POLICY "rx_med_insert_admin"
    ON rx.prescription_medicines FOR INSERT
    WITH CHECK (public.is_admin());

CREATE POLICY "rx_med_update_patient"
    ON rx.prescription_medicines FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM rx.prescriptions p
            WHERE p.id = rx.prescription_medicines.prescription_id
              AND p.user_id = auth.uid()
        )
    );

CREATE POLICY "rx_med_update_caregiver"
    ON rx.prescription_medicines FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM rx.prescriptions p
            WHERE p.id = rx.prescription_medicines.prescription_id
              AND public.caregiver_can_write(p.user_id)
        )
    );

CREATE POLICY "rx_med_update_admin"
    ON rx.prescription_medicines FOR UPDATE
    USING (public.is_admin());

CREATE POLICY "rx_med_delete_patient"
    ON rx.prescription_medicines FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM rx.prescriptions p
            WHERE p.id = rx.prescription_medicines.prescription_id
              AND p.user_id = auth.uid()
        )
    );

CREATE POLICY "rx_med_delete_admin"
    ON rx.prescription_medicines FOR DELETE
    USING (public.is_admin());


-- =============================================================================
-- SECTION 5 — ocr.ocr_jobs
-- =============================================================================

ALTER TABLE ocr.ocr_jobs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "ocr_jobs_select_patient"   ON ocr.ocr_jobs;
DROP POLICY IF EXISTS "ocr_jobs_select_caregiver" ON ocr.ocr_jobs;
DROP POLICY IF EXISTS "ocr_jobs_select_admin"     ON ocr.ocr_jobs;
DROP POLICY IF EXISTS "ocr_jobs_insert_patient"   ON ocr.ocr_jobs;
DROP POLICY IF EXISTS "ocr_jobs_insert_caregiver" ON ocr.ocr_jobs;
DROP POLICY IF EXISTS "ocr_jobs_insert_admin"     ON ocr.ocr_jobs;
DROP POLICY IF EXISTS "ocr_jobs_update_admin"     ON ocr.ocr_jobs;

-- PATIENT: view their own OCR jobs
CREATE POLICY "ocr_jobs_select_patient"
    ON ocr.ocr_jobs FOR SELECT
    USING (user_id = auth.uid());

-- CAREGIVER: view OCR jobs for their assigned patients
CREATE POLICY "ocr_jobs_select_caregiver"
    ON ocr.ocr_jobs FOR SELECT
    USING (public.is_caregiver_of(user_id));

-- ADMIN: view all
CREATE POLICY "ocr_jobs_select_admin"
    ON ocr.ocr_jobs FOR SELECT
    USING (public.is_admin());

-- PATIENT: create OCR jobs for their own images
CREATE POLICY "ocr_jobs_insert_patient"
    ON ocr.ocr_jobs FOR INSERT
    WITH CHECK (user_id = auth.uid());

-- CAREGIVER: trigger OCR for assigned patients (write+)
CREATE POLICY "ocr_jobs_insert_caregiver"
    ON ocr.ocr_jobs FOR INSERT
    WITH CHECK (public.caregiver_can_write(user_id));

-- ADMIN: full insert
CREATE POLICY "ocr_jobs_insert_admin"
    ON ocr.ocr_jobs FOR INSERT
    WITH CHECK (public.is_admin());

-- Only service_role / admin updates OCR job status (engine callback)
CREATE POLICY "ocr_jobs_update_admin"
    ON ocr.ocr_jobs FOR UPDATE
    USING (public.is_admin());


-- =============================================================================
-- SECTION 6 — ocr.ocr_corrections
-- =============================================================================

ALTER TABLE ocr.ocr_corrections ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "ocr_corr_select_patient"   ON ocr.ocr_corrections;
DROP POLICY IF EXISTS "ocr_corr_select_caregiver" ON ocr.ocr_corrections;
DROP POLICY IF EXISTS "ocr_corr_select_admin"     ON ocr.ocr_corrections;
DROP POLICY IF EXISTS "ocr_corr_insert_patient"   ON ocr.ocr_corrections;
DROP POLICY IF EXISTS "ocr_corr_insert_caregiver" ON ocr.ocr_corrections;
DROP POLICY IF EXISTS "ocr_corr_insert_admin"     ON ocr.ocr_corrections;

CREATE POLICY "ocr_corr_select_patient"
    ON ocr.ocr_corrections FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM ocr.ocr_jobs j
            WHERE j.id = ocr.ocr_corrections.ocr_job_id
              AND j.user_id = auth.uid()
        )
    );

CREATE POLICY "ocr_corr_select_caregiver"
    ON ocr.ocr_corrections FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM ocr.ocr_jobs j
            WHERE j.id = ocr.ocr_corrections.ocr_job_id
              AND public.is_caregiver_of(j.user_id)
        )
    );

CREATE POLICY "ocr_corr_select_admin"
    ON ocr.ocr_corrections FOR SELECT
    USING (public.is_admin());

CREATE POLICY "ocr_corr_insert_patient"
    ON ocr.ocr_corrections FOR INSERT
    WITH CHECK (
        corrected_by = auth.uid()
        AND EXISTS (
            SELECT 1 FROM ocr.ocr_jobs j
            WHERE j.id = ocr.ocr_corrections.ocr_job_id
              AND j.user_id = auth.uid()
        )
    );

CREATE POLICY "ocr_corr_insert_caregiver"
    ON ocr.ocr_corrections FOR INSERT
    WITH CHECK (
        corrected_by = auth.uid()
        AND EXISTS (
            SELECT 1 FROM ocr.ocr_jobs j
            WHERE j.id = ocr.ocr_corrections.ocr_job_id
              AND public.caregiver_can_write(j.user_id)
        )
    );

CREATE POLICY "ocr_corr_insert_admin"
    ON ocr.ocr_corrections FOR INSERT
    WITH CHECK (public.is_admin());


-- =============================================================================
-- SECTION 7 — med.medicines  (shared read-only catalog)
-- =============================================================================

ALTER TABLE med.medicines ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "medicines_select_authenticated" ON med.medicines;
DROP POLICY IF EXISTS "medicines_insert_admin"         ON med.medicines;
DROP POLICY IF EXISTS "medicines_update_admin"         ON med.medicines;
DROP POLICY IF EXISTS "medicines_delete_admin"         ON med.medicines;

-- All authenticated users can read active medicines
CREATE POLICY "medicines_select_authenticated"
    ON med.medicines FOR SELECT
    TO authenticated
    USING (is_active = TRUE);

-- Only admin can add to the catalog
CREATE POLICY "medicines_insert_admin"
    ON med.medicines FOR INSERT
    WITH CHECK (public.is_admin());

CREATE POLICY "medicines_update_admin"
    ON med.medicines FOR UPDATE
    USING (public.is_admin());

CREATE POLICY "medicines_delete_admin"
    ON med.medicines FOR DELETE
    USING (public.is_admin());


-- =============================================================================
-- SECTION 8 — med.medicine_aliases
-- =============================================================================

ALTER TABLE med.medicine_aliases ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "med_alias_select_authenticated" ON med.medicine_aliases;
DROP POLICY IF EXISTS "med_alias_insert_admin"         ON med.medicine_aliases;
DROP POLICY IF EXISTS "med_alias_update_admin"         ON med.medicine_aliases;
DROP POLICY IF EXISTS "med_alias_delete_admin"         ON med.medicine_aliases;

CREATE POLICY "med_alias_select_authenticated"
    ON med.medicine_aliases FOR SELECT
    TO authenticated
    USING (TRUE);

CREATE POLICY "med_alias_insert_admin"
    ON med.medicine_aliases FOR INSERT
    WITH CHECK (public.is_admin());

CREATE POLICY "med_alias_update_admin"
    ON med.medicine_aliases FOR UPDATE
    USING (public.is_admin());

CREATE POLICY "med_alias_delete_admin"
    ON med.medicine_aliases FOR DELETE
    USING (public.is_admin());


-- =============================================================================
-- SECTION 9 — sched.medicine_schedules
-- =============================================================================

ALTER TABLE sched.medicine_schedules ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "sched_select_patient"   ON sched.medicine_schedules;
DROP POLICY IF EXISTS "sched_select_caregiver" ON sched.medicine_schedules;
DROP POLICY IF EXISTS "sched_select_admin"     ON sched.medicine_schedules;
DROP POLICY IF EXISTS "sched_insert_patient"   ON sched.medicine_schedules;
DROP POLICY IF EXISTS "sched_insert_caregiver" ON sched.medicine_schedules;
DROP POLICY IF EXISTS "sched_insert_admin"     ON sched.medicine_schedules;
DROP POLICY IF EXISTS "sched_update_patient"   ON sched.medicine_schedules;
DROP POLICY IF EXISTS "sched_update_caregiver" ON sched.medicine_schedules;
DROP POLICY IF EXISTS "sched_update_admin"     ON sched.medicine_schedules;
DROP POLICY IF EXISTS "sched_delete_patient"   ON sched.medicine_schedules;
DROP POLICY IF EXISTS "sched_delete_admin"     ON sched.medicine_schedules;

CREATE POLICY "sched_select_patient"
    ON sched.medicine_schedules FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "sched_select_caregiver"
    ON sched.medicine_schedules FOR SELECT
    USING (public.is_caregiver_of(user_id));

CREATE POLICY "sched_select_admin"
    ON sched.medicine_schedules FOR SELECT
    USING (public.is_admin());

CREATE POLICY "sched_insert_patient"
    ON sched.medicine_schedules FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "sched_insert_caregiver"
    ON sched.medicine_schedules FOR INSERT
    WITH CHECK (public.caregiver_can_write(user_id));

CREATE POLICY "sched_insert_admin"
    ON sched.medicine_schedules FOR INSERT
    WITH CHECK (public.is_admin());

CREATE POLICY "sched_update_patient"
    ON sched.medicine_schedules FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "sched_update_caregiver"
    ON sched.medicine_schedules FOR UPDATE
    USING (public.caregiver_can_write(user_id))
    WITH CHECK (public.caregiver_can_write(user_id));

CREATE POLICY "sched_update_admin"
    ON sched.medicine_schedules FOR UPDATE
    USING (public.is_admin());

CREATE POLICY "sched_delete_patient"
    ON sched.medicine_schedules FOR DELETE
    USING (user_id = auth.uid());

CREATE POLICY "sched_delete_admin"
    ON sched.medicine_schedules FOR DELETE
    USING (public.is_admin());


-- =============================================================================
-- SECTION 10 — sched.schedule_exceptions
-- =============================================================================

ALTER TABLE sched.schedule_exceptions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "sched_exc_select_patient"   ON sched.schedule_exceptions;
DROP POLICY IF EXISTS "sched_exc_select_caregiver" ON sched.schedule_exceptions;
DROP POLICY IF EXISTS "sched_exc_select_admin"     ON sched.schedule_exceptions;
DROP POLICY IF EXISTS "sched_exc_insert_patient"   ON sched.schedule_exceptions;
DROP POLICY IF EXISTS "sched_exc_insert_caregiver" ON sched.schedule_exceptions;
DROP POLICY IF EXISTS "sched_exc_insert_admin"     ON sched.schedule_exceptions;
DROP POLICY IF EXISTS "sched_exc_delete_patient"   ON sched.schedule_exceptions;
DROP POLICY IF EXISTS "sched_exc_delete_admin"     ON sched.schedule_exceptions;

CREATE POLICY "sched_exc_select_patient"
    ON sched.schedule_exceptions FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM sched.medicine_schedules ms
            WHERE ms.id = sched.schedule_exceptions.medicine_schedule_id
              AND ms.user_id = auth.uid()
        )
    );

CREATE POLICY "sched_exc_select_caregiver"
    ON sched.schedule_exceptions FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM sched.medicine_schedules ms
            WHERE ms.id = sched.schedule_exceptions.medicine_schedule_id
              AND public.is_caregiver_of(ms.user_id)
        )
    );

CREATE POLICY "sched_exc_select_admin"
    ON sched.schedule_exceptions FOR SELECT
    USING (public.is_admin());

CREATE POLICY "sched_exc_insert_patient"
    ON sched.schedule_exceptions FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM sched.medicine_schedules ms
            WHERE ms.id = sched.schedule_exceptions.medicine_schedule_id
              AND ms.user_id = auth.uid()
        )
    );

CREATE POLICY "sched_exc_insert_caregiver"
    ON sched.schedule_exceptions FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM sched.medicine_schedules ms
            WHERE ms.id = sched.schedule_exceptions.medicine_schedule_id
              AND public.caregiver_can_write(ms.user_id)
        )
    );

CREATE POLICY "sched_exc_insert_admin"
    ON sched.schedule_exceptions FOR INSERT
    WITH CHECK (public.is_admin());

CREATE POLICY "sched_exc_delete_patient"
    ON sched.schedule_exceptions FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM sched.medicine_schedules ms
            WHERE ms.id = sched.schedule_exceptions.medicine_schedule_id
              AND ms.user_id = auth.uid()
        )
    );

CREATE POLICY "sched_exc_delete_admin"
    ON sched.schedule_exceptions FOR DELETE
    USING (public.is_admin());


-- =============================================================================
-- SECTION 11 — remind.reminders
-- =============================================================================

ALTER TABLE remind.reminders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "remind_select_patient"   ON remind.reminders;
DROP POLICY IF EXISTS "remind_select_caregiver" ON remind.reminders;
DROP POLICY IF EXISTS "remind_select_admin"     ON remind.reminders;
DROP POLICY IF EXISTS "remind_insert_patient"   ON remind.reminders;
DROP POLICY IF EXISTS "remind_insert_admin"     ON remind.reminders;
DROP POLICY IF EXISTS "remind_update_patient"   ON remind.reminders;
DROP POLICY IF EXISTS "remind_update_caregiver" ON remind.reminders;
DROP POLICY IF EXISTS "remind_update_admin"     ON remind.reminders;
DROP POLICY IF EXISTS "remind_delete_admin"     ON remind.reminders;

CREATE POLICY "remind_select_patient"
    ON remind.reminders FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "remind_select_caregiver"
    ON remind.reminders FOR SELECT
    USING (public.is_caregiver_of(user_id));

CREATE POLICY "remind_select_admin"
    ON remind.reminders FOR SELECT
    USING (public.is_admin());

-- Reminders are created by the system (service_role) or the patient directly
CREATE POLICY "remind_insert_patient"
    ON remind.reminders FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "remind_insert_admin"
    ON remind.reminders FOR INSERT
    WITH CHECK (public.is_admin());

-- Patient updates status (snooze, acknowledge)
CREATE POLICY "remind_update_patient"
    ON remind.reminders FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- Caregiver can acknowledge reminders (write+)
CREATE POLICY "remind_update_caregiver"
    ON remind.reminders FOR UPDATE
    USING (public.caregiver_can_write(user_id))
    WITH CHECK (public.caregiver_can_write(user_id));

CREATE POLICY "remind_update_admin"
    ON remind.reminders FOR UPDATE
    USING (public.is_admin());

CREATE POLICY "remind_delete_admin"
    ON remind.reminders FOR DELETE
    USING (public.is_admin());


-- =============================================================================
-- SECTION 12 — remind.dose_logs  (append-only for patients/caregivers)
-- =============================================================================

ALTER TABLE remind.dose_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "dose_log_select_patient"   ON remind.dose_logs;
DROP POLICY IF EXISTS "dose_log_select_caregiver" ON remind.dose_logs;
DROP POLICY IF EXISTS "dose_log_select_admin"     ON remind.dose_logs;
DROP POLICY IF EXISTS "dose_log_insert_patient"   ON remind.dose_logs;
DROP POLICY IF EXISTS "dose_log_insert_caregiver" ON remind.dose_logs;
DROP POLICY IF EXISTS "dose_log_insert_admin"     ON remind.dose_logs;
DROP POLICY IF EXISTS "dose_log_delete_admin"     ON remind.dose_logs;

CREATE POLICY "dose_log_select_patient"
    ON remind.dose_logs FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "dose_log_select_caregiver"
    ON remind.dose_logs FOR SELECT
    USING (public.is_caregiver_of(user_id));

CREATE POLICY "dose_log_select_admin"
    ON remind.dose_logs FOR SELECT
    USING (public.is_admin());

-- Dose logs are immutable — INSERT only, no UPDATE
CREATE POLICY "dose_log_insert_patient"
    ON remind.dose_logs FOR INSERT
    WITH CHECK (user_id = auth.uid());

-- Caregiver marks dose taken/skipped on behalf of patient (write+)
CREATE POLICY "dose_log_insert_caregiver"
    ON remind.dose_logs FOR INSERT
    WITH CHECK (public.caregiver_can_write(user_id));

CREATE POLICY "dose_log_insert_admin"
    ON remind.dose_logs FOR INSERT
    WITH CHECK (public.is_admin());

-- Only admins can delete dose logs (audit integrity)
CREATE POLICY "dose_log_delete_admin"
    ON remind.dose_logs FOR DELETE
    USING (public.is_admin());


-- =============================================================================
-- SECTION 13 — safety.drug_interactions  (reference catalog)
-- =============================================================================

ALTER TABLE safety.drug_interactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "drug_inter_select_authenticated" ON safety.drug_interactions;
DROP POLICY IF EXISTS "drug_inter_insert_admin"         ON safety.drug_interactions;
DROP POLICY IF EXISTS "drug_inter_update_admin"         ON safety.drug_interactions;
DROP POLICY IF EXISTS "drug_inter_delete_admin"         ON safety.drug_interactions;

-- All authenticated users can read interactions (needed for safety checks)
CREATE POLICY "drug_inter_select_authenticated"
    ON safety.drug_interactions FOR SELECT
    TO authenticated
    USING (TRUE);

CREATE POLICY "drug_inter_insert_admin"
    ON safety.drug_interactions FOR INSERT
    WITH CHECK (public.is_admin());

CREATE POLICY "drug_inter_update_admin"
    ON safety.drug_interactions FOR UPDATE
    USING (public.is_admin());

CREATE POLICY "drug_inter_delete_admin"
    ON safety.drug_interactions FOR DELETE
    USING (public.is_admin());


-- =============================================================================
-- SECTION 14 — safety.user_interaction_alerts
-- =============================================================================

ALTER TABLE safety.user_interaction_alerts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "alert_select_patient"   ON safety.user_interaction_alerts;
DROP POLICY IF EXISTS "alert_select_caregiver" ON safety.user_interaction_alerts;
DROP POLICY IF EXISTS "alert_select_admin"     ON safety.user_interaction_alerts;
DROP POLICY IF EXISTS "alert_insert_admin"     ON safety.user_interaction_alerts;
DROP POLICY IF EXISTS "alert_update_patient"   ON safety.user_interaction_alerts;
DROP POLICY IF EXISTS "alert_update_caregiver" ON safety.user_interaction_alerts;
DROP POLICY IF EXISTS "alert_update_admin"     ON safety.user_interaction_alerts;

CREATE POLICY "alert_select_patient"
    ON safety.user_interaction_alerts FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "alert_select_caregiver"
    ON safety.user_interaction_alerts FOR SELECT
    USING (public.is_caregiver_of(user_id));

CREATE POLICY "alert_select_admin"
    ON safety.user_interaction_alerts FOR SELECT
    USING (public.is_admin());

-- Alerts are system-generated; only service_role/admin inserts
CREATE POLICY "alert_insert_admin"
    ON safety.user_interaction_alerts FOR INSERT
    WITH CHECK (public.is_admin());

-- Patient acknowledges/overrides their own alert
CREATE POLICY "alert_update_patient"
    ON safety.user_interaction_alerts FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- Caregiver can acknowledge alerts for patients (write+)
CREATE POLICY "alert_update_caregiver"
    ON safety.user_interaction_alerts FOR UPDATE
    USING (public.caregiver_can_write(user_id))
    WITH CHECK (public.caregiver_can_write(user_id));

CREATE POLICY "alert_update_admin"
    ON safety.user_interaction_alerts FOR UPDATE
    USING (public.is_admin());


-- =============================================================================
-- SECTION 15 — i18n.languages  (public reference)
-- =============================================================================

ALTER TABLE i18n.languages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "lang_select_public" ON i18n.languages;
DROP POLICY IF EXISTS "lang_insert_admin"  ON i18n.languages;
DROP POLICY IF EXISTS "lang_update_admin"  ON i18n.languages;
DROP POLICY IF EXISTS "lang_delete_admin"  ON i18n.languages;

CREATE POLICY "lang_select_public"
    ON i18n.languages FOR SELECT
    USING (is_active = TRUE);

CREATE POLICY "lang_insert_admin"
    ON i18n.languages FOR INSERT
    WITH CHECK (public.is_admin());

CREATE POLICY "lang_update_admin"
    ON i18n.languages FOR UPDATE
    USING (public.is_admin());

CREATE POLICY "lang_delete_admin"
    ON i18n.languages FOR DELETE
    USING (public.is_admin());


-- =============================================================================
-- SECTION 16 — i18n.medicine_explanations  (shared reference)
-- =============================================================================

ALTER TABLE i18n.medicine_explanations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "med_expl_select_authenticated" ON i18n.medicine_explanations;
DROP POLICY IF EXISTS "med_expl_insert_admin"         ON i18n.medicine_explanations;
DROP POLICY IF EXISTS "med_expl_update_admin"         ON i18n.medicine_explanations;
DROP POLICY IF EXISTS "med_expl_delete_admin"         ON i18n.medicine_explanations;

CREATE POLICY "med_expl_select_authenticated"
    ON i18n.medicine_explanations FOR SELECT
    TO authenticated
    USING (TRUE);

CREATE POLICY "med_expl_insert_admin"
    ON i18n.medicine_explanations FOR INSERT
    WITH CHECK (public.is_admin());

CREATE POLICY "med_expl_update_admin"
    ON i18n.medicine_explanations FOR UPDATE
    USING (public.is_admin());

CREATE POLICY "med_expl_delete_admin"
    ON i18n.medicine_explanations FOR DELETE
    USING (public.is_admin());


-- =============================================================================
-- SECTION 17 — i18n.prescription_explanations
-- =============================================================================

ALTER TABLE i18n.prescription_explanations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "rx_expl_select_patient"   ON i18n.prescription_explanations;
DROP POLICY IF EXISTS "rx_expl_select_caregiver" ON i18n.prescription_explanations;
DROP POLICY IF EXISTS "rx_expl_select_admin"     ON i18n.prescription_explanations;
DROP POLICY IF EXISTS "rx_expl_insert_patient"   ON i18n.prescription_explanations;
DROP POLICY IF EXISTS "rx_expl_insert_admin"     ON i18n.prescription_explanations;
DROP POLICY IF EXISTS "rx_expl_update_patient"   ON i18n.prescription_explanations;
DROP POLICY IF EXISTS "rx_expl_update_admin"     ON i18n.prescription_explanations;
DROP POLICY IF EXISTS "rx_expl_delete_admin"     ON i18n.prescription_explanations;

CREATE POLICY "rx_expl_select_patient"
    ON i18n.prescription_explanations FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM rx.prescriptions p
            WHERE p.id = i18n.prescription_explanations.prescription_id
              AND p.user_id = auth.uid()
        )
    );

CREATE POLICY "rx_expl_select_caregiver"
    ON i18n.prescription_explanations FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM rx.prescriptions p
            WHERE p.id = i18n.prescription_explanations.prescription_id
              AND public.is_caregiver_of(p.user_id)
        )
    );

CREATE POLICY "rx_expl_select_admin"
    ON i18n.prescription_explanations FOR SELECT
    USING (public.is_admin());

-- System/patient generates explanations
CREATE POLICY "rx_expl_insert_patient"
    ON i18n.prescription_explanations FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM rx.prescriptions p
            WHERE p.id = i18n.prescription_explanations.prescription_id
              AND p.user_id = auth.uid()
        )
    );

CREATE POLICY "rx_expl_insert_admin"
    ON i18n.prescription_explanations FOR INSERT
    WITH CHECK (public.is_admin());

CREATE POLICY "rx_expl_update_patient"
    ON i18n.prescription_explanations FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM rx.prescriptions p
            WHERE p.id = i18n.prescription_explanations.prescription_id
              AND p.user_id = auth.uid()
        )
    );

CREATE POLICY "rx_expl_update_admin"
    ON i18n.prescription_explanations FOR UPDATE
    USING (public.is_admin());

CREATE POLICY "rx_expl_delete_admin"
    ON i18n.prescription_explanations FOR DELETE
    USING (public.is_admin());


-- =============================================================================
-- SECTION 18 — care.caregiver_relationships
-- =============================================================================

ALTER TABLE care.caregiver_relationships ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "care_rel_select_own"     ON care.caregiver_relationships;
DROP POLICY IF EXISTS "care_rel_select_admin"   ON care.caregiver_relationships;
DROP POLICY IF EXISTS "care_rel_insert_patient" ON care.caregiver_relationships;
DROP POLICY IF EXISTS "care_rel_insert_admin"   ON care.caregiver_relationships;
DROP POLICY IF EXISTS "care_rel_update_patient" ON care.caregiver_relationships;
DROP POLICY IF EXISTS "care_rel_update_caregiver" ON care.caregiver_relationships;
DROP POLICY IF EXISTS "care_rel_update_admin"   ON care.caregiver_relationships;
DROP POLICY IF EXISTS "care_rel_delete_patient" ON care.caregiver_relationships;
DROP POLICY IF EXISTS "care_rel_delete_admin"   ON care.caregiver_relationships;

-- Both parties see their own relationships
CREATE POLICY "care_rel_select_own"
    ON care.caregiver_relationships FOR SELECT
    USING (
        caregiver_user_id = auth.uid()
        OR patient_user_id = auth.uid()
    );

CREATE POLICY "care_rel_select_admin"
    ON care.caregiver_relationships FOR SELECT
    USING (public.is_admin());

-- Only the PATIENT invites/creates relationships
CREATE POLICY "care_rel_insert_patient"
    ON care.caregiver_relationships FOR INSERT
    WITH CHECK (patient_user_id = auth.uid());

CREATE POLICY "care_rel_insert_admin"
    ON care.caregiver_relationships FOR INSERT
    WITH CHECK (public.is_admin());

-- Patient can update their relationships (accept, revoke, change access level)
CREATE POLICY "care_rel_update_patient"
    ON care.caregiver_relationships FOR UPDATE
    USING (patient_user_id = auth.uid())
    WITH CHECK (patient_user_id = auth.uid());

-- Caregiver can accept a pending invitation (status: pending → active)
CREATE POLICY "care_rel_update_caregiver"
    ON care.caregiver_relationships FOR UPDATE
    USING (
        caregiver_user_id = auth.uid()
        AND status = 'pending'
    )
    WITH CHECK (
        caregiver_user_id = auth.uid()
        AND status = 'active'   -- caregiver can only accept, not revoke
    );

CREATE POLICY "care_rel_update_admin"
    ON care.caregiver_relationships FOR UPDATE
    USING (public.is_admin());

-- Only patient or admin can delete relationships
CREATE POLICY "care_rel_delete_patient"
    ON care.caregiver_relationships FOR DELETE
    USING (patient_user_id = auth.uid());

CREATE POLICY "care_rel_delete_admin"
    ON care.caregiver_relationships FOR DELETE
    USING (public.is_admin());


-- =============================================================================
-- SECTION 19 — care.caregiver_activity_logs  (audit — append-only)
-- =============================================================================

ALTER TABLE care.caregiver_activity_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "care_log_select_patient"   ON care.caregiver_activity_logs;
DROP POLICY IF EXISTS "care_log_select_caregiver" ON care.caregiver_activity_logs;
DROP POLICY IF EXISTS "care_log_select_admin"     ON care.caregiver_activity_logs;
DROP POLICY IF EXISTS "care_log_insert_caregiver" ON care.caregiver_activity_logs;
DROP POLICY IF EXISTS "care_log_insert_admin"     ON care.caregiver_activity_logs;
DROP POLICY IF EXISTS "care_log_delete_admin"     ON care.caregiver_activity_logs;

-- Patient sees all actions taken on their data
CREATE POLICY "care_log_select_patient"
    ON care.caregiver_activity_logs FOR SELECT
    USING (patient_user_id = auth.uid());

-- Caregiver sees their own activity
CREATE POLICY "care_log_select_caregiver"
    ON care.caregiver_activity_logs FOR SELECT
    USING (caregiver_user_id = auth.uid());

CREATE POLICY "care_log_select_admin"
    ON care.caregiver_activity_logs FOR SELECT
    USING (public.is_admin());

-- Caregivers write their own audit entries
CREATE POLICY "care_log_insert_caregiver"
    ON care.caregiver_activity_logs FOR INSERT
    WITH CHECK (
        caregiver_user_id = auth.uid()
        AND public.is_caregiver_of(patient_user_id)
    );

CREATE POLICY "care_log_insert_admin"
    ON care.caregiver_activity_logs FOR INSERT
    WITH CHECK (public.is_admin());

-- Audit logs are immutable — only admin can delete (e.g., GDPR request)
CREATE POLICY "care_log_delete_admin"
    ON care.caregiver_activity_logs FOR DELETE
    USING (public.is_admin());


-- =============================================================================
-- SECTION 20 — notify.notification_channels  (reference)
-- =============================================================================

ALTER TABLE notify.notification_channels ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "notif_chan_select_authenticated" ON notify.notification_channels;
DROP POLICY IF EXISTS "notif_chan_insert_admin"         ON notify.notification_channels;
DROP POLICY IF EXISTS "notif_chan_update_admin"         ON notify.notification_channels;
DROP POLICY IF EXISTS "notif_chan_delete_admin"         ON notify.notification_channels;

CREATE POLICY "notif_chan_select_authenticated"
    ON notify.notification_channels FOR SELECT
    TO authenticated
    USING (is_active = TRUE);

CREATE POLICY "notif_chan_insert_admin"
    ON notify.notification_channels FOR INSERT
    WITH CHECK (public.is_admin());

CREATE POLICY "notif_chan_update_admin"
    ON notify.notification_channels FOR UPDATE
    USING (public.is_admin());

CREATE POLICY "notif_chan_delete_admin"
    ON notify.notification_channels FOR DELETE
    USING (public.is_admin());


-- =============================================================================
-- SECTION 21 — notify.notification_templates  (reference)
-- =============================================================================

ALTER TABLE notify.notification_templates ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "notif_tmpl_select_authenticated" ON notify.notification_templates;
DROP POLICY IF EXISTS "notif_tmpl_insert_admin"         ON notify.notification_templates;
DROP POLICY IF EXISTS "notif_tmpl_update_admin"         ON notify.notification_templates;
DROP POLICY IF EXISTS "notif_tmpl_delete_admin"         ON notify.notification_templates;

CREATE POLICY "notif_tmpl_select_authenticated"
    ON notify.notification_templates FOR SELECT
    TO authenticated
    USING (is_active = TRUE);

CREATE POLICY "notif_tmpl_insert_admin"
    ON notify.notification_templates FOR INSERT
    WITH CHECK (public.is_admin());

CREATE POLICY "notif_tmpl_update_admin"
    ON notify.notification_templates FOR UPDATE
    USING (public.is_admin());

CREATE POLICY "notif_tmpl_delete_admin"
    ON notify.notification_templates FOR DELETE
    USING (public.is_admin());


-- =============================================================================
-- SECTION 22 — notify.notification_logs
-- =============================================================================

ALTER TABLE notify.notification_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "notif_log_select_patient"   ON notify.notification_logs;
DROP POLICY IF EXISTS "notif_log_select_caregiver" ON notify.notification_logs;
DROP POLICY IF EXISTS "notif_log_select_admin"     ON notify.notification_logs;
DROP POLICY IF EXISTS "notif_log_insert_admin"     ON notify.notification_logs;
DROP POLICY IF EXISTS "notif_log_delete_admin"     ON notify.notification_logs;

-- Patients see their own notification history
CREATE POLICY "notif_log_select_patient"
    ON notify.notification_logs FOR SELECT
    USING (user_id = auth.uid());

-- Caregivers see notification logs for assigned patients
CREATE POLICY "notif_log_select_caregiver"
    ON notify.notification_logs FOR SELECT
    USING (public.is_caregiver_of(user_id));

-- Admin sees all
CREATE POLICY "notif_log_select_admin"
    ON notify.notification_logs FOR SELECT
    USING (public.is_admin());

-- Only the system (service_role) / admin inserts notification log entries
CREATE POLICY "notif_log_insert_admin"
    ON notify.notification_logs FOR INSERT
    WITH CHECK (public.is_admin());

-- Only admin can purge logs (retention/GDPR)
CREATE POLICY "notif_log_delete_admin"
    ON notify.notification_logs FOR DELETE
    USING (public.is_admin());


-- =============================================================================
-- GRANTS — ensure roles can use schemas and invoke helpers
-- =============================================================================

GRANT USAGE ON SCHEMA
    auth_ext, rx, ocr, med, sched, remind, safety, i18n, care, notify
TO authenticated;

GRANT EXECUTE ON FUNCTION public.current_user_role()          TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin()                   TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_caregiver_of(UUID)        TO authenticated;
GRANT EXECUTE ON FUNCTION public.caregiver_can_write(UUID)    TO authenticated;
GRANT EXECUTE ON FUNCTION public.caregiver_is_admin_of(UUID)  TO authenticated;

-- service_role bypasses RLS entirely — no additional grants needed


-- =============================================================================
-- VERIFICATION QUERIES  (run after applying to confirm policies are active)
-- =============================================================================

-- Check all RLS-enabled tables
-- SELECT schemaname, tablename, rowsecurity
-- FROM   pg_tables
-- WHERE  schemaname IN ('auth_ext','rx','ocr','med','sched','remind','safety','i18n','care','notify')
--   AND  rowsecurity = true
-- ORDER  BY schemaname, tablename;

-- List all policies
-- SELECT schemaname, tablename, policyname, cmd, roles, qual
-- FROM   pg_policies
-- WHERE  schemaname IN ('auth_ext','rx','ocr','med','sched','remind','safety','i18n','care','notify')
-- ORDER  BY schemaname, tablename, policyname;


-- =============================================================================
-- END OF RLS POLICIES
-- =============================================================================
