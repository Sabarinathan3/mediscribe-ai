import os
from typing import List
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    # App Settings
    APP_NAME: str = "MediScribe AI Backend"
    ENVIRONMENT: str = "development"
    DEBUG: bool = True

    # Database Settings
    # Using POSTGRES_URL to match db.py
    POSTGRES_URL: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/mediscribe"

    # JWT Settings
    JWT_SECRET_KEY: str = "super-secret-key-for-development-only"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    # Supabase / Storage Settings
    SUPABASE_URL: str = ""
    SUPABASE_SERVICE_ROLE_KEY: str = ""
    SUPABASE_BUCKET_PRESCRIPTIONS: str = "prescriptions"

    # CORS Settings
    # Can be configured as a comma-separated list of origins in .env
    CORS_ORIGINS: List[str] = ["*"]

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )


# Instantiate Settings
settings = Settings()
