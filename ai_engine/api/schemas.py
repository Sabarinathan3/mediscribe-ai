from pydantic import BaseModel, Field
from typing import List, Dict

class ProcessPrescriptionResponse(BaseModel):
    medicine: str = Field(..., example="Metformin")
    dosage: str = Field(..., example="500mg")
    frequency: str = Field(..., example="1-0-1")
    duration: str = Field(..., example="30 Days")
    instruction: str = Field(..., example="After Food")
    language_explanations: Dict[str, str] = Field(default_factory=dict)
    warnings: List[str] = Field(default_factory=list)
    confidence_score: float = Field(..., example=0.94)
