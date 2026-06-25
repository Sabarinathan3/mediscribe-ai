import uuid
import logging
from datetime import datetime
from typing import Optional
from fastapi import APIRouter, Depends, UploadFile, File, Form, Query, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from backend.database.session import get_db
from backend.auth.auth import get_current_user
from backend.models import User, Prescription, PrescriptionImage, OCRResult
from backend.schemas import OCRResultResponse
from backend.services.file_upload import FileUploadService
from ai_engine.pipeline import PrescriptionAIEngine

logger = logging.getLogger("mediscribe.backend.api.ocr")

router = APIRouter(prefix="/ocr", tags=["OCR Processing"])


@router.post("/process", response_model=OCRResultResponse, status_code=status.HTTP_201_CREATED)
async def process_prescription_image(
    file: UploadFile = File(...),
    prescription_id: Optional[uuid.UUID] = Form(None),
    target_lang: str = Query("en", description="Target language code for explanations/instructions (e.g. 'en', 'es', 'fr', 'hi')"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Upload a prescription image, run layout-aware OCR extraction, and parse medications.
    Automatically checks for drug-drug interactions and dosage safety issues.
    """
    # 1. Validate Prescription belongs to User or create a default Draft prescription
    if prescription_id:
        presc_result = await db.execute(
            select(Prescription).where(
                Prescription.id == prescription_id,
                Prescription.user_id == current_user.user_id
            )
        )
        prescription = presc_result.scalars().first()
        if not prescription:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Prescription {prescription_id} not found for this user."
            )
    else:
        # Create a new draft prescription container for this upload
        prescription = Prescription(
            user_id=current_user.user_id,
            title=f"Uploaded Prescription - {datetime.utcnow().strftime('%Y-%m-%d %H:%M')}",
            status="draft",
            created_by=current_user.user_id
        )
        db.add(prescription)
        await db.commit()
        await db.refresh(prescription)

    # 2. Upload file to Supabase Storage
    try:
        upload_details = await FileUploadService.upload_prescription_image(
            user_id=current_user.user_id,
            file=file
        )
    except HTTPException as http_err:
        raise http_err
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Storage upload error: {str(e)}"
        )

    # 3. Create PrescriptionImage entry
    presc_image = PrescriptionImage(
        prescription_id=prescription.id,
        file_path=upload_details["public_url"],
        file_size_bytes=upload_details["file_size_bytes"],
        mime_type=upload_details["mime_type"],
        uploaded_by=current_user.user_id
    )
    db.add(presc_image)
    await db.commit()
    await db.refresh(presc_image)

    # 4. Create initial OCRResult record (Pending)
    ocr_job = OCRResult(
        prescription_image_id=presc_image.id,
        user_id=current_user.user_id,
        status="processing",
        engine_used="EasyOCR",
        started_at=datetime.utcnow()
    )
    db.add(ocr_job)
    await db.commit()
    await db.refresh(ocr_job)

    # 5. Run AI Engine Pipeline on the raw uploaded file content
    try:
        # Reset file stream and read bytes
        await file.seek(0)
        file_bytes = await file.read()
        
        # Run pipeline logic
        pipeline_output = PrescriptionAIEngine.process_prescription(
            image_input=file_bytes,
            target_lang=target_lang,
            run_quality_check=True,
            generate_audio=True
        )
        
        if pipeline_output.get("pipeline_status") == "success":
            ocr_job.status = "completed"
            ocr_job.confidence_score = pipeline_output["processing_metadata"]["ocr_confidence_average"]
            ocr_job.raw_text = pipeline_output["extracted_prescription"]["raw_text_assembled"]
            ocr_job.structured_data = pipeline_output
        else:
            ocr_job.status = "failed"
            ocr_job.error_message = pipeline_output.get("error", "AI Engine pipeline failure")
            ocr_job.structured_data = pipeline_output

    except Exception as pipe_err:
        logger.error(f"OCR Pipeline failed on upload {presc_image.id}: {str(pipe_err)}")
        ocr_job.status = "failed"
        ocr_job.error_message = str(pipe_err)
        
    ocr_job.completed_at = datetime.utcnow()
    
    try:
        await db.commit()
        await db.refresh(ocr_job)
    except Exception as db_err:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Database update failed after OCR: {str(db_err)}"
        )

    return ocr_job


@router.get("/jobs/{job_id}", response_model=OCRResultResponse)
async def get_ocr_job_status(
    job_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Retrieve the status and full structured extraction results of a previous OCR processing job.
    """
    result = await db.execute(
        select(OCRResult).where(
            OCRResult.id == job_id,
            OCRResult.user_id == current_user.user_id
        )
    )
    ocr_job = result.scalars().first()
    if not ocr_job:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"OCR Job {job_id} not found."
        )
    return ocr_job
