import time
import logging
import base64
from typing import Dict, Any, List, Union, Optional
from PIL import Image

from ai_engine.ocr.extract_text import TextExtractor
from ai_engine.parser.abbreviation_parser import AbbreviationParser
from ai_engine.parser.prescription_parser import PrescriptionParser
from ai_engine.parser.prescription_validator import PrescriptionValidator
from ai_engine.multilingual.translator import TranslationService
from ai_engine.multilingual.voice_generator import VoiceGenerator
from ai_engine.interactions.interaction_checker import DrugInteractionChecker
from ai_engine.interactions.overdose_checker import OverdoseChecker
from concurrent.futures import ThreadPoolExecutor

logger = logging.getLogger("mediscribe.ai_engine.pipeline")


class PrescriptionAIEngine:
    @classmethod
    def process_prescription(
        cls, 
        image_input: Union[str, bytes, Image.Image], 
        target_lang: str = "en",
        run_quality_check: bool = True,
        generate_audio: bool = False,
        languages: List[str] = None
    ) -> Dict[str, Any]:
        """
        Executes the full pipeline:
        Image -> Preprocessing -> OCR -> Text Extraction -> Abbreviation Expansion -> 
        Dosage Parsing -> Frequency Parsing -> Duration Parsing -> Validation -> Final JSON
        """
        # Always include "en" in OCR languages to preserve English text recognition.
        # Add target language only when non-English multilingual detection is requested.
        if not languages:
            if target_lang != "en":
                languages = ["en", target_lang]
            else:
                languages = ["en"]

        # 1-3. Preprocessing, OCR, and Text Extraction
        ocr_result = TextExtractor.extract_text(image_input, languages=languages)
        raw_text = ocr_result.get("text", "")
        confidence = ocr_result.get("confidence", 0.0)

        if not raw_text and "error" in ocr_result:
            return {
                "pipeline_status": "failed",
                "error": ocr_result["error"],
                "valid": False,
                "errors": [ocr_result["error"]],
                "medications": [],
                "ocr_metadata": {
                    "confidence": 0.0,
                    "raw_text": "",
                    "abbreviation_resolution_confidence": 0.0,
                }
            }

        # 4. Abbreviation Expansion (on raw extracted text)
        abbrev_parser = AbbreviationParser()
        resolution_result = abbrev_parser.resolve_abbreviations(raw_text)
        expanded_text = resolution_result["expanded_text"]

        # 5-8. Dosage, Frequency, and Duration Parsing (inside PrescriptionParser)
        medications = PrescriptionParser.parse_prescription_text(expanded_text)

        # Apply translations & voice synthesis if requested
        for med in medications:
            # Translate instruction/food relation to target language
            original_instr = med.get("instruction", "")
            if target_lang.lower() != "en" and original_instr:
                translated_instr = TranslationService.translate_phrase(original_instr, target_lang)
                med["translated_instruction"] = translated_instr
            else:
                med["translated_instruction"] = original_instr

        # Optional Text-to-Speech generation
        if generate_audio:
            with ThreadPoolExecutor(max_workers=5) as executor:
                def get_audio(m: Dict[str, Any]) -> Optional[bytes]:
                    speech_text = m.get("translated_instruction") or m.get("instruction", "")
                    return VoiceGenerator.generate_speech(speech_text, lang=target_lang)
                
                audio_results = list(executor.map(get_audio, medications))
                
            for med, audio_bytes in zip(medications, audio_results):
                if audio_bytes:
                    med["audio_base64"] = base64.b64encode(audio_bytes).decode("utf-8")
                else:
                    med["audio_base64"] = None

        # 9. Validation
        validation_result = PrescriptionValidator.validate(medications)
        
        # 10. Drug Interactions and Overdose Checks
        drug_names = [med["medicine"] for med in medications]
        interactions = DrugInteractionChecker.check_interactions(drug_names)
        overdose_warnings = OverdoseChecker.check_overdose(medications)

        # 11. Final JSON output format
        return {
            "pipeline_status": "success",
            "valid": validation_result["valid"],
            "errors": validation_result["errors"],
            "medications": medications,
            "interactions": interactions,
            "overdose_warnings": overdose_warnings,
            "ocr_metadata": {
                "confidence": confidence,
                "raw_text": raw_text,
                "abbreviation_resolution_confidence": resolution_result["confidence"]
            }
        }
