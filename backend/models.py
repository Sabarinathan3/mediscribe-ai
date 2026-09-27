import uuid
from datetime import datetime, date, time
from typing import List, Optional, Any
from sqlalchemy import String, Boolean, DateTime, Date, Time, ForeignKey, Text, Float, JSON, CheckConstraint, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID, ARRAY
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship
from sqlalchemy.sql import func


class Base(DeclarativeBase):
    pass


class AuditMixin:
    """Mixin for audit fields."""
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )


# ==========================================
# 1. User Model
# ==========================================
class User(Base, AuditMixin):
    __tablename__ = "user_profiles"

    __table_args__ = (
        CheckConstraint("role IN ('patient', 'caregiver', 'admin')", name="ck_user_role"),
        {"schema": "auth_ext"}
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), unique=True, nullable=False)
    full_name: Mapped[str] = mapped_column(String(100), nullable=False)
    phone: Mapped[Optional[str]] = mapped_column(String(20), unique=True)
    locale: Mapped[str] = mapped_column(String(10), default="en")
    role: Mapped[str] = mapped_column(String(20), default="patient")  # patient, caregiver, admin
    hashed_password: Mapped[Optional[str]] = mapped_column(String(255))  # bcrypt hash for local auth
    date_of_birth: Mapped[Optional[date]] = mapped_column(Date)
    gender: Mapped[Optional[str]] = mapped_column(String(20))
    blood_group: Mapped[Optional[str]] = mapped_column(String(5))
    allergies: Mapped[Optional[List[str]]] = mapped_column(ARRAY(String))
    chronic_conditions: Mapped[Optional[List[str]]] = mapped_column(ARRAY(String))
    avatar_url: Mapped[Optional[str]] = mapped_column(Text)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    # Relationships
    prescriptions: Mapped[List["Prescription"]] = relationship(
        "Prescription",
        back_populates="patient",
        foreign_keys="[Prescription.user_id]",
        cascade="all, delete-orphan",
        passive_deletes=True
    )
    medicine_schedules: Mapped[List["MedicineSchedule"]] = relationship(
        "MedicineSchedule",
        back_populates="user",
        cascade="all, delete-orphan",
        passive_deletes=True
    )
    reminders: Mapped[List["Reminder"]] = relationship(
        "Reminder",
        back_populates="user",
        cascade="all, delete-orphan",
        passive_deletes=True
    )
    patients_managed: Mapped[List["CaregiverPatientMap"]] = relationship(
        "CaregiverPatientMap",
        foreign_keys="[CaregiverPatientMap.caregiver_user_id]",
        back_populates="caregiver",
        cascade="all, delete-orphan",
        passive_deletes=True
    )
    caregivers: Mapped[List["CaregiverPatientMap"]] = relationship(
        "CaregiverPatientMap",
        foreign_keys="[CaregiverPatientMap.patient_user_id]",
        back_populates="patient",
        cascade="all, delete-orphan",
        passive_deletes=True
    )

class TokenBlocklist(Base, AuditMixin):
    __tablename__ = "token_blocklist"
    __table_args__ = {"schema": "auth_ext"}

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    jti: Mapped[str] = mapped_column(String(36), unique=True, nullable=False, index=True)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("auth_ext.user_profiles.user_id", ondelete="CASCADE"), nullable=False)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)


