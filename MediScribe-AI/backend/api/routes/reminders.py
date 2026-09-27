import uuid
from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from backend.database.session import get_db
from backend.auth.auth import get_current_user
from backend.models import User
from backend.schemas import ReminderCreate, ReminderUpdate, ReminderResponse, ReminderLogCreate, ReminderLogResponse
from backend.services.reminder_service import ReminderService

router = APIRouter(prefix="/reminders", tags=["Reminders"])

def get_reminder_service(db: AsyncSession = Depends(get_db)) -> ReminderService:
    return ReminderService(db)

# ==========================================
# Reminders Endpoints
# ==========================================
@router.get("/pending", response_model=List[ReminderResponse])
async def list_pending_reminders(
    service: ReminderService = Depends(get_reminder_service),
    current_user: User = Depends(get_current_user)
):
    """List all pending reminders for the current user."""
    return await service.list_pending_reminders(current_user.user_id)


@router.post("/", response_model=ReminderResponse, status_code=status.HTTP_201_CREATED)
async def create_reminder(
    reminder_in: ReminderCreate,
    service: ReminderService = Depends(get_reminder_service),
    current_user: User = Depends(get_current_user)
):
    """Create a new reminder linked to a medicine schedule."""
    return await service.create_reminder(current_user.user_id, reminder_in)


@router.put("/{reminder_id}", response_model=ReminderResponse)
async def update_reminder(
    reminder_id: uuid.UUID,
    reminder_in: ReminderUpdate,
    service: ReminderService = Depends(get_reminder_service),
    current_user: User = Depends(get_current_user)
):
    """Update reminder status (e.g., snooze)."""
    return await service.update_reminder(reminder_id, user_id=current_user.user_id, reminder_in=reminder_in)


@router.delete("/{reminder_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_reminder(
    reminder_id: uuid.UUID,
    service: ReminderService = Depends(get_reminder_service),
    current_user: User = Depends(get_current_user)
):
    """Delete a reminder."""
    await service.delete_reminder(reminder_id, user_id=current_user.user_id)
    return None

# ==========================================
# Dose Logging Endpoints
# ==========================================
@router.post("/logs", response_model=ReminderLogResponse, status_code=status.HTTP_201_CREATED)
async def log_dose(
    log_in: ReminderLogCreate,
    service: ReminderService = Depends(get_reminder_service),
    current_user: User = Depends(get_current_user)
):
    """
    Log a dose (taken/skipped) and automatically update associated reminder status.
    """
    return await service.log_dose(current_user.user_id, log_in)
