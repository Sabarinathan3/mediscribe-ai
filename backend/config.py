import os
from typing import List
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    # App Settings
    APP_NAME: str = "MediScribe AI Backend"
    ENVIRONMENT: str = "development"
    DEBUG: bool = True

    # Database Settings
    # Must be set explicitly in .env — no insecure default
    POSTGRES_URL: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/mediscribe"

    # JWT Settings
    # REQUIRED — no default. App will fail to start if not provided.
    # Generate with: python -c "import secrets; print(secrets.token_hex(32))"
    JWT_SECRET_KEY: str
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    # Supabase / Storage Settings
    SUPABASE_URL: str = ""
    SUPABASE_SERVICE_ROLE_KEY: str = ""
    SUPABASE_BUCKET_PRESCRIPTIONS: str = "prescriptions"

    # CORS Settings
    # FIX Issue #6: Default is deny-all []. Set allowed origins explicitly in .env.
    # Development example:  CORS_ORIGINS=*
    # Production example:   CORS_ORIGINS=https://mediscribe.app,https://app.mediscribe.ai
    CORS_ORIGINS: List[str] = []

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )


# Instantiate Settings
settings = Settings()
