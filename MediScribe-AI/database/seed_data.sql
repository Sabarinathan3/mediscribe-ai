-- =============================================================================
-- MediScribe AI — Realistic Seed Data
-- =============================================================================
-- PostgreSQL 16 | Supabase Compatible
-- Generated: 2026-06-24
--
-- Execution order (respects FK dependencies):
--   1. auth_ext.user_profiles
--   2. med.medicines + med.medicine_aliases
--   3. rx.prescriptions
--   4. rx.prescription_medicines
--   5. ocr.ocr_jobs
--   6. sched.medicine_schedules
--   7. sched.schedule_exceptions
--   8. remind.reminders  (50 rows)
--   9. remind.dose_logs
--  10. safety.drug_interactions  (20 pairs)
--  11. safety.user_interaction_alerts
--  12. i18n.medicine_explanations  (10 rows)
--  13. care.caregiver_relationships
--  14. care.caregiver_activity_logs
--  15. notify.notification_logs
-- =============================================================================


-- =============================================================================
-- 0. FIXED UUIDs  (declared as variables via DO block for readability)
-- =============================================================================
-- NOTE: In Supabase, auth.users rows are created by the Auth service.
--       These UUIDs simulate existing auth.uid() values.
--       Run this seed AFTER the auth users exist, or set up test users first.


-- =============================================================================
-- 1. USERS  (auth_ext.user_profiles — 10 rows)
-- =============================================================================

INSERT INTO auth_ext.user_profiles
    (id, user_id, full_name, phone, locale, role, date_of_birth, gender,
     blood_group, allergies, chronic_conditions, avatar_url, is_active,
     created_at, updated_at)
VALUES

-- Patient 1
('a1000000-0000-0000-0000-000000000001',
 'a1000000-0000-0000-0000-000000000001',
 'Arjun Mehta', '+919876543210', 'hi', 'patient',
 '1985-03-14', 'male', 'B+',
 ARRAY['Penicillin', 'Sulfa drugs'],
 ARRAY['Type 2 Diabetes', 'Hypertension'],
 'https://api.dicebear.com/7.x/avataaars/svg?seed=ArjunMehta',
 TRUE, NOW() - INTERVAL '180 days', NOW() - INTERVAL '2 days'),

-- Patient 2
('a2000000-0000-0000-0000-000000000002',
 'a2000000-0000-0000-0000-000000000002',
 'Priya Sharma', '+919812345678', 'ta', 'patient',
 '1992-07-22', 'female', 'O+',
 ARRAY['Aspirin', 'Latex'],
 ARRAY['Hypothyroidism', 'PCOS'],
 'https://api.dicebear.com/7.x/avataaars/svg?seed=PriyaSharma',
 TRUE, NOW() - INTERVAL '150 days', NOW() - INTERVAL '5 days'),

-- Patient 3
('a3000000-0000-0000-0000-000000000003',
 'a3000000-0000-0000-0000-000000000003',
 'Ravi Kumar', '+919823456789', 'kn', 'patient',
 '1971-11-05', 'male', 'A+',
 ARRAY['NSAIDs'],
 ARRAY['Chronic Kidney Disease', 'Hypertension', 'Anaemia'],
 'https://api.dicebear.com/7.x/avataaars/svg?seed=RaviKumar',
 TRUE, NOW() - INTERVAL '200 days', NOW() - INTERVAL '1 day'),

-- Patient 4
('a4000000-0000-0000-0000-000000000004',
 'a4000000-0000-0000-0000-000000000004',
 'Fatima Begum', '+919834567890', 'ar', 'patient',
 '1968-05-30', 'female', 'AB-',
 ARRAY['Codeine'],
 ARRAY['Rheumatoid Arthritis', 'Osteoporosis'],
 'https://api.dicebear.com/7.x/avataaars/svg?seed=FatimaBegum',
 TRUE, NOW() - INTERVAL '90 days', NOW() - INTERVAL '3 days'),

-- Patient 5
('a5000000-0000-0000-0000-000000000005',
 'a5000000-0000-0000-0000-000000000005',
 'Suresh Pillai', '+919845678901', 'ml', 'patient',
 '1979-09-17', 'male', 'O-',
 ARRAY['Shellfish allergy'],
 ARRAY['Asthma', 'Acid Reflux'],
 'https://api.dicebear.com/7.x/avataaars/svg?seed=SureshPillai',
 TRUE, NOW() - INTERVAL '120 days', NOW() - INTERVAL '10 days'),

-- Caregiver 1 (for Patient 1)
('b1000000-0000-0000-0000-000000000006',
 'b1000000-0000-0000-0000-000000000006',
 'Sneha Mehta', '+919856789012', 'hi', 'caregiver',
 '1988-01-10', 'female', 'B+',
 ARRAY[]::TEXT[], ARRAY[]::TEXT[],
 'https://api.dicebear.com/7.x/avataaars/svg?seed=SnehaMehta',
 TRUE, NOW() - INTERVAL '170 days', NOW() - INTERVAL '4 days'),

-- Caregiver 2 (for Patient 3 & 4)
('b2000000-0000-0000-0000-000000000007',
 'b2000000-0000-0000-0000-000000000007',
 'Dr. Ananya Rao', '+919867890123', 'te', 'caregiver',
 '1980-06-25', 'female', 'A-',
 ARRAY[]::TEXT[], ARRAY[]::TEXT[],
 'https://api.dicebear.com/7.x/avataaars/svg?seed=AnanyaRao',
 TRUE, NOW() - INTERVAL '210 days', NOW() - INTERVAL '1 day'),

-- Caregiver 3 (for Patient 2)
('b3000000-0000-0000-0000-000000000008',
 'b3000000-0000-0000-0000-000000000008',
 'Karan Sharma', '+919878901234', 'en', 'caregiver',
 '1990-12-03', 'male', 'O+',
 ARRAY[]::TEXT[], ARRAY[]::TEXT[],
 'https://api.dicebear.com/7.x/avataaars/svg?seed=KaranSharma',
 TRUE, NOW() - INTERVAL '140 days', NOW() - INTERVAL '6 days'),

-- Admin 1
('c1000000-0000-0000-0000-000000000009',
 'c1000000-0000-0000-0000-000000000009',
 'Admin MediScribe', '+919889012345', 'en', 'admin',
 '1982-04-20', 'male', 'A+',
 ARRAY[]::TEXT[], ARRAY[]::TEXT[],
 'https://api.dicebear.com/7.x/avataaars/svg?seed=AdminMediScribe',
 TRUE, NOW() - INTERVAL '365 days', NOW() - INTERVAL '1 day'),

-- Patient 6 (elderly, multiple conditions)
('a6000000-0000-0000-0000-000000000010',
 'a6000000-0000-0000-0000-000000000010',
 'Kamala Devi', '+919890123456', 'mr', 'patient',
 '1952-08-11', 'female', 'B-',
 ARRAY['Morphine', 'Contrast dye'],
 ARRAY['Heart Failure', 'Type 2 Diabetes', 'CKD Stage 3', 'Hypothyroidism'],
 'https://api.dicebear.com/7.x/avataaars/svg?seed=KamalaDevi',
 TRUE, NOW() - INTERVAL '60 days', NOW() - INTERVAL '1 day');


-- =============================================================================
-- 2. MEDICINES  (med.medicines — 20 rows)
-- =============================================================================

INSERT INTO med.medicines
    (id, name, generic_name, brand_name, manufacturer, drug_class,
     form, strength, unit, is_otc, is_controlled, is_active,
     created_at, updated_at, created_by)
VALUES

('m01-0000-0000-0000-000000000001',
 'Metformin 500mg', 'Metformin Hydrochloride', 'Glucophage',
 'Sun Pharma', 'Biguanide Antidiabetic',
 'tablet', '500', 'mg', FALSE, FALSE, TRUE,
 NOW() - INTERVAL '365 days', NOW() - INTERVAL '30 days',
 'c1000000-0000-0000-0000-000000000009'),

('m02-0000-0000-0000-000000000002',
 'Metformin 1000mg', 'Metformin Hydrochloride', 'Glucophage XR',
 'Sun Pharma', 'Biguanide Antidiabetic',
 'tablet', '1000', 'mg', FALSE, FALSE, TRUE,
 NOW() - INTERVAL '365 days', NOW() - INTERVAL '30 days',
 'c1000000-0000-0000-0000-000000000009'),

('m03-0000-0000-0000-000000000003',
 'Amlodipine 5mg', 'Amlodipine Besylate', 'Norvasc',
 'Pfizer', 'Calcium Channel Blocker',
 'tablet', '5', 'mg', FALSE, FALSE, TRUE,
 NOW() - INTERVAL '365 days', NOW() - INTERVAL '60 days',
 'c1000000-0000-0000-0000-000000000009'),

('m04-0000-0000-0000-000000000004',
 'Atorvastatin 10mg', 'Atorvastatin Calcium', 'Lipitor',
 'Pfizer', 'HMG-CoA Reductase Inhibitor (Statin)',
 'tablet', '10', 'mg', FALSE, FALSE, TRUE,
 NOW() - INTERVAL '365 days', NOW() - INTERVAL '45 days',
 'c1000000-0000-0000-0000-000000000009'),

('m05-0000-0000-0000-000000000005',
 'Atorvastatin 40mg', 'Atorvastatin Calcium', 'Lipitor',
 'Pfizer', 'HMG-CoA Reductase Inhibitor (Statin)',
 'tablet', '40', 'mg', FALSE, FALSE, TRUE,
 NOW() - INTERVAL '365 days', NOW() - INTERVAL '45 days',
 'c1000000-0000-0000-0000-000000000009'),

('m06-0000-0000-0000-000000000006',
 'Levothyroxine 50mcg', 'Levothyroxine Sodium', 'Synthroid',
 'AbbVie', 'Thyroid Hormone',
 'tablet', '50', 'mcg', FALSE, FALSE, TRUE,
 NOW() - INTERVAL '300 days', NOW() - INTERVAL '20 days',
 'c1000000-0000-0000-0000-000000000009'),

('m07-0000-0000-0000-000000000007',
 'Levothyroxine 100mcg', 'Levothyroxine Sodium', 'Synthroid',
 'AbbVie', 'Thyroid Hormone',
 'tablet', '100', 'mcg', FALSE, FALSE, TRUE,
 NOW() - INTERVAL '300 days', NOW() - INTERVAL '20 days',
 'c1000000-0000-0000-0000-000000000009'),

('m08-0000-0000-0000-000000000008',
 'Omeprazole 20mg', 'Omeprazole', 'Prilosec',
 'AstraZeneca', 'Proton Pump Inhibitor',
 'capsule', '20', 'mg', TRUE, FALSE, TRUE,
 NOW() - INTERVAL '365 days', NOW() - INTERVAL '10 days',
 'c1000000-0000-0000-0000-000000000009'),

('m09-0000-0000-0000-000000000009',
 'Salbutamol 100mcg Inhaler', 'Salbutamol Sulfate', 'Ventolin',
 'GSK', 'Short-acting Beta-2 Agonist (SABA)',
 'inhaler', '100', 'mcg', FALSE, FALSE, TRUE,
 NOW() - INTERVAL '365 days', NOW() - INTERVAL '15 days',
 'c1000000-0000-0000-0000-000000000009'),

('m10-0000-0000-0000-000000000010',
 'Methotrexate 2.5mg', 'Methotrexate', 'Rheumatrex',
 'Ipca Laboratories', 'Disease-Modifying Antirheumatic Drug (DMARD)',
 'tablet', '2.5', 'mg', FALSE, FALSE, TRUE,
 NOW() - INTERVAL '300 days', NOW() - INTERVAL '30 days',
 'c1000000-0000-0000-0000-000000000009'),

('m11-0000-0000-0000-000000000011',
 'Folic Acid 5mg', 'Folic Acid', 'Folvite',
 'Abbott', 'Vitamin B9 Supplement',
 'tablet', '5', 'mg', TRUE, FALSE, TRUE,
 NOW() - INTERVAL '365 days', NOW() - INTERVAL '10 days',
 'c1000000-0000-0000-0000-000000000009'),

('m12-0000-0000-0000-000000000012',
 'Losartan 50mg', 'Losartan Potassium', 'Cozaar',
 'MSD', 'Angiotensin II Receptor Blocker (ARB)',
 'tablet', '50', 'mg', FALSE, FALSE, TRUE,
 NOW() - INTERVAL '365 days', NOW() - INTERVAL '25 days',
 'c1000000-0000-0000-0000-000000000009'),

('m13-0000-0000-0000-000000000013',
 'Furosemide 40mg', 'Furosemide', 'Lasix',
 'Sanofi', 'Loop Diuretic',
 'tablet', '40', 'mg', FALSE, FALSE, TRUE,
 NOW() - INTERVAL '365 days', NOW() - INTERVAL '10 days',
 'c1000000-0000-0000-0000-000000000009'),

('m14-0000-0000-0000-000000000014',
 'Carvedilol 6.25mg', 'Carvedilol', 'Coreg',
 'GSK', 'Alpha-Beta Blocker',
 'tablet', '6.25', 'mg', FALSE, FALSE, TRUE,
 NOW() - INTERVAL '365 days', NOW() - INTERVAL '15 days',
 'c1000000-0000-0000-0000-000000000009'),

('m15-0000-0000-0000-000000000015',
 'Warfarin 2mg', 'Warfarin Sodium', 'Coumadin',
 'BMS', 'Vitamin K Antagonist Anticoagulant',
 'tablet', '2', 'mg', FALSE, FALSE, TRUE,
 NOW() - INTERVAL '365 days', NOW() - INTERVAL '10 days',
 'c1000000-0000-0000-0000-000000000009'),

('m16-0000-0000-0000-000000000016',
 'Glimepiride 2mg', 'Glimepiride', 'Amaryl',
 'Sanofi', 'Sulfonylurea Antidiabetic',
 'tablet', '2', 'mg', FALSE, FALSE, TRUE,
 NOW() - INTERVAL '365 days', NOW() - INTERVAL '20 days',
 'c1000000-0000-0000-0000-000000000009'),

('m17-0000-0000-0000-000000000017',
 'Pantoprazole 40mg', 'Pantoprazole Sodium', 'Pantodac',
 'Zydus Cadila', 'Proton Pump Inhibitor',
 'tablet', '40', 'mg', FALSE, FALSE, TRUE,
 NOW() - INTERVAL '365 days', NOW() - INTERVAL '10 days',
 'c1000000-0000-0000-0000-000000000009'),

('m18-0000-0000-0000-000000000018',
 'Erythropoietin 4000 IU Injection', 'Epoetin Alfa', 'Eprex',
 'Janssen', 'Erythropoiesis-Stimulating Agent',
 'injection', '4000', 'IU', FALSE, FALSE, TRUE,
 NOW() - INTERVAL '300 days', NOW() - INTERVAL '30 days',
 'c1000000-0000-0000-0000-000000000009'),

