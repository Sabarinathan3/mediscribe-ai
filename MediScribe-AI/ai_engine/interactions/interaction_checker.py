from typing import List, Dict, Any, Set

# Known Drug-Drug Interactions Catalog
# Keys are frozensets of lowercased drug generic/brand names
INTERACTION_CATALOG: Dict[frozenset, Dict[str, Any]] = {
    frozenset({"aspirin", "warfarin"}): {
        "severity": "critical",
        "description_en": "Co-administration of aspirin and warfarin significantly increases risk of major gastrointestinal and systemic bleeding.",
        "description_es": "La coadministración de aspirina y warfarina aumenta significativamente el riesgo de sangrado gastrointestinal y sistémico grave."
    },
    frozenset({"ibuprofen", "warfarin"}): {
        "severity": "critical",
        "description_en": "Concomitant use of NSAIDs like ibuprofen with warfarin may lead to severe mucosal bleeding and gastric ulcers.",
        "description_es": "El uso concomitante de AINE como el ibuprofeno con warfarina puede provocar hemorragias mucosas graves y úlceras gástricas."
    },
    frozenset({"aspirin", "ibuprofen"}): {
        "severity": "moderate",
        "description_en": "Ibuprofen can interfere with the antiplatelet effect of low-dose aspirin, reducing its cardioprotective benefits.",
        "description_es": "El ibuprofeno puede interferir con el efecto antiplaquetario de la aspirina en dosis bajas, reduciendo sus beneficios cardioprotectores."
    },
    frozenset({"sildenafil", "nitroglycerin"}): {
        "severity": "critical",
        "description_en": "Sildenafil co-prescribed with organic nitrates (nitroglycerin) causes severe, synergistic peripheral vasodilation and acute hypotension.",
        "description_es": "El sildenafilo recetado junto con nitratos orgánicos (nitroglicerina) causa una vasodilatación periférica grave y sinérgica e hipotensión aguda."
    },
    frozenset({"lisinopril", "potassium"}): {
        "severity": "moderate",
        "description_en": "Lisinopril impairs potassium excretion. Concomitant potassium supplements may lead to severe hyperkalemia.",
        "description_es": "El lisinopril altera la excreción de potasio. Los suplementos de potasio concomitantes pueden provocar hiperpotasemia grave."
    },
    frozenset({"simvastatin", "amlodipine"}): {
        "severity": "moderate",
        "description_en": "Amlodipine increases systemic exposure to simvastatin, increasing the risk of rhabdomyolysis and myopathy.",
        "description_es": "La amlodipina aumenta la exposición sistémica a la simvastatina, lo que incrementa el riesgo de rabdomiólisis y miopatía."
    },
    frozenset({"omeprazole", "clopidogrel"}): {
        "severity": "moderate",
        "description_en": "Omeprazole decreases the active metabolite of clopidogrel, potentially lowering its efficacy in preventing blood clots.",
        "description_es": "El omeprazol disminuye el metabolito activo de clopidogrel, lo que podría reducir su eficacia para prevenir los coágulos sanguíneos."
    }
}


class DrugInteractionChecker:
    @staticmethod
    def check_interactions(drugs: List[str]) -> List[Dict[str, Any]]:
        """
        Takes a list of drug names and returns warnings for any pairs matching 
        the known drug-drug interaction catalog.
        """
        warnings = []
        if len(drugs) < 2:
            return warnings

        # Normalize drug names
        normalized_drugs = [d.lower().strip() for d in drugs if d]
        
        # Check all unique combinations of size 2
        seen_pairs: Set[frozenset] = set()
        
        for i in range(len(normalized_drugs)):
            for j in range(i + 1, len(normalized_drugs)):
                drug_a = normalized_drugs[i]
                drug_b = normalized_drugs[j]
                
                if drug_a == drug_b:
                    continue
                    
                pair = frozenset({drug_a, drug_b})
                if pair in seen_pairs:
                    continue
                    
                seen_pairs.add(pair)
                
                # Check interaction catalog
                if pair in INTERACTION_CATALOG:
                    detail = INTERACTION_CATALOG[pair]
                    warnings.append({
                        "source_drug": drug_a.capitalize(),
                        "target_drug": drug_b.capitalize(),
                        "severity": detail["severity"],
                        "description_en": detail["description_en"],
                        "description_es": detail["description_es"]
                    })
                    
        return warnings