# ==========================================
# 2. Prescription Model
# ==========================================
class Prescription(Base, AuditMixin):
    __tablename__ = "prescriptions"
    __table_args__ = (
        CheckConstraint("status IN ('active', 'expired', 'revoked', 'draft')", name="ck_prescription_status"),
        {"schema": "rx"}
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("auth_ext.user_profiles.user_id", ondelete="CASCADE"), nullable=False)
    caregiver_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("auth_ext.user_profiles.user_id", ondelete="SET NULL"))
    title: Mapped[Optional[str]] = mapped_column(String(255))
    doctor_name: Mapped[Optional[str]] = mapped_column(String(255))
    hospital_name: Mapped[Optional[str]] = mapped_column(String(255))
    prescribed_date: Mapped[Optional[date]] = mapped_column(Date)
    valid_until: Mapped[Optional[date]] = mapped_column(Date)
    status: Mapped[str] = mapped_column(String(20), default="active")  # active, expired, revoked
    raw_notes: Mapped[Optional[str]] = mapped_column(Text)
    created_by: Mapped[Optional[uuid.UUID]] = mapped_column(UUID(as_uuid=True))

    # Relationships
    patient: Mapped["User"] = relationship("User", foreign_keys=[user_id], back_populates="prescriptions")
    images: Mapped[List["PrescriptionImage"]] = relationship("PrescriptionImage", back_populates="prescription", cascade="all, delete-orphan")
    medicines: Mapped[List["PrescriptionMedicine"]] = relationship("PrescriptionMedicine", back_populates="prescription", cascade="all, delete-orphan")


# ==========================================
# 2b. Prescription Medicine Model (MISSING — now added)
# ==========================================
class PrescriptionMedicine(Base, AuditMixin):
    __tablename__ = "prescription_medicines"
    __table_args__ = {"schema": "rx"}

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    prescription_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("rx.prescriptions.id", ondelete="CASCADE"), nullable=False)
    medicine_name: Mapped[str] = mapped_column(String(255), nullable=False)
    generic_name: Mapped[Optional[str]] = mapped_column(String(255))
    dosage: Mapped[Optional[str]] = mapped_column(String(100))
    frequency: Mapped[Optional[str]] = mapped_column(String(100))
    duration: Mapped[Optional[str]] = mapped_column(String(100))
    instruction: Mapped[Optional[str]] = mapped_column(Text)
    form: Mapped[Optional[str]] = mapped_column(String(50))  # tablet, capsule, syrup, injection
    quantity: Mapped[Optional[str]] = mapped_column(String(50))
    refills: Mapped[int] = mapped_column(default=0)
    notes: Mapped[Optional[str]] = mapped_column(Text)
    medicine_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("med.medicines.id", ondelete="SET NULL"))

    # Relationships
    prescription: Mapped["Prescription"] = relationship("Prescription", back_populates="medicines")
    schedules: Mapped[List["MedicineSchedule"]] = relationship("MedicineSchedule", back_populates="prescription_medicine")


# ==========================================
# 3. Prescription Image Model
# ==========================================
class PrescriptionImage(Base, AuditMixin):
    __tablename__ = "prescription_images"
    __table_args__ = {"schema": "rx"}

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    prescription_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("rx.prescriptions.id", ondelete="CASCADE"), nullable=False)
    public_url: Mapped[str] = mapped_column(Text, nullable=False)
    storage_path: Mapped[Optional[str]] = mapped_column(Text)
    file_size_bytes: Mapped[Optional[int]] = mapped_column()
    mime_type: Mapped[Optional[str]] = mapped_column(String(50))
    uploaded_by: Mapped[Optional[uuid.UUID]] = mapped_column(UUID(as_uuid=True))

    # Relationships
    prescription: Mapped["Prescription"] = relationship("Prescription", back_populates="images")
    ocr_jobs: Mapped[List["OCRResult"]] = relationship("OCRResult", back_populates="image")


# ==========================================
# 4. OCR Result (Job) Model
# ==========================================
class OCRResult(Base, AuditMixin):
    __tablename__ = "ocr_jobs"
    __table_args__ = {"schema": "ocr"}

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    prescription_image_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("rx.prescription_images.id", ondelete="CASCADE"), nullable=False)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("auth_ext.user_profiles.user_id", ondelete="CASCADE"), nullable=False)
    status: Mapped[str] = mapped_column(String(20), default="pending")  # pending, processing, completed, failed
    engine_used: Mapped[Optional[str]] = mapped_column(String(50))
    confidence_score: Mapped[Optional[float]] = mapped_column(Float)
    raw_text: Mapped[Optional[str]] = mapped_column(Text)
    structured_data: Mapped[Optional[dict[str, Any]]] = mapped_column(JSON)
    error_message: Mapped[Optional[str]] = mapped_column(Text)
    started_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    completed_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))

    # Relationships
    image: Mapped["PrescriptionImage"] = relationship("PrescriptionImage", back_populates="ocr_jobs")


