import re

class AbbreviationMapper:
    def __init__(self):
        # Standard Indian prescription abbreviations
        self.freq_map = {
            "1-0-1": "morning and night",
            "1-1-1": "morning, afternoon, and night",
            "0-0-1": "at night",
            "0-1-0": "afternoon",
            "1-0-0": "morning",
            "OD": "once a day",
            "BD": "twice a day",
            "BID": "twice a day",
            "TDS": "three times a day",
            "TID": "three times a day",
            "QID": "four times a day",
            "SOS": "as needed",
            "STAT": "immediately",
            "PRN": "as needed"
        }
        self.timing_map = {
            "PC": "after food",
            "AC": "before food",
            "HS": "at bedtime",
            "BT": "at bedtime"
        }

    def expand_abbreviations(self, raw_text: str) -> str:
        text = raw_text.upper()
        
        for abbr, expansion in self.freq_map.items():
            text = re.sub(rf'\b{re.escape(abbr)}\b', expansion, text)
            
        for abbr, expansion in self.timing_map.items():
            text = re.sub(rf'\b{re.escape(abbr)}\b', expansion, text)
            
        return text.title()
