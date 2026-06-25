import logging
from typing import AsyncGenerator
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import Request
from .db import SessionLocal

logger = logging.getLogger(__name__)

# ==========================================
# FastAPI Dependency Injection
# ==========================================
async def get_db(request: Request) -> AsyncGenerator[AsyncSession, None]:
    """
    FastAPI dependency that provides an asynchronous database session.
    It yields the session to the request handler and ensures the session
    is safely closed after the request completes, regardless of exceptions.
    """
    session: AsyncSession = SessionLocal()
    
    # Optional: Attach session to request state if custom middleware requires it
    request.state.db = session
    
    try:
        yield session
        # Unhandled commits should ideally be done in the service layer,
        # but yield handles the lifecycle boundaries.
    except Exception as e:
        logger.error(f"Database session error: {str(e)}")
        await session.rollback()
        raise
    finally:
        await session.close()
