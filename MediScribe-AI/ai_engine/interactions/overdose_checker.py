import re
from typing import Dict, Any, List, Optional, Tuple

# Safety thresholds: Maximum recommended daily dose (in mg) for adults
MAX_DAILY_DOSAGE_MG: Dict[str, float] = {
    "acetaminophen": 4000.0,
    "tylenol": 4000.0,
    "ibuprofen": 3200.0,
    "advil": 3200.0,
    "aspirin": 4000.0,
    "metformin": 2550.0,
    "lisinopril": 80.0,
    "simvastatin": 40.0,
    "omeprazole": 40.0,
    "claritin": 10.0,
    "atorvastatin": 80.0,
    "levothyroxine": 0.2, # 200 mcg
}

# Mapping frequency codes to daily multipliers
FREQ_MULTIPLIER: Dict[str, float] = {
    "once daily": 1.0,
    "qd": 1.0,
    "twice daily": 2.0,
    "bid": 2.0,
    "three times daily": 3.0,
    "tid": 3.0,
    "four times daily": 4.0,
    "qid": 4.0,
    "at bedtime": 1.0,
    "qhs": 1.0,
    "every 4 hours": 6.0,
    "q4h": 6.0,
    "every 6 hours": 4.0,
    "q6h": 4.0,
    "every 8 hours": 3.0,
    "q8h": 3.0,
    "every 12 hours": 2.0,
    "q12h": 2.0,
    "every other day": 0.5,
    "qod": 0.5,
    "as needed": 1.0,
    "prn": 1.0,
}


class OverdoseChecker:
    @staticmethod
    def calculate_daily_intake(medication: Dict[str, str]) -> Tuple[Optional[float], Optional[str]]:
        """
        Calculates the estimated daily dosage in mg from the flat dosage and frequency strings.
        Returns (daily_mg_value, unit).
        """
        dosage_str = medication.get("dosage", "")
        freq_str = medication.get("frequency", "")

        if not dosage_str or dosage_str == "Not Specified":
            return None, None

        # Parse dosage strength and unit (e.g. "500mg" or "10 mcg")
        match = re.search(r"(\d+(?:\.\d+)?)\s*(mg|mcg|g|ml|l|units|iu|ug)\b", dosage_str, re.IGNORECASE)
        if not match:
            return None, None

        val_str, unit = match.groups()
        try:
            strength_val = float(val_str)
        except ValueError:
            return None, None

        # Normalize strength to mg
        unit = unit.lower()
        if unit == "g":
            strength_val *= 1000.0
            unit = "mg"
        elif unit == "mcg":
            strength_val /= 1000.0
            unit = "mg"
        elif unit != "mg":
            return None, unit

        # Calculate frequency multiplier
        multiplier = 1.0
        freq_clean = freq_str.lower().strip()

        # Check if frequency is a numeric pattern like "1-0-1" or "1-1-1"
        num_pattern = re.match(r"^([0-2])\s*-\s*([0-2])\s*-\s*([0-2])\s*(?:-\s*([0-2]))?$", freq_clean)
        if num_pattern:
            # Sum up the number of doses taken per day (e.g., 1-0-1 -> 2 doses)
            multiplier = float(num_pattern.group(1)) + float(num_pattern.group(2)) + float(num_pattern.group(3))
            if num_pattern.group(4):
                multiplier += float(num_pattern.group(4))
        else:
            # Direct lookup in mapping
            matched = False
            for k, mult in FREQ_MULTIPLIER.items():
                if k in freq_clean:
                    multiplier = mult
                    matched = True
                    break
            if not matched:
                multiplier = 1.0

        daily_intake = strength_val * multiplier
        return daily_intake, "mg"

    @classmethod
    def check_overdose(cls, medications: List[Dict[str, str]]) -> List[Dict[str, Any]]:
        """
        Scans parsed medications and returns warnings if any dosage exceeds max daily thresholds.
        """
        warnings = []
        for med in medications:
            raw_name = med.get("medicine", "")
            norm_name = raw_name.lower().strip()
            
            if not norm_name:
                continue

            if norm_name in MAX_DAILY_DOSAGE_MG:
                limit = MAX_DAILY_DOSAGE_MG[norm_name]
                daily_dose, unit = cls.calculate_daily_intake(med)
                
                if daily_dose is not None and unit == "mg" and daily_dose > limit:
                    warnings.append({
                        "drug_name": raw_name,
                        "calculated_daily_dose": f"{daily_dose} mg",
                        "max_recommended_dose": f"{limit} mg",
                        "severity": "high",
                        "warning_en": f"The calculated daily dose of {raw_name} ({daily_dose} mg) exceeds the standard recommended limit of {limit} mg per day.",
                        "warning_es": f"La dosis diaria calculada de {raw_name} ({daily_dose} mg) supera el límite estándar recomendado de {limit} mg al día."
                    })
                    
        return warnings
