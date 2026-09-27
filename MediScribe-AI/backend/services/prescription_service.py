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
