from typing import Dict, Any, List

class PrescriptionValidator:
    @staticmethod
    def validate(entities: Dict[str, Any]) -> List[str]:
        """
        Validates extracted entities and returns a list of error strings.
        """
        errors = []
        if not entities.get("medicine") or entities.get("medicine") == "Unknown":
            errors.append("Medicine name could not be identified.")
        
        if not entities.get("dosage"):
            errors.append("Missing dosage information.")
            
        return errors
