import uuid
from typing import List, Optional
from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload

from backend.models import Prescription, User
from backend.schemas import PrescriptionCreate, PrescriptionUpdate


class PrescriptionService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_prescription(
        self, 
        prescription_id: uuid.UUID,
        user_id: uuid.UUID
    ) -> Prescription:
        """
        Fetch a prescription by ID, enforcing that it belongs to the requesting user.
        Returns 404 (not 403) to avoid leaking whether other users' prescriptions exist.
        """
        result = await self.db.execute(
            select(Prescription)
            .options(selectinload(Prescription.images))
            .where(
                Prescription.id == prescription_id,
                Prescription.user_id == user_id,  # Ownership check — CRITICAL
            )
        )
        prescription = result.scalars().first()
        if not prescription:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Prescription {prescription_id} not found."
            )
        return prescription

    async def list_user_prescriptions(self, user_id: uuid.UUID) -> List[Prescription]:
        result = await self.db.execute(
            select(Prescription)
            .where(Prescription.user_id == user_id)
            .order_by(Prescription.created_at.desc())
        )
        return list(result.scalars().all())

    async def create_prescription(
        self, 
        user_id: uuid.UUID, 
        presc_in: PrescriptionCreate, 
        created_by: uuid.UUID
    ) -> Prescription:
        # Validate patient exists
        user_check = await self.db.execute(select(User).where(User.user_id == user_id))
        if not user_check.scalars().first():
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Patient user not found."
            )

        new_presc = Prescription(
            user_id=user_id,
            caregiver_id=presc_in.caregiver_id,
            title=presc_in.title,
            doctor_name=presc_in.doctor_name,
            hospital_name=presc_in.hospital_name,
            prescribed_date=presc_in.prescribed_date,
            valid_until=presc_in.valid_until,
            status=presc_in.status,
            raw_notes=presc_in.raw_notes,
            created_by=created_by
        )
        
        self.db.add(new_presc)
        try:
            await self.db.commit()
            await self.db.refresh(new_presc)
            return new_presc
        except Exception as e:
            await self.db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create prescription due to database error."
            )

    async def update_prescription(
        self, 
        prescription_id: uuid.UUID,
        user_id: uuid.UUID,
        presc_in: PrescriptionUpdate
    ) -> Prescription:
        # Ownership is checked inside get_prescription
        prescription = await self.get_prescription(prescription_id, user_id)

        update_data = presc_in.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(prescription, field, value)

        try:
            await self.db.commit()
            await self.db.refresh(prescription)
            return prescription
        except Exception as e:
            await self.db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to update prescription due to database error."
            )

    async def delete_prescription(
        self, 
        prescription_id: uuid.UUID,
        user_id: uuid.UUID
    ) -> dict:
        # Ownership is checked inside get_prescription
        prescription = await self.get_prescription(prescription_id, user_id)
        
        try:
            await self.db.delete(prescription)
            await self.db.commit()
            return {"message": "Prescription deleted successfully"}
        except Exception as e:
            await self.db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to delete prescription due to database error."
            )

    async def analyze_prescription(self, image_path: str, user_id: uuid.UUID) -> dict:
        import os
        import logging
        from datetime import datetime, date, time, timedelta
        from ai_engine.pipeline import MediScribePipeline
        from backend.models import Prescription, PrescriptionImage, PrescriptionMedicine, MedicineSchedule, Reminder
        
        logger = logging.getLogger(__name__)
        pipeline = MediScribePipeline()

        try:
            with open(image_path, "rb") as f:
                image_bytes = f.read()
                
            analysis_result = pipeline.process(image_bytes=image_bytes, target_languages=["en"])
            
            med_name = analysis_result.get("medicine", "Unknown Medicine")
            dosage = analysis_result.get("dosage", "Unknown Dosage")
            frequency = analysis_result.get("frequency", "Unknown Frequency")
            duration = analysis_result.get("duration", "Unknown Duration")
            instruction = analysis_result.get("instruction", "")
            
            # 1. Create and save Prescription
            prescription = Prescription(
                id=uuid.uuid4(),
                user_id=user_id,
                title=f"Prescription - {med_name}",
                doctor_name="AI Extraction",
                hospital_name="MediScribe Platform",
                prescribed_date=date.today(),
                status="active",
                raw_notes=f"AI parsed instruction: {instruction}",
                created_by=user_id
            )
            self.db.add(prescription)
            
            # 2. Save image metadata
            prescription_image = PrescriptionImage(
                id=uuid.uuid4(),
                prescription_id=prescription.id,
                public_url=f"/static/uploads/{prescription.id}.png",
                storage_path=image_path,
                file_size_bytes=len(image_bytes),
                mime_type="image/png",
                uploaded_by=user_id
            )
            self.db.add(prescription_image)
            
            # 3. Save medicine details
            prescription_medicine = PrescriptionMedicine(
                id=uuid.uuid4(),
                prescription_id=prescription.id,
                medicine_name=med_name,
                dosage=dosage,
                frequency=frequency,
                duration=duration,
                instruction=instruction
            )
            self.db.add(prescription_medicine)
            
            # 4. Generate schedule
            schedule = MedicineSchedule(
                id=uuid.uuid4(),
                prescription_medicine_id=prescription_medicine.id,
                user_id=user_id,
                schedule_name=f"Daily {med_name}",
                medicine_name=med_name,
                recurrence_type="daily",
                dose_time=time(9, 0),
                dose_amount="1",
                is_active=True
            )
            self.db.add(schedule)
            
            # 5. Generate pending Reminder
            now = datetime.now()
            scheduled_time = datetime(now.year, now.month, now.day, 9, 0)
            if scheduled_time < now:
                scheduled_time += timedelta(days=1)
                
            reminder = Reminder(
                id=uuid.uuid4(),
                medicine_schedule_id=schedule.id,
                user_id=user_id,
                scheduled_at=scheduled_time,
                status="pending"
            )
            self.db.add(reminder)
            
            await self.db.commit()
            
            return {
                "id": str(prescription.id),
                "title": prescription.title,
                "doctor_name": prescription.doctor_name,
                "hospital_name": prescription.hospital_name,
                "prescribed_date": str(prescription.prescribed_date),
                "status": prescription.status,
                "raw_notes": prescription.raw_notes,
                "medicines": [
                    {
                        "id": str(prescription_medicine.id),
                        "medicine_name": prescription_medicine.medicine_name,
                        "dosage": prescription_medicine.dosage,
                        "frequency": prescription_medicine.frequency,
                        "duration": prescription_medicine.duration,
                        "instruction": prescription_medicine.instruction
                    }
                ],
                "ai_analysis": analysis_result
            }
            
        except Exception as e:
            await self.db.rollback()
            logger.error(f"Failed to analyze and save prescription: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Integration failed: {str(e)}"
            )
