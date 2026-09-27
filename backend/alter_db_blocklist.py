import asyncio
import os
import sys

BACKEND_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(BACKEND_DIR)
if PROJECT_ROOT not in sys.path:
    sys.path.insert(0, PROJECT_ROOT)

from backend.database.db import engine
from sqlalchemy import text

async def create_blocklist_table():
    async with engine.begin() as conn:
        await conn.execute(text("""
            CREATE TABLE IF NOT EXISTS auth_ext.token_blocklist (
                id UUID PRIMARY KEY,
                jti VARCHAR(36) UNIQUE NOT NULL,
                user_id UUID NOT NULL REFERENCES auth_ext.user_profiles(user_id) ON DELETE CASCADE,
                expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
                updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
            );
        """))
        await conn.execute(text("""
            CREATE INDEX IF NOT EXISTS idx_token_blocklist_jti ON auth_ext.token_blocklist(jti);
        """))
    print("Blocklist table created successfully")

asyncio.run(create_blocklist_table())
