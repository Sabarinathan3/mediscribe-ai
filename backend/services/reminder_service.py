import uuid
from typing import List, Optional
from datetime import datetime, timezone
from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from backend.models import Reminder, ReminderLog, MedicineSchedule
from backend.schemas import ReminderCreate, ReminderUpdate, ReminderLogCreate

class ReminderService:
    def __init__(self, db: AsyncSession):
        self.db = db

    # ==========================================
    # Reminder Operations
    # ==========================================
    async def get_reminder(self, reminder_id: uuid.UUID, user_id: uuid.UUID) -> Reminder:
        """Fetch a reminder by ID, enforcing that it belongs to the requesting user."""
        result = await self.db.execute(
            select(Reminder).where(
                Reminder.id == reminder_id,
                Reminder.user_id == user_id,  # Ownership check
            )
        )
        reminder = result.scalars().first()
        if not reminder:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Reminder {reminder_id} not found."
            )
        return reminder

    async def list_pending_reminders(self, user_id: uuid.UUID) -> List[Reminder]:
        result = await self.db.execute(
            select(Reminder)
            .where(Reminder.user_id == user_id, Reminder.status == "pending")
            .order_by(Reminder.scheduled_at.asc())
        )
        return list(result.scalars().all())

    async def create_reminder(self, user_id: uuid.UUID, reminder_in: ReminderCreate) -> Reminder:
        # Validate schedule exists
        sched_check = await self.db.execute(
            select(MedicineSchedule).where(MedicineSchedule.id == reminder_in.medicine_schedule_id)
        )
        if not sched_check.scalars().first():
            raise HTTPException(status_code=404, detail="Medicine Schedule not found.")

        new_reminder = Reminder(
            medicine_schedule_id=reminder_in.medicine_schedule_id,
            user_id=user_id,
            scheduled_at=reminder_in.scheduled_at,
            status=reminder_in.status,
            snooze_count=reminder_in.snooze_count,
            snoozed_until=reminder_in.snoozed_until,
            acknowledged_at=reminder_in.acknowledged_at
        )
        self.db.add(new_reminder)
        
        try:
            await self.db.commit()
            await self.db.refresh(new_reminder)
            return new_reminder
        except Exception as e:
            await self.db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create reminder."
            )

    async def update_reminder(self, reminder_id: uuid.UUID, user_id: uuid.UUID, reminder_in: ReminderUpdate) -> Reminder:
        reminder = await self.get_reminder(reminder_id, user_id)
        
        update_data = reminder_in.model_dump(exclude_unset=True)
        if "snooze_count" in update_data:
            if update_data["snooze_count"] > 3:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Maximum snooze limit reached."
                )
        
        for field, value in update_data.items():
            setattr(reminder, field, value)

        try:
            await self.db.commit()
            await self.db.refresh(reminder)
            return reminder
        except Exception as e:
            await self.db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to update reminder."
            )

    async def delete_reminder(self, reminder_id: uuid.UUID, user_id: uuid.UUID) -> dict:
        reminder = await self.get_reminder(reminder_id, user_id)
        try:
            await self.db.delete(reminder)
            await self.db.commit()
            return {"message": "Reminder deleted successfully"}
        except Exception:
            await self.db.rollback()
            raise HTTPException(status_code=500, detail="Failed to delete reminder.")

    # ==========================================
    # Dose Log Operations
    # ==========================================
    async def log_dose(self, user_id: uuid.UUID, log_in: ReminderLogCreate) -> ReminderLog:
        # If logging against a reminder, ensure it exists and update its status
        if log_in.reminder_id:
            reminder = await self.get_reminder(log_in.reminder_id, user_id)
            reminder.status = "acknowledged" if log_in.action == "taken" else log_in.action
            reminder.acknowledged_at = datetime.now(timezone.utc)

        new_log = ReminderLog(
            reminder_id=log_in.reminder_id,
            user_id=user_id,
            medicine_schedule_id=log_in.medicine_schedule_id,
            action=log_in.action,
            notes=log_in.notes
        )
        if log_in.action_at:
            new_log.action_at = log_in.action_at
            
        self.db.add(new_log)
        
        try:
            await self.db.commit()
            await self.db.refresh(new_log)
            return new_log
        except Exception:
            await self.db.rollback()
            raise HTTPException(status_code=500, detail="Failed to create dose log.")
