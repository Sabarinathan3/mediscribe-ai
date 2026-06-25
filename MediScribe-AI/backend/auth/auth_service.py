import uuid
from datetime import datetime, timezone
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from fastapi import HTTPException, status

# Assuming these schemas are in backend/schemas.py (adapted to include password fields)
from backend.schemas import UserCreate
from backend.models import User
from .auth_utils import get_password_hash, verify_password, create_access_token, create_refresh_token

class AuthService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def register_user(self, user_in: UserCreate, password: str) -> dict:
        """
        Registers a new user. Hashes the password and creates tokens.
        Note: The actual DB model needs a 'hashed_password' column for local auth.
        """
        # Check if user already exists
        result = await self.db.execute(select(User).where(User.phone == user_in.phone))
        existing_user = result.scalars().first()
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="User with this phone number already exists."
            )

        # Hash password and create user
        hashed_password = get_password_hash(password)
        new_user = User(
            user_id=user_in.user_id or uuid.uuid4(),  # Generate unique subject ID
            full_name=user_in.full_name,
            phone=user_in.phone,
            role=user_in.role,
            locale=user_in.locale,
            hashed_password=hashed_password,
        )
        self.db.add(new_user)
        await self.db.commit()
        await self.db.refresh(new_user)

        # Generate tokens
        access_token = create_access_token({"sub": str(new_user.user_id), "role": new_user.role})
        refresh_token = create_refresh_token({"sub": str(new_user.user_id)})

        return {
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "bearer",
            "user": new_user
        }

    async def authenticate_user(self, phone: str, password: str) -> dict:
        """
        Authenticates a user via phone and password.
        """
        result = await self.db.execute(select(User).where(User.phone == phone))
        user = result.scalars().first()

        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid credentials",
                headers={"WWW-Authenticate": "Bearer"},
            )

        # Verify password against stored hash
        if not user.hashed_password or not verify_password(password, user.hashed_password):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid credentials",
                headers={"WWW-Authenticate": "Bearer"},
            )

        access_token = create_access_token({"sub": str(user.user_id), "role": user.role})
        refresh_token = create_refresh_token({"sub": str(user.user_id)})

        return {
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "bearer"
        }

    async def refresh_tokens(self, refresh_token: str) -> dict:
        """
        Takes a valid refresh token and issues a new access token pair.
        """
        from .auth_utils import decode_token
        payload = decode_token(refresh_token)
        
        if not payload or payload.get("token_type") != "refresh":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or expired refresh token",
                headers={"WWW-Authenticate": "Bearer"},
            )

        user_id = payload.get("sub")
        if not user_id:
            raise HTTPException(status_code=401, detail="Invalid token payload")

        # Verify user still exists and is active
        result = await self.db.execute(select(User).where(User.user_id == uuid.UUID(user_id)))
        user = result.scalars().first()

        if not user or not user.is_active:
            raise HTTPException(status_code=401, detail="User not found or inactive")

        # Issue new tokens
        new_access_token = create_access_token({"sub": str(user.user_id), "role": user.role})
        new_refresh_token = create_refresh_token({"sub": str(user.user_id)})

        return {
            "access_token": new_access_token,
            "refresh_token": new_refresh_token,
            "token_type": "bearer"
        }
