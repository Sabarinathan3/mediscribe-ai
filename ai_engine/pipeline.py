import io
from PIL import Image
from typing import Dict, Any, List
from ai_engine.ocr.easyocr_engine import EasyOCREngine
from ai_engine.ocr.trocr_engine import TrOCREngine
from ai_engine.nlp.entity_extractor import MedicalEntityExtractor
from ai_engine.nlp.abbreviation_mapper import AbbreviationMapper
from ai_engine.safety.interaction_checker import SafetyEngine
from ai_engine.safety.overdose_checker import OverdoseChecker
from ai_engine.safety.patient_warnings import PatientWarnings
from ai_engine.multilingual.indic_translator import IndicTranslator
from ai_engine.voice.tts_engine import VoiceGenerator

class MediScribePipeline:
    def __init__(self):
        self.easy_ocr = EasyOCREngine()
        self.tr_ocr = TrOCREngine()
        self.nlp = MedicalEntityExtractor()
        self.abbrev_mapper = AbbreviationMapper()
        self.safety_interactions = SafetyEngine()
        self.safety_overdose = OverdoseChecker()
        self.safety_warnings = PatientWarnings()
        self.translator = IndicTranslator()
        self.voice = VoiceGenerator()

    def process(self, image_bytes: bytes, target_languages: List[str]) -> Dict[str, Any]:
        image = Image.open(io.BytesIO(image_bytes))
        
        # 1. OCR Layer (Hybrid approach for speed vs accuracy)
        raw_text, ocr_conf = self.easy_ocr.extract_text(image)
        if ocr_conf < 0.8:
            raw_text, ocr_conf = self.tr_ocr.extract_text(image)
            
        # 2. NLP Layer
        expanded_text = self.abbrev_mapper.expand_abbreviations(raw_text)
        structured_data = self.nlp.extract_entities(expanded_text)
        
        # 3. Safety Layer
        med_name = structured_data.get("medicine", "")
        dosage_str = structured_data.get("dosage", "")
        # Dummy parsing dosage logic for overdose checker
        dosage_mg = 0.0
        if dosage_str and "mg" in dosage_str.lower():
            try:
                dosage_mg = float(dosage_str.lower().replace("mg", "").strip())
            except ValueError:
                pass
                
        interaction_warnings = self.safety_interactions.check_interactions([med_name])
        overdose_warnings = self.safety_overdose.check_overdose(med_name, dosage_mg)
        patient_warns = self.safety_warnings.generate_warnings(med_name)
        
        all_warnings = interaction_warnings + overdose_warnings + patient_warns
        
        # 4. Multilingual Layer
        explanations = {}
        for lang in target_languages:
            # We translate a combined readable instruction string
            instruction_en = f"Take {structured_data.get('dosage', '')} {structured_data.get('frequency', '')} for {structured_data.get('duration', '')}."
            translated = self.translator.translate(instruction_en, lang)
            explanations[lang] = translated
            
        # Assign instruction string based on English
        structured_data["instruction"] = f"Take {structured_data.get('dosage', '')} {structured_data.get('frequency', '')} for {structured_data.get('duration', '')}."
            
        return {
            "medicine": structured_data.get("medicine", "Unknown"),
            "dosage": structured_data.get("dosage", "Unknown"),
            "frequency": structured_data.get("frequency", "Unknown"),
            "duration": structured_data.get("duration", "Unknown"),
            "instruction": structured_data.get("instruction", ""),
            "language_explanations": explanations,
            "warnings": all_warnings,
            "confidence_score": min(ocr_conf, structured_data.get("nlp_confidence", 0.0))
        }
