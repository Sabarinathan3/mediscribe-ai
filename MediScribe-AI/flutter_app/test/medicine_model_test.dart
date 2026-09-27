import 'package:flutter_test/flutter_test.dart';
import 'package:mediscribe_app/models/medicine_model.dart';

void main() {
  group('DrugInteractionModel Tests', () {
    test('fromJson should parse interactions correctly', () {
      final json = {
        'source_drug': 'aspirin',
        'target_drug': 'ibuprofen',
        'severity': 'moderate',
        'description_en': 'Increased risk of bleeding.',
        'description_es': 'Mayor riesgo de sangrado.',
      };

      final interaction = DrugInteractionModel.fromJson(json);

      expect(interaction.sourceDrug, 'aspirin');
      expect(interaction.targetDrug, 'ibuprofen');
      expect(interaction.severity, 'moderate');
      expect(interaction.descriptionEn, 'Increased risk of bleeding.');
      expect(interaction.descriptionEs, 'Mayor riesgo de sangrado.');
    });

    test('toJson should convert interactions to json correctly', () {
      final interaction = DrugInteractionModel(
        sourceDrug: 'warfarin',
        targetDrug: 'aspirin',
        severity: 'critical',
        descriptionEn: 'Severe bleeding risk.',
        descriptionEs: 'Riesgo de sangrado grave.',
      );

      final json = interaction.toJson();

      expect(json['source_drug'], 'warfarin');
      expect(json['target_drug'], 'aspirin');
      expect(json['severity'], 'critical');
      expect(json['description_en'], 'Severe bleeding risk.');
      expect(json['description_es'], 'Riesgo de sangrado grave.');
    });
  });

  group('MedicineModel Tests', () {
    test('fromJson should parse medicine model correctly with all fields', () {
      final json = {
        'id': 'med-123',
        'medicine': 'Amoxicillin',
        'dosage': '500mg',
        'frequency': '3 times daily',
        'duration': '7 days',
        'instruction': 'Take with food.',
        'translated_instruction': 'Tomar con comida.',
        'audio_base64': 'base64audiobytes',
        'interactions': [
          {
            'source_drug': 'Amoxicillin',
            'target_drug': 'Methotrexate',
            'severity': 'minor',
            'description_en': 'Minor interaction.',
            'description_es': 'Interacción menor.',
          }
        ],
      };

      final medicine = MedicineModel.fromJson(json);

      expect(medicine.id, 'med-123');
      expect(medicine.name, 'Amoxicillin');
      expect(medicine.dosage, '500mg');
      expect(medicine.frequency, '3 times daily');
      expect(medicine.duration, '7 days');
      expect(medicine.instruction, 'Take with food.');
      expect(medicine.translatedInstruction, 'Tomar con comida.');
      expect(medicine.audioBase64, 'base64audiobytes');
      expect(medicine.interactions.length, 1);
      expect(medicine.interactions[0].sourceDrug, 'Amoxicillin');
    });

    test('fromJson should generate UUID if id is missing or empty', () {
      final json = {
        'medicine': 'Aspirin',
        'dosage': '81mg',
        'frequency': 'Once daily',
        'duration': '30 days',
        'instruction': 'Take in the morning.',
      };

      final medicine = MedicineModel.fromJson(json);

      expect(medicine.id, isNotEmpty);
      expect(medicine.id.length, 36); // standard UUID length
      expect(medicine.name, 'Aspirin');
    });

    test('toJson should convert medicine model to json correctly', () {
      final medicine = MedicineModel(
        id: 'med-456',
        name: 'Lisinopril',
        dosage: '10mg',
        frequency: 'Once daily',
        duration: 'Ongoing',
        instruction: 'Take before bed.',
        translatedInstruction: 'Tomar antes de acostarse.',
        audioBase64: 'audiobytes',
        interactions: [],
      );

      final json = medicine.toJson();

      expect(json['id'], 'med-456');
      expect(json['medicine'], 'Lisinopril');
      expect(json['dosage'], '10mg');
      expect(json['frequency'], 'Once daily');
      expect(json['duration'], 'Ongoing');
      expect(json['instruction'], 'Take before bed.');
      expect(json['translated_instruction'], 'Tomar antes de acostarse.');
      expect(json['audio_base64'], 'audiobytes');
      expect(json['interactions'], isEmpty);
    });
  });
}
