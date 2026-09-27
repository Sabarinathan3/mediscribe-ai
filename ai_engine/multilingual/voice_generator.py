import io
import logging
from typing import Optional

try:
    from gtts import gTTS
    GTTS_AVAILABLE = True
except ImportError:
    GTTS_AVAILABLE = False

logger = logging.getLogger("mediscribe.ai_engine.multilingual")


class VoiceGenerator:
    @staticmethod
    def is_available() -> bool:
        """Check if gTTS is installed."""
        return GTTS_AVAILABLE

    @staticmethod
    def generate_speech(text: str, lang: str = "en") -> Optional[bytes]:
        """
        Converts text instructions into audio bytes (MP3 format) using Google Text-to-Speech.
        Falls back gracefully with logs if gTTS is not installed or offline.
        """
        if not text:
            return None

        # Standardize language code format (gTTS expects e.g., 'es', 'fr', 'en')
        normalized_lang = lang.split("-")[0].lower()

        if not GTTS_AVAILABLE:
            logger.warning("gTTS is not installed in the environment. Speech generation skipped.")
            # Return dummy silent MP3 header bytes for testing if needed
            return b""

        try:
            # Generate TTS audio
            tts = gTTS(text=text, lang=normalized_lang, slow=False)
            
            # Save audio to bytes buffer
            audio_buffer = io.BytesIO()
            tts.write_to_fp(audio_buffer)
            audio_buffer.seek(0)
            
            return audio_buffer.read()
            
        except Exception as e:
            logger.error(f"Failed to generate Text-to-Speech audio: {str(e)}")
            return None
