-- =============================================================================
-- MediScribe AI — Migration: Add missing columns to auth_ext.user_profiles
-- Run this ONCE on any existing database that was provisioned before the
-- schema.sql was corrected (Issue #4 fix).
-- =============================================================================

-- Add hashed_password column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'auth_ext'
          AND table_name   = 'user_profiles'
          AND column_name  = 'hashed_password'
    ) THEN
        ALTER TABLE auth_ext.user_profiles
            ADD COLUMN hashed_password TEXT;

        COMMENT ON COLUMN auth_ext.user_profiles.hashed_password
            IS 'bcrypt hash for local (non-Supabase) authentication.';

        RAISE NOTICE 'Added hashed_password column to auth_ext.user_profiles';
    ELSE
        RAISE NOTICE 'hashed_password column already exists — skipping.';
    END IF;
END $$;

-- Add UNIQUE constraint on phone if not already present
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE table_schema = 'auth_ext'
          AND table_name   = 'user_profiles'
          AND constraint_name = 'user_profiles_phone_key'
    ) THEN
        ALTER TABLE auth_ext.user_profiles
            ADD CONSTRAINT user_profiles_phone_key UNIQUE (phone);

        RAISE NOTICE 'Added UNIQUE constraint on phone';
    ELSE
        RAISE NOTICE 'UNIQUE constraint on phone already exists — skipping.';
    END IF;
END $$;

-- Verification queries — run after migration to confirm
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'auth_ext'
  AND table_name   = 'user_profiles'
ORDER BY ordinal_position;
