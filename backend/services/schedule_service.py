import uuid
from typing import List, Optional
from datetime import datetime, timezone
from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from backend.models import MedicineSchedule, Reminder
from backend.schemas import MedicineScheduleCreate, MedicineScheduleUpdate

class ScheduleService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def list_schedules(self, user_id: uuid.UUID) -> List[MedicineSchedule]:
        """List all medicine schedules for the user."""
        result = await self.db.execute(
            select(MedicineSchedule)
            .where(MedicineSchedule.user_id == user_id)
            .order_by(MedicineSchedule.created_at.desc())
        )
        return list(result.scalars().all())

    async def get_schedule(self, schedule_id: uuid.UUID, user_id: uuid.UUID) -> MedicineSchedule:
        """Get a schedule by ID."""
        result = await self.db.execute(
            select(MedicineSchedule).where(
                MedicineSchedule.id == schedule_id,
                MedicineSchedule.user_id == user_id,
            )
        )
        schedule = result.scalars().first()
        if not schedule:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Medicine Schedule {schedule_id} not found."
            )
        return schedule

    async def create_schedule(self, user_id: uuid.UUID, schedule_in: MedicineScheduleCreate) -> MedicineSchedule:
        """Create a new medicine schedule."""
        new_schedule = MedicineSchedule(
            user_id=user_id,
            schedule_name=schedule_in.schedule_name,
            medicine_name=schedule_in.medicine_name,
            prescription_medicine_id=schedule_in.prescription_medicine_id,
            recurrence_type=schedule_in.recurrence_type,
            recurrence_rule=schedule_in.recurrence_rule,
            dose_time=schedule_in.dose_time,
            dose_amount=schedule_in.dose_amount,
            is_active=schedule_in.is_active
        )
        self.db.add(new_schedule)
        
        try:
            await self.db.commit()
            await self.db.refresh(new_schedule)
            return new_schedule
        except Exception as e:
            await self.db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create medicine schedule."
            )

    async def update_schedule(self, schedule_id: uuid.UUID, user_id: uuid.UUID, schedule_in: MedicineScheduleUpdate) -> MedicineSchedule:
        """Update an existing medicine schedule."""
        schedule = await self.get_schedule(schedule_id, user_id)
        
        update_data = schedule_in.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(schedule, field, value)

        try:
            await self.db.commit()
            await self.db.refresh(schedule)
            return schedule
        except Exception as e:
            await self.db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to update medicine schedule."
            )

    async def delete_schedule(self, schedule_id: uuid.UUID, user_id: uuid.UUID) -> dict:
        """Delete a medicine schedule."""
        schedule = await self.get_schedule(schedule_id, user_id)
        try:
            await self.db.delete(schedule)
            await self.db.commit()
            return {"message": "Medicine schedule deleted successfully"}
        except Exception:
            await self.db.rollback()
            raise HTTPException(status_code=500, detail="Failed to delete medicine schedule.")
