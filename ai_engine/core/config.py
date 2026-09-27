import os
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    ENVIRONMENT: str = "development"
    OCR_CONFIDENCE_THRESHOLD: float = 0.4
    ENABLE_OFFLINE_TRANSLATION: bool = True
    MODELS_DIR: str = os.path.join(os.path.dirname(__file__), "..", "..", "models")
    
    # Offline Model paths (to be downloaded)
    TROCR_MODEL_PATH: str = os.path.join(MODELS_DIR, "trocr-small-handwritten")
    INDIC_TRANS_MODEL_PATH: str = os.path.join(MODELS_DIR, "indictrans2-en-indic-dist-200M")
    
    model_config = {"env_file": ".env", "extra": "ignore"}

settings = Settings()
