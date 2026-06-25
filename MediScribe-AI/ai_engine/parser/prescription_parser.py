import re
from typing import Dict, Any, List, Optional

# ==========================================
# Regex Patterns
# ==========================================

# Form Prefixes (e.g., Tab, Caps, Syr, Injection)
FORM_PREFIXES = r"\b(?:tab|tabs|tablet|tablets|cap|caps|capsule|capsules|syr|syrup|inj|injection|susp|suspension)\b\.?"

# Dosage pattern (e.g., 500mg, 10mcg, 5ml, 2.5 mg)
DOSAGE_PATTERN = re.compile(
    r"\b(\d+(?:\.\d+)?)\s*(mg|mcg|g|ml|l|units|iu|ug|tabs|caps|puffs)\b",
    re.IGNORECASE
)

# Numeric Frequency pattern (e.g., 1-0-1, 1-1-1, 0-0-1, 1-0-0-1)
NUMERIC_FREQ_PATTERN = re.compile(
    r"\b([0-2])\s*-\s*([0-2])\s*-\s*([0-2])\s*(?:-\s*([0-2]))?\b",
    re.IGNORECASE
)

# Textual Frequency pattern (e.g., QD, BID, TID, QID, PRN, once daily, etc.)
SIG_FREQ_MAP = {
    r"\b(od|qd|once\s+daily|1x\s+daily|every\s+day|daily)\b": "Once Daily",
    r"\b(bd|bid|twice\s+daily|2x\s+daily|two\s+times\s+a\s+day)\b": "Twice Daily",
    r"\b(tds|tid|three\s+times\s+daily|3x\s+daily|three\s+times\s+a\s+day)\b": "Three Times Daily",
    r"\b(qid|four\s+times\s+daily|4x\s+daily|four\s+times\s+a\s+day)\b": "Four Times Daily",
    r"\b(qhs|hs|at\s+bedtime|bedtime)\b": "At Bedtime",
    r"\b(sos|prn|as\s+needed|when\s+necessary)\b": "As Needed",
}

# Duration pattern (e.g., x30D, x10D, x2W, x1M, for 30 days)
DURATION_PATTERN = re.compile(
    r"\b(?:x|for\s+)(\d+)\s*(d|day|days|w|week|weeks|m|month|months)\b|\b(\d+)\s*(day|days|week|weeks|month|months)\b|\b(\d+)(d|w|m)\b",
    re.IGNORECASE
)

# Instruction mappings (e.g., PC -> After Food, AC -> Before Food)
INSTRUCTION_MAP = {
    r"\b(pc|after\s+meals|after\s+food|post\s+cibum)\b": "After Food",
    r"\b(ac|before\s+meals|before\s+food|ante\s+cibum)\b": "Before Food",
    r"\b(prn|as\s+needed)\b": "As Needed",
    r"\b(po|by\s+mouth|oral)\b": "By Mouth",
}