('m19-0000-0000-0000-000000000019',
 'Calcium Carbonate 500mg', 'Calcium Carbonate', 'Shelcal',
 'Elder Pharma', 'Calcium Supplement',
 'tablet', '500', 'mg', TRUE, FALSE, TRUE,
 NOW() - INTERVAL '365 days', NOW() - INTERVAL '10 days',
 'c1000000-0000-0000-0000-000000000009'),

('m20-0000-0000-0000-000000000020',
 'Aspirin 75mg', 'Acetylsalicylic Acid', 'Ecosprin',
 'USV', 'Antiplatelet / NSAID',
 'tablet', '75', 'mg', TRUE, FALSE, TRUE,
 NOW() - INTERVAL '365 days', NOW() - INTERVAL '10 days',
 'c1000000-0000-0000-0000-000000000009');


-- =============================================================================
-- 2b. MEDICINE ALIASES  (med.medicine_aliases)
-- =============================================================================

INSERT INTO med.medicine_aliases (id, medicine_id, alias, locale) VALUES
('ma01-000-0000-0000-000000000001', 'm01-0000-0000-0000-000000000001', 'मेटफॉर्मिन', 'hi'),
('ma02-000-0000-0000-000000000002', 'm01-0000-0000-0000-000000000001', 'மெட்ஃபார்மின்', 'ta'),
('ma03-000-0000-0000-000000000003', 'm01-0000-0000-0000-000000000001', 'Metformine', 'fr'),
('ma04-000-0000-0000-000000000004', 'm03-0000-0000-0000-000000000003', 'அம்லோடிபைன்', 'ta'),
('ma05-000-0000-0000-000000000005', 'm03-0000-0000-0000-000000000003', 'अम्लोडिपिन', 'hi'),
('ma06-000-0000-0000-000000000006', 'm06-0000-0000-0000-000000000006', 'लेवोथायरोक्सिन', 'hi'),
('ma07-000-0000-0000-000000000007', 'm09-0000-0000-0000-000000000009', 'Salbutamol Inhaler', 'en'),
('ma08-000-0000-0000-000000000008', 'm15-0000-0000-0000-000000000015', 'وارفارين', 'ar'),
('ma09-000-0000-0000-000000000009', 'm13-0000-0000-0000-000000000013', 'Lasix', 'en'),
('ma10-000-0000-0000-000000000010', 'm20-0000-0000-0000-000000000020', 'ആസ്പിരിൻ', 'ml');


-- =============================================================================
-- 3. PRESCRIPTIONS  (rx.prescriptions — 10 rows)
-- =============================================================================

INSERT INTO rx.prescriptions
    (id, user_id, caregiver_id, title, doctor_name, hospital_name,
     prescribed_date, valid_until, status, raw_notes,
     created_at, updated_at, created_by)
VALUES

('rx01-0000-0000-0000-000000000001',
 'a1000000-0000-0000-0000-000000000001', NULL,
 'Diabetes & BP Management', 'Dr. Ramesh Gupta', 'Apollo Hospitals Delhi',
 '2026-01-15', '2026-07-15', 'active',
 'Patient on dual therapy for T2DM + HTN. Monitor RFT quarterly.',
 NOW() - INTERVAL '160 days', NOW() - INTERVAL '2 days',
 'a1000000-0000-0000-0000-000000000001'),

('rx02-0000-0000-0000-000000000002',
 'a2000000-0000-0000-0000-000000000002', 'b3000000-0000-0000-0000-000000000008',
 'Hypothyroid & PCOS Treatment', 'Dr. Meera Nair', 'Fortis Hospital Chennai',
 '2026-02-10', '2026-08-10', 'active',
 'Thyroid levels improving. Review after 3 months. Ensure empty stomach dosing for Levothyroxine.',
 NOW() - INTERVAL '134 days', NOW() - INTERVAL '5 days',
 'b3000000-0000-0000-0000-000000000008'),

('rx03-0000-0000-0000-000000000003',
 'a3000000-0000-0000-0000-000000000003', 'b2000000-0000-0000-0000-000000000007',
 'CKD & Hypertension Protocol', 'Dr. Ananya Rao', 'Manipal Hospital Bengaluru',
 '2026-03-01', '2026-06-01', 'expired',
 'CrCl 35 ml/min. Avoid NSAIDs. Restrict potassium diet. Monitor BP daily.',
 NOW() - INTERVAL '116 days', NOW() - INTERVAL '1 day',
 'b2000000-0000-0000-0000-000000000007'),

('rx04-0000-0000-0000-000000000004',
 'a3000000-0000-0000-0000-000000000003', 'b2000000-0000-0000-0000-000000000007',
 'CKD Revised Protocol Q2', 'Dr. Ananya Rao', 'Manipal Hospital Bengaluru',
 '2026-06-01', '2026-12-01', 'active',
 'GFR stable at 38. Continue EPO injections. Monthly haemoglobin check.',
 NOW() - INTERVAL '23 days', NOW() - INTERVAL '1 day',
 'b2000000-0000-0000-0000-000000000007'),

('rx05-0000-0000-0000-000000000005',
 'a4000000-0000-0000-0000-000000000004', 'b2000000-0000-0000-0000-000000000007',
 'Rheumatoid Arthritis Management', 'Dr. Ananya Rao', 'AIIMS New Delhi',
 '2026-03-15', '2026-09-15', 'active',
 'MTX weekly dose with folic acid supplementation. Monitor LFT monthly. Bone density scan scheduled.',
 NOW() - INTERVAL '101 days', NOW() - INTERVAL '3 days',
 'b2000000-0000-0000-0000-000000000007'),

('rx06-0000-0000-0000-000000000006',
 'a5000000-0000-0000-0000-000000000005', NULL,
 'Asthma + Acid Reflux Treatment', 'Dr. Suresh Menon', 'PVS Hospital Kochi',
 '2026-04-01', '2026-10-01', 'active',
 'Use salbutamol as rescue inhaler only. Omeprazole 30 min before breakfast. Avoid trigger foods.',
 NOW() - INTERVAL '84 days', NOW() - INTERVAL '10 days',
 'a5000000-0000-0000-0000-000000000005'),

('rx07-0000-0000-0000-000000000007',
 'a6000000-0000-0000-0000-000000000010', NULL,
 'Heart Failure Complex Regimen', 'Dr. Vijay Kulkarni', 'KEM Hospital Mumbai',
 '2026-05-01', '2026-11-01', 'active',
 'HFrEF EF 35%. Fluid restriction 1.5L/day. Daily weight monitoring. Call if >2kg gain in 24h.',
 NOW() - INTERVAL '54 days', NOW() - INTERVAL '1 day',
 'a6000000-0000-0000-0000-000000000010'),

('rx08-0000-0000-0000-000000000008',
 'a1000000-0000-0000-0000-000000000001', NULL,
 'Lipid Management Add-on', 'Dr. Ramesh Gupta', 'Apollo Hospitals Delhi',
 '2026-05-20', '2026-11-20', 'active',
 'LDL 145 mg/dL. Target LDL < 70 for diabetic patient. Recheck lipids in 6 weeks.',
 NOW() - INTERVAL '35 days', NOW() - INTERVAL '2 days',
 'a1000000-0000-0000-0000-000000000001'),

('rx09-0000-0000-0000-000000000009',
 'a2000000-0000-0000-0000-000000000002', NULL,
 'Gastritis Short Course', 'Dr. Pradeep Iyer', 'Global Hospital Chennai',
 '2026-06-01', '2026-06-29', 'active',
 'H. pylori positive. PPI therapy for 4 weeks. Retest after completion.',
 NOW() - INTERVAL '23 days', NOW() - INTERVAL '5 days',
 'a2000000-0000-0000-0000-000000000002'),

('rx10-0000-0000-0000-000000000010',
 'a6000000-0000-0000-0000-000000000010', NULL,
 'Diabetes Management for Kamala', 'Dr. Vijay Kulkarni', 'KEM Hospital Mumbai',
 '2026-05-15', '2026-11-15', 'active',
 'HbA1c 8.2%. Intensify diabetes regimen. Add glimepiride with caution given CKD.',
 NOW() - INTERVAL '40 days', NOW() - INTERVAL '1 day',
 'a6000000-0000-0000-0000-000000000010');


-- =============================================================================
-- 4. PRESCRIPTION MEDICINES  (rx.prescription_medicines)
-- =============================================================================

INSERT INTO rx.prescription_medicines
    (id, prescription_id, medicine_id, dosage, frequency, route,
     instructions, duration_days, start_date, end_date,
     quantity_prescribed, refills_allowed)
VALUES

-- Rx01: Arjun — Metformin 500mg BD + Amlodipine 5mg OD
('pm01-000-0000-0000-000000000001',
 'rx01-0000-0000-0000-000000000001', 'm01-0000-0000-0000-000000000001',
 '500mg', 'Twice daily', 'oral',
 'Take after meals with water', 180, '2026-01-15', '2026-07-15', 360, 1),

('pm02-000-0000-0000-000000000002',
 'rx01-0000-0000-0000-000000000001', 'm03-0000-0000-0000-000000000003',
 '5mg', 'Once daily', 'oral',
 'Take in the morning at the same time each day', 180, '2026-01-15', '2026-07-15', 180, 1),

-- Rx02: Priya — Levothyroxine 100mcg OD
('pm03-000-0000-0000-000000000003',
 'rx02-0000-0000-0000-000000000002', 'm07-0000-0000-0000-000000000007',
 '100mcg', 'Once daily', 'oral',
 'Take on empty stomach 30–60 min before breakfast. Separate from calcium/iron by 4 hours.', 180, '2026-02-10', '2026-08-10', 180, 1),

-- Rx03: Ravi — Losartan 50mg OD + Furosemide 40mg OD (expired Rx)
('pm04-000-0000-0000-000000000004',
 'rx03-0000-0000-0000-000000000003', 'm12-0000-0000-0000-000000000012',
 '50mg', 'Once daily', 'oral',
 'Monitor blood pressure and serum potassium monthly', 92, '2026-03-01', '2026-06-01', 92, 0),

('pm05-000-0000-0000-000000000005',
 'rx03-0000-0000-0000-000000000003', 'm13-0000-0000-0000-000000000013',
 '40mg', 'Once daily morning', 'oral',
 'Take in the morning. Monitor weight daily. Report sudden >2kg gain.', 92, '2026-03-01', '2026-06-01', 92, 0),

-- Rx04: Ravi — CKD revised (Losartan + EPO + Calcium)
('pm06-000-0000-0000-000000000006',
 'rx04-0000-0000-0000-000000000004', 'm12-0000-0000-0000-000000000012',
 '50mg', 'Once daily', 'oral',
 'Take at the same time each day. Avoid high-potassium foods.', 184, '2026-06-01', '2026-12-01', 184, 1),

('pm07-000-0000-0000-000000000007',
 'rx04-0000-0000-0000-000000000004', 'm18-0000-0000-0000-000000000018',
 '4000 IU', 'Three times weekly', 'subcutaneous',
 'Inject subcutaneously on Mon/Wed/Fri. Rotate injection sites.', 184, '2026-06-01', '2026-12-01', 72, 1),

('pm08-000-0000-0000-000000000008',
 'rx04-0000-0000-0000-000000000004', 'm19-0000-0000-0000-000000000019',
 '500mg', 'Twice daily', 'oral',
 'Take after meals to reduce GI side effects', 184, '2026-06-01', '2026-12-01', 368, 1),

-- Rx05: Fatima — Methotrexate 2.5mg weekly + Folic Acid 5mg (6 days/week)
('pm09-000-0000-0000-000000000009',
 'rx05-0000-0000-0000-000000000005', 'm10-0000-0000-0000-000000000010',
 '15mg (6 tablets)', 'Once weekly on Saturday', 'oral',
 'Take all 6 tablets together on Saturday morning. Never take on same day as folic acid.', 184, '2026-03-15', '2026-09-15', 26, 1),

('pm10-000-0000-0000-000000000010',
 'rx05-0000-0000-0000-000000000005', 'm11-0000-0000-0000-000000000011',
 '5mg', 'Once daily except Saturday', 'oral',
 'Take every day EXCEPT the day you take methotrexate (Saturday).', 184, '2026-03-15', '2026-09-15', 158, 1),

-- Rx06: Suresh — Salbutamol Inhaler PRN + Omeprazole OD
('pm11-000-0000-0000-000000000011',
 'rx06-0000-0000-0000-000000000006', 'm09-0000-0000-0000-000000000009',
 '200mcg (2 puffs)', 'As needed', 'inhalation',
 'Use only during asthma attack or before exercise. Max 8 puffs/day. Seek help if >4 puffs needed.', 184, '2026-04-01', '2026-10-01', 1, 1),

('pm12-000-0000-0000-000000000012',
 'rx06-0000-0000-0000-000000000006', 'm08-0000-0000-0000-000000000008',
 '20mg', 'Once daily', 'oral',
 'Take 30 minutes before breakfast. Swallow whole, do not crush.', 184, '2026-04-01', '2026-10-01', 184, 1),

-- Rx07: Kamala — Heart Failure: Furosemide + Carvedilol + Warfarin
('pm13-000-0000-0000-000000000013',
 'rx07-0000-0000-0000-000000000007', 'm13-0000-0000-0000-000000000013',
 '40mg', 'Once daily morning', 'oral',
 'Take in morning. Weigh yourself daily. Call doctor if weight increases >2kg overnight.', 184, '2026-05-01', '2026-11-01', 184, 1),

('pm14-000-0000-0000-000000000014',
 'rx07-0000-0000-0000-000000000007', 'm14-0000-0000-0000-000000000014',
 '6.25mg', 'Twice daily', 'oral',
 'Take with food. Do not stop suddenly. Call if heart rate drops below 55/min.', 184, '2026-05-01', '2026-11-01', 368, 1),

('pm15-000-0000-0000-000000000015',
 'rx07-0000-0000-0000-000000000007', 'm15-0000-0000-0000-000000000015',
 '2mg', 'Once daily at 6pm', 'oral',
 'Take at the same time every day. INR target 2–3. Monthly blood test mandatory.', 184, '2026-05-01', '2026-11-01', 184, 1),

-- Rx08: Arjun — Atorvastatin 40mg OD
('pm16-000-0000-0000-000000000016',
 'rx08-0000-0000-0000-000000000008', 'm05-0000-0000-0000-000000000005',
 '40mg', 'Once daily at night', 'oral',
 'Take at bedtime. Avoid grapefruit juice. Report muscle pain immediately.', 184, '2026-05-20', '2026-11-20', 184, 1),

-- Rx09: Priya — Pantoprazole 40mg BD
('pm17-000-0000-0000-000000000017',
 'rx09-0000-0000-0000-000000000009', 'm17-0000-0000-0000-000000000017',
 '40mg', 'Twice daily', 'oral',
 'Take 30 minutes before breakfast and dinner for 4 weeks.', 28, '2026-06-01', '2026-06-29', 56, 0),

