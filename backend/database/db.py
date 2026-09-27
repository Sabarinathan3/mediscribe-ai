import os
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncEngine
from sqlalchemy.pool import NullPool, AsyncAdaptedQueuePool

# ==========================================
# Environment Variables & Configuration
# ==========================================
# In production, ensure POSTGRES_URL is set (e.g., postgresql+asyncpg://user:pass@host/db)
# Fallback provided for local development if needed.
from backend.config import settings

DATABASE_URL = settings.POSTGRES_URL

# Determine environment to optimize pooling strategies
ENV = os.getenv("ENVIRONMENT", "development").lower()

# ==========================================
# Engine Configuration
# ==========================================
# For production (e.g., behind PgBouncer or Supabase connection pooler), NullPool is recommended 
# to avoid maintaining connection state on the Python side, letting the pooler handle it.
# Otherwise, AsyncAdaptedQueuePool is robust for direct database connections.

if ENV == "production":
    engine_kwargs = {
        "poolclass": NullPool,  # Best for external connection poolers (PgBouncer/Supabase)
        "echo": False,          # Disable SQL query logging in production
    }
else:
    engine_kwargs = {
        "poolclass": AsyncAdaptedQueuePool,
        "pool_size": 10,
        "max_overflow": 20,
        "pool_timeout": 30.0,
        "pool_pre_ping": True,  # Verifies connections before using them
        "echo": True,           # Enable SQL query logging for debugging
    }

engine: AsyncEngine = create_async_engine(
    DATABASE_URL,
    **engine_kwargs
)

# ==========================================
# SessionMaker Factory
# ==========================================
SessionLocal = async_sessionmaker(
    bind=engine,
    autocommit=False,
    autoflush=False,
    expire_on_commit=False,
)
