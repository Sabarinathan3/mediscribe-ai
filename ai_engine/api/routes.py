from fastapi import APIRouter, File, UploadFile, Query
from ai_engine.pipeline import MediScribePipeline
from ai_engine.api.schemas import ProcessPrescriptionResponse

router = APIRouter()
pipeline = MediScribePipeline()

@router.post("/process", response_model=ProcessPrescriptionResponse)
async def process_prescription(
    image: UploadFile = File(...),
    languages: str = Query(default="en,hi,ta")
):
    image_bytes = await image.read()
    lang_list = languages.split(",")
    
    result = pipeline.process(image_bytes, target_languages=lang_list)
    return ProcessPrescriptionResponse(**result)