class PrescriptionParser:
    @classmethod
    def extract_medicine(cls, text: str) -> str:
        """
        Extracts the medicine name from the text segment.
        Strips common prefix forms (Tab, Caps, Syr) and locates the drug identifier.
        """
        cleaned = re.sub(r"^\s*\d+[\.\)]\s*", "", text)
        cleaned = re.sub(FORM_PREFIXES, "", cleaned, flags=re.IGNORECASE)
        cleaned = DOSAGE_PATTERN.sub("", cleaned)
        cleaned = DURATION_PATTERN.sub("", cleaned)
        cleaned = NUMERIC_FREQ_PATTERN.sub("", cleaned)
        for pattern in SIG_FREQ_MAP.keys():
            cleaned = re.sub(pattern, "", cleaned, flags=re.IGNORECASE)
        for pattern in INSTRUCTION_MAP.keys():
            cleaned = re.sub(pattern, "", cleaned, flags=re.IGNORECASE)
            
        cleaned = re.sub(r"[^\w\s]+", "", cleaned).strip()
        tokens = cleaned.split()
        if tokens:
            return " ".join(t.capitalize() for t in tokens)
        return "Unknown Medicine"

    @staticmethod
    def extract_dosage(text: str) -> str:
        """
        Extracts the dosage/strength (e.g. 500mg, 10mcg).
        """
        match = DOSAGE_PATTERN.search(text)
        if match:
            val_str = match.group(1)
            unit = match.group(2).lower()
            val = float(val_str) if '.' in val_str else int(val_str)
            
            if unit == 'g':
                val = int(val * 1000)
                unit = 'mg'
            elif unit == 'l':
                val = int(val * 1000)
                unit = 'ml'
                
            val_formatted = f"{val:g}" if isinstance(val, float) else str(val)
            return f"{val_formatted}{unit}"
        return "Not Specified"

    @staticmethod
    def extract_frequency(text: str) -> str:
        """
        Extracts dose frequency (e.g. 1-0-1 or Twice Daily).
        """
        # 1. Check numeric frequency (e.g., 1-0-1)
        num_match = NUMERIC_FREQ_PATTERN.search(text)
        if num_match:
            parts = [num_match.group(1), num_match.group(2), num_match.group(3)]
            if num_match.group(4):
                parts.append(num_match.group(4))
            return "-".join(parts)

        # 2. Check textual maps (e.g., QD, BID, Twice Daily)
        for pattern, replacement in SIG_FREQ_MAP.items():
            if re.search(pattern, text, re.IGNORECASE):
                return replacement

        return "As Directed"

    @staticmethod
    def extract_duration(text: str) -> str:
        """
        Extracts treatment duration (e.g., x30D -> 30 Days).
        """
        match = DURATION_PATTERN.search(text)
        if match:
            if match.group(1):
                val, unit_str = match.group(1), match.group(2)
            elif match.group(3):
                val, unit_str = match.group(3), match.group(4)
            else:
                val, unit_str = match.group(5), match.group(6)
                
            unit_char = unit_str.lower()[0]
            
            if unit_char == 'd':
                unit = "Days"
            elif unit_char == 'w':
                unit = "Weeks"
            elif unit_char == 'm':
                unit = "Months"
            else:
                unit = "Days"
                
            return f"{val} {unit}"
        return "As Directed"

    @staticmethod
    def extract_instruction(text: str) -> str:
        """
        Extracts instructions like food relation or bedtime directions (e.g. After Food).
        """
        for pattern, label in INSTRUCTION_MAP.items():
            if re.search(pattern, text, re.IGNORECASE):
                return label
        return "As Directed"

    @classmethod
    def parse_line(cls, line: str) -> Dict[str, str]:
        """
        Parses a single prescription line/text to return the exact structured format.
        """
        try:
            medicine = cls.extract_medicine(line)
            dosage = cls.extract_dosage(line)
            frequency = cls.extract_frequency(line)
            duration = cls.extract_duration(line)
            instruction = cls.extract_instruction(line)
            
            # Validation / default mappings
            if not medicine or medicine == "Unknown Medicine":
                # Fallback check
                medicine = "Unknown"

            return {
                "medicine": medicine,
                "dosage": dosage,
                "frequency": frequency,
                "duration": duration,
                "instruction": instruction
            }
        except Exception as e:
            # Error handling fallback
            return {
                "medicine": "Error Parsing",
                "dosage": "Error",
                "frequency": "Error",
                "duration": "Error",
                "instruction": str(e)
            }

    @classmethod
    def parse_prescription_text(cls, text: str) -> List[Dict[str, str]]:
        """
        Parses a complete prescription containing multiple lines.
        """
        lines = text.split("\n")
        results = []
        for line in lines:
            line = line.strip()
            if not line:
                continue
                
            if re.match(r"^(patient|date|age|gender|sex|dr\.|doctor)\b", line, re.IGNORECASE):
                continue
                
            has_dosage = DOSAGE_PATTERN.search(line) is not None
            has_form = re.search(FORM_PREFIXES, line, flags=re.IGNORECASE) is not None
            has_freq = NUMERIC_FREQ_PATTERN.search(line) is not None or any(re.search(p, line, re.IGNORECASE) for p in SIG_FREQ_MAP.keys())
            
            if not (has_dosage or has_form or has_freq):
                continue
                
            results.append(cls.parse_line(line))
            
        unique_results = []
        seen = set()
        for r in results:
            med_key = r["medicine"].lower()
            if med_key not in seen:
                seen.add(med_key)
                unique_results.append(r)
                
        return unique_results
