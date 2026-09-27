import 'package:flutter_test/flutter_test.dart';
import 'package:mediscribe_app/models/medicine_model.dart';

void main() {
  group('DrugInteractionModel', () {
    test('fromJson parses severity levels correctly', () {
      final highSeverityJson = {
        'source_drug': 'Aspirin',
        'target_drug': 'Warfarin',
        'severity': 'critical',
        'description_en': 'High risk of bleeding',
      };
      
      final modSeverityJson = {
        'source_drug': 'Ibuprofen',
        'target_drug': 'Aspirin',
        'severity': 'moderate',
        'description_en': 'Moderate risk',
      };
      
      final lowSeverityJson = {
        'source_drug': 'Vitamin C',
        'target_drug': 'Iron',
        'severity': 'minor',
        'description_en': 'Low risk',
      };

      final unknownSeverityJson = {
        'source_drug': 'Unknown',
        'target_drug': 'Unknown',
        'severity': 'unknown',
        'description_en': 'Unknown risk',
      };
      
      final missingSeverityJson = {
        'source_drug': 'Missing',
        'target_drug': 'Missing',
      };

      final high = DrugInteractionModel.fromJson(highSeverityJson);
      final mod = DrugInteractionModel.fromJson(modSeverityJson);
      final low = DrugInteractionModel.fromJson(lowSeverityJson);
      final unknown = DrugInteractionModel.fromJson(unknownSeverityJson);
      final missing = DrugInteractionModel.fromJson(missingSeverityJson);

      expect(high.sourceDrug, 'Aspirin');
      expect(high.severity, 'critical');
      expect(high.descriptionEn, 'High risk of bleeding');

      expect(mod.severity, 'moderate');
      expect(low.severity, 'minor');
      expect(unknown.severity, 'unknown');
      
      // Defaults to 'moderate' based on implementation
      expect(missing.severity, 'moderate');
    });
  });
}
