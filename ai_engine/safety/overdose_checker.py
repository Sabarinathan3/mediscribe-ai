from typing import List, Dict

class OverdoseChecker:
    def __init__(self):
        self.max_dosages = {
            "Paracetamol": 4000, # mg per day
            "Ibuprofen": 3200,   # mg per day
            "Metformin": 2550    # mg per day
        }
        
    def check_overdose(self, medicine: str, daily_dosage_mg: float) -> List[str]:
        warnings = []
        max_dose = self.max_dosages.get(medicine.title())
        
        if max_dose and daily_dosage_mg > max_dose:
            warnings.append(f"OVERDOSE WARNING: {medicine} daily dosage ({daily_dosage_mg}mg) exceeds recommended maximum of {max_dose}mg.")
            
        return warnings
