import re
from typing import Dict, Any

# Regex for matches like 1-0-1, 1-1-1, 0-1-1
NUMERIC_FREQ_PATTERN = re.compile(
    r"\b([0-2])\s*-\s*([0-2])\s*-\s*([0-2])\s*(?:-\s*([0-2]))?\b"
)

# Case-insensitive map for shorthand frequencies
SHORTHAND_FREQ_MAP = {
    "od": {"code": "QD", "standardized": "Once Daily"},
    "qd": {"code": "QD", "standardized": "Once Daily"},
    "bd": {"code": "BID", "standardized": "Twice Daily"},
    "bid": {"code": "BID", "standardized": "Twice Daily"},
    "tds": {"code": "TID", "standardized": "Three Times Daily"},
    "tid": {"code": "TID", "standardized": "Three Times Daily"},
    "qid": {"code": "QID", "standardized": "Four Times Daily"},
    "hs": {"code": "QHS", "standardized": "At Bedtime"},
    "qhs": {"code": "QHS", "standardized": "At Bedtime"},
    "sos": {"code": "PRN", "standardized": "As Needed"},
    "prn": {"code": "PRN", "standardized": "As Needed"},
}

# Regex mapping for textual phrases
PHRASE_FREQ_MAP = {
    r"\bonce\s+daily\b": {"code": "QD", "standardized": "Once Daily"},
    r"\btwice\s+daily\b": {"code": "BID", "standardized": "Twice Daily"},
    r"\bthree\s+times\s+daily\b": {"code": "TID", "standardized": "Three Times Daily"},
    r"\bfour\s+times\s+daily\b": {"code": "QID", "standardized": "Four Times Daily"},
    r"\bat\s+bedtime\b": {"code": "QHS", "standardized": "At Bedtime"},
    r"\bas\s+needed\b": {"code": "PRN", "standardized": "As Needed"},
}


class FrequencyParser:
    @staticmethod
    def parse(text: str) -> Dict[str, Any]:
        """
        Parses dosage frequency from text and standardizes it.
        Example: "1-0-1" -> {"code": "BID", "standardized": "Twice Daily"}
        """
        lower_text = text.lower().strip()

        # 1. Match numeric patterns (e.g. 1-0-1)
        num_match = NUMERIC_FREQ_PATTERN.search(text)
        if num_match:
            morning = int(num_match.group(1))
            afternoon = int(num_match.group(2))
            night = int(num_match.group(3))
            extra = int(num_match.group(4)) if num_match.group(4) else 0
            
            total_doses = morning + afternoon + night + extra

            if total_doses == 1:
                return {"code": "QD", "standardized": "Once Daily"}
            elif total_doses == 2:
                return {"code": "BID", "standardized": "Twice Daily"}
            elif total_doses == 3:
                return {"code": "TID", "standardized": "Three Times Daily"}
            elif total_doses >= 4:
                return {"code": "QID", "standardized": "Four Times Daily"}

        # 2. Check shorthand codes (OD, BD, TDS, QID)
        words = re.split(r"[^\w]+", lower_text)
        for word in words:
            if word in SHORTHAND_FREQ_MAP:
                return SHORTHAND_FREQ_MAP[word]

        # 3. Check verbal phrases
        for pattern, res in PHRASE_FREQ_MAP.items():
            if re.search(pattern, lower_text):
                return res

        return {
            "code": "OTHER",
            "standardized": "As Directed"
        }
