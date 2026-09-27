from typing import List, Optional
from fastapi import APIRouter, UploadFile, File, HTTPException, Depends, status
from pydantic import BaseModel

from ai_engine.pipeline import MediScribePipeline
from backend.auth.auth import get_current_user
from backend.models import User

router = APIRouter(prefix="/ai", tags=["AI Engine"])


# ==========================================
# Pydantic Schemas for Response Validation
# ==========================================
class MedicationItem(BaseModel):
    medicine: str
    dosage: str
    frequency: str
    duration: str
    instruction: str
    translated_instruction: Optional[str] = None
    audio_base64: Optional[str] = None


class OCRMetadata(BaseModel):
    confidence: float
    raw_text: str
    abbreviation_resolution_confidence: float


class PrescriptionProcessResponse(BaseModel):
    valid: bool
    errors: List[str]
    medications: List[MedicationItem]
    ocr_metadata: Optional[OCRMetadata] = None


# ==========================================
# Endpoint definition
# ==========================================
@router.post(
    "/process-prescription", 
    status_code=status.HTTP_200_OK
)
async def process_prescription(
    file: UploadFile = File(...),
    target_lang: str = "en",
    current_user: User = Depends(get_current_user)  # Auth required — prevents unauthenticated compute abuse
):
    """
    Uploads a prescription image and processes it through the AI pipeline.
    Returns layout-aware OCR text, parsed medications, sig code expansions, and validation results.
    """
    # 1. Basic File Content Validation
    if not file.content_type.startswith("image/"):
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail="Uploaded file must be a valid image."
        )

    try:
        # 2. Read raw image bytes
        image_bytes = await file.read()
        
        # 3. Invoke the AI Pipeline orchestrator
        pipeline = MediScribePipeline()
        result = pipeline.process(
            image_bytes=image_bytes,
            target_languages=[target_lang]
        )
        
        # Ensure we return valid format or wrap in response
        return result

    except HTTPException as http_err:
        raise http_err
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"An error occurred during prescription analysis: {str(e)}"
        )
