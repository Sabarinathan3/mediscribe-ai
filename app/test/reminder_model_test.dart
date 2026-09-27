import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediscribe_app/models/reminder_model.dart';

void main() {
  group('ReminderModel', () {
    test('fromJson parses snooze fields with defaults', () {
      final reminder = ReminderModel.fromJson({
        'id': 'r1',
        'medicine_name': 'Aspirin',
        'dosage': '81mg',
        'hour': 9,
        'minute': 30,
        'days_of_week': [1, 3, 5],
        'is_active': true,
      });

      expect(reminder.snoozeCount, 0);
      expect(reminder.snoozedUntil, isNull);
      expect(reminder.canSnooze, isTrue);
      expect(reminder.time, const TimeOfDay(hour: 9, minute: 30));
    });

    test('fromJson parses snoozed_until ISO string', () {
      final reminder = ReminderModel.fromJson({
        'id': 'r2',
        'medicine_name': 'Metformin',
        'dosage': '500mg',
        'hour': 8,
        'minute': 0,
        'snooze_count': 2,
        'snoozed_until': '2026-06-26T10:30:00.000Z',
      });

      expect(reminder.snoozeCount, 2);
      expect(reminder.snoozedUntil, isNotNull);
      expect(reminder.canSnooze, isTrue);
    });

    test('canSnooze is false at max snooze count', () {
      final reminder = ReminderModel(
        id: 'r3',
        medicineName: 'Ibuprofen',
        dosage: '200mg',
        time: const TimeOfDay(hour: 12, minute: 0),
        daysOfWeek: const [],
        snoozeCount: ReminderModel.maxSnoozeCount,
      );

      expect(reminder.canSnooze, isFalse);
    });

    test('toJson round-trips snooze fields', () {
      final snoozedUntil = DateTime.utc(2026, 6, 26, 10, 30);
      final reminder = ReminderModel(
        id: 'r4',
        medicineName: 'Vitamin D',
        dosage: '1000iu',
        time: const TimeOfDay(hour: 7, minute: 0),
        daysOfWeek: const [1, 2, 3, 4, 5],
        snoozeCount: 1,
        snoozedUntil: snoozedUntil,
      );

      final json = reminder.toJson();
      final restored = ReminderModel.fromJson(json);

      expect(restored.snoozeCount, 1);
      expect(restored.snoozedUntil?.toUtc(), snoozedUntil);
      expect(restored.medicineName, 'Vitamin D');
    });

    test('copyWith can clear snoozedUntil', () {
      final reminder = ReminderModel(
        id: 'r5',
        medicineName: 'Lisinopril',
        dosage: '10mg',
        time: const TimeOfDay(hour: 20, minute: 0),
        daysOfWeek: const [],
        snoozeCount: 2,
        snoozedUntil: DateTime.now(),
      );

      final cleared = reminder.copyWith(clearSnoozedUntil: true, snoozeCount: 0);

      expect(cleared.snoozedUntil, isNull);
      expect(cleared.snoozeCount, 0);
    });
  });
}
