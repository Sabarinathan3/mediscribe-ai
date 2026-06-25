import uuid
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from pydantic import BaseModel, field_validator
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from backend.database.session import get_db
from backend.models import User
from backend.schemas import UserCreate, UserResponse
from .auth_service import AuthService
from .auth_utils import decode_token

# ==========================================
# Router Setup
# ==========================================
router = APIRouter(prefix="/auth", tags=["Authentication"])

# OAuth2 scheme configures Swagger UI to expect a Bearer token
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


# ==========================================
# Request Schema: Registration (flat body — no nested user_in key)
# ==========================================
class UserRegisterRequest(BaseModel):
    """Flat registration body so password is never a query parameter."""
    full_name: str
    phone: str
    password: str
    role: str = "patient"
    locale: str = "en"
    is_active: bool = True

    @field_validator("phone")
    @classmethod
    def validate_phone(cls, v: str) -> str:
        import re
        if not re.match(r"^\+?[0-9]{7,15}$", v):
            raise ValueError("Phone must be 7–15 digits, optionally starting with '+'")
        return v

    @field_validator("role")
    @classmethod
    def validate_role(cls, v: str) -> str:
        allowed = {"patient", "caregiver", "admin"}
        if v not in allowed:
            raise ValueError(f"Role must be one of: {', '.join(allowed)}")
        return v


# ==========================================
# Dependencies
# ==========================================
def get_auth_service(db: AsyncSession = Depends(get_db)) -> AuthService:
    return AuthService(db)

async def get_current_user(
    token: str = Depends(oauth2_scheme), 
    db: AsyncSession = Depends(get_db)
) -> User:
    """
    Dependency that decodes the JWT, verifies it, and returns the current user.
    Handles malformed UUIDs in the token payload gracefully (returns 401, not 500).
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    payload = decode_token(token)
    if payload is None or payload.get("token_type") != "access":
        raise credentials_exception
        
    user_id: str = payload.get("sub")
    if user_id is None:
        raise credentials_exception

    # Guard against tampered / malformed UUID in the JWT sub claim
    try:
        user_uuid = uuid.UUID(user_id)
    except ValueError:
        raise credentials_exception

    # Query the database for the user
    result = await db.execute(select(User).where(User.user_id == user_uuid))
    user = result.scalars().first()
    
    if user is None:
        raise credentials_exception
        
    if not user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")
        
    return user

# ==========================================
# Endpoints
# ==========================================
@router.post("/register", status_code=status.HTTP_201_CREATED)
async def register(
    body: UserRegisterRequest,
    auth_service: AuthService = Depends(get_auth_service)
):
    """
    Register a new user.
    Password is accepted securely in the JSON request body (not as a query parameter).
    """
    user_in = UserCreate(
        full_name=body.full_name,
        phone=body.phone,
        role=body.role,
        locale=body.locale,
        is_active=body.is_active,
    )
    return await auth_service.register_user(user_in, body.password)


@router.post("/login")
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    auth_service: AuthService = Depends(get_auth_service)
):
    """
    Authenticate a user and return JWT access and refresh tokens.
    Uses OAuth2PasswordRequestForm so Swagger UI login works out of the box.
    form_data.username is the phone number here.
    """
    return await auth_service.authenticate_user(
        phone=form_data.username, 
        password=form_data.password
    )


@router.post("/refresh")
async def refresh_token(
    refresh_token: str,
    auth_service: AuthService = Depends(get_auth_service)
):
    """
    Exchange a valid refresh token for a new access/refresh token pair.
    """
    return await auth_service.refresh_tokens(refresh_token)


@router.get("/me", response_model=UserResponse)
async def read_users_me(current_user: User = Depends(get_current_user)):
    """
    Get the currently authenticated user's profile.
    Demonstrates usage of the get_current_user dependency.
    """
    return current_user
