import asyncio
import os
import sys
import json

BACKEND_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(BACKEND_DIR)
if PROJECT_ROOT not in sys.path:
    sys.path.insert(0, PROJECT_ROOT)

from backend.database.db import engine
from sqlalchemy import text

async def create_onboarding_tables():
    async with engine.begin() as conn:
        print("Creating app_config schema...")
        await conn.execute(text("CREATE SCHEMA IF NOT EXISTS app_config;"))

        print("Creating app_config.onboarding_slides table...")
        await conn.execute(text("""
            CREATE TABLE IF NOT EXISTS app_config.onboarding_slides (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                step_number INT NOT NULL UNIQUE,
                title VARCHAR(255) NOT NULL,
                subtitle TEXT NOT NULL,
                illustration_url VARCHAR(255) NOT NULL,
                features JSONB NOT NULL DEFAULT '[]'::jsonb,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
                updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
            );
        """))

        # Clear existing slides so running this script refreshes the data cleanly
        print("Clearing existing onboarding slides...")
        await conn.execute(text("TRUNCATE TABLE app_config.onboarding_slides CASCADE;"))

        # Insert seed slides
        print("Inserting seed onboarding slides...")
        slides = [
            {
                "step_number": 1,
                "title": "AI-Powered Prescription Interpreter",
                "subtitle": "Your Health, Simplified.",
                "illustration_url": "assets/images/onboarding_1.png",
                "features": json.dumps([
                    {"title": "Scan Prescriptions", "icon": "document_scanner"},
                    {"title": "AI-Powered Insights", "icon": "psychology"},
                    {"title": "Safe & Reliable", "icon": "verified_user"}
                ])
            },
            {
                "step_number": 2,
                "title": "Scan & Transcribe Instantly",
                "subtitle": "Simply snap a photo of any written prescription to instantly extract medications, dosages, frequency, and instructions.",
                "illustration_url": "assets/images/onboarding_1.png",
                "features": json.dumps([
                    {"title": "High Accuracy OCR", "icon": "camera_alt"},
                    {"title": "Structured Data", "icon": "analytics"},
                    {"title": "Raw Notes Capture", "icon": "edit_note"}
                ])
            },
            {
                "step_number": 3,
                "title": "Smart Dose Reminders",
                "subtitle": "Receive intelligent notifications, set customized schedules, track adherence, and add caregivers to monitor your health.",
                "illustration_url": "assets/images/onboarding_1.png",
                "features": json.dumps([
                    {"title": "Adherence Tracking", "icon": "check_circle"},
                    {"title": "Caregiver Alerts", "icon": "group"},
                    {"title": "Snooze & Skip", "icon": "notifications_active"}
                ])
            },
            {
                "step_number": 4,
                "title": "Advanced Drug Safety",
                "subtitle": "Our AI automatically cross-references your medications to detect harmful drug-to-drug interactions and safety warnings.",
                "illustration_url": "assets/images/onboarding_1.png",
                "features": json.dumps([
                    {"title": "Interaction Warnings", "icon": "warning"},
                    {"title": "Severity Levels", "icon": "rule"},
                    {"title": "Clinical Guidance", "icon": "health_and_safety"}
                ])
            }
        ]

        for s in slides:
            await conn.execute(
                text("""
                    INSERT INTO app_config.onboarding_slides (step_number, title, subtitle, illustration_url, features)
                    VALUES (:step_number, :title, :subtitle, :illustration_url, :features::jsonb);
                """),
                s
            )

    print("Onboarding slides table created and seeded successfully.")

if __name__ == "__main__":
    asyncio.run(create_onboarding_tables())
