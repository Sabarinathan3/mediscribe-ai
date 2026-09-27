import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder_model.dart';
import '../core/constants/app_constants.dart';

final localNotificationsProvider = Provider<FlutterLocalNotificationsPlugin>((ref) {
  final plugin = FlutterLocalNotificationsPlugin();
  
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  // Note: initialize() is async but the Provider is synchronous.
  // We call it here and let it complete in the background. The actual
  // await is performed in NotificationService.initialize() before any
  // notifications are scheduled.
  plugin.initialize(initSettings);

  return plugin;
});

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  bool _initialized = false;

  NotificationService(this._notificationsPlugin) {
    _init();
  }

  Future<void> _init() async {
    if (_initialized) return;
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _notificationsPlugin.initialize(initSettings);
    tz.initializeTimeZones();
    final TimezoneInfo tzInfo = await FlutterTimezone.getLocalTimezone();
    final String timeZoneName = tzInfo.identifier;
    tz.setLocalLocation(tz.getLocation(timeZoneName));
    _initialized = true;
  }

  Future<void> requestPermissions() async {
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
        
    final iosImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosImplementation != null) {
      await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  int _generateNotificationId(String reminderId, int dayIndex) {
    return (reminderId.hashCode + dayIndex) & 0x7FFFFFFF;
  }

  Future<void> scheduleReminder(ReminderModel reminder) async {
    await cancelReminder(reminder.id);

    if (!reminder.isActive) return;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      AppConstants.reminderChannelId,
      AppConstants.reminderChannelName,
      channelDescription: AppConstants.reminderChannelDesc,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final now = tz.TZDateTime.now(tz.local);

    // Schedule for each day of the week
    for (int day in reminder.daysOfWeek) {
      final notifId = _generateNotificationId(reminder.id, day);
      
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        reminder.time.hour,
        reminder.time.minute,
      );

      while (scheduledDate.weekday != day) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 7));
      }

      await _notificationsPlugin.zonedSchedule(
        notifId,
        'Time for ${reminder.medicineName}',
        'Please take your dosage: ${reminder.dosage}',
        scheduledDate,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }

    if (reminder.daysOfWeek.isEmpty) {
      final notifId = _generateNotificationId(reminder.id, 0);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        reminder.time.hour,
        reminder.time.minute,
      );
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _notificationsPlugin.zonedSchedule(
        notifId,
        'Time for ${reminder.medicineName}',
        'Please take your dosage: ${reminder.dosage}',
        scheduledDate,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> cancelReminder(String reminderId) async {
    // Cancel all possible notification IDs:
    // day=0 is used for "every day" (no specific weekday) reminders
    // day=1..7 corresponds to DateTime.weekday values (Monday=1 .. Sunday=7)
    for (int day = 0; day <= 7; day++) {
      final notifId = _generateNotificationId(reminderId, day);
      await _notificationsPlugin.cancel(notifId);
    }
    // Cancel any one-time snooze notification
    await _notificationsPlugin.cancel(_generateNotificationId(reminderId, 99));
  }

  Future<void> scheduleSnooze(ReminderModel reminder, DateTime snoozedUntil) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      AppConstants.reminderChannelId,
      AppConstants.reminderChannelName,
      channelDescription: AppConstants.reminderChannelDesc,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final scheduledDate = tz.TZDateTime.from(snoozedUntil, tz.local);
    final notifId = _generateNotificationId(reminder.id, 99);

    await _notificationsPlugin.zonedSchedule(
      notifId,
      'Snoozed: ${reminder.medicineName}',
      'Please take your dosage: ${reminder.dosage}',
      scheduledDate,
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