-- Rx10: Kamala — Metformin 500mg BD + Glimepiride 2mg OD
('pm18-000-0000-0000-000000000018',
 'rx10-0000-0000-0000-000000000010', 'm01-0000-0000-0000-000000000001',
 '500mg', 'Twice daily', 'oral',
 'Take with meals. Monitor blood sugar daily. Dose reduced due to CKD.', 184, '2026-05-15', '2026-11-15', 368, 1),

('pm19-000-0000-0000-000000000019',
 'rx10-0000-0000-0000-000000000010', 'm16-0000-0000-0000-000000000016',
 '2mg', 'Once daily with breakfast', 'oral',
 'Take with first bite of breakfast. Risk of hypoglycaemia — carry glucose tablets.', 184, '2026-05-15', '2026-11-15', 184, 1);


-- =============================================================================
-- 5. OCR JOBS  (ocr.ocr_jobs)
-- =============================================================================

INSERT INTO ocr.ocr_jobs
    (id, prescription_image_id, user_id, status, engine_used,
     confidence_score, raw_text, structured_data, error_message,
     started_at, completed_at, created_at)
VALUES

-- We skip prescription_images for brevity; use representative image UUIDs
('ocr1-0000-0000-0000-000000000001',
 -- Simulate image UUID inline
 gen_random_uuid(),
 'a1000000-0000-0000-0000-000000000001',
 'completed', 'google-vision', 0.97,
 'APOLLO HOSPITALS\nDr Ramesh Gupta MD\nPatient: Arjun Mehta DOB: 14-Mar-1985\nRx: Tab Metformin 500mg BD AF\n    Tab Amlodipine 5mg OD AM\nDate: 15-Jan-2026  Valid: 15-Jul-2026',
 '{"medicines":[{"name":"Metformin","strength":"500mg","frequency":"BD","route":"oral"},{"name":"Amlodipine","strength":"5mg","frequency":"OD","route":"oral"}],"doctor":"Dr Ramesh Gupta","hospital":"Apollo Hospitals","date":"2026-01-15"}',
 NULL,
 NOW() - INTERVAL '160 days' + INTERVAL '2 minutes',
 NOW() - INTERVAL '160 days' + INTERVAL '14 seconds',
 NOW() - INTERVAL '160 days'),

('ocr2-0000-0000-0000-000000000002',
 gen_random_uuid(),
 'a2000000-0000-0000-0000-000000000002',
 'completed', 'azure-ocr', 0.91,
 'FORTIS HOSPITAL CHENNAI\nDr Meera Nair MBBS MD Endo\nPt: Priya Sharma  10/02/2026\nRx: Tab Levothyroxine 100mcg OD empty stomach\nRev 3/m TSH target 0.5-2.5',
 '{"medicines":[{"name":"Levothyroxine","strength":"100mcg","frequency":"OD","instructions":"empty stomach"}],"doctor":"Dr Meera Nair","hospital":"Fortis Hospital Chennai","date":"2026-02-10"}',
 NULL,
 NOW() - INTERVAL '134 days' + INTERVAL '1 minute',
 NOW() - INTERVAL '134 days' + INTERVAL '22 seconds',
 NOW() - INTERVAL '134 days'),

('ocr3-0000-0000-0000-000000000003',
 gen_random_uuid(),
 'a5000000-0000-0000-0000-000000000005',
 'completed', 'tesseract', 0.78,
 'PVS HOSPITAL KOCHI\nDr Suresh Menon MD\nPt: Suresh Pillai 01/04/2026\nRx Salbutamol Inhaler 100 mcg 2 puffs prn\n   Omeprazole cap 20mg od ac breakfast',
 '{"medicines":[{"name":"Salbutamol Inhaler","strength":"100mcg","frequency":"PRN"},{"name":"Omeprazole","strength":"20mg","frequency":"OD","instructions":"before breakfast"}],"doctor":"Dr Suresh Menon","date":"2026-04-01"}',
 NULL,
 NOW() - INTERVAL '84 days' + INTERVAL '3 minutes',
 NOW() - INTERVAL '84 days' + INTERVAL '48 seconds',
 NOW() - INTERVAL '84 days'),

('ocr4-0000-0000-0000-000000000004',
 gen_random_uuid(),
 'a6000000-0000-0000-0000-000000000010',
 'failed', 'google-vision', NULL,
 NULL, NULL,
 'Image too blurry. Confidence below threshold. Please retake photo in good lighting.',
 NOW() - INTERVAL '54 days' + INTERVAL '30 seconds',
 NOW() - INTERVAL '54 days' + INTERVAL '45 seconds',
 NOW() - INTERVAL '54 days'),

('ocr5-0000-0000-0000-000000000005',
 gen_random_uuid(),
 'a6000000-0000-0000-0000-000000000010',
 'completed', 'google-vision', 0.93,
 'KEM HOSPITAL MUMBAI\nDr Vijay Kulkarni MD DM Cardiology\nPt: Kamala Devi 01/05/2026\nTab Furosemide 40mg OD AM\nTab Carvedilol 6.25mg BD\nTab Warfarin 2mg OD 6pm\nINR target 2-3 Monthly INR check mandatory',
 '{"medicines":[{"name":"Furosemide","strength":"40mg","frequency":"OD"},{"name":"Carvedilol","strength":"6.25mg","frequency":"BD"},{"name":"Warfarin","strength":"2mg","frequency":"OD","time":"18:00"}],"doctor":"Dr Vijay Kulkarni","hospital":"KEM Hospital Mumbai","date":"2026-05-01"}',
 NULL,
 NOW() - INTERVAL '54 days' + INTERVAL '5 minutes',
 NOW() - INTERVAL '54 days' + INTERVAL '1 minute',
 NOW() - INTERVAL '54 days');


-- =============================================================================
-- 6. MEDICINE SCHEDULES  (sched.medicine_schedules — 30 rows)
-- =============================================================================

INSERT INTO sched.medicine_schedules
    (id, prescription_medicine_id, user_id, schedule_name,
     recurrence_type, recurrence_rule, dose_time, dose_amount, is_active,
     created_at, updated_at)
VALUES

-- ARJUN (a1) — Metformin 500mg: Morning + Evening
('sc01-0000-0000-0000-000000000001', 'pm01-000-0000-0000-000000000001',
 'a1000000-0000-0000-0000-000000000001',
 'Metformin Morning', 'daily', '{"freq":"daily"}',
 '08:00', '1 tablet (500mg)', TRUE, NOW() - INTERVAL '160 days', NOW()),

('sc02-0000-0000-0000-000000000002', 'pm01-000-0000-0000-000000000001',
 'a1000000-0000-0000-0000-000000000001',
 'Metformin Evening', 'daily', '{"freq":"daily"}',
 '20:00', '1 tablet (500mg)', TRUE, NOW() - INTERVAL '160 days', NOW()),

-- ARJUN — Amlodipine 5mg: Morning
('sc03-0000-0000-0000-000000000003', 'pm02-000-0000-0000-000000000002',
 'a1000000-0000-0000-0000-000000000001',
 'Amlodipine Morning', 'daily', '{"freq":"daily"}',
 '08:00', '1 tablet (5mg)', TRUE, NOW() - INTERVAL '160 days', NOW()),

-- ARJUN — Atorvastatin 40mg: Night
('sc04-0000-0000-0000-000000000004', 'pm16-000-0000-0000-000000000016',
 'a1000000-0000-0000-0000-000000000001',
 'Atorvastatin Bedtime', 'daily', '{"freq":"daily"}',
 '22:00', '1 tablet (40mg)', TRUE, NOW() - INTERVAL '35 days', NOW()),

-- PRIYA (a2) — Levothyroxine: 6am empty stomach
('sc05-0000-0000-0000-000000000005', 'pm03-000-0000-0000-000000000003',
 'a2000000-0000-0000-0000-000000000002',
 'Levothyroxine Empty Stomach', 'daily', '{"freq":"daily"}',
 '06:00', '1 tablet (100mcg)', TRUE, NOW() - INTERVAL '134 days', NOW()),

-- PRIYA — Pantoprazole: Before Breakfast + Before Dinner
('sc06-0000-0000-0000-000000000006', 'pm17-000-0000-0000-000000000017',
 'a2000000-0000-0000-0000-000000000002',
 'Pantoprazole Before Breakfast', 'daily', '{"freq":"daily"}',
 '07:30', '1 tablet (40mg)', TRUE, NOW() - INTERVAL '23 days', NOW()),

('sc07-0000-0000-0000-000000000007', 'pm17-000-0000-0000-000000000017',
 'a2000000-0000-0000-0000-000000000002',
 'Pantoprazole Before Dinner', 'daily', '{"freq":"daily"}',
 '19:30', '1 tablet (40mg)', TRUE, NOW() - INTERVAL '23 days', NOW()),

-- RAVI (a3) — Losartan (active Rx04) + EPO (Mon/Wed/Fri) + Calcium
('sc08-0000-0000-0000-000000000008', 'pm06-000-0000-0000-000000000006',
 'a3000000-0000-0000-0000-000000000003',
 'Losartan Morning', 'daily', '{"freq":"daily"}',
 '09:00', '1 tablet (50mg)', TRUE, NOW() - INTERVAL '23 days', NOW()),

('sc09-0000-0000-0000-000000000009', 'pm07-000-0000-0000-000000000007',
 'a3000000-0000-0000-0000-000000000003',
 'EPO Injection MWF', 'weekly',
 '{"freq":"weekly","byday":["MO","WE","FR"]}',
 '10:00', '1 injection (4000 IU)', TRUE, NOW() - INTERVAL '23 days', NOW()),

('sc10-0000-0000-0000-000000000010', 'pm08-000-0000-0000-000000000008',
 'a3000000-0000-0000-0000-000000000003',
 'Calcium After Breakfast', 'daily', '{"freq":"daily"}',
 '09:30', '1 tablet (500mg)', TRUE, NOW() - INTERVAL '23 days', NOW()),

('sc11-0000-0000-0000-000000000011', 'pm08-000-0000-0000-000000000008',
 'a3000000-0000-0000-0000-000000000003',
 'Calcium After Dinner', 'daily', '{"freq":"daily"}',
 '20:30', '1 tablet (500mg)', TRUE, NOW() - INTERVAL '23 days', NOW()),

-- FATIMA (a4) — Methotrexate: Saturday only
('sc12-0000-0000-0000-000000000012', 'pm09-000-0000-0000-000000000009',
 'a4000000-0000-0000-0000-000000000004',
 'Methotrexate Saturday', 'weekly',
 '{"freq":"weekly","byday":["SA"]}',
 '09:00', '6 tablets (15mg total)', TRUE, NOW() - INTERVAL '101 days', NOW()),

-- FATIMA — Folic Acid: Mon–Fri + Sun (all days except Saturday)
('sc13-0000-0000-0000-000000000013', 'pm10-000-0000-0000-000000000010',
 'a4000000-0000-0000-0000-000000000004',
 'Folic Acid Daily (not Sat)', 'weekly',
 '{"freq":"weekly","byday":["SU","MO","TU","WE","TH","FR"]}',
 '09:00', '1 tablet (5mg)', TRUE, NOW() - INTERVAL '101 days', NOW()),

-- SURESH (a5) — Salbutamol PRN (as needed — no fixed schedule)
('sc14-0000-0000-0000-000000000014', 'pm11-000-0000-0000-000000000011',
 'a5000000-0000-0000-0000-000000000005',
 'Salbutamol Rescue Inhaler', 'as_needed', NULL,
 NULL, '2 puffs (200mcg)', TRUE, NOW() - INTERVAL '84 days', NOW()),

-- SURESH — Omeprazole: 30 min before breakfast
('sc15-0000-0000-0000-000000000015', 'pm12-000-0000-0000-000000000012',
 'a5000000-0000-0000-0000-000000000005',
 'Omeprazole Before Breakfast', 'daily', '{"freq":"daily"}',
 '07:00', '1 capsule (20mg)', TRUE, NOW() - INTERVAL '84 days', NOW()),

-- KAMALA (a6) — Furosemide Morning
('sc16-0000-0000-0000-000000000016', 'pm13-000-0000-0000-000000000013',
 'a6000000-0000-0000-0000-000000000010',
 'Furosemide Morning', 'daily', '{"freq":"daily"}',
 '07:00', '1 tablet (40mg)', TRUE, NOW() - INTERVAL '54 days', NOW()),

-- KAMALA — Carvedilol Morning + Evening
('sc17-0000-0000-0000-000000000017', 'pm14-000-0000-0000-000000000014',
 'a6000000-0000-0000-0000-000000000010',
 'Carvedilol Morning', 'daily', '{"freq":"daily"}',
 '08:00', '1 tablet (6.25mg)', TRUE, NOW() - INTERVAL '54 days', NOW()),

('sc18-0000-0000-0000-000000000018', 'pm14-000-0000-0000-000000000014',
 'a6000000-0000-0000-0000-000000000010',
 'Carvedilol Evening', 'daily', '{"freq":"daily"}',
 '20:00', '1 tablet (6.25mg)', TRUE, NOW() - INTERVAL '54 days', NOW()),

-- KAMALA — Warfarin 6pm
('sc19-0000-0000-0000-000000000019', 'pm15-000-0000-0000-000000000015',
 'a6000000-0000-0000-0000-000000000010',
 'Warfarin 6pm', 'daily', '{"freq":"daily"}',
 '18:00', '1 tablet (2mg)', TRUE, NOW() - INTERVAL '54 days', NOW()),

-- KAMALA — Metformin Morning + Evening
('sc20-0000-0000-0000-000000000020', 'pm18-000-0000-0000-000000000018',
 'a6000000-0000-0000-0000-000000000010',
 'Metformin Morning (Kamala)', 'daily', '{"freq":"daily"}',
 '08:30', '1 tablet (500mg)', TRUE, NOW() - INTERVAL '40 days', NOW()),

('sc21-0000-0000-0000-000000000021', 'pm18-000-0000-0000-000000000018',
 'a6000000-0000-0000-0000-000000000010',
 'Metformin Evening (Kamala)', 'daily', '{"freq":"daily"}',
 '20:30', '1 tablet (500mg)', TRUE, NOW() - INTERVAL '40 days', NOW()),

-- KAMALA — Glimepiride with Breakfast
('sc22-0000-0000-0000-000000000022', 'pm19-000-0000-0000-000000000019',
 'a6000000-0000-0000-0000-000000000010',
 'Glimepiride with Breakfast', 'daily', '{"freq":"daily"}',
 '08:30', '1 tablet (2mg)', TRUE, NOW() - INTERVAL '40 days', NOW()),

-- Additional schedules to reach 30
('sc23-0000-0000-0000-000000000023', 'pm02-000-0000-0000-000000000002',
 'a1000000-0000-0000-0000-000000000001',
 'BP Check Reminder (morning)', 'daily', '{"freq":"daily"}',
 '08:15', 'Check BP before taking Amlodipine', TRUE, NOW() - INTERVAL '100 days', NOW()),

