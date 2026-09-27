import asyncio
import os
import sys

BACKEND_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(BACKEND_DIR)
if PROJECT_ROOT not in sys.path:
    sys.path.insert(0, PROJECT_ROOT)

from backend.database.db import engine
from sqlalchemy import text

async def create_caregiver_tables():
    async with engine.begin() as conn:
        # Create schemas if not exists (though care and sched should already exist)
        await conn.execute(text("CREATE SCHEMA IF NOT EXISTS care;"))
        await conn.execute(text("CREATE SCHEMA IF NOT EXISTS sched;"))

        # 1. Caregiver Notes Table
        print("Creating care.caregiver_notes table...")
        await conn.execute(text("""
            CREATE TABLE IF NOT EXISTS care.caregiver_notes (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                caregiver_id UUID NOT NULL REFERENCES auth_ext.user_profiles(user_id) ON DELETE CASCADE,
                patient_id UUID NOT NULL REFERENCES auth_ext.user_profiles(user_id) ON DELETE CASCADE,
                title VARCHAR(100) NOT NULL,
                content TEXT NOT NULL,
                is_pinned BOOLEAN DEFAULT FALSE,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
                updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
            );
        """))

        # 2. Patient Alerts Table
        print("Creating care.patient_alerts table...")
        await conn.execute(text("""
            CREATE TABLE IF NOT EXISTS care.patient_alerts (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                patient_id UUID NOT NULL REFERENCES auth_ext.user_profiles(user_id) ON DELETE CASCADE,
                alert_type VARCHAR(50) NOT NULL,
                severity VARCHAR(20) NOT NULL,
                message TEXT NOT NULL,
                metadata JSONB,
                is_resolved BOOLEAN DEFAULT FALSE,
                resolved_at TIMESTAMP WITH TIME ZONE,
                resolved_by UUID REFERENCES auth_ext.user_profiles(user_id) ON DELETE SET NULL,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
                updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
            );
        """))

        # 3. Patient Medicine Stock Table
        print("Creating sched.patient_medicine_stock table...")
        await conn.execute(text("""
            CREATE TABLE IF NOT EXISTS sched.patient_medicine_stock (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                user_id UUID NOT NULL REFERENCES auth_ext.user_profiles(user_id) ON DELETE CASCADE,
                prescription_medicine_id UUID NOT NULL REFERENCES rx.prescription_medicines(id) ON DELETE CASCADE,
                current_quantity INT NOT NULL DEFAULT 0,
                daily_dosage INT NOT NULL DEFAULT 1,
                min_threshold INT NOT NULL DEFAULT 10,
                predicted_runout_date DATE,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
                updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
                UNIQUE(user_id, prescription_medicine_id)
            );
        """))

        # Create indices
        print("Creating indexes...")
        await conn.execute(text("CREATE INDEX IF NOT EXISTS idx_caregiver_notes_patient ON care.caregiver_notes(patient_id);"))
        await conn.execute(text("CREATE INDEX IF NOT EXISTS idx_patient_alerts_patient ON care.patient_alerts(patient_id);"))
        await conn.execute(text("CREATE INDEX IF NOT EXISTS idx_patient_alerts_resolved ON care.patient_alerts(is_resolved);"))
        await conn.execute(text("CREATE INDEX IF NOT EXISTS idx_medicine_stock_user ON sched.patient_medicine_stock(user_id);"))

    print("Caregiver tables created successfully.")

if __name__ == "__main__":
    asyncio.run(create_caregiver_tables())
