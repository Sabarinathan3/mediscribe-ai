import 'package:flutter/material.dart';

class ReminderModel {
  static const int maxSnoozeCount = 3;
  static const Duration snoozeDuration = Duration(minutes: 10);

  final String id;
  final String medicineName;
  final String dosage;
  final TimeOfDay time;
  final List<int> daysOfWeek; // 1 = Monday, 7 = Sunday
  final bool isActive;
  final int snoozeCount;
  final DateTime? snoozedUntil;

  ReminderModel({
    required this.id,
    required this.medicineName,
    required this.dosage,
    required this.time,
    required this.daysOfWeek,
    this.isActive = true,
    this.snoozeCount = 0,
    this.snoozedUntil,
  });

  bool get canSnooze => snoozeCount < maxSnoozeCount;

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    DateTime? snoozedUntil;
    final rawSnoozedUntil = json['snoozed_until'];
    if (rawSnoozedUntil is String && rawSnoozedUntil.isNotEmpty) {
      snoozedUntil = DateTime.tryParse(rawSnoozedUntil);
    }

    // Handle backend schema mappings
    List<int> days = [];
    if (json.containsKey('recurrence_rule') && json['recurrence_rule'] != null) {
      final rule = json['recurrence_rule'] as Map<String, dynamic>;
      if (rule.containsKey('days_of_week')) {
        days = List<int>.from(rule['days_of_week']);
      }
    } else {
      days = List<int>.from((json['days_of_week'] as List?) ?? []);
    }

    TimeOfDay time = const TimeOfDay(hour: 8, minute: 0);
    if (json.containsKey('dose_time') && json['dose_time'] != null) {
      final parts = (json['dose_time'] as String).split(':');
      if (parts.length >= 2) {
        time = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    } else {
      time = TimeOfDay(
        hour: json['hour'] as int? ?? 8,
        minute: json['minute'] as int? ?? 0,
      );
    }

    return ReminderModel(
      id: json['id'] as String? ?? '',
      medicineName: (json['medicine_name'] ?? json['schedule_name']) as String? ?? '',
      dosage: (json['dose_amount'] ?? json['dosage']) as String? ?? '',
      time: time,
      daysOfWeek: days,
      isActive: json['is_active'] as bool? ?? true,
      snoozeCount: json['snooze_count'] as int? ?? 0,
      snoozedUntil: snoozedUntil,
    );
  }

  Map<String, dynamic> toJson() {
    final doseTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
    return {
      'id': id,
      'medicine_name': medicineName,
      'schedule_name': medicineName, // backend requires schedule_name
      'dosage': dosage, // local
      'dose_amount': dosage, // backend
      'hour': time.hour, // local
      'minute': time.minute, // local
      'dose_time': doseTime, // backend
      'days_of_week': daysOfWeek, // local
      'recurrence_type': 'weekly', // backend
      'recurrence_rule': {'days_of_week': daysOfWeek}, // backend
      'is_active': isActive,
      'snooze_count': snoozeCount,
      'snoozed_until': snoozedUntil?.toIso8601String(),
    };
  }

  ReminderModel copyWith({
    String? id,
    String? medicineName,
    String? dosage,
    TimeOfDay? time,
    List<int>? daysOfWeek,
    bool? isActive,
    int? snoozeCount,
    DateTime? snoozedUntil,
    bool clearSnoozedUntil = false,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      medicineName: medicineName ?? this.medicineName,
      dosage: dosage ?? this.dosage,
      time: time ?? this.time,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      isActive: isActive ?? this.isActive,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      snoozedUntil: clearSnoozedUntil ? null : (snoozedUntil ?? this.snoozedUntil),
    );
  }
}
