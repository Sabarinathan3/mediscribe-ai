import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import or_

from backend.database.session import get_db
from backend.auth.auth import get_current_user
from backend.models import User, Medicine
from backend.schemas import MedicineCreate, MedicineResponse

router = APIRouter(prefix="/medicines", tags=["Medicines"])

@router.get("/", response_model=List[MedicineResponse])
async def search_medicines(
    q: Optional[str] = Query(None, description="Search term for medicine name or generic name"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Search the shared medicine catalog. Requires authentication.
    """
    stmt = select(Medicine).where(Medicine.is_active == True)
    if q:
        search_term = f"%{q}%"
        stmt = stmt.where(
            or_(
                Medicine.name.ilike(search_term),
                Medicine.generic_name.ilike(search_term),
                Medicine.brand_name.ilike(search_term)
            )
        )
    stmt = stmt.limit(50)
    result = await db.execute(stmt)
    return list(result.scalars().all())


@router.get("/{medicine_id}", response_model=MedicineResponse)
async def get_medicine(
    medicine_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get a specific medicine by ID.
    """
    result = await db.execute(select(Medicine).where(Medicine.id == medicine_id))
    medicine = result.scalars().first()
    if not medicine:
        raise HTTPException(status_code=404, detail="Medicine not found")
    return medicine


@router.post("/", response_model=MedicineResponse, status_code=status.HTTP_201_CREATED)
async def create_medicine(
    medicine_in: MedicineCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Add a new medicine to the catalog (Admin only logic typically applies here).
    """
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized to modify medicine catalog")
        
    new_medicine = Medicine(**medicine_in.model_dump(), created_by=current_user.user_id)
    db.add(new_medicine)
    try:
        await db.commit()
        await db.refresh(new_medicine)
        return new_medicine
    except Exception:
        await db.rollback()
        raise HTTPException(status_code=500, detail="Database error while adding medicine")
