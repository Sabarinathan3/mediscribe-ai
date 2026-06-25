from typing import List, Dict, Any

class PrescriptionValidator:
    @staticmethod
    def validate(medications: List[Dict[str, str]]) -> Dict[str, Any]:
        """
        Validates parsed prescription medications.
        Checks for:
          - Missing dosage
          - Invalid/unspecified frequency
          - Invalid/unspecified duration
          - Unknown medicine name
          - Duplicate medicine entries (case-insensitive)
        """
        errors: List[str] = []
        seen_medicines = set()

        for idx, med in enumerate(medications):
            medicine = med.get("medicine", "").strip()
            dosage = med.get("dosage", "").strip()
            frequency = med.get("frequency", "").strip()
            duration = med.get("duration", "").strip()

            # 1. Check Unknown Medicine
            if not medicine or medicine.lower() in ["unknown", "unknown medicine", "error parsing", "error"]:
                errors.append(f"Entry {idx + 1}: A medicine entry has an unknown or unparseable name.")
                # Skip further checks for this item if name is completely unknown
                continue

            # 2. Check Duplicate Medicine Entries
            med_lower = medicine.lower()
            if med_lower in seen_medicines:
                errors.append(f"Duplicate entries found for medicine '{medicine}'.")
            seen_medicines.add(med_lower)

            # 3. Check Missing Dosage
            if not dosage or dosage.lower() in ["not specified", "error"]:
                errors.append(f"Medicine '{medicine}' has a missing or unparseable dosage.")

            # 4. Check Invalid Frequency
            # "As Directed" is a valid clinical instruction (doctor gave verbal guidance) — do not flag as error
            if not frequency or frequency.lower() in ["error", "other", "not specified"]:
                errors.append(f"Medicine '{medicine}' has an invalid or unspecified frequency.")

            # 5. Check Invalid Duration
            if not duration or duration.lower() in ["as directed", "error"]:
                errors.append(f"Medicine '{medicine}' has an invalid or unspecified duration.")

        return {
            "valid": len(errors) == 0,
            "errors": errors
        }
