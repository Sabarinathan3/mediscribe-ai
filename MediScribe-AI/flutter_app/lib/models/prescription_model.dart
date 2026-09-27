/// Model representing a single medication entry from the AI prescription analysis pipeline.
class MedicationItem {
  final String medicine;
  final String dosage;
  final String frequency;
  final String duration;
  final String instruction;
  final String? translatedInstruction;
  final String? audioBase64;

  const MedicationItem({
    required this.medicine,
    required this.dosage,
    required this.frequency,
    required this.duration,
    required this.instruction,
    this.translatedInstruction,
    this.audioBase64,
  });

  factory MedicationItem.fromJson(Map<String, dynamic> json) {
    return MedicationItem(
      medicine: json['medicine'] as String? ?? 'Unknown',
      dosage: json['dosage'] as String? ?? 'Not Specified',
      frequency: json['frequency'] as String? ?? 'Not Specified',
      duration: json['duration'] as String? ?? 'Not Specified',
      instruction: json['instruction'] as String? ?? '',
      translatedInstruction: json['translated_instruction'] as String?,
      audioBase64: json['audio_base64'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'medicine': medicine,
        'dosage': dosage,
        'frequency': frequency,
        'duration': duration,
        'instruction': instruction,
        if (translatedInstruction != null)
          'translated_instruction': translatedInstruction,
        if (audioBase64 != null) 'audio_base64': audioBase64,
      };
}

/// OCR metadata returned alongside the parsed medications.
class OcrMetadata {
  final double confidence;
  final String rawText;
  final double abbreviationResolutionConfidence;

  const OcrMetadata({
    required this.confidence,
    required this.rawText,
    required this.abbreviationResolutionConfidence,
  });

  factory OcrMetadata.fromJson(Map<String, dynamic> json) {
    return OcrMetadata(
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      rawText: json['raw_text'] as String? ?? '',
      abbreviationResolutionConfidence:
          (json['abbreviation_resolution_confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Full prescription analysis result from the AI pipeline.
class PrescriptionResultModel {
  final bool valid;
  final List<String> errors;
  final List<MedicationItem> medications;
  final OcrMetadata? ocrMetadata;

  const PrescriptionResultModel({
    required this.valid,
    required this.errors,
    required this.medications,
    this.ocrMetadata,
  });

  factory PrescriptionResultModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionResultModel(
      valid: json['valid'] as bool? ?? false,
      errors: List<String>.from(json['errors'] as List? ?? []),
      medications: (json['medications'] as List? ?? [])
          .map((m) => MedicationItem.fromJson(m as Map<String, dynamic>))
          .toList(),
      ocrMetadata: json['ocr_metadata'] != null
          ? OcrMetadata.fromJson(json['ocr_metadata'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// A saved prescription record from the backend database.
class PrescriptionModel {
  final String id;
  final String userId;
  final String? title;
  final String? doctorName;
  final String? hospitalName;
  final String? prescribedDate;
  final String? validUntil;
  final String status;
  final String? rawNotes;
  final String createdAt;

  const PrescriptionModel({
    required this.id,
    required this.userId,
    this.title,
    this.doctorName,
    this.hospitalName,
    this.prescribedDate,
    this.validUntil,
    required this.status,
    this.rawNotes,
    required this.createdAt,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      title: json['title'] as String?,
      doctorName: json['doctor_name'] as String?,
      hospitalName: json['hospital_name'] as String?,
      prescribedDate: json['prescribed_date'] as String?,
      validUntil: json['valid_until'] as String?,
      status: json['status'] as String? ?? 'active',
      rawNotes: json['raw_notes'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        if (title != null) 'title': title,
        if (doctorName != null) 'doctor_name': doctorName,
        if (hospitalName != null) 'hospital_name': hospitalName,
        if (prescribedDate != null) 'prescribed_date': prescribedDate,
        if (validUntil != null) 'valid_until': validUntil,
        'status': status,
        if (rawNotes != null) 'raw_notes': rawNotes,
        'created_at': createdAt,
      };
}
