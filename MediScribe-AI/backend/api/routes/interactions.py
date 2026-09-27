import uuid
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession

from backend.database.session import get_db
from backend.auth.auth import get_current_user
from backend.models import User
from backend.schemas import DrugInteractionCreate, DrugInteractionResponse
from backend.services.interaction_service import InteractionService

router = APIRouter(prefix="/interactions", tags=["Interactions"])

def get_interaction_service(db: AsyncSession = Depends(get_db)) -> InteractionService:
    return InteractionService(db)


@router.get("/check", response_model=List[DrugInteractionResponse])
async def check_interactions(
    medicine_ids: List[uuid.UUID] = Query(..., description="List of medicine IDs to cross-check for interactions"),
    service: InteractionService = Depends(get_interaction_service),
    current_user: User = Depends(get_current_user)
):
    """
    Check for potential drug interactions given a list of medicine IDs.
    Returns any known contraindications or warnings.
    """
    return await service.check_interactions(medicine_ids)


@router.post("/", response_model=DrugInteractionResponse, status_code=status.HTTP_201_CREATED)
async def create_interaction(
    interaction_in: DrugInteractionCreate,
    service: InteractionService = Depends(get_interaction_service),
    current_user: User = Depends(get_current_user)
):
    """
    Add a new known drug interaction to the catalog.
    Restricted to admin role only.
    """
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only administrators can manage the drug interaction catalog."
        )
    return await service.create_interaction(
        interaction_in=interaction_in,
        created_by=current_user.user_id
    )


@router.delete("/{interaction_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_interaction(
    interaction_id: uuid.UUID,
    service: InteractionService = Depends(get_interaction_service),
    current_user: User = Depends(get_current_user)
):
    """
    Remove an interaction record. Restricted to admin role only.
    """
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only administrators can manage the drug interaction catalog."
        )
    await service.delete_interaction(interaction_id)
    return None