# ==========================================
# 5. Medicine Model
# ==========================================
class Medicine(Base, AuditMixin):
    __tablename__ = "medicines"
    __table_args__ = {"schema": "med"}

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    generic_name: Mapped[Optional[str]] = mapped_column(String(255))
    brand_name: Mapped[Optional[str]] = mapped_column(String(255))
    manufacturer: Mapped[Optional[str]] = mapped_column(String(255))
    drug_class: Mapped[Optional[str]] = mapped_column(String(100))
    form: Mapped[Optional[str]] = mapped_column(String(50))
    strength: Mapped[Optional[str]] = mapped_column(String(50))
    unit: Mapped[Optional[str]] = mapped_column(String(20))
    is_otc: Mapped[bool] = mapped_column(Boolean, default=False)
    is_controlled: Mapped[bool] = mapped_column(Boolean, default=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_by: Mapped[Optional[uuid.UUID]] = mapped_column(UUID(as_uuid=True))


# ==========================================
# 6. Medicine Schedule Model
# ==========================================
class MedicineSchedule(Base, AuditMixin):
    __tablename__ = "medicine_schedules"
    __table_args__ = {"schema": "sched"}

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    prescription_medicine_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("rx.prescription_medicines.id", ondelete="CASCADE"), nullable=True)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("auth_ext.user_profiles.user_id", ondelete="CASCADE"), nullable=False)
    schedule_name: Mapped[str] = mapped_column(String(100), nullable=False)
    medicine_name: Mapped[Optional[str]] = mapped_column(String(255))
    recurrence_type: Mapped[str] = mapped_column(String(20), nullable=False)  # daily, weekly, monthly, as_needed
    recurrence_rule: Mapped[Optional[dict[str, Any]]] = mapped_column(JSON)
    dose_time: Mapped[Optional[time]] = mapped_column(Time)
    dose_amount: Mapped[Optional[str]] = mapped_column(String(50))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="medicine_schedules")
    prescription_medicine: Mapped[Optional["PrescriptionMedicine"]] = relationship("PrescriptionMedicine", back_populates="schedules")
    reminders: Mapped[List["Reminder"]] = relationship("Reminder", back_populates="schedule", cascade="all, delete-orphan", passive_deletes=True)


# ==========================================
# 7. Reminder Model
# ==========================================
class Reminder(Base, AuditMixin):
    __tablename__ = "reminders"
    __table_args__ = (
        CheckConstraint("status IN ('pending', 'sent', 'acknowledged', 'missed', 'skipped', 'snoozed')", name="ck_reminder_status"),
        {"schema": "remind"}
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    medicine_schedule_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("sched.medicine_schedules.id", ondelete="CASCADE"), nullable=False)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("auth_ext.user_profiles.user_id", ondelete="CASCADE"), nullable=False)
    scheduled_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    status: Mapped[str] = mapped_column(String(20), default="pending")  # pending, sent, acknowledged, missed, skipped, snoozed
    snooze_count: Mapped[int] = mapped_column(default=0)
    snoozed_until: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    acknowledged_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))

    # Relationships
    schedule: Mapped["MedicineSchedule"] = relationship("MedicineSchedule", back_populates="reminders")
    user: Mapped["User"] = relationship("User", back_populates="reminders")
    dose_logs: Mapped[List["ReminderLog"]] = relationship("ReminderLog", back_populates="reminder")


