import uuid
from datetime import datetime, date, time
from typing import List, Optional, Any, Dict
from pydantic import BaseModel, Field, HttpUrl, ConfigDict


# ==========================================
# 1. User Schemas
# ==========================================
class UserBase(BaseModel):
    full_name: str
    phone: Optional[str] = None
    locale: str = "en"
    role: str = "patient"
    date_of_birth: Optional[date] = None
    gender: Optional[str] = None
    blood_group: Optional[str] = None
    allergies: Optional[List[str]] = []
    chronic_conditions: Optional[List[str]] = []
    avatar_url: Optional[str] = None
    is_active: bool = True


class UserCreate(UserBase):
    user_id: Optional[uuid.UUID] = None  # Typically mapped from Auth provider


class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    phone: Optional[str] = None
    locale: Optional[str] = None
    date_of_birth: Optional[date] = None
    gender: Optional[str] = None
    blood_group: Optional[str] = None
    allergies: Optional[List[str]] = None
    chronic_conditions: Optional[List[str]] = None
    avatar_url: Optional[str] = None


class UserResponse(UserBase):
    id: uuid.UUID
    user_id: uuid.UUID
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class TokenResponse(BaseModel):
    """Response schema for authentication endpoints (login/register/refresh)."""
    access_token: str
    refresh_token: str
    token_type: str
    user: UserResponse


# ==========================================
# 2. Prescription Schemas
# ==========================================
class PrescriptionBase(BaseModel):
    title: Optional[str] = None
    doctor_name: Optional[str] = None
    hospital_name: Optional[str] = None
    prescribed_date: Optional[date] = None
    valid_until: Optional[date] = None
    status: str = "active"
    raw_notes: Optional[str] = None


class PrescriptionCreate(PrescriptionBase):
    caregiver_id: Optional[uuid.UUID] = None


class PrescriptionUpdate(BaseModel):
    title: Optional[str] = None
    doctor_name: Optional[str] = None
    hospital_name: Optional[str] = None
    prescribed_date: Optional[date] = None
    valid_until: Optional[date] = None
    status: Optional[str] = None
    raw_notes: Optional[str] = None


class PrescriptionResponse(PrescriptionBase):
    id: uuid.UUID
    user_id: uuid.UUID
    caregiver_id: Optional[uuid.UUID] = None
    created_by: Optional[uuid.UUID] = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


# ==========================================
# 3. Prescription Image Schemas
# ==========================================
class PrescriptionImageBase(BaseModel):
    public_url: str
    storage_path: Optional[str] = None
    file_size_bytes: Optional[int] = None
    mime_type: Optional[str] = None


class PrescriptionImageCreate(PrescriptionImageBase):
    prescription_id: uuid.UUID


class PrescriptionImageResponse(PrescriptionImageBase):
    id: uuid.UUID
    prescription_id: uuid.UUID
    uploaded_by: Optional[uuid.UUID] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


# ==========================================
# 4. OCR Result Schemas
# ==========================================
class OCRResultBase(BaseModel):
    status: str = "pending"
    engine_used: Optional[str] = None
    confidence_score: Optional[float] = None
    raw_text: Optional[str] = None
    structured_data: Optional[Dict[str, Any]] = None
    error_message: Optional[str] = None


class OCRResultCreate(OCRResultBase):
    prescription_image_id: uuid.UUID


class OCRResultUpdate(BaseModel):
    status: Optional[str] = None
    confidence_score: Optional[float] = None
    raw_text: Optional[str] = None
    structured_data: Optional[Dict[str, Any]] = None
    error_message: Optional[str] = None
    completed_at: Optional[datetime] = None


class OCRResultResponse(OCRResultBase):
    id: uuid.UUID
    prescription_image_id: uuid.UUID
    user_id: uuid.UUID
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


# ==========================================
# 5. Medicine Schemas
# ==========================================
class MedicineBase(BaseModel):
    name: str
    generic_name: Optional[str] = None
    brand_name: Optional[str] = None
    manufacturer: Optional[str] = None
    drug_class: Optional[str] = None
    form: Optional[str] = None
    strength: Optional[str] = None
    unit: Optional[str] = None
    is_otc: bool = False
    is_controlled: bool = False
    is_active: bool = True


class MedicineCreate(MedicineBase):
    pass


class MedicineResponse(MedicineBase):
    id: uuid.UUID
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