('sc24-0000-0000-0000-000000000024', 'pm06-000-0000-0000-000000000006',
 'a3000000-0000-0000-0000-000000000003',
 'Losartan BP Log', 'daily', '{"freq":"daily"}',
 '09:15', 'Log blood pressure reading', TRUE, NOW() - INTERVAL '20 days', NOW()),

('sc25-0000-0000-0000-000000000025', 'pm12-000-0000-0000-000000000012',
 'a5000000-0000-0000-0000-000000000005',
 'Omeprazole Before Dinner (Suresh)', 'daily', '{"freq":"daily"}',
 '19:00', '1 capsule (20mg)', FALSE, NOW() - INTERVAL '84 days', NOW() - INTERVAL '60 days'),

('sc26-0000-0000-0000-000000000026', 'pm03-000-0000-0000-000000000003',
 'a2000000-0000-0000-0000-000000000002',
 'Thyroid Med Reminder', 'daily', '{"freq":"daily"}',
 '05:45', 'Wake up alarm — take Levothyroxine then go back to sleep', TRUE, NOW() - INTERVAL '134 days', NOW()),

('sc27-0000-0000-0000-000000000027', 'pm13-000-0000-0000-000000000013',
 'a6000000-0000-0000-0000-000000000010',
 'Daily Weight Log — Kamala', 'daily', '{"freq":"daily"}',
 '06:30', 'Weigh before Furosemide dose. Log in app.', TRUE, NOW() - INTERVAL '54 days', NOW()),

('sc28-0000-0000-0000-000000000028', 'pm15-000-0000-0000-000000000015',
 'a6000000-0000-0000-0000-000000000010',
 'Warfarin INR Alert', 'monthly',
 '{"freq":"monthly","bymonthday":[1]}',
 '10:00', 'Monthly INR blood test due', TRUE, NOW() - INTERVAL '54 days', NOW()),

('sc29-0000-0000-0000-000000000029', 'pm09-000-0000-0000-000000000009',
 'a4000000-0000-0000-0000-000000000004',
 'MTX LFT Reminder', 'monthly',
 '{"freq":"monthly","bymonthday":[15]}',
 '09:00', 'Monthly liver function test due — book appointment', TRUE, NOW() - INTERVAL '101 days', NOW()),

('sc30-0000-0000-0000-000000000030', 'pm16-000-0000-0000-000000000016',
 'a1000000-0000-0000-0000-000000000001',
 'Lipid Panel Reminder', 'monthly',
 '{"freq":"monthly","bymonthday":[20]}',
 '09:00', 'Lipid panel blood test reminder — fasting required', TRUE, NOW() - INTERVAL '35 days', NOW());


-- =============================================================================
-- 7. SCHEDULE EXCEPTIONS
-- =============================================================================

INSERT INTO sched.schedule_exceptions
    (id, medicine_schedule_id, exception_date, reason, created_at)
VALUES
('se01-0000-0000-0000-000000000001', 'sc01-0000-0000-0000-000000000001',
 '2026-05-10', 'Hospitalised for fever — NPO status', NOW() - INTERVAL '45 days'),
('se02-0000-0000-0000-000000000002', 'sc09-0000-0000-0000-000000000009',
 '2026-06-09', 'Scheduled pre-operative nil by mouth', NOW() - INTERVAL '15 days'),
('se03-0000-0000-0000-000000000003', 'sc12-0000-0000-0000-000000000012',
 '2026-05-17', 'Travelling — cold chain not available', NOW() - INTERVAL '38 days');


-- =============================================================================
-- 8. REMINDERS  (remind.reminders — 50 rows)
-- =============================================================================

INSERT INTO remind.reminders
    (id, medicine_schedule_id, user_id, scheduled_at,
     status, snooze_count, snoozed_until, acknowledged_at,
     created_at, updated_at)
VALUES

-- ARJUN — Metformin morning (last 5 days)
('rm01-0000-0000-0000-000000000001', 'sc01-0000-0000-0000-000000000001',
 'a1000000-0000-0000-0000-000000000001',
 NOW() - INTERVAL '4 days' + TIME '08:00', 'acknowledged', 0, NULL,
 NOW() - INTERVAL '4 days' + TIME '08:03', NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),

('rm02-0000-0000-0000-000000000002', 'sc01-0000-0000-0000-000000000001',
 'a1000000-0000-0000-0000-000000000001',
 NOW() - INTERVAL '3 days' + TIME '08:00', 'acknowledged', 0, NULL,
 NOW() - INTERVAL '3 days' + TIME '08:05', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),

('rm03-0000-0000-0000-000000000003', 'sc01-0000-0000-0000-000000000001',
 'a1000000-0000-0000-0000-000000000001',
 NOW() - INTERVAL '2 days' + TIME '08:00', 'missed', 0, NULL,
 NULL, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),

('rm04-0000-0000-0000-000000000004', 'sc01-0000-0000-0000-000000000001',
 'a1000000-0000-0000-0000-000000000001',
 NOW() - INTERVAL '1 day' + TIME '08:00', 'acknowledged', 1,
 NULL, NOW() - INTERVAL '1 day' + TIME '08:35',
 NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),

('rm05-0000-0000-0000-000000000005', 'sc01-0000-0000-0000-000000000001',
 'a1000000-0000-0000-0000-000000000001',
 NOW()::DATE + TIME '08:00', 'pending', 0, NULL,
 NULL, NOW(), NOW()),

-- ARJUN — Metformin evening (last 5 days)
('rm06-0000-0000-0000-000000000006', 'sc02-0000-0000-0000-000000000002',
 'a1000000-0000-0000-0000-000000000001',
 NOW() - INTERVAL '4 days' + TIME '20:00', 'acknowledged', 0, NULL,
 NOW() - INTERVAL '4 days' + TIME '20:02', NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),

('rm07-0000-0000-0000-000000000007', 'sc02-0000-0000-0000-000000000002',
 'a1000000-0000-0000-0000-000000000001',
 NOW() - INTERVAL '3 days' + TIME '20:00', 'snoozed', 2,
 NOW() - INTERVAL '3 days' + TIME '20:30',
 NULL, NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),

('rm08-0000-0000-0000-000000000008', 'sc02-0000-0000-0000-000000000002',
 'a1000000-0000-0000-0000-000000000001',
 NOW() - INTERVAL '2 days' + TIME '20:00', 'acknowledged', 0, NULL,
 NOW() - INTERVAL '2 days' + TIME '20:07', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),

('rm09-0000-0000-0000-000000000009', 'sc02-0000-0000-0000-000000000002',
 'a1000000-0000-0000-0000-000000000001',
 NOW() - INTERVAL '1 day' + TIME '20:00', 'acknowledged', 0, NULL,
 NOW() - INTERVAL '1 day' + TIME '20:04', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),

('rm10-0000-0000-0000-000000000010', 'sc02-0000-0000-0000-000000000002',
 'a1000000-0000-0000-0000-000000000001',
 NOW()::DATE + TIME '20:00', 'pending', 0, NULL,
 NULL, NOW(), NOW()),

-- PRIYA — Levothyroxine (last 5 mornings)
('rm11-0000-0000-0000-000000000011', 'sc05-0000-0000-0000-000000000005',
 'a2000000-0000-0000-0000-000000000002',
 NOW() - INTERVAL '4 days' + TIME '06:00', 'acknowledged', 0, NULL,
 NOW() - INTERVAL '4 days' + TIME '06:01', NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),

('rm12-0000-0000-0000-000000000012', 'sc05-0000-0000-0000-000000000005',
 'a2000000-0000-0000-0000-000000000002',
 NOW() - INTERVAL '3 days' + TIME '06:00', 'acknowledged', 0, NULL,
 NOW() - INTERVAL '3 days' + TIME '06:02', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),

('rm13-0000-0000-0000-000000000013', 'sc05-0000-0000-0000-000000000005',
 'a2000000-0000-0000-0000-000000000002',
 NOW() - INTERVAL '2 days' + TIME '06:00', 'acknowledged', 0, NULL,
 NOW() - INTERVAL '2 days' + TIME '06:03', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),

('rm14-0000-0000-0000-000000000014', 'sc05-0000-0000-0000-000000000005',
 'a2000000-0000-0000-0000-000000000002',
 NOW() - INTERVAL '1 day' + TIME '06:00', 'missed', 0, NULL,
 NULL, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),

('rm15-0000-0000-0000-000000000015', 'sc05-0000-0000-0000-000000000005',
 'a2000000-0000-0000-0000-000000000002',
 NOW()::DATE + TIME '06:00', 'sent', 0, NULL,
 NULL, NOW(), NOW()),

-- RAVI — Losartan (last 5 days)
('rm16-0000-0000-0000-000000000016', 'sc08-0000-0000-0000-000000000008',
 'a3000000-0000-0000-0000-000000000003',
 NOW() - INTERVAL '4 days' + TIME '09:00', 'acknowledged', 0, NULL,
 NOW() - INTERVAL '4 days' + TIME '09:10', NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),

('rm17-0000-0000-0000-000000000017', 'sc08-0000-0000-0000-000000000008',
 'a3000000-0000-0000-0000-000000000003',
 NOW() - INTERVAL '3 days' + TIME '09:00', 'acknowledged', 0, NULL,
 NOW() - INTERVAL '3 days' + TIME '09:05', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),

('rm18-0000-0000-0000-000000000018', 'sc08-0000-0000-0000-000000000008',
 'a3000000-0000-0000-0000-000000000003',
 NOW() - INTERVAL '2 days' + TIME '09:00', 'acknowledged', 0, NULL,
 NOW() - INTERVAL '2 days' + TIME '09:08', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),

('rm19-0000-0000-0000-000000000019', 'sc08-0000-0000-0000-000000000008',
 'a3000000-0000-0000-0000-000000000003',
 NOW() - INTERVAL '1 day' + TIME '09:00', 'acknowledged', 0, NULL,
 NOW() - INTERVAL '1 day' + TIME '09:12', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),

('rm20-0000-0000-0000-000000000020', 'sc08-0000-0000-0000-000000000008',
 'a3000000-0000-0000-0000-000000000003',
 NOW()::DATE + TIME '09:00', 'pending', 0, NULL,
 NULL, NOW(), NOW()),

-- FATIMA — Methotrexate (last 3 Saturdays)
('rm21-0000-0000-0000-000000000021', 'sc12-0000-0000-0000-000000000012',
 'a4000000-0000-0000-0000-000000000004',
 '2026-06-07 09:00:00+05:30', 'acknowledged', 0, NULL,
 '2026-06-07 09:15:00+05:30', '2026-06-07 09:00:00+05:30', '2026-06-07 09:00:00+05:30'),

('rm22-0000-0000-0000-000000000022', 'sc12-0000-0000-0000-000000000012',
 'a4000000-0000-0000-0000-000000000004',
 '2026-06-14 09:00:00+05:30', 'acknowledged', 0, NULL,
 '2026-06-14 09:22:00+05:30', '2026-06-14 09:00:00+05:30', '2026-06-14 09:00:00+05:30'),

('rm23-0000-0000-0000-000000000023', 'sc12-0000-0000-0000-000000000012',
 'a4000000-0000-0000-0000-000000000004',
 '2026-06-21 09:00:00+05:30', 'acknowledged', 1,
 NULL, '2026-06-21 09:45:00+05:30',
 '2026-06-21 09:00:00+05:30', '2026-06-21 09:45:00+05:30'),

-- SURESH — Omeprazole (last 5 mornings)
('rm24-0000-0000-0000-000000000024', 'sc15-0000-0000-0000-000000000015',
 'a5000000-0000-0000-0000-000000000005',
 NOW() - INTERVAL '4 days' + TIME '07:00', 'acknowledged', 0, NULL,
 NOW() - INTERVAL '4 days' + TIME '07:05', NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),

('rm25-0000-0000-0000-000000000025', 'sc15-0000-0000-0000-000000000015',
 'a5000000-0000-0000-0000-000000000005',
 NOW() - INTERVAL '3 days' + TIME '07:00', 'acknowledged', 0, NULL,
 NOW() - INTERVAL '3 days' + TIME '07:08', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),

('rm26-0000-0000-0000-000000000026', 'sc15-0000-0000-0000-000000000015',
 'a5000000-0000-0000-0000-000000000005',
 NOW() - INTERVAL '2 days' + TIME '07:00', 'skipped', 0, NULL,
 NULL, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),

('rm27-0000-0000-0000-000000000027', 'sc15-0000-0000-0000-000000000015',
 'a5000000-0000-0000-0000-000000000005',
 NOW() - INTERVAL '1 day' + TIME '07:00', 'acknowledged', 0, NULL,
 NOW() - INTERVAL '1 day' + TIME '07:03', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),

('rm28-0000-0000-0000-000000000028', 'sc15-0000-0000-0000-000000000015',
 'a5000000-0000-0000-0000-000000000005',
 NOW()::DATE + TIME '07:00', 'pending', 0, NULL,
 NULL, NOW(), NOW()),

-- KAMALA — Furosemide (5 days)
('rm29-0000-0000-0000-000000000029', 'sc16-0000-0000-0000-000000000016',
 'a6000000-0000-0000-0000-000000000010',
 NOW() - INTERVAL '4 days' + TIME '07:00', 'acknowledged', 0, NULL,
 NOW() - INTERVAL '4 days' + TIME '07:02', NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),

('rm30-0000-0000-0000-000000000030', 'sc16-0000-0000-0000-000000000016',
 'a6000000-0000-0000-0000-000000000010',
 NOW() - INTERVAL '3 days' + TIME '07:00', 'acknowledged', 0, NULL,
 NOW() - INTERVAL '3 days' + TIME '07:04', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),

('rm31-0000-0000-0000-000000000031', 'sc16-0000-0000-0000-000000000016',
 'a6000000-0000-0000-0000-000000000010',
 NOW() - INTERVAL '2 days' + TIME '07:00', 'acknowledged', 0, NULL,
 NOW() - INTERVAL '2 days' + TIME '07:10', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),

('rm32-0000-0000-0000-000000000032', 'sc16-0000-0000-0000-000000000016',
 'a6000000-0000-0000-0000-000000000010',
 NOW() - INTERVAL '1 day' + TIME '07:00', 'acknowledged', 1,
 NULL, NOW() - INTERVAL '1 day' + TIME '07:40',
 NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),

('rm33-0000-0000-0000-000000000033', 'sc16-0000-0000-0000-000000000016',
 'a6000000-0000-0000-0000-000000000010',
 NOW()::DATE + TIME '07:00', 'sent', 0, NULL,
 NULL, NOW(), NOW()),

-- KAMALA — Warfarin 6pm (5 days)
('rm34-0000-0000-0000-000000000034', 'sc19-0000-0000-0000-000000000019',
 'a6000000-0000-0000-0000-000000000010',
 NOW() - INTERVAL '4 days' + TIME '18:00', 'acknowledged', 0, NULL,
 NOW() - INTERVAL '4 days' + TIME '18:06', NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),

