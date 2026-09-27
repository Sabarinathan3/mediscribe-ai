from typing import List, Dict, Any

class SafetyEngine:
    def __init__(self):
        # In a real system, this connects to the local SQLite offline database
        self.known_interactions = {
            frozenset(["Aspirin", "Warfarin"]): "High risk of bleeding. Avoid combination.",
            frozenset(["Metformin", "Iodine Contrast"]): "Risk of lactic acidosis. Stop Metformin 48h before.",
        }
        
    def check_interactions(self, medications: List[str]) -> List[str]:
        warnings = []
        # Check all pairs
        for i in range(len(medications)):
            for j in range(i + 1, len(medications)):
                pair = frozenset([medications[i], medications[j]])
                if pair in self.known_interactions:
                    warnings.append(self.known_interactions[pair])
        return warnings
