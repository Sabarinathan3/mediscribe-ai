import asyncio
import os
import sys

BACKEND_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(BACKEND_DIR)
if PROJECT_ROOT not in sys.path:
    sys.path.insert(0, PROJECT_ROOT)

from backend.database.db import engine
from sqlalchemy import text

async def alter_db():
    async with engine.begin() as conn:
        await conn.execute(text("ALTER TABLE sched.medicine_schedules ALTER COLUMN prescription_medicine_id DROP NOT NULL;"))
        await conn.execute(text("ALTER TABLE sched.medicine_schedules ADD COLUMN IF NOT EXISTS medicine_name VARCHAR(255);"))
    print("Database altered successfully")

asyncio.run(alter_db())