# ==========================================
# 8. Reminder Log (Dose Log) Model
# ==========================================
class ReminderLog(Base, AuditMixin):
    __tablename__ = "dose_logs"
    __table_args__ = (
        CheckConstraint("action IN ('taken', 'missed', 'skipped')", name="ck_dose_log_action"),
        {"schema": "remind"}
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    reminder_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("remind.reminders.id", ondelete="SET NULL"))
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("auth_ext.user_profiles.user_id", ondelete="CASCADE"), nullable=False)
    medicine_schedule_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("sched.medicine_schedules.id", ondelete="CASCADE"), nullable=False)
    action: Mapped[str] = mapped_column(String(20), nullable=False)  # taken, missed, skipped
    action_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    notes: Mapped[Optional[str]] = mapped_column(Text)

    # Relationships
    reminder: Mapped[Optional["Reminder"]] = relationship("Reminder", back_populates="dose_logs")


# ==========================================
# 9. Drug Interaction Model
# ==========================================
class DrugInteraction(Base, AuditMixin):
    __tablename__ = "drug_interactions"
    # Bidirectional uniqueness: (A,B) and (B,A) are the same interaction.
    # The DB-level CHECK ensures medicine_a_id < medicine_b_id so the pair is always stored canonically.
    __table_args__ = (
        UniqueConstraint("medicine_a_id", "medicine_b_id", name="uq_drug_interaction_pair"),
        CheckConstraint("medicine_a_id < medicine_b_id", name="ck_drug_interaction_order"),
        CheckConstraint("severity IN ('major', 'moderate', 'minor')", name="ck_drug_interaction_severity"),
        {"schema": "safety"}
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    medicine_a_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("med.medicines.id", ondelete="CASCADE"), nullable=False)
    medicine_b_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("med.medicines.id", ondelete="CASCADE"), nullable=False)
    severity: Mapped[str] = mapped_column(String(20), nullable=False)  # major, moderate, minor
    interaction_type: Mapped[Optional[str]] = mapped_column(String(50))
    mechanism: Mapped[Optional[str]] = mapped_column(Text)
    clinical_effect: Mapped[Optional[str]] = mapped_column(Text)
    management: Mapped[Optional[str]] = mapped_column(Text)
    evidence_level: Mapped[Optional[str]] = mapped_column(String(50))
    source_reference: Mapped[Optional[str]] = mapped_column(Text)
    created_by: Mapped[Optional[uuid.UUID]] = mapped_column(UUID(as_uuid=True))


# ==========================================
# 10. Caregiver-Patient Map Model
# ==========================================
class CaregiverPatientMap(Base, AuditMixin):
    __tablename__ = "caregiver_relationships"
    __table_args__ = {"schema": "care"}

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    caregiver_user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("auth_ext.user_profiles.user_id", ondelete="CASCADE"), nullable=False)
    patient_user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("auth_ext.user_profiles.user_id", ondelete="CASCADE"), nullable=False)
    relationship_type: Mapped[Optional[str]] = mapped_column(String(50))
    access_level: Mapped[str] = mapped_column(String(20), default="read")  # read, write, admin
    status: Mapped[str] = mapped_column(String(20), default="pending")  # pending, active, revoked
    invited_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    accepted_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    revoked_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))

    # Relationships
    caregiver: Mapped["User"] = relationship("User", foreign_keys=[caregiver_user_id], back_populates="patients_managed")
    patient: Mapped["User"] = relationship("User", foreign_keys=[patient_user_id], back_populates="caregivers")


# ==========================================
# 11. Onboarding Slide Model
# ==========================================
class OnboardingSlide(Base, AuditMixin):
    __tablename__ = "onboarding_slides"
    __table_args__ = {"schema": "app_config"}

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    step_number: Mapped[int] = mapped_column(nullable=False, unique=True)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    subtitle: Mapped[str] = mapped_column(Text, nullable=False)
    illustration_url: Mapped[str] = mapped_column(String(255), nullable=False)
    features: Mapped[List[dict[str, Any]]] = mapped_column(JSON, nullable=False, default=list)

