import csv
import re
from typing import Dict, List, Tuple, Any, Optional

DEFAULT_MAPPING: Dict[str, str] = {
    "PC": "After Food",
    "AC": "Before Food",
    "OD": "Once Daily",
    "BD": "Twice Daily",
    "TDS": "Three Times Daily",
    "QID": "Four Times Daily",
    "HS": "At Bedtime",
    "SOS": "When Required"
}

SIG_CODES: Dict[str, Dict[str, str]] = {
    "pc": {"meaning": "after food", "latin": "post cibum"},
    "ac": {"meaning": "before food", "latin": "ante cibum"},
    "od": {"meaning": "once daily", "latin": "quaque die"},
    "bd": {"meaning": "twice daily", "latin": "bis in die"},
    "tds": {"meaning": "three times daily", "latin": "ter in die"},
    "qid": {"meaning": "four times daily", "latin": "quater in die"},
    "hs": {"meaning": "at bedtime", "latin": "hora somni"},
    "qhs": {"meaning": "at bedtime", "latin": "quaque hora somni"},
    "sos": {"meaning": "when required", "latin": "si opus sit"},
    "qd": {"meaning": "once daily", "latin": "quaque die"},
    "bid": {"meaning": "twice daily", "latin": "bis in die"},
    "tid": {"meaning": "three times daily", "latin": "ter in die"},
    "prn": {"meaning": "as needed", "latin": "pro re nata"},
    "po": {"meaning": "by mouth", "latin": "per os"}
}


class AbbreviationParser:
    def __init__(self, csv_path: Optional[str] = None):
        """
        Initializes the abbreviation parser. Optionally loads additional
        mappings from a CSV file.
        """
        self.mapping = DEFAULT_MAPPING.copy()
        # Populates mapping with SIG_CODES keys for full abbreviation support
        for k, v in SIG_CODES.items():
            self.mapping[k.upper()] = v["meaning"]
        if csv_path:
            self.load_from_csv(csv_path)

    def load_from_csv(self, csv_path: str) -> bool:
        """
        Loads custom abbreviation mappings from a CSV file.
        Expects a CSV with format: abbreviation,meaning
        """
        try:
            with open(csv_path, mode='r', encoding='utf-8') as f:
                reader = csv.reader(f)
                for row in reader:
                    if len(row) >= 2:
                        abbrev = row[0].strip().upper()
                        meaning = row[1].strip()
                        if abbrev and meaning:
                            self.mapping[abbrev] = meaning
            return True
        except Exception:
            return False

    def detect_unknown_abbreviations(self, text: str) -> List[str]:
        """
        Detects potential abbreviations in the text that are not in the dictionary.
        An abbreviation candidate is defined as an uppercase alphabetical word 
        of length 2 to 5.
        """
        candidates = re.findall(r"\b([A-Z]{2,5})\b", text)
        unknowns = []
        for cand in candidates:
            if cand not in self.mapping:
                unknowns.append(cand)
        return list(set(unknowns))

    def resolve_abbreviations(self, text: str) -> Dict[str, Any]:
        """
        Resolves known abbreviations in the text.
        Returns:
          - "expanded_text": The text with abbreviations replaced.
          - "confidence": Ratio of resolved abbreviations to total detected abbreviation candidates.
          - "unknown_abbreviations": List of potential unresolved abbreviations detected.
        """
        # Find potential unknown uppercase abbreviations in raw text
        uppercase_words = re.findall(r"\b([A-Z]{2,5})\b", text)
        unknown_abbrev = list(set([w for w in uppercase_words if w.upper() not in self.mapping]))
        unknown_count = sum(1 for w in uppercase_words if w.upper() not in self.mapping)

        expanded_text = text
        resolved_count = 0

        # Resolve all known mapping keys case-insensitively in descending order of length
        sorted_keys = sorted(self.mapping.keys(), key=len, reverse=True)
        for key in sorted_keys:
            pattern = rf"\b{re.escape(key)}\b"
            matches = re.findall(pattern, expanded_text, re.IGNORECASE)
            if matches:
                meaning = self.mapping[key]
                expanded_text = re.sub(pattern, meaning, expanded_text, flags=re.IGNORECASE)
                resolved_count += len(matches)

        total_detected = resolved_count + unknown_count

        confidence = 1.0
        if total_detected > 0:
            confidence = round(resolved_count / total_detected, 2)

        return {
            "expanded_text": expanded_text,
            "confidence": confidence,
            "unknown_abbreviations": unknown_abbrev
        }


# ==========================================
# Compatibility Wrapper
# ==========================================
class AbbreviationResolver:
    @staticmethod
    def resolve_abbreviation(code: str) -> Dict[str, str]:
        code_lower = code.lower().strip()
        if code_lower in SIG_CODES:
            return {"meaning": SIG_CODES[code_lower]["meaning"], "latin": SIG_CODES[code_lower].get("latin", "")}
        return {"meaning": code, "latin": ""}

    @staticmethod
    def expand_text(text: str) -> str:
        parser = AbbreviationParser()
        return parser.resolve_abbreviations(text)["expanded_text"]
