import uuid
from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from backend.database.session import get_db
from backend.auth.auth import get_current_user
from backend.models import User
from backend.schemas import PrescriptionCreate, PrescriptionUpdate, PrescriptionResponse
from backend.services.prescription_service import PrescriptionService
import tempfile
import shutil
import os
from fastapi import File, UploadFile, HTTPException

router = APIRouter(prefix="/prescriptions", tags=["Prescriptions"])

def get_prescription_service(db: AsyncSession = Depends(get_db)) -> PrescriptionService:
    return PrescriptionService(db)


@router.post("/", response_model=PrescriptionResponse, status_code=status.HTTP_201_CREATED)
async def create_prescription(
    prescription_in: PrescriptionCreate,
    service: PrescriptionService = Depends(get_prescription_service),
    current_user: User = Depends(get_current_user)
):
    """
    Create a new prescription for the currently authenticated user.
    """
    return await service.create_prescription(
        user_id=current_user.user_id,
        presc_in=prescription_in,
        created_by=current_user.user_id
    )


@router.get("/", response_model=List[PrescriptionResponse])
async def list_prescriptions(
    service: PrescriptionService = Depends(get_prescription_service),
    current_user: User = Depends(get_current_user)
):
    """
    List all prescriptions belonging to the current user.
    """
    return await service.list_user_prescriptions(user_id=current_user.user_id)


@router.get("/{prescription_id}", response_model=PrescriptionResponse)
async def get_prescription(
    prescription_id: uuid.UUID,
    service: PrescriptionService = Depends(get_prescription_service),
    current_user: User = Depends(get_current_user)
):
    """
    Get a specific prescription by ID.
    (Note: Additional RLS/authorization checks would be handled either at DB level or here)
    """
    return await service.get_prescription(prescription_id, user_id=current_user.user_id)


@router.put("/{prescription_id}", response_model=PrescriptionResponse)
async def update_prescription(
    prescription_id: uuid.UUID,
    prescription_in: PrescriptionUpdate,
    service: PrescriptionService = Depends(get_prescription_service),
    current_user: User = Depends(get_current_user)
):
    """
    Update an existing prescription.
    """
    return await service.update_prescription(prescription_id, user_id=current_user.user_id, presc_in=prescription_in)


@router.delete("/{prescription_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_prescription(
    prescription_id: uuid.UUID,
    service: PrescriptionService = Depends(get_prescription_service),
    current_user: User = Depends(get_current_user)
):
    """
    Delete a specific prescription.
    """
    await service.delete_prescription(prescription_id, user_id=current_user.user_id)
    return None

@router.post("/analyze", status_code=status.HTTP_200_OK)
async def analyze_prescription(
    image: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    service: PrescriptionService = Depends(get_prescription_service)
):
    """
    Analyzes an uploaded prescription image. (Public endpoint for universal testing via Swagger/Flutter)
    """
    if not image.filename.lower().endswith((".jpg", ".jpeg", ".png")):
        raise HTTPException(status_code=400, detail="Invalid file type.")
        
    temp_file_path = ""
    try:
        fd, temp_file_path = tempfile.mkstemp(suffix=os.path.splitext(image.filename)[1])
        with os.fdopen(fd, "wb") as temp_file:
            shutil.copyfileobj(image.file, temp_file)
            
        result = await service.analyze_prescription(temp_file_path, user_id=current_user.user_id)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if temp_file_path and os.path.exists(temp_file_path):
            try:
                os.remove(temp_file_path)
            except:
                pass

