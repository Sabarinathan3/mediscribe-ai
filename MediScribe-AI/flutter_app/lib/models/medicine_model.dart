import 'package:uuid/uuid.dart';

class MedicineModel {
  final String id;
  final String name;
  final String dosage;
  final String frequency;
  final String duration;
  final String instruction;
  final String? translatedInstruction;
  final String? audioBase64;
  final List<DrugInteractionModel> interactions;

  MedicineModel({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.duration,
    required this.instruction,
    this.translatedInstruction,
    this.audioBase64,
    this.interactions = const [],
  });

  factory MedicineModel.fromJson(Map<String, dynamic> json) {
    var interactionsList = json['interactions'] as List?;
    List<DrugInteractionModel> parsedInteractions = interactionsList != null
        ? interactionsList.map((i) => DrugInteractionModel.fromJson(i)).toList()
        : [];

    String parsedId = json['id'] ?? '';
    if (parsedId.isEmpty) {
      parsedId = const Uuid().v4();
    }

    return MedicineModel(
      id: parsedId,
      name: json['medicine'] ?? json['name'] ?? '',
      dosage: json['dosage'] ?? '',
      frequency: json['frequency'] ?? '',
      duration: json['duration'] ?? '',
      instruction: json['instruction'] ?? '',
      translatedInstruction: json['translated_instruction'],
      audioBase64: json['audio_base64'],
      interactions: parsedInteractions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicine': name,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'instruction': instruction,
      'translated_instruction': translatedInstruction,
      'audio_base64': audioBase64,
      'interactions': interactions.map((i) => i.toJson()).toList(),
    };
  }
}

class DrugInteractionModel {
  final String sourceDrug;
  final String targetDrug;
  final String severity; // critical, moderate, minor
  final String descriptionEn;
  final String descriptionEs;

  DrugInteractionModel({
    required this.sourceDrug,
    required this.targetDrug,
    required this.severity,
    required this.descriptionEn,
    required this.descriptionEs,
  });

  factory DrugInteractionModel.fromJson(Map<String, dynamic> json) {
    return DrugInteractionModel(
      sourceDrug: json['source_drug'] ?? '',
      targetDrug: json['target_drug'] ?? '',
      severity: json['severity'] ?? 'moderate',
      descriptionEn: json['description_en'] ?? '',
      descriptionEs: json['description_es'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'source_drug': sourceDrug,
      'target_drug': targetDrug,
      'severity': severity,
      'description_en': descriptionEn,
      'description_es': descriptionEs,
    };
  }
}
