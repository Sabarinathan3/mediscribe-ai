from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from backend.database.session import get_db
from backend.models import OnboardingSlide
from backend.schemas import OnboardingSlideResponse

router = APIRouter(prefix="/onboarding", tags=["Onboarding"])

@router.get("/slides", response_model=List[OnboardingSlideResponse])
async def get_onboarding_slides(db: AsyncSession = Depends(get_db)):
    """
    Retrieve all onboarding slides ordered by step number. Public access.
    """
    try:
        stmt = select(OnboardingSlide).order_by(OnboardingSlide.step_number.asc())
        result = await db.execute(stmt)
        return list(result.scalars().all())
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Database error while retrieving onboarding slides: {str(e)}"
        )
