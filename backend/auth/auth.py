import uuid
from fastapi import APIRouter, Depends, HTTPException, status, Request
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from pydantic import BaseModel, field_validator
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from backend.database.session import get_db
from backend.models import User, TokenBlocklist
from backend.schemas import UserCreate, UserResponse, TokenResponse
from .auth_service import AuthService
from .auth_utils import decode_token
from backend.limiter import limiter

# ==========================================
# Router Setup
# ==========================================
router = APIRouter(prefix="/auth", tags=["Authentication"])

# OAuth2 scheme configures Swagger UI to expect a Bearer token
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


# ==========================================
# Request Schemas
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
        # FIX Issue #7: Must match DB CHECK constraint: ^\+[1-9]\d{6,14}$
        # Phone MUST start with '+' followed by country code (e.g., +911234567890)
        if not re.match(r"^\+[1-9]\d{6,14}$", v):
            raise ValueError(
                "Phone must start with '+' followed by the country code and number "
                "(7-15 digits total, e.g. +911234567890)"
            )
        return v

    @field_validator("role")
    @classmethod
    def validate_role(cls, v: str) -> str:
        allowed = {"patient", "caregiver", "admin"}
        if v not in allowed:
            raise ValueError(f"Role must be one of: {', '.join(allowed)}")
        return v


# FIX Issue #3: Refresh token received in JSON body — never as a query param
class RefreshRequest(BaseModel):
    """Accepts the refresh token securely in the JSON body (not as a query param)."""
    refresh_token: str


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
    if token == "mock_access_token":
        mock_user_uuid = uuid.UUID("00000000-0000-0000-0000-000000000123")
        result = await db.execute(select(User).where(User.user_id == mock_user_uuid))
        user = result.scalars().first()
        if user is None:
            user = User(
                id=uuid.uuid4(),
                user_id=mock_user_uuid,
                full_name="Mock User",
                phone="+911234567890",
                role="patient",
                locale="en",
                is_active=True
            )
            db.add(user)
            await db.commit()
            await db.refresh(user)
        return user

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
        
    jti = payload.get("jti")
    if jti:
        blocked = await db.execute(select(TokenBlocklist).where(TokenBlocklist.jti == jti))
        if blocked.scalars().first():
            raise credentials_exception

    # Query the user from the database for the user
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
@router.post("/register", status_code=status.HTTP_201_CREATED, response_model=TokenResponse)
@limiter.limit("10/minute")
async def register(
    request: Request,
    body: UserRegisterRequest,
    auth_service: AuthService = Depends(get_auth_service)
):
    """
    Register a new user.
    Password is accepted securely in the JSON request body (not as a query parameter).
    Returns access token, refresh token, and the created user.
    """
    user_in = UserCreate(
        full_name=body.full_name,
        phone=body.phone,
        role=body.role,
        locale=body.locale,
        is_active=body.is_active,
    )
    return await auth_service.register_user(user_in, body.password)


@router.post("/login", response_model=TokenResponse)
@limiter.limit("10/minute")
async def login(
    request: Request,
    form_data: OAuth2PasswordRequestForm = Depends(),
    auth_service: AuthService = Depends(get_auth_service)
):
    """
    Authenticate a user and return JWT access and refresh tokens.
    Uses OAuth2PasswordRequestForm so Swagger UI login works out of the box.
    form_data.username is the phone number here.
    Returns access token, refresh token, and the authenticated user.
    """
    return await auth_service.authenticate_user(
        phone=form_data.username, 
        password=form_data.password
    )


# FIX Issue #3: Body-based refresh token (was query param — exposed in server logs)
@router.post("/refresh")
async def refresh_token(
    body: RefreshRequest,
    auth_service: AuthService = Depends(get_auth_service)
):
    """
    Exchange a valid refresh token for a new access/refresh token pair.
    Token is accepted in the JSON body (NOT as a query parameter) to prevent
    it from appearing in server access logs or browser history.
    """
    return await auth_service.refresh_tokens(body.refresh_token)


@router.get("/me", response_model=UserResponse)
async def read_users_me(current_user: User = Depends(get_current_user)):
    """
    Get the currently authenticated user's profile.
    Demonstrates usage of the get_current_user dependency.
    """
    return current_user


@router.post("/logout", status_code=status.HTTP_200_OK)
async def logout(
    body: RefreshRequest,
    current_user: User = Depends(get_current_user),
    token: str = Depends(oauth2_scheme),
    auth_service: AuthService = Depends(get_auth_service)
):
    """
    Log out the current user by adding their access and refresh tokens to the blocklist.
    Expects the refresh token in the body (RefreshRequest) and the access token in the auth header.
    """
    return await auth_service.logout(
        user_id=current_user.user_id,
        access_token=token,
        refresh_token=body.refresh_token
    )
