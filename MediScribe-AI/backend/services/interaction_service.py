import uuid
from typing import List
from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import or_, and_

from backend.models import DrugInteraction, Medicine
from backend.schemas import DrugInteractionCreate

class InteractionService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_interaction(self, interaction_id: uuid.UUID) -> DrugInteraction:
        result = await self.db.execute(select(DrugInteraction).where(DrugInteraction.id == interaction_id))
        interaction = result.scalars().first()
        if not interaction:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Drug Interaction {interaction_id} not found."
            )
        return interaction

    async def check_interactions(self, medicine_ids: List[uuid.UUID]) -> List[DrugInteraction]:
        """
        Takes a list of medicine IDs and returns any known interactions between them.
        """
        if len(medicine_ids) < 2:
            return []

        # Check for any interaction where both medicine_a and medicine_b are in the provided list
        result = await self.db.execute(
            select(DrugInteraction).where(
                and_(
                    DrugInteraction.medicine_a_id.in_(medicine_ids),
                    DrugInteraction.medicine_b_id.in_(medicine_ids)
                )
            )
        )
        return list(result.scalars().all())

    async def create_interaction(
        self, 
        interaction_in: DrugInteractionCreate, 
        created_by: uuid.UUID
    ) -> DrugInteraction:
        # Validate medicines exist
        meds_check = await self.db.execute(
            select(Medicine.id).where(
                Medicine.id.in_([interaction_in.medicine_a_id, interaction_in.medicine_b_id])
            )
        )
        found_meds = meds_check.scalars().all()
        if len(found_meds) != 2 and interaction_in.medicine_a_id != interaction_in.medicine_b_id:
            raise HTTPException(status_code=404, detail="One or both medicines not found.")

        # Check if interaction already exists (bidirectional check)
        existing_check = await self.db.execute(
            select(DrugInteraction).where(
                or_(
                    and_(
                        DrugInteraction.medicine_a_id == interaction_in.medicine_a_id,
                        DrugInteraction.medicine_b_id == interaction_in.medicine_b_id
                    ),
                    and_(
                        DrugInteraction.medicine_a_id == interaction_in.medicine_b_id,
                        DrugInteraction.medicine_b_id == interaction_in.medicine_a_id
                    )
                )
            )
        )
        if existing_check.scalars().first():
            raise HTTPException(status_code=400, detail="Interaction between these medicines already exists.")

        new_interaction = DrugInteraction(
            medicine_a_id=interaction_in.medicine_a_id,
            medicine_b_id=interaction_in.medicine_b_id,
            severity=interaction_in.severity,
            interaction_type=interaction_in.interaction_type,
            mechanism=interaction_in.mechanism,
            clinical_effect=interaction_in.clinical_effect,
            management=interaction_in.management,
            evidence_level=interaction_in.evidence_level,
            source_reference=interaction_in.source_reference,
            created_by=created_by
        )
        
        self.db.add(new_interaction)
        try:
            await self.db.commit()
            await self.db.refresh(new_interaction)
            return new_interaction
        except Exception:
            await self.db.rollback()
            raise HTTPException(status_code=500, detail="Failed to create interaction record.")

    async def delete_interaction(self, interaction_id: uuid.UUID) -> dict:
        interaction = await self.get_interaction(interaction_id)
        try:
            await self.db.delete(interaction)
            await self.db.commit()
            return {"message": "Drug Interaction deleted successfully"}
        except Exception:
            await self.db.rollback()
            raise HTTPException(status_code=500, detail="Failed to delete interaction record.")