('rm35-0000-0000-0000-000000000035', 'sc19-0000-0000-0000-000000000019',
 'a6000000-0000-0000-0000-000000000010',
 NOW() - INTERVAL '3 days' + TIME '18:00', 'acknowledged', 0, NULL,
 NOW() - INTERVAL '3 days' + TIME '18:02', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),

('rm36-0000-0000-0000-000000000036', 'sc19-0000-0000-0000-000000000019',
 'a6000000-0000-0000-0000-000000000010',
 NOW() - INTERVAL '2 days' + TIME '18:00', 'missed', 0, NULL,
 NULL, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),

('rm37-0000-0000-0000-000000000037', 'sc19-0000-0000-0000-000000000019',
 'a6000000-0000-0000-0000-000000000010',
 NOW() - INTERVAL '1 day' + TIME '18:00', 'acknowledged', 0, NULL,
 NOW() - INTERVAL '1 day' + TIME '18:09', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),

('rm38-0000-0000-0000-000000000038', 'sc19-0000-0000-0000-000000000019',
 'a6000000-0000-0000-0000-000000000010',
 NOW()::DATE + TIME '18:00', 'pending', 0, NULL,
 NULL, NOW(), NOW()),

-- KAMALA — Carvedilol Morning (5 days)
('rm39-0000-0000-0000-000000000039', 'sc17-0000-0000-0000-000000000017',
 'a6000000-0000-0000-0000-000000000010',
 NOW() - INTERVAL '4 days' + TIME '08:00', 'acknowledged', 0, NULL,
 NOW() - INTERVAL '4 days' + TIME '08:04', NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),

('rm40-0000-0000-0000-000000000040', 'sc17-0000-0000-0000-000000000017',
 'a6000000-0000-0000-0000-000000000010',
 NOW() - INTERVAL '3 days' + TIME '08:00', 'acknowledged', 0, NULL,
 NOW() - INTERVAL '3 days' + TIME '08:06', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),

('rm41-0000-0000-0000-000000000041', 'sc17-0000-0000-0000-000000000017',
 'a6000000-0000-0000-0000-000000000010',
 NOW() - INTERVAL '2 days' + TIME '08:00', 'acknowledged', 0, NULL,
 NOW() - INTERVAL '2 days' + TIME '08:03', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),

('rm42-0000-0000-0000-000000000042', 'sc17-0000-0000-0000-000000000017',
 'a6000000-0000-0000-0000-000000000010',
 NOW() - INTERVAL '1 day' + TIME '08:00', 'missed', 0, NULL,
 NULL, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),

('rm43-0000-0000-0000-000000000043', 'sc17-0000-0000-0000-000000000017',
 'a6000000-0000-0000-0000-000000000010',
 NOW()::DATE + TIME '08:00', 'pending', 0, NULL,
 NULL, NOW(), NOW()),

-- ARJUN — Atorvastatin Night (last 5)
('rm44-0000-0000-0000-000000000044', 'sc04-0000-0000-0000-000000000004',
 'a1000000-0000-0000-0000-000000000001',
 NOW() - INTERVAL '4 days' + TIME '22:00', 'acknowledged', 0, NULL,
 NOW() - INTERVAL '4 days' + TIME '22:05', NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),

('rm45-0000-0000-0000-000000000045', 'sc04-0000-0000-0000-000000000004',
 'a1000000-0000-0000-0000-000000000001',
 NOW() - INTERVAL '3 days' + TIME '22:00', 'acknowledged', 0, NULL,
 NOW() - INTERVAL '3 days' + TIME '22:03', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),

('rm46-0000-0000-0000-000000000046', 'sc04-0000-0000-0000-000000000004',
 'a1000000-0000-0000-0000-000000000001',
 NOW() - INTERVAL '2 days' + TIME '22:00', 'acknowledged', 0, NULL,
 NOW() - INTERVAL '2 days' + TIME '22:08', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),

('rm47-0000-0000-0000-000000000047', 'sc04-0000-0000-0000-000000000004',
 'a1000000-0000-0000-0000-000000000001',
 NOW() - INTERVAL '1 day' + TIME '22:00', 'acknowledged', 0, NULL,
 NOW() - INTERVAL '1 day' + TIME '22:02', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),

('rm48-0000-0000-0000-000000000048', 'sc04-0000-0000-0000-000000000004',
 'a1000000-0000-0000-0000-000000000001',
 NOW()::DATE + TIME '22:00', 'pending', 0, NULL,
 NULL, NOW(), NOW()),

-- KAMALA — Metformin Evening (2 more reminders to reach 50)
('rm49-0000-0000-0000-000000000049', 'sc21-0000-0000-0000-000000000021',
 'a6000000-0000-0000-0000-000000000010',
 NOW() - INTERVAL '1 day' + TIME '20:30', 'acknowledged', 0, NULL,
 NOW() - INTERVAL '1 day' + TIME '20:35', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),

('rm50-0000-0000-0000-000000000050', 'sc21-0000-0000-0000-000000000021',
 'a6000000-0000-0000-0000-000000000010',
 NOW()::DATE + TIME '20:30', 'pending', 0, NULL,
 NULL, NOW(), NOW());


-- =============================================================================
-- 9. DOSE LOGS  (remind.dose_logs)
-- =============================================================================

INSERT INTO remind.dose_logs
    (id, reminder_id, user_id, medicine_schedule_id, action, action_at, notes)
VALUES

('dl01-0000-0000-0000-000000000001', 'rm01-0000-0000-0000-000000000001',
 'a1000000-0000-0000-0000-000000000001', 'sc01-0000-0000-0000-000000000001',
 'taken', NOW() - INTERVAL '4 days' + TIME '08:03', NULL),

('dl02-0000-0000-0000-000000000002', 'rm02-0000-0000-0000-000000000002',
 'a1000000-0000-0000-0000-000000000001', 'sc01-0000-0000-0000-000000000001',
 'taken', NOW() - INTERVAL '3 days' + TIME '08:05', NULL),

('dl03-0000-0000-0000-000000000003', 'rm03-0000-0000-0000-000000000003',
 'a1000000-0000-0000-0000-000000000001', 'sc01-0000-0000-0000-000000000001',
 'missed', NOW() - INTERVAL '2 days' + TIME '10:00', 'Forgot — was in a meeting all morning'),

('dl04-0000-0000-0000-000000000004', 'rm04-0000-0000-0000-000000000004',
 'a1000000-0000-0000-0000-000000000001', 'sc01-0000-0000-0000-000000000001',
 'taken', NOW() - INTERVAL '1 day' + TIME '08:35', 'Snoozed once, took with breakfast'),

('dl05-0000-0000-0000-000000000005', 'rm06-0000-0000-0000-000000000006',
 'a1000000-0000-0000-0000-000000000001', 'sc02-0000-0000-0000-000000000002',
 'taken', NOW() - INTERVAL '4 days' + TIME '20:02', NULL),

('dl06-0000-0000-0000-000000000006', 'rm07-0000-0000-0000-000000000007',
 'a1000000-0000-0000-0000-000000000001', 'sc02-0000-0000-0000-000000000002',
 'taken', NOW() - INTERVAL '3 days' + TIME '20:32', 'Snoozed twice — was driving'),

('dl07-0000-0000-0000-000000000007', 'rm08-0000-0000-0000-000000000008',
 'a1000000-0000-0000-0000-000000000001', 'sc02-0000-0000-0000-000000000002',
 'taken', NOW() - INTERVAL '2 days' + TIME '20:07', NULL),

('dl08-0000-0000-0000-000000000008', 'rm09-0000-0000-0000-000000000009',
 'a1000000-0000-0000-0000-000000000001', 'sc02-0000-0000-0000-000000000002',
 'taken', NOW() - INTERVAL '1 day' + TIME '20:04', NULL),

('dl09-0000-0000-0000-000000000009', 'rm11-0000-0000-0000-000000000011',
 'a2000000-0000-0000-0000-000000000002', 'sc05-0000-0000-0000-000000000005',
 'taken', NOW() - INTERVAL '4 days' + TIME '06:01', 'Taken on empty stomach as instructed'),

('dl10-0000-0000-0000-000000000010', 'rm12-0000-0000-0000-000000000012',
 'a2000000-0000-0000-0000-000000000002', 'sc05-0000-0000-0000-000000000005',
 'taken', NOW() - INTERVAL '3 days' + TIME '06:02', NULL),

('dl11-0000-0000-0000-000000000011', 'rm13-0000-0000-0000-000000000013',
 'a2000000-0000-0000-0000-000000000002', 'sc05-0000-0000-0000-000000000005',
 'taken', NOW() - INTERVAL '2 days' + TIME '06:03', NULL),

('dl12-0000-0000-0000-000000000012', 'rm14-0000-0000-0000-000000000014',
 'a2000000-0000-0000-0000-000000000002', 'sc05-0000-0000-0000-000000000005',
 'missed', NOW() - INTERVAL '1 day' + TIME '09:00', 'Woke up late — already had breakfast by then'),

('dl13-0000-0000-0000-000000000013', 'rm16-0000-0000-0000-000000000016',
 'a3000000-0000-0000-0000-000000000003', 'sc08-0000-0000-0000-000000000008',
 'taken', NOW() - INTERVAL '4 days' + TIME '09:10', NULL),

('dl14-0000-0000-0000-000000000014', 'rm17-0000-0000-0000-000000000017',
 'a3000000-0000-0000-0000-000000000003', 'sc08-0000-0000-0000-000000000008',
 'taken', NOW() - INTERVAL '3 days' + TIME '09:05', NULL),

('dl15-0000-0000-0000-000000000015', 'rm18-0000-0000-0000-000000000018',
 'a3000000-0000-0000-0000-000000000003', 'sc08-0000-0000-0000-000000000008',
 'taken', NOW() - INTERVAL '2 days' + TIME '09:08', NULL),

('dl16-0000-0000-0000-000000000016', 'rm19-0000-0000-0000-000000000019',
 'a3000000-0000-0000-0000-000000000003', 'sc08-0000-0000-0000-000000000008',
 'taken', NOW() - INTERVAL '1 day' + TIME '09:12', 'BP 128/82 today — improving'),

('dl17-0000-0000-0000-000000000017', 'rm21-0000-0000-0000-000000000021',
 'a4000000-0000-0000-0000-000000000004', 'sc12-0000-0000-0000-000000000012',
 'taken', '2026-06-07 09:15:00+05:30', 'Took all 6 tablets with large glass of water'),

('dl18-0000-0000-0000-000000000018', 'rm22-0000-0000-0000-000000000022',
 'a4000000-0000-0000-0000-000000000004', 'sc12-0000-0000-0000-000000000012',
 'taken', '2026-06-14 09:22:00+05:30', NULL),

('dl19-0000-0000-0000-000000000019', 'rm23-0000-0000-0000-000000000023',
 'a4000000-0000-0000-0000-000000000004', 'sc12-0000-0000-0000-000000000012',
 'taken', '2026-06-21 09:45:00+05:30', 'Snoozed — forgot it was Saturday for a moment'),

('dl20-0000-0000-0000-000000000020', 'rm24-0000-0000-0000-000000000024',
 'a5000000-0000-0000-0000-000000000005', 'sc15-0000-0000-0000-000000000015',
 'taken', NOW() - INTERVAL '4 days' + TIME '07:05', NULL),

('dl21-0000-0000-0000-000000000021', 'rm25-0000-0000-0000-000000000025',
 'a5000000-0000-0000-0000-000000000005', 'sc15-0000-0000-0000-000000000015',
 'taken', NOW() - INTERVAL '3 days' + TIME '07:08', NULL),

('dl22-0000-0000-0000-000000000022', 'rm26-0000-0000-0000-000000000026',
 'a5000000-0000-0000-0000-000000000005', 'sc15-0000-0000-0000-000000000015',
 'skipped', NOW() - INTERVAL '2 days' + TIME '07:30', 'Fasting for blood test today'),

('dl23-0000-0000-0000-000000000023', 'rm27-0000-0000-0000-000000000027',
 'a5000000-0000-0000-0000-000000000005', 'sc15-0000-0000-0000-000000000015',
 'taken', NOW() - INTERVAL '1 day' + TIME '07:03', NULL),

('dl24-0000-0000-0000-000000000024', 'rm29-0000-0000-0000-000000000029',
 'a6000000-0000-0000-0000-000000000010', 'sc16-0000-0000-0000-000000000016',
 'taken', NOW() - INTERVAL '4 days' + TIME '07:02', 'Weight 62kg today'),

('dl25-0000-0000-0000-000000000025', 'rm30-0000-0000-0000-000000000030',
 'a6000000-0000-0000-0000-000000000010', 'sc16-0000-0000-0000-000000000016',
 'taken', NOW() - INTERVAL '3 days' + TIME '07:04', 'Weight 61.5kg — slight decrease'),

('dl26-0000-0000-0000-000000000026', 'rm31-0000-0000-0000-000000000031',
 'a6000000-0000-0000-0000-000000000010', 'sc16-0000-0000-0000-000000000016',
 'taken', NOW() - INTERVAL '2 days' + TIME '07:10', 'Weight 62.2kg — called doctor per protocol'),

('dl27-0000-0000-0000-000000000027', 'rm34-0000-0000-0000-000000000034',
 'a6000000-0000-0000-0000-000000000010', 'sc19-0000-0000-0000-000000000019',
 'taken', NOW() - INTERVAL '4 days' + TIME '18:06', NULL),

('dl28-0000-0000-0000-000000000028', 'rm35-0000-0000-0000-000000000035',
 'a6000000-0000-0000-0000-000000000010', 'sc19-0000-0000-0000-000000000019',
 'taken', NOW() - INTERVAL '3 days' + TIME '18:02', NULL),

('dl29-0000-0000-0000-000000000029', 'rm36-0000-0000-0000-000000000036',
 'a6000000-0000-0000-0000-000000000010', 'sc19-0000-0000-0000-000000000019',
 'missed', NOW() - INTERVAL '2 days' + TIME '21:00', 'Was hospitalised in evening — missed dose'),

('dl30-0000-0000-0000-000000000030', 'rm44-0000-0000-0000-000000000044',
 'a1000000-0000-0000-0000-000000000001', 'sc04-0000-0000-0000-000000000004',
 'taken', NOW() - INTERVAL '4 days' + TIME '22:05', NULL);


-- =============================================================================
-- 10. DRUG INTERACTIONS  (safety.drug_interactions — 20 pairs)
-- =============================================================================

INSERT INTO safety.drug_interactions
    (id, medicine_a_id, medicine_b_id, severity, interaction_type,
     mechanism, clinical_effect, management, evidence_level,
     source_reference, created_at, updated_at, created_by)
VALUES

