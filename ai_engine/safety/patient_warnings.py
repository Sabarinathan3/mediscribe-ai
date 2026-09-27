from typing import List

class PatientWarnings:
    def __init__(self):
        self.pregnancy_warnings = ["Isotretinoin", "Thalidomide", "Lisinopril"]
        self.pediatric_warnings = ["Aspirin", "Tetracycline"]
        
    def generate_warnings(self, medicine: str, patient_age: int = None, is_pregnant: bool = False) -> List[str]:
        warnings = []
        med_title = medicine.title()
        
        if is_pregnant and med_title in self.pregnancy_warnings:
            warnings.append(f"PREGNANCY WARNING: {med_title} is contraindicated during pregnancy.")
            
        if patient_age is not None and patient_age < 12 and med_title in self.pediatric_warnings:
            warnings.append(f"PEDIATRIC WARNING: {med_title} is generally contraindicated in young children.")
            
        return warnings
