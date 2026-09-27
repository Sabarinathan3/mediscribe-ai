import 'package:flutter/material.dart';

class ReminderModel {
  final String id;
  final String medicineName;
  final String dosage;
  final TimeOfDay time;
  final List<int> daysOfWeek; // 1 = Monday, 7 = Sunday
  final bool isActive;

  ReminderModel({
    required this.id,
    required this.medicineName,
    required this.dosage,
    required this.time,
    required this.daysOfWeek,
    this.isActive = true,
  });

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['id'] as String? ?? '',
      medicineName: json['medicine_name'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '',
      time: TimeOfDay(
        hour: json['hour'] as int? ?? 8,
        minute: json['minute'] as int? ?? 0,
      ),
      daysOfWeek: List<int>.from((json['days_of_week'] as List?) ?? []),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicine_name': medicineName,
      'dosage': dosage,
      'hour': time.hour,
      'minute': time.minute,
      'days_of_week': daysOfWeek,
      'is_active': isActive,
    };
  }

  ReminderModel copyWith({
    String? id,
    String? medicineName,
    String? dosage,
    TimeOfDay? time,
    List<int>? daysOfWeek,
    bool? isActive,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      medicineName: medicineName ?? this.medicineName,
      dosage: dosage ?? this.dosage,
      time: time ?? this.time,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      isActive: isActive ?? this.isActive,
    );
  }
}