-- 1. Warfarin + Aspirin → major bleeding risk
('di01-0000-0000-0000-000000000001',
 'm15-0000-0000-0000-000000000015', 'm20-0000-0000-0000-000000000020',
 'major', 'pharmacodynamic',
 'Aspirin inhibits platelet aggregation AND displaces warfarin from plasma protein binding, increasing free warfarin concentration.',
 'Significantly increased risk of serious bleeding including GI haemorrhage and intracranial haemorrhage.',
 'Avoid combination unless benefits outweigh risks (e.g. mechanical heart valves). If used together, monitor INR closely and use lowest effective aspirin dose (75mg). Counsel patient on bleeding signs.',
 'established', 'PMID: 12134001 | BNF 2025',
 NOW() - INTERVAL '365 days', NOW() - INTERVAL '30 days',
 'c1000000-0000-0000-0000-000000000009'),

-- 2. Metformin + Furosemide → lactic acidosis risk
('di02-0000-0000-0000-000000000002',
 'm01-0000-0000-0000-000000000001', 'm13-0000-0000-0000-000000000013',
 'moderate', 'pharmacokinetic',
 'Furosemide reduces renal blood flow and increases risk of dehydration, leading to elevated metformin levels and reduced renal clearance, raising lactic acidosis risk.',
 'Elevated plasma metformin levels; increased risk of metformin-associated lactic acidosis (MALA) particularly in patients with reduced baseline renal function.',
 'Monitor renal function (eGFR) before and during co-administration. Withhold metformin if eGFR < 30 mL/min. Counsel patient on hydration.',
 'clinical_study', 'PMID: 18678813 | WHO Drug Safety 2023',
 NOW() - INTERVAL '365 days', NOW() - INTERVAL '30 days',
 'c1000000-0000-0000-0000-000000000009'),

-- 3. Warfarin + Methotrexate → toxicity
('di03-0000-0000-0000-000000000003',
 'm15-0000-0000-0000-000000000015', 'm10-0000-0000-0000-000000000010',
 'major', 'pharmacokinetic',
 'Methotrexate displaces warfarin from protein-binding sites. Additionally, both drugs affect hepatic metabolism (CYP2C9), increasing free warfarin and methotrexate concentrations.',
 'Increased risk of haemorrhage and methotrexate toxicity (hepatotoxicity, myelosuppression).',
 'Monitor INR weekly when initiating or changing MTX dose. Reduce warfarin dose preemptively. Monitor CBC and LFTs monthly.',
 'clinical_study', 'PMID: 9781882',
 NOW() - INTERVAL '365 days', NOW() - INTERVAL '30 days',
 'c1000000-0000-0000-0000-000000000009'),

-- 4. Metformin + Glimepiride → hypoglycaemia
('di04-0000-0000-0000-000000000004',
 'm01-0000-0000-0000-000000000001', 'm16-0000-0000-0000-000000000016',
 'moderate', 'pharmacodynamic',
 'Additive glucose-lowering effect from different mechanisms: Metformin reduces hepatic glucose production; Glimepiride stimulates pancreatic insulin release.',
 'Risk of hypoglycaemia, especially in elderly, those with irregular meals, or with renal impairment.',
 'Monitor blood glucose regularly. Counsel patient on hypoglycaemia symptoms and management (carry glucose tablets). Start glimepiride at lowest dose.',
 'established', 'ADA Standards of Care 2025 | PMID: 31862748',
 NOW() - INTERVAL '365 days', NOW() - INTERVAL '30 days',
 'c1000000-0000-0000-0000-000000000009'),

-- 5. Warfarin + Atorvastatin → bleeding
('di05-0000-0000-0000-000000000005',
 'm15-0000-0000-0000-000000000015', 'm05-0000-0000-0000-000000000005',
 'moderate', 'pharmacokinetic',
 'Atorvastatin inhibits CYP3A4, which is involved in warfarin metabolism, potentially increasing warfarin plasma levels.',
 'INR elevation and increased bleeding risk, particularly with higher atorvastatin doses.',
 'Monitor INR closely when initiating, changing, or stopping atorvastatin. Adjust warfarin dose accordingly.',
 'clinical_study', 'PMID: 10495589 | BNF 2025',
 NOW() - INTERVAL '365 days', NOW() - INTERVAL '30 days',
 'c1000000-0000-0000-0000-000000000009'),

-- 6. Carvedilol + Furosemide → excessive hypotension
('di06-0000-0000-0000-000000000006',
 'm14-0000-0000-0000-000000000014', 'm13-0000-0000-0000-000000000013',
 'moderate', 'pharmacodynamic',
 'Carvedilol causes vasodilation via alpha-blockade; furosemide reduces preload via diuresis. Combined effect can cause orthostatic hypotension.',
 'Excessive blood pressure drop, especially on standing (orthostatic hypotension), dizziness, syncope risk.',
 'Titrate carvedilol slowly. Advise patient to rise slowly from sitting/lying. Monitor BP regularly, especially after dose changes.',
 'established', 'ESC Heart Failure Guidelines 2021',
 NOW() - INTERVAL '365 days', NOW() - INTERVAL '30 days',
 'c1000000-0000-0000-0000-000000000009'),

-- 7. Losartan + Furosemide → acute kidney injury
('di07-0000-0000-0000-000000000007',
 'm12-0000-0000-0000-000000000012', 'm13-0000-0000-0000-000000000013',
 'moderate', 'pharmacokinetic',
 'Furosemide-induced volume depletion reduces renal perfusion. Losartan (ARB) impairs the compensatory angiotensin II-mediated efferent arteriole constriction, leading to acute tubular injury.',
 'Risk of acute kidney injury (AKI), particularly in dehydrated patients or those with baseline CKD.',
 'Monitor serum creatinine and electrolytes 1–2 weeks after initiation. Withhold if creatinine rises >30% from baseline or patient is severely dehydrated.',
 'established', 'KDIGO AKI Guidelines 2022 | PMID: 22890260',
 NOW() - INTERVAL '365 days', NOW() - INTERVAL '30 days',
 'c1000000-0000-0000-0000-000000000009'),

-- 8. Methotrexate + NSAIDs → MTX toxicity (listed with aspirin as proxy)
('di08-0000-0000-0000-000000000008',
 'm10-0000-0000-0000-000000000010', 'm20-0000-0000-0000-000000000020',
 'major', 'pharmacokinetic',
 'NSAIDs (including aspirin) reduce renal tubular secretion of methotrexate, leading to accumulation. They also compete for plasma protein binding.',
 'Life-threatening methotrexate toxicity: severe mucositis, pancytopenia, hepatotoxicity.',
 'Avoid combination. If unavoidable, use low-dose aspirin only with very close monitoring of CBC, LFTs, and renal function. Reduce MTX dose.',
 'established', 'PMID: 16533030 | BSR MTX Guidelines 2016',
 NOW() - INTERVAL '365 days', NOW() - INTERVAL '30 days',
 'c1000000-0000-0000-0000-000000000009'),

-- 9. Levothyroxine + Calcium Carbonate → absorption reduction
('di09-0000-0000-0000-000000000009',
 'm06-0000-0000-0000-000000000006', 'm19-0000-0000-0000-000000000019',
 'moderate', 'pharmacokinetic',
 'Calcium carbonate binds to levothyroxine in the gut, forming an insoluble complex that reduces gastrointestinal absorption of levothyroxine by up to 40%.',
 'Reduced thyroid hormone levels, worsening hypothyroidism symptoms, elevated TSH.',
 'Separate administration by at least 4 hours. Levothyroxine should be taken on empty stomach; calcium with meals. Monitor TSH after any change.',
 'established', 'PMID: 10547166 | BNF 2025',
 NOW() - INTERVAL '365 days', NOW() - INTERVAL '30 days',
 'c1000000-0000-0000-0000-000000000009'),

-- 10. Levothyroxine + Omeprazole → absorption reduction
('di10-0000-0000-0000-000000000010',
 'm06-0000-0000-0000-000000000006', 'm08-0000-0000-0000-000000000008',
 'moderate', 'pharmacokinetic',
 'Omeprazole raises gastric pH. Levothyroxine dissolution requires acidic pH; reduced gastric acid leads to decreased absorption of levothyroxine tablets.',
 'Reduced levothyroxine bioavailability resulting in elevated TSH and hypothyroid symptoms.',
 'Monitor TSH levels after initiating or stopping omeprazole. May require levothyroxine dose adjustment. Consider liquid formulation of levothyroxine if clinically significant.',
 'clinical_study', 'PMID: 16855180',
 NOW() - INTERVAL '365 days', NOW() - INTERVAL '30 days',
 'c1000000-0000-0000-0000-000000000009'),

-- 11. Carvedilol + Metformin → masking hypoglycaemia symptoms
('di11-0000-0000-0000-000000000011',
 'm14-0000-0000-0000-000000000014', 'm01-0000-0000-0000-000000000001',
 'minor', 'pharmacodynamic',
 'Beta-blockers mask adrenergic symptoms of hypoglycaemia (tremor, tachycardia). Sweating (cholinergic) is preserved.',
 'Patient may not recognise early hypoglycaemia warning signs while on carvedilol.',
 'Counsel patient that sweating (but not tremor/palpitations) will still occur during hypoglycaemia. Educate on glucose monitoring. Use selective beta-1 blockers where possible.',
 'established', 'BNF 2025 | ADA 2025',
 NOW() - INTERVAL '365 days', NOW() - INTERVAL '30 days',
 'c1000000-0000-0000-0000-000000000009'),

