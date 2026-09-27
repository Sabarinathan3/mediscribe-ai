import os
import uuid
from typing import Optional
from fastapi import UploadFile, HTTPException, status
from supabase import create_client, Client

# ==========================================
# Configuration & Supabase Client
# ==========================================
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")  # Requires service role for backend uploads
SUPABASE_BUCKET = os.getenv("SUPABASE_BUCKET_PRESCRIPTIONS", "prescriptions")

# Initialize Supabase client lazily or handle missing env vars gracefully
def get_supabase_client() -> Optional[Client]:
    if not SUPABASE_URL or not SUPABASE_KEY:
        # In a real app, you might raise an exception if storage is mandatory
        return None
    return create_client(SUPABASE_URL, SUPABASE_KEY)

supabase: Optional[Client] = get_supabase_client()

# ==========================================
# Validation Constants
# ==========================================
MAX_FILE_SIZE_BYTES = 5 * 1024 * 1024  # 5 MB limit
ALLOWED_MIME_TYPES = {
    "image/jpeg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp"
}

# ==========================================
# Upload Service
# ==========================================
class FileUploadService:
    @staticmethod
    async def validate_image(file: UploadFile) -> str:
        """
        Validates the uploaded file's MIME type and size.
        Returns the validated file extension.
        """
        if file.content_type not in ALLOWED_MIME_TYPES:
            raise HTTPException(
                status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
                detail=f"Unsupported file type: {file.content_type}. Allowed types: JPEG, PNG, WEBP."
            )

        # Check file size
        if file.size is not None:
            file_size = file.size
        else:
            await file.seek(0)
            content = await file.read()
            file_size = len(content)
            await file.seek(0)
        
        if file_size > MAX_FILE_SIZE_BYTES:
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail=f"File too large. Maximum size allowed is {MAX_FILE_SIZE_BYTES / (1024 * 1024)} MB."
            )
            
        return ALLOWED_MIME_TYPES[file.content_type]

    @staticmethod
    async def upload_prescription_image(user_id: uuid.UUID, file: UploadFile) -> dict:
        """
        Validates the image, generates a secure UUID filename, and uploads it to Supabase Storage.
        Returns the public URL and metadata.
        """
        # 1. Validate File
        file_extension = await FileUploadService.validate_image(file)

        if not supabase:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Storage service is not configured."
            )

        # 2. Generate UUID Filename (format: user_id/uuid.ext for isolation)
        secure_filename = f"{str(user_id)}/{str(uuid.uuid4())}{file_extension}"

        # 3. Read File Bytes
        file_bytes = await file.read()

        try:
            # 4. Upload to Supabase Storage
            response = supabase.storage.from_(SUPABASE_BUCKET).upload(
                file=file_bytes,
                path=secure_filename,
                file_options={"content-type": file.content_type}
            )

            # 5. Generate Public URL (Assuming public bucket for OCR/Patient viewing)
            # If private, use create_signed_url instead
            public_url = supabase.storage.from_(SUPABASE_BUCKET).get_public_url(secure_filename)

            return {
                "file_path": secure_filename,
                "public_url": public_url,
                "mime_type": file.content_type,
                "file_size_bytes": len(file_bytes)
            }

        except Exception as e:
            # Catch Supabase Storage errors (e.g., StorageApiError)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to upload image to storage: {str(e)}"
            )
