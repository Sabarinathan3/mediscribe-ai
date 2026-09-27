import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediscribe_app/models/reminder_model.dart';
import 'package:mediscribe_app/services/notification_service.dart';
import 'package:mediscribe_app/widgets/reminder_card.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReminderCard', () {
    testWidgets('shows snooze icon for active reminders under snooze limit', (tester) async {
      final reminder = ReminderModel(
        id: 'test-reminder',
        medicineName: 'Amoxicillin',
        dosage: '500mg',
        time: const TimeOfDay(hour: 8, minute: 0),
        daysOfWeek: const [1, 2, 3],
        isActive: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localNotificationsProvider.overrideWithValue(FlutterLocalNotificationsPlugin()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ReminderCard(reminder: reminder, animationIndex: 0),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.snooze_rounded), findsOneWidget);
    });

    testWidgets('hides snooze icon when max snooze count reached', (tester) async {
      final reminder = ReminderModel(
        id: 'test-reminder-2',
        medicineName: 'Paracetamol',
        dosage: '650mg',
        time: const TimeOfDay(hour: 14, minute: 0),
        daysOfWeek: const [],
        isActive: true,
        snoozeCount: ReminderModel.maxSnoozeCount,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localNotificationsProvider.overrideWithValue(FlutterLocalNotificationsPlugin()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ReminderCard(reminder: reminder, animationIndex: 0),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.snooze_rounded), findsNothing);
    });
  });
}
