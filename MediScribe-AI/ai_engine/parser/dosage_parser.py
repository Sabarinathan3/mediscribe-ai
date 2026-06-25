import re
from typing import Dict, Any, Optional

# Regex pattern for matching strength/volume (e.g. 500mg, 250mg, 5ml, 10mcg)
STRENGTH_PATTERN = re.compile(
    r"\b(\d+(?:\.\d+)?)\s*(mg|mcg|g|ml|l|units|iu|ug)\b",
    re.IGNORECASE
)


class DosageParser:
    @staticmethod
    def parse(text: str) -> Dict[str, Any]:
        """
        Extracts and standardizes dosage/strength from text.
        Example: "Take Metformin 500mg" -> {"value": 500, "unit": "mg", "standardized": "500mg"}
        """
        match = STRENGTH_PATTERN.search(text)
        if match:
            val_str, unit_str = match.groups()
            try:
                value = float(val_str)
                # Convert to integer if it's a whole number
                if value.is_integer():
                    value = int(value)
            except ValueError:
                value = val_str

            unit = unit_str.lower()
            standardized = f"{value}{unit}"

            return {
                "value": value,
                "unit": unit,
                "standardized": standardized
            }

        return {
            "value": None,
            "unit": None,
            "standardized": "Not Specified"
        }

    # ==========================================
    # Compatibility Wrappers for Older Code
    # ==========================================
    @classmethod
    def extract_strength(cls, text: str) -> Optional[Dict[str, Any]]:
        parsed = cls.parse(text)
        if parsed["value"] is not None:
            return {
                "value": parsed["value"],
                "unit": parsed["unit"],
                "raw": parsed["standardized"]
            }
        return None

    @classmethod
    def extract_form_and_quantity(cls, text: str) -> Optional[Dict[str, Any]]:
        # Keep placeholder check for quantity/forms if needed
        form_pattern = re.compile(
            r"\b(\d+)?\s*(tablet|tablets|tab|tabs|capsule|capsules|cap|caps|drop|drops|puff|puffs)\b",
            re.IGNORECASE
        )
        match = form_pattern.search(text)
        if match:
            qty_str, form = match.groups()
            quantity = int(qty_str) if qty_str else 1
            norm_form = form.lower()
            if norm_form in ["tablets", "tab", "tabs"]:
                norm_form = "tablet"
            elif norm_form in ["capsules", "cap", "caps"]:
                norm_form = "capsule"
            elif norm_form in ["drops"]:
                norm_form = "drop"
            elif norm_form in ["puffs"]:
                norm_form = "puff"
                
            return {
                "quantity": quantity,
                "form": norm_form,
                "raw": match.group(0)
            }
        return None