-- 12. Furosemide + Carvedilol + Warfarin (two pairs already covered; additional pairs)
-- Furosemide + Metformin (already #2) — Adding Atorvastatin + Metformin
('di12-0000-0000-0000-000000000012',
 'm04-0000-0000-0000-000000000004', 'm01-0000-0000-0000-000000000001',
 'minor', 'pharmacodynamic',
 'No direct PK interaction. Combined use in metabolic syndrome is common and generally well-tolerated. Theoretical additive hepatic load.',
 'Minimal clinical significance. Monitor LFTs annually as both drugs are hepatically processed.',
 'Routine monitoring of liver enzymes. No dose adjustment usually required.',
 'theoretical', 'Internal clinical guideline',
 NOW() - INTERVAL '300 days', NOW() - INTERVAL '30 days',
 'c1000000-0000-0000-0000-000000000009'),

-- 13. Warfarin + Omeprazole → INR elevation
('di13-0000-0000-0000-000000000013',
 'm15-0000-0000-0000-000000000015', 'm08-0000-0000-0000-000000000008',
 'moderate', 'pharmacokinetic',
 'Omeprazole inhibits CYP2C19, which contributes to S-warfarin metabolism. Increased warfarin plasma levels raise anticoagulation effect.',
 'Elevated INR. Increased bleeding risk.',
 'Monitor INR closely when starting, stopping, or changing omeprazole dose. Adjust warfarin dose as needed. Consider pantoprazole as an alternative (less CYP2C19 inhibition).',
 'clinical_study', 'PMID: 9534022',
 NOW() - INTERVAL '365 days', NOW() - INTERVAL '30 days',
 'c1000000-0000-0000-0000-000000000009'),

-- 14. Glimepiride + Furosemide → hyperglycaemia
('di14-0000-0000-0000-000000000014',
 'm16-0000-0000-0000-000000000016', 'm13-0000-0000-0000-000000000013',
 'minor', 'pharmacodynamic',
 'Furosemide can cause hyperglycaemia by inhibiting insulin secretion from pancreatic beta cells, partially counteracting glimepiride.',
 'Blood glucose levels may be less well controlled. Glycaemic targets may be harder to achieve.',
 'Monitor blood glucose more frequently. May need to increase glimepiride dose. Ensure adequate fluid intake.',
 'clinical_study', 'PMID: 14640093',
 NOW() - INTERVAL '300 days', NOW() - INTERVAL '30 days',
 'c1000000-0000-0000-0000-000000000009'),

-- 15. Carvedilol + Levothyroxine → reduced carvedilol effect
('di15-0000-0000-0000-000000000015',
 'm14-0000-0000-0000-000000000014', 'm06-0000-0000-0000-000000000006',
 'minor', 'pharmacodynamic',
 'Thyroid hormones increase beta-receptor sensitivity. Achieving euthyroid state may reduce the amount of beta-blockade needed.',
 'If hypothyroidism is corrected with levothyroxine, the dose of carvedilol may need adjustment as cardiovascular parameters change.',
 'Monitor heart rate and blood pressure after thyroid function stabilises. Adjust carvedilol dose accordingly.',
 'theoretical', 'Clinical pharmacology principles — Rang & Dale',
 NOW() - INTERVAL '300 days', NOW() - INTERVAL '30 days',
 'c1000000-0000-0000-0000-000000000009'),

-- 16. Amlodipine + Atorvastatin → elevated statin levels
('di16-0000-0000-0000-000000000016',
 'm03-0000-0000-0000-000000000003', 'm05-0000-0000-0000-000000000005',
 'minor', 'pharmacokinetic',
 'Amlodipine is a weak inhibitor of CYP3A4, which metabolises atorvastatin. Co-administration can modestly increase atorvastatin plasma AUC.',
 'Slightly elevated atorvastatin levels. Low risk of myopathy at standard doses, but relevant at higher doses.',
 'Limit atorvastatin dose to 40mg when combined with amlodipine. Monitor for muscle pain or weakness (myopathy). CK levels if symptoms arise.',
 'clinical_study', 'PMID: 11215658 | FDA Drug Label Atorvastatin',
 NOW() - INTERVAL '365 days', NOW() - INTERVAL '30 days',
 'c1000000-0000-0000-0000-000000000009'),

-- 17. Losartan + Glimepiride → hypoglycaemia (ARBs may enhance insulin sensitivity)
('di17-0000-0000-0000-000000000017',
 'm12-0000-0000-0000-000000000012', 'm16-0000-0000-0000-000000000016',
 'minor', 'pharmacodynamic',
 'ARBs (losartan) may enhance insulin sensitivity and glucose uptake via PPAR-gamma activity, potentially augmenting the glucose-lowering effect of glimepiride.',
 'Minor increase in hypoglycaemia risk, more relevant in elderly or malnourished patients.',
 'No routine dose adjustment required. Educate patient on hypoglycaemia signs. Monitor blood glucose when initiating losartan.',
 'case_report', 'PMID: 17244901',
 NOW() - INTERVAL '300 days', NOW() - INTERVAL '30 days',
 'c1000000-0000-0000-0000-000000000009'),

-- 18. Warfarin + Pantoprazole → mild INR effect
('di18-0000-0000-0000-000000000018',
 'm15-0000-0000-0000-000000000015', 'm17-0000-0000-0000-000000000017',
 'minor', 'pharmacokinetic',
 'Pantoprazole is a weaker CYP2C19 inhibitor than omeprazole. May cause a mild increase in S-warfarin levels in CYP2C19 poor metabolisers.',
 'Slight INR elevation possible, particularly in genetically susceptible patients (CYP2C19 poor metabolisers).',
 'Monitor INR when starting pantoprazole. Usually no significant interaction in extensive metabolisers. Consider genotyping in cases of unexplained INR lability.',
 'case_report', 'PMID: 12920180',
 NOW() - INTERVAL '300 days', NOW() - INTERVAL '30 days',
 'c1000000-0000-0000-0000-000000000009'),

-- 19. Furosemide + Warfarin → reduced diuretic effect + anticoagulation variability
('di19-0000-0000-0000-000000000019',
 'm13-0000-0000-0000-000000000013', 'm15-0000-0000-0000-000000000015',
 'minor', 'pharmacokinetic',
 'Furosemide may displace warfarin from protein binding sites, transiently increasing free warfarin. Rapid volume shifts from diuresis can also alter drug distribution volumes.',
 'Transient INR changes; generally not clinically significant but may require monitoring.',
 'Monitor INR when starting or stopping furosemide, particularly in patients with unstable anticoagulation.',
 'theoretical', 'Stockley Drug Interactions 12th Ed',
 NOW() - INTERVAL '300 days', NOW() - INTERVAL '30 days',
 'c1000000-0000-0000-0000-000000000009'),

-- 20. Glimepiride + Warfarin → enhanced anticoagulation
('di20-0000-0000-0000-000000000020',
 'm16-0000-0000-0000-000000000016', 'm15-0000-0000-0000-000000000015',
 'moderate', 'pharmacokinetic',
 'Sulfonylureas (glimepiride) compete with warfarin for CYP2C9 metabolism and plasma protein binding sites. Can displace warfarin, increasing free drug concentration.',
 'Elevated INR and increased bleeding risk when glimepiride is added or dose increased.',
 'Monitor INR closely when initiating or adjusting glimepiride. Adjust warfarin dose as needed. Patient education on bleeding signs.',
 'clinical_study', 'PMID: 11215660 | BNF 2025',
 NOW() - INTERVAL '300 days', NOW() - INTERVAL '30 days',
 'c1000000-0000-0000-0000-000000000009');


-- =============================================================================
-- 11. USER INTERACTION ALERTS
-- =============================================================================

INSERT INTO safety.user_interaction_alerts
    (id, user_id, drug_interaction_id, prescription_id, status,
     override_reason, alerted_at, acknowledged_at)
VALUES

('ia01-0000-0000-0000-000000000001',
 'a6000000-0000-0000-0000-000000000010',
 'di06-0000-0000-0000-000000000006',
 'rx07-0000-0000-0000-000000000007',
 'acknowledged', NULL,
 NOW() - INTERVAL '54 days', NOW() - INTERVAL '54 days' + INTERVAL '2 hours'),

('ia02-0000-0000-0000-000000000002',
 'a6000000-0000-0000-0000-000000000010',
 'di07-0000-0000-0000-000000000007',
 'rx04-0000-0000-0000-000000000004',
 'overridden',
 'Patient''s nephrologist aware of dual ARB+diuretic use. eGFR stable at 38. Risk-benefit favourable for fluid management.',
 NOW() - INTERVAL '23 days', NOW() - INTERVAL '23 days' + INTERVAL '1 hour'),

('ia03-0000-0000-0000-000000000003',
 'a6000000-0000-0000-0000-000000000010',
 'di02-0000-0000-0000-000000000002',
 'rx10-0000-0000-0000-000000000010',
 'active', NULL,
 NOW() - INTERVAL '40 days', NULL),

('ia04-0000-0000-0000-000000000004',
 'a4000000-0000-0000-0000-000000000004',
 'di03-0000-0000-0000-000000000003',
 'rx05-0000-0000-0000-000000000005',
 'acknowledged', NULL,
 NOW() - INTERVAL '101 days', NOW() - INTERVAL '101 days' + INTERVAL '3 hours'),

('ia05-0000-0000-0000-000000000005',
 'a6000000-0000-0000-0000-000000000010',
 'di19-0000-0000-0000-000000000019',
 'rx07-0000-0000-0000-000000000007',
 'resolved', NULL,
 NOW() - INTERVAL '50 days', NOW() - INTERVAL '48 days');


-- =============================================================================
-- 12. MULTILINGUAL MEDICINE EXPLANATIONS  (i18n.medicine_explanations — 10)
-- =============================================================================

INSERT INTO i18n.medicine_explanations
    (id, medicine_id, language_id, usage_description, side_effects,
     precautions, storage_instructions, is_verified, created_at, updated_at, created_by)
VALUES

-- Metformin — Hindi
('me01-0000-0000-0000-000000000001',
 'm01-0000-0000-0000-000000000001',
 (SELECT id FROM i18n.languages WHERE code = 'hi'),
 'मेटफॉर्मिन टाइप 2 मधुमेह के उपचार के लिए उपयोग की जाती है। यह यकृत में ग्लूकोज उत्पादन को कम करती है और इंसुलिन के प्रति शरीर की संवेदनशीलता बढ़ाती है।',
 'सामान्य दुष्प्रभाव: मतली, उल्टी, दस्त, पेट दर्द — विशेषतः शुरुआत में। भोजन के साथ लेने पर ये कम होते हैं। गंभीर लेकिन दुर्लभ: लैक्टिक एसिडोसिस।',
 'शराब से बचें। यदि सर्जरी हो या आयोडीन कंट्रास्ट दिया जाए तो डॉक्टर को बताएं। गुर्दे की बीमारी में सावधानी से उपयोग करें।',
 'कमरे के तापमान पर (15–30°C) धूप से दूर, नमी से बचाकर रखें।',
 TRUE, NOW() - INTERVAL '300 days', NOW() - INTERVAL '30 days',
 'c1000000-0000-0000-0000-000000000009'),

-- Metformin — Tamil
('me02-0000-0000-0000-000000000002',
 'm01-0000-0000-0000-000000000001',
 (SELECT id FROM i18n.languages WHERE code = 'ta'),
 'மெட்ஃபார்மின் வகை 2 நீரிழிவு நோயை கட்டுப்படுத்த பயன்படுகிறது. கல்லீரலில் குளுக்கோஸ் உற்பத்தியை குறைத்து, இன்சுலின் உணர்திறனை அதிகரிக்கிறது.',
 'பொதுவான பக்க விளைவுகள்: குமட்டல், வாந்தி, வயிற்றுப்போக்கு — குறிப்பாக சிகிச்சையின் தொடக்கத்தில். உணவுடன் எடுத்தால் குறையும்.',
 'மது அருந்துவதை தவிர்க்கவும். அறுவை சிகிச்சை அல்லது கான்ட்ராஸ்ட் ஊசி எடுக்கும் முன் மருத்துவரிடம் தெரிவிக்கவும்.',
 '15-30°C வெப்பநிலையில், நேரடி சூரிய ஒளி மற்றும் ஈரப்பதத்தில் இருந்து விலகி வைக்கவும்.',
 TRUE, NOW() - INTERVAL '280 days', NOW() - INTERVAL '30 days',
 'c1000000-0000-0000-0000-000000000009'),

-- Levothyroxine — Hindi
('me03-0000-0000-0000-000000000003',
 'm06-0000-0000-0000-000000000006',
 (SELECT id FROM i18n.languages WHERE code = 'hi'),
 'लेवोथायरोक्सिन थायरॉयड ग्रंथि की कमी (हाइपोथायरायडिज्म) के इलाज के लिए दी जाती है। यह शरीर में थायरॉयड हार्मोन की कमी को पूरा करती है।',
 'अधिक मात्रा में लेने पर: धड़कन बढ़ना, हाथ कांपना, वजन कम होना, अनिद्रा, अत्यधिक पसीना।',
 'खाली पेट सुबह लें, नाश्ते से 30-60 मिनट पहले। कैल्शियम, आयरन, एंटासिड से 4 घंटे की दूरी रखें। मात्रा डॉक्टर की सलाह के बिना न बदलें।',
 'कमरे के तापमान पर नमी और प्रकाश से दूर रखें।',
 TRUE, NOW() - INTERVAL '280 days', NOW() - INTERVAL '30 days',
 'c1000000-0000-0000-0000-000000000009'),

-- Amlodipine — Telugu
('me04-0000-0000-0000-000000000004',
 'm03-0000-0000-0000-000000000003',
 (SELECT id FROM i18n.languages WHERE code = 'te'),
 'అమ్లోడిపైన్ అధిక రక్తపోటు (హైపర్టెన్షన్) మరియు ఛాతీ నొప్పి (అంజినా) చికిత్సకు వాడతారు. ఇది రక్తనాళాలను వ్యాకోచింపజేసి రక్తపోటును తగ్గిస్తుంది.',
 'సాధారణ దుష్ప్రభావాలు: పాదాల వాపు, తలతిరుగుట, ముఖం ఎర్రబడటం. తీవ్రమైన దుష్ప్రభావాలు అరుదు.',
 'హఠాత్తుగా మాత్రలు ఆపకండి. ప్రతిరోజూ ఒకే సమయంలో తీసుకోండి. గ్రేప్ ఫ్రూట్ జ్యూస్ నివారించండి.',
 '30°C కంటే తక్కువ ఉష్ణోగ్రతలో, పొడి చోట నిల్వ చేయండి.',
 TRUE, NOW() - INTERVAL '260 days', NOW() - INTERVAL '30 days',
 'c1000000-0000-0000-0000-000000000009'),

-- Warfarin — Arabic
('me05-0000-0000-0000-000000000005',
 'm15-0000-0000-0000-000000000015',
 (SELECT id FROM i18n.languages WHERE code = 'ar'),
 'وارفارين مضاد للتخثر يُستخدم لمنع تكوين جلطات الدم في المرضى المصابين بالرجفان الأذيني أو صمامات القلب الاصطناعية أو جلطات الأوردة.',
 'أبرز الآثار الجانبية: نزيف مرئي أو غير مرئي. انتبه لنزيف اللثة، البول الأحمر، أو البراز الداكن.',
 'لا تتناول الأسبرين أو مضادات الالتهاب دون استشارة الطبيب. حافظ على نظام غذائي ثابت من الخضار الورقية (فيتامين K). أجرِ فحص INR شهريًا.',
 'احفظه في درجة حرارة الغرفة بعيداً عن الضوء والرطوبة. بعيداً عن متناول الأطفال.',
 TRUE, NOW() - INTERVAL '250 days', NOW() - INTERVAL '30 days',
 'c1000000-0000-0000-0000-000000000009'),

-- Salbutamol Inhaler — Malayalam
('me06-0000-0000-0000-000000000006',
 'm09-0000-0000-0000-000000000009',
 (SELECT id FROM i18n.languages WHERE code = 'ml'),
 'സൽബ്യൂട്ടമോൾ ഇൻഹേലർ ആസ്ത്മ ആക്രമണ സമയത്ത് ശ്വാസം മുട്ട ഒഴിവാക്കുവാൻ ഉപയോഗിക്കുന്നു. ഇത് ഒരു "rescue inhaler" ആണ്.',
 'വേഗതയേറിയ ഹൃദയമിടിപ്പ്, കൈ വിറയ്ക്കൽ, തലകറക്കം — ഇവ സാധാരണ ദോഷഫലങ്ങളാണ്, സാധാരണ ഏതാനും മിനിറ്റിൽ ശരിയാകും.',
 'ദിവസം 4 തവണയിൽ കൂടുതൽ ഉപയോഗിക്കേണ്ടി വന്നാൽ ഡോക്ടറെ കാണണം. ഒരിക്കലും inhaler ഇല്ലാതെ ഒരിടത്തേക്കും പോകരുത്.',
 '30°C-ൽ താഴെ, ഫ്രീസ് ചെയ്യാതെ, ഇൻഹേലർ ചൂടിൽ തുറക്കരുത്.',
 TRUE, NOW() - INTERVAL '240 days', NOW() - INTERVAL '30 days',
 'c1000000-0000-0000-0000-000000000009'),

-- Atorvastatin — English
('me07-0000-0000-0000-000000000007',
 'm05-0000-0000-0000-000000000005',
 (SELECT id FROM i18n.languages WHERE code = 'en'),
 'Atorvastatin is used to lower high cholesterol (LDL) and triglycerides, and to reduce the risk of heart attacks and strokes in patients with diabetes or cardiovascular risk factors.',
 'Common: muscle aches, headache, nausea, liver enzyme elevation. Rare but serious: rhabdomyolysis (severe muscle breakdown) — report muscle pain, weakness, or dark urine immediately.',
 'Avoid grapefruit juice — it dramatically increases atorvastatin blood levels. Do not stop without telling your doctor. Take at bedtime for maximum efficacy.',
 'Store below 30°C, away from moisture. Keep in original packaging.',
 TRUE, NOW() - INTERVAL '240 days', NOW() - INTERVAL '30 days',
 'c1000000-0000-0000-0000-000000000009'),

-- Methotrexate — English
('me08-0000-0000-0000-000000000008',
 'm10-0000-0000-0000-000000000010',
 (SELECT id FROM i18n.languages WHERE code = 'en'),
 'Methotrexate is used to treat rheumatoid arthritis and certain cancers. In low weekly doses for arthritis, it reduces joint inflammation by suppressing the immune system.',
 'Common: nausea, mouth sores (take folic acid to reduce these), fatigue. Serious: liver damage, bone marrow suppression, lung toxicity. Report breathlessness, unusual bruising, or yellow skin immediately.',
 'Take ONLY ONCE A WEEK on the same day. Taking it daily is DANGEROUS and potentially fatal. Always take folic acid on the other 6 days. Avoid alcohol entirely. Use contraception — teratogenic.',
 'Store at room temperature (15–25°C), away from light and moisture. Keep out of reach of children.',
 TRUE, NOW() - INTERVAL '230 days', NOW() - INTERVAL '30 days',
 'c1000000-0000-0000-0000-000000000009'),

-- Furosemide — Marathi
('me09-0000-0000-0000-000000000009',
 'm13-0000-0000-0000-000000000013',
 (SELECT id FROM i18n.languages WHERE code = 'mr'),
 'फ्युरोसेमाइड एक लघवीलावणारी (लघवी वाढवणारी) औषध आहे जी हृदयाची विफलता, उच्च रक्तदाब आणि मूत्रपिंडाच्या आजारात शरीरातील जास्तीचे पाणी काढून टाकण्यास मदत करते.',
 'सामान्य दुष्परिणाम: जास्त लघवी होणे, चक्कर येणे, कमजोरी. गंभीर: पोटॅशियम कमी होणे (पाय दुखणे, हृदयाची धडधड).',
 'सकाळी घ्या जेणेकरून रात्री लघवीला उठावे लागणार नाही. रोज वजन करा — २ किलोपेक्षा जास्त वाढले तर डॉक्टरांना कळवा.',
 '२५°C च्या खाली, उन आणि ओलावा टाळून ठेवा.',
 TRUE, NOW() - INTERVAL '220 days', NOW() - INTERVAL '30 days',
 'c1000000-0000-0000-0000-000000000009'),

-- Omeprazole — Kannada
('me10-0000-0000-0000-000000000010',
 'm08-0000-0000-0000-000000000008',
 (SELECT id FROM i18n.languages WHERE code = 'kn'),
 'ಒಮೆಪ್ರಾಜೋಲ್ ಜಠರದ ಆಮ್ಲ ಉತ್ಪಾದನೆಯನ್ನು ಕಡಿಮೆ ಮಾಡಲು ಬಳಸಲಾಗುತ್ತದೆ. ಇದು ಅಸಿಡ್ ರಿಫ್ಲಕ್ಸ್, ಅಲ್ಸರ್ ಮತ್ತು GERD ಚಿಕಿತ್ಸೆಯಲ್ಲಿ ಸಹಾಯಕ.',
 'ಸಾಮಾನ್ಯ ಅಡ್ಡ ಪರಿಣಾಮಗಳು: ತಲೆನೋವು, ಅತಿಸಾರ, ಹೊಟ್ಟೆ ನೋವು. ದೀರ್ಘಾವಧಿ ಬಳಕೆಯಲ್ಲಿ ಮ್ಯಾಗ್ನೀಸಿಯಂ ಕೊರತೆ ಸಾಧ್ಯ.',
 'ಉಪಾಹಾರದ ೩೦ ನಿಮಿಷ ಮೊದಲು ತೆಗೆದುಕೊಳ್ಳಿ. ಕ್ಯಾಪ್ಸೂಲ್ ಅಗಿಯಬೇಡಿ — ಸಂಪೂರ್ಣ ನುಂಗಿ.',
 '25°C ಗಿಂತ ಕಡಿಮೆ ತಾಪಮಾನದಲ್ಲಿ, ಒಣ ಸ್ಥಳದಲ್ಲಿ ಇಡಿ.',
 TRUE, NOW() - INTERVAL '210 days', NOW() - INTERVAL '30 days',
 'c1000000-0000-0000-0000-000000000009');


-- =============================================================================
-- 13. CAREGIVER RELATIONSHIPS  (care.caregiver_relationships)
-- =============================================================================

INSERT INTO care.caregiver_relationships
    (id, caregiver_user_id, patient_user_id, relationship_type,
     access_level, status, invited_at, accepted_at, revoked_at, created_at)
VALUES

-- Sneha (spouse) cares for Arjun
('cr01-0000-0000-0000-000000000001',
 'b1000000-0000-0000-0000-000000000006',
 'a1000000-0000-0000-0000-000000000001',
 'spouse', 'admin', 'active',
 NOW() - INTERVAL '170 days',
 NOW() - INTERVAL '169 days', NULL,
 NOW() - INTERVAL '170 days'),

-- Dr. Ananya Rao cares for Ravi Kumar (doctor–patient)
('cr02-0000-0000-0000-000000000002',
 'b2000000-0000-0000-0000-000000000007',
 'a3000000-0000-0000-0000-000000000003',
 'doctor', 'write', 'active',
 NOW() - INTERVAL '210 days',
 NOW() - INTERVAL '208 days', NULL,
 NOW() - INTERVAL '210 days'),

-- Dr. Ananya Rao cares for Fatima Begum
('cr03-0000-0000-0000-000000000003',
 'b2000000-0000-0000-0000-000000000007',
 'a4000000-0000-0000-0000-000000000004',
 'doctor', 'write', 'active',
 NOW() - INTERVAL '105 days',
 NOW() - INTERVAL '103 days', NULL,
 NOW() - INTERVAL '105 days'),

-- Karan Sharma (son) cares for Priya Sharma
('cr04-0000-0000-0000-000000000004',
 'b3000000-0000-0000-0000-000000000008',
 'a2000000-0000-0000-0000-000000000002',
 'sibling', 'read', 'active',
 NOW() - INTERVAL '140 days',
 NOW() - INTERVAL '138 days', NULL,
 NOW() - INTERVAL '140 days'),

-- Sneha invited to also monitor Kamala (parent of Arjun) — pending
('cr05-0000-0000-0000-000000000005',
 'b1000000-0000-0000-0000-000000000006',
 'a6000000-0000-0000-0000-000000000010',
 'child', 'read', 'pending',
 NOW() - INTERVAL '5 days',
 NULL, NULL,
 NOW() - INTERVAL '5 days');


-- =============================================================================
-- 14. CAREGIVER ACTIVITY LOGS  (care.caregiver_activity_logs)
-- =============================================================================

INSERT INTO care.caregiver_activity_logs
    (id, caregiver_user_id, patient_user_id, action_type,
     resource_type, resource_id, metadata, performed_at)
VALUES

('ca01-0000-0000-0000-000000000001',
 'b1000000-0000-0000-0000-000000000006',
 'a1000000-0000-0000-0000-000000000001',
 'view_prescription', 'prescription',
 'rx01-0000-0000-0000-000000000001',
 '{"device":"mobile","platform":"android"}',
 NOW() - INTERVAL '3 days'),

('ca02-0000-0000-0000-000000000002',
 'b1000000-0000-0000-0000-000000000006',
 'a1000000-0000-0000-0000-000000000001',
 'mark_dose_taken', 'reminder',
 'rm03-0000-0000-0000-000000000003',
 '{"note":"Arjun was in surgery — I administered his morning Metformin","dose":"500mg"}',
 NOW() - INTERVAL '2 days' + INTERVAL '10 hours'),

('ca03-0000-0000-0000-000000000003',
 'b2000000-0000-0000-0000-000000000007',
 'a3000000-0000-0000-0000-000000000003',
 'upload_prescription', 'prescription',
 'rx04-0000-0000-0000-000000000004',
 '{"pages":2,"ocr_engine":"google-vision"}',
 NOW() - INTERVAL '23 days'),

('ca04-0000-0000-0000-000000000004',
 'b2000000-0000-0000-0000-000000000007',
 'a3000000-0000-0000-0000-000000000003',
 'view_dose_logs', 'dose_log',
 NULL,
 '{"period":"last_7_days","adherence_pct":85.7}',
 NOW() - INTERVAL '1 day'),

('ca05-0000-0000-0000-000000000005',
 'b2000000-0000-0000-0000-000000000007',
 'a4000000-0000-0000-0000-000000000004',
 'acknowledge_alert', 'interaction_alert',
 'ia04-0000-0000-0000-000000000004',
 '{"interaction":"Warfarin+Methotrexate","action":"acknowledged_clinically_reviewed"}',
 NOW() - INTERVAL '101 days' + INTERVAL '3 hours'),

('ca06-0000-0000-0000-000000000006',
 'b3000000-0000-0000-0000-000000000008',
 'a2000000-0000-0000-0000-000000000002',
 'view_prescription', 'prescription',
 'rx02-0000-0000-0000-000000000002',
 '{"device":"web","browser":"chrome"}',
 NOW() - INTERVAL '10 days'),

('ca07-0000-0000-0000-000000000007',
 'b1000000-0000-0000-0000-000000000006',
 'a1000000-0000-0000-0000-000000000001',
 'update_schedule', 'schedule',
 'sc04-0000-0000-0000-000000000004',
 '{"change":"moved_atorvastatin_from_10pm_to_11pm","reason":"patient_sleep_issues"}',
 NOW() - INTERVAL '7 days');


-- =============================================================================
-- 15. NOTIFICATION LOGS  (notify.notification_logs)
-- =============================================================================

INSERT INTO notify.notification_logs
    (id, user_id, reminder_id, channel_id, template_id,
     event_type, recipient_address, status, provider_message_id,
     error_message, retry_count, sent_at, delivered_at, failed_at, created_at)
VALUES

-- Push notification — Arjun, Metformin morning reminder
('nl01-0000-0000-0000-000000000001',
 'a1000000-0000-0000-0000-000000000001',
 'rm01-0000-0000-0000-000000000001',
 (SELECT id FROM notify.notification_channels WHERE name = 'push'),
 NULL,
 'dose_reminder',
 'fcm:dvc_arjun_android_token_xxxxxx',
 'delivered', 'fcm_msg_20260620_001', NULL, 0,
 NOW() - INTERVAL '4 days' + TIME '07:59',
 NOW() - INTERVAL '4 days' + TIME '08:00',
 NULL, NOW() - INTERVAL '4 days' + TIME '07:59'),

-- SMS — Arjun, missed dose alert
('nl02-0000-0000-0000-000000000002',
 'a1000000-0000-0000-0000-000000000001',
 'rm03-0000-0000-0000-000000000003',
 (SELECT id FROM notify.notification_channels WHERE name = 'sms'),
 NULL,
 'dose_missed',
 '+91987****210',
 'delivered', 'twilio_SM_arjun_missed_001', NULL, 0,
 NOW() - INTERVAL '2 days' + TIME '09:05',
 NOW() - INTERVAL '2 days' + TIME '09:06',
 NULL, NOW() - INTERVAL '2 days' + TIME '09:04'),

-- WhatsApp — Priya, Levothyroxine reminder
('nl03-0000-0000-0000-000000000003',
 'a2000000-0000-0000-0000-000000000002',
 'rm11-0000-0000-0000-000000000011',
 (SELECT id FROM notify.notification_channels WHERE name = 'whatsapp'),
 NULL,
 'dose_reminder',
 '+91981****678',
 'delivered', 'meta_wapi_priya_001', NULL, 0,
 NOW() - INTERVAL '4 days' + TIME '05:58',
 NOW() - INTERVAL '4 days' + TIME '06:00',
 NULL, NOW() - INTERVAL '4 days' + TIME '05:58'),

-- Email — Priya, monthly thyroid test reminder
('nl04-0000-0000-0000-000000000004',
 'a2000000-0000-0000-0000-000000000002',
 NULL,
 (SELECT id FROM notify.notification_channels WHERE name = 'email'),
 NULL,
 'lab_test_reminder',
 'priya.sha****@gmail.com',
 'delivered', 'resend_msg_priya_lab_001', NULL, 0,
 NOW() - INTERVAL '15 days' + TIME '09:00',
 NOW() - INTERVAL '15 days' + TIME '09:01',
 NULL, NOW() - INTERVAL '15 days' + TIME '09:00'),

-- Push — Ravi, drug interaction alert (Losartan + Furosemide)
('nl05-0000-0000-0000-000000000005',
 'a3000000-0000-0000-0000-000000000003',
 NULL,
 (SELECT id FROM notify.notification_channels WHERE name = 'push'),
 NULL,
 'interaction_alert',
 'fcm:dvc_ravi_ios_token_yyyyyy',
 'delivered', 'fcm_msg_ravi_alert_001', NULL, 0,
 NOW() - INTERVAL '23 days' + TIME '10:05',
 NOW() - INTERVAL '23 days' + TIME '10:06',
 NULL, NOW() - INTERVAL '23 days' + TIME '10:05'),

-- Push — Fatima, Methotrexate Saturday reminder
('nl06-0000-0000-0000-000000000006',
 'a4000000-0000-0000-0000-000000000004',
 'rm21-0000-0000-0000-000000000021',
 (SELECT id FROM notify.notification_channels WHERE name = 'push'),
 NULL,
 'dose_reminder',
 'fcm:dvc_fatima_android_token_zzzzzz',
 'delivered', 'fcm_msg_fatima_mtx_001', NULL, 0,
 '2026-06-07 08:59:00+05:30',
 '2026-06-07 09:00:00+05:30',
 NULL, '2026-06-07 08:58:00+05:30'),

-- SMS — Suresh, prescription expiry warning
('nl07-0000-0000-0000-000000000007',
 'a5000000-0000-0000-0000-000000000005',
 NULL,
 (SELECT id FROM notify.notification_channels WHERE name = 'sms'),
 NULL,
 'prescription_expiry',
 '+91984****901',
 'delivered', 'twilio_SM_suresh_expiry_001', NULL, 0,
 NOW() - INTERVAL '7 days' + TIME '10:00',
 NOW() - INTERVAL '7 days' + TIME '10:01',
 NULL, NOW() - INTERVAL '7 days' + TIME '09:59'),

-- Push — Kamala, Warfarin missed dose critical alert
('nl08-0000-0000-0000-000000000008',
 'a6000000-0000-0000-0000-000000000010',
 'rm36-0000-0000-0000-000000000036',
 (SELECT id FROM notify.notification_channels WHERE name = 'push'),
 NULL,
 'dose_missed_critical',
 'fcm:dvc_kamala_android_token_aaaaaa',
 'delivered', 'fcm_msg_kamala_warfarin_missed', NULL, 0,
 NOW() - INTERVAL '2 days' + TIME '19:05',
 NOW() - INTERVAL '2 days' + TIME '19:06',
 NULL, NOW() - INTERVAL '2 days' + TIME '19:04'),

-- Email — Admin, system summary report
('nl09-0000-0000-0000-000000000009',
 'c1000000-0000-0000-0000-000000000009',
 NULL,
 (SELECT id FROM notify.notification_channels WHERE name = 'email'),
 NULL,
 'admin_daily_report',
 'admin@mediscribe.ai',
 'delivered', 'resend_msg_admin_daily_001', NULL, 0,
 NOW() - INTERVAL '1 day' + TIME '06:00',
 NOW() - INTERVAL '1 day' + TIME '06:01',
 NULL, NOW() - INTERVAL '1 day' + TIME '05:59'),

-- Push — Arjun, Atorvastatin bedtime reminder (failed first attempt, retry succeeded)
('nl10-0000-0000-0000-000000000010',
 'a1000000-0000-0000-0000-000000000001',
 'rm44-0000-0000-0000-000000000044',
 (SELECT id FROM notify.notification_channels WHERE name = 'push'),
 NULL,
 'dose_reminder',
 'fcm:dvc_arjun_android_token_xxxxxx',
 'failed', NULL,
 'FCM token expired. Device offline.',
 1,
 NOW() - INTERVAL '4 days' + TIME '21:59',
 NULL,
 NOW() - INTERVAL '4 days' + TIME '22:00',
 NOW() - INTERVAL '4 days' + TIME '21:58'),

-- In-app — Ravi, EPO injection due today
('nl11-0000-0000-0000-000000000011',
 'a3000000-0000-0000-0000-000000000003',
 'rm20-0000-0000-0000-000000000020',
 (SELECT id FROM notify.notification_channels WHERE name = 'in_app'),
 NULL,
 'dose_reminder',
 'user:a3000000-0000-0000-0000-000000000003',
 'delivered', 'inapp_ravi_epo_today', NULL, 0,
 NOW()::DATE + TIME '09:00' - INTERVAL '1 minute',
 NOW()::DATE + TIME '09:00',
 NULL, NOW()::DATE + TIME '08:59'),

-- WhatsApp — Kamala, caregiver invite sent to Sneha
('nl12-0000-0000-0000-000000000012',
 'a6000000-0000-0000-0000-000000000010',
 NULL,
 (SELECT id FROM notify.notification_channels WHERE name = 'whatsapp'),
 NULL,
 'caregiver_invite',
 '+91985****012',
 'delivered', 'meta_wapi_kamala_invite_001', NULL, 0,
 NOW() - INTERVAL '5 days' + TIME '14:00',
 NOW() - INTERVAL '5 days' + TIME '14:01',
 NULL, NOW() - INTERVAL '5 days' + TIME '13:59');


-- =============================================================================
-- END OF SEED DATA
-- =============================================================================
