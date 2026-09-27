import uuid
from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from backend.database.session import get_db
from backend.auth.auth import get_current_user
from backend.models import User
from backend.schemas import MedicineScheduleCreate, MedicineScheduleUpdate, MedicineScheduleResponse
from backend.services.schedule_service import ScheduleService

router = APIRouter(prefix="/schedules", tags=["Schedules"])

def get_schedule_service(db: AsyncSession = Depends(get_db)) -> ScheduleService:
    return ScheduleService(db)

@router.get("/", response_model=List[MedicineScheduleResponse])
async def list_schedules(
    service: ScheduleService = Depends(get_schedule_service),
    current_user: User = Depends(get_current_user)
):
    """List all medicine schedules for the current user."""
    return await service.list_schedules(current_user.user_id)


@router.post("/", response_model=MedicineScheduleResponse, status_code=status.HTTP_201_CREATED)
async def create_schedule(
    schedule_in: MedicineScheduleCreate,
    service: ScheduleService = Depends(get_schedule_service),
    current_user: User = Depends(get_current_user)
):
    """Create a new medicine schedule."""
    return await service.create_schedule(current_user.user_id, schedule_in)


@router.put("/{schedule_id}", response_model=MedicineScheduleResponse)
async def update_schedule(
    schedule_id: uuid.UUID,
    schedule_in: MedicineScheduleUpdate,
    service: ScheduleService = Depends(get_schedule_service),
    current_user: User = Depends(get_current_user)
):
    """Update a medicine schedule."""
    return await service.update_schedule(schedule_id, user_id=current_user.user_id, schedule_in=schedule_in)


@router.delete("/{schedule_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_schedule(
    schedule_id: uuid.UUID,
    service: ScheduleService = Depends(get_schedule_service),
    current_user: User = Depends(get_current_user)
):
    """Delete a medicine schedule."""
    await service.delete_schedule(schedule_id, user_id=current_user.user_id)
    return None