# ==========================================
# 6. Medicine Schedule Schemas
# ==========================================
class MedicineScheduleBase(BaseModel):
    schedule_name: str
    medicine_name: Optional[str] = None
    recurrence_type: str
    recurrence_rule: Optional[Dict[str, Any]] = None
    dose_time: Optional[time] = None
    dose_amount: Optional[str] = None
    is_active: bool = True


class MedicineScheduleCreate(MedicineScheduleBase):
    prescription_medicine_id: Optional[uuid.UUID] = None


class MedicineScheduleUpdate(BaseModel):
    schedule_name: Optional[str] = None
    medicine_name: Optional[str] = None
    recurrence_type: Optional[str] = None
    recurrence_rule: Optional[Dict[str, Any]] = None
    dose_time: Optional[time] = None
    dose_amount: Optional[str] = None
    is_active: Optional[bool] = None


class MedicineScheduleResponse(MedicineScheduleBase):
    id: uuid.UUID
    prescription_medicine_id: Optional[uuid.UUID] = None
    user_id: uuid.UUID
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


# ==========================================
# 7. Reminder Schemas
# ==========================================
class ReminderBase(BaseModel):
    scheduled_at: datetime
    status: str = "pending"
    snooze_count: int = 0
    snoozed_until: Optional[datetime] = None
    acknowledged_at: Optional[datetime] = None


class ReminderCreate(ReminderBase):
    medicine_schedule_id: uuid.UUID


class ReminderUpdate(BaseModel):
    status: Optional[str] = None
    snooze_count: Optional[int] = None
    snoozed_until: Optional[datetime] = None
    acknowledged_at: Optional[datetime] = None


class ReminderResponse(ReminderBase):
    id: uuid.UUID
    medicine_schedule_id: uuid.UUID
    user_id: uuid.UUID
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


# ==========================================
# 8. Reminder Log Schemas
# ==========================================
class ReminderLogBase(BaseModel):
    action: str
    action_at: Optional[datetime] = None
    notes: Optional[str] = None


class ReminderLogCreate(ReminderLogBase):
    reminder_id: Optional[uuid.UUID] = None
    medicine_schedule_id: uuid.UUID


class ReminderLogResponse(ReminderLogBase):
    id: uuid.UUID
    reminder_id: Optional[uuid.UUID] = None
    user_id: uuid.UUID
    medicine_schedule_id: uuid.UUID
    action_at: datetime

    model_config = ConfigDict(from_attributes=True)


# ==========================================
# 9. Drug Interaction Schemas
# ==========================================
class DrugInteractionBase(BaseModel):
    severity: str
    interaction_type: Optional[str] = None
    mechanism: Optional[str] = None
    clinical_effect: Optional[str] = None
    management: Optional[str] = None
    evidence_level: Optional[str] = None
    source_reference: Optional[str] = None


class DrugInteractionCreate(DrugInteractionBase):
    medicine_a_id: uuid.UUID
    medicine_b_id: uuid.UUID


class DrugInteractionResponse(DrugInteractionBase):
    id: uuid.UUID
    medicine_a_id: uuid.UUID
    medicine_b_id: uuid.UUID
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


# ==========================================
# 10. Caregiver-Patient Map Schemas
# ==========================================
class CaregiverPatientMapBase(BaseModel):
    relationship_type: Optional[str] = None
    access_level: str = "read"
    status: str = "pending"


class CaregiverPatientMapCreate(CaregiverPatientMapBase):
    caregiver_user_id: uuid.UUID
    patient_user_id: uuid.UUID


class CaregiverPatientMapUpdate(BaseModel):
    relationship_type: Optional[str] = None
    access_level: Optional[str] = None
    status: Optional[str] = None
    accepted_at: Optional[datetime] = None
    revoked_at: Optional[datetime] = None


class CaregiverPatientMapResponse(CaregiverPatientMapBase):
    id: uuid.UUID
    caregiver_user_id: uuid.UUID
    patient_user_id: uuid.UUID
    invited_at: datetime
    accepted_at: Optional[datetime] = None
    revoked_at: Optional[datetime] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


# ==========================================
# 11. Onboarding Slide Schemas
# ==========================================
class OnboardingFeature(BaseModel):
    title: str
    icon: str


class OnboardingSlideBase(BaseModel):
    step_number: int
    title: str
    subtitle: str
    illustration_url: str
    features: List[OnboardingFeature] = []


class OnboardingSlideCreate(OnboardingSlideBase):
    pass


class OnboardingSlideResponse(OnboardingSlideBase):
    id: uuid.UUID
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)

