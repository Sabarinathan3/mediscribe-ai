from typing import Dict, Any, Optional

# Basic dictionary-based translation of clinical instructions to popular languages
# Key = English phrase, Value = Map of language code to translation
TRANSLATION_DICT: Dict[str, Dict[str, str]] = {
    "once daily": {
        "es": "una vez al día",
        "fr": "une fois par jour",
        "hi": "दिन में एक बार",
        "zh": "每日一次"
    },
    "twice daily": {
        "es": "dos veces al día",
        "fr": "deux fois par jour",
        "hi": "दिन में दो बार",
        "zh": "每日两次"
    },
    "three times daily": {
        "es": "tres veces al día",
        "fr": "trois fois par jour",
        "hi": "दिन में तीन बार",
        "zh": "每日三次"
    },
    "four times daily": {
        "es": "cuatro veces al día",
        "fr": "quatre fois par jour",
        "hi": "दिन में चार बार",
        "zh": "每日四次"
    },
    "as needed": {
        "es": "según sea necesario",
        "fr": "au besoin",
        "hi": "आवश्यकतानुसार",
        "zh": "根据需要"
    },
    "by mouth": {
        "es": "por vía oral",
        "fr": "par voie orale",
        "hi": "मुंह से",
        "zh": "口服"
    },
    "before meals": {
        "es": "antes de las comidas",
        "fr": "avant les repas",
        "hi": "भोजन से पहले",
        "zh": "饭前"
    },
    "after meals": {
        "es": "después de las comidas",
        "fr": "après les repas",
        "hi": "भोजन के बाद",
        "zh": "饭后"
    },
    "at bedtime": {
        "es": "al acostarse",
        "fr": "au coucher",
        "hi": "सोते समय",
        "zh": "睡前"
    },
    "every 4 hours": {
        "es": "cada 4 horas",
        "fr": "toutes les 4 heures",
        "hi": "हर 4 घंटे में",
        "zh": "每4小时"
    },
    "every 6 hours": {
        "es": "cada 6 horas",
        "fr": "toutes les 6 heures",
        "hi": "हर 6 घंटे में",
        "zh": "每6小时"
    },
    "every 8 hours": {
        "es": "cada 8 horas",
        "fr": "toutes les 8 heures",
        "hi": "हर 8 घंटे में",
        "zh": "每8小时"
    },
    "every 12 hours": {
        "es": "cada 12 horas",
        "fr": "toutes les 12 heures",
        "hi": "हर 12 घंटे में",
        "zh": "每12小时"
    },
    "every other day": {
        "es": "cada dos días",
        "fr": "tous les deux jours",
        "hi": "एक दिन छोड़कर",
        "zh": "隔天一次"
    },
    "oral": {
        "es": "oral",
        "fr": "orale",
        "hi": "मौखिक",
        "zh": "口服"
    },
    "sublingual": {
        "es": "sublingual",
        "fr": "sublinguale",
        "hi": "सब्लिंगुअल",
        "zh": "舌下"
    },
    "intramuscular": {
        "es": "intramuscular",
        "fr": "intramusculaire",
        "hi": "इंट्रामस्क्युलर",
        "zh": "肌肉注射"
    },
    "intravenous": {
        "es": "intravenoso",
        "fr": "intraveineux",
        "hi": "अंतःशिरा",
        "zh": "静脉注射"
    },
    "subcutaneous": {
        "es": "subcutáneo",
        "fr": "sous-cutané",
        "hi": "चमड़े के नीचे",
        "zh": "皮下注射"
    },
    "rectal": {
        "es": "rectal",
        "fr": "rectal",
        "hi": "मलाशय",
        "zh": "直肠"
    },
    "topical": {
        "es": "tópico",
        "fr": "topique",
        "hi": "सामयिक",
        "zh": "局部涂抹"
    }
}


class TranslationService:
    @staticmethod
    def translate_phrase(phrase: str, lang_code: str) -> str:
        """
        Translates a common medical/clinical phrase into the target language.
        If translation is not found, returns the original phrase.
        """
        if not phrase or not lang_code:
            return phrase

        normalized_phrase = phrase.lower().strip()
        lang = lang_code.lower()

        # Direct dictionary match
        if normalized_phrase in TRANSLATION_DICT:
            translations = TRANSLATION_DICT[normalized_phrase]
            if lang in translations:
                return translations[lang].capitalize()

        # Fuzzy translation for sentence phrases
        import re
        translated_text = phrase
        for eng_key, lang_map in TRANSLATION_DICT.items():
            if lang in lang_map:
                # Use regex to replace exact words case-insensitively
                pattern = rf"\b{re.escape(eng_key)}\b"
                translated_text = re.sub(pattern, lang_map[lang], translated_text, flags=re.IGNORECASE)

        return translated_text
