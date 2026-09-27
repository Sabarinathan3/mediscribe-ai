import re
from typing import Dict, Any

# Matches format: x5D, x30D, for 7 days, 2 weeks, 3 months
DURATION_PATTERN = re.compile(
    r"\b(?:x|for\s+)?(\d+)[\s-]*(d|day|days|w|week|weeks|m|month|months|y|year|years)\b",
    re.IGNORECASE
)


class DurationParser:
    @staticmethod
    def parse(text: str) -> Dict[str, Any]:
        """
        Parses treatment duration from text and outputs a standardized format.
        Example: "x30D" -> {"value": 30, "unit": "Days", "standardized": "30 Days"}
        """
        match = DURATION_PATTERN.search(text)
        if match:
            value_str, unit_raw = match.groups()
            try:
                value = int(value_str)
            except ValueError:
                value = value_str

            unit_char = unit_raw.lower()[0]
            if unit_char == 'd':
                unit = "Days"
            elif unit_char == 'w':
                unit = "Weeks"
            elif unit_char == 'm':
                unit = "Months"
            elif unit_char == 'y':
                unit = "Years"
            else:
                unit = "Days"

            # Singular/plural formatting
            unit_display = unit
            if value == 1:
                # remove 's'
                unit_display = unit[:-1]

            return {
                "value": value,
                "unit": unit,
                "standardized": f"{value} {unit_display}"
            }

        return {
            "value": None,
            "unit": None,
            "standardized": "As Directed"
        }
