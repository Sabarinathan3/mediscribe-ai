import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/reminder_model.dart';
import '../services/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final localNotifications = ref.read(localNotificationsProvider);
  return NotificationService(localNotifications);
});

// ==========================================
// State: Wrap the list with optional error information
// ==========================================
class ReminderState {
  final List<ReminderModel> reminders;
  final String? errorMessage;

  const ReminderState({this.reminders = const [], this.errorMessage});

  ReminderState copyWith({List<ReminderModel>? reminders, String? errorMessage}) {
    return ReminderState(
      reminders: reminders ?? this.reminders,
      errorMessage: errorMessage,
    );
  }
}

class ReminderNotifier extends StateNotifier<ReminderState> {
  final NotificationService _notificationService;
  static const String _prefsKey = 'mediscribe_reminders';

  ReminderNotifier(this._notificationService) : super(const ReminderState()) {
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? remindersJson = prefs.getString(_prefsKey);
      if (remindersJson != null) {
        final List<dynamic> decodedList = jsonDecode(remindersJson);
        final reminders = decodedList
            .map((item) => ReminderModel.fromJson(item as Map<String, dynamic>))
            .toList();
        state = state.copyWith(reminders: reminders);
      }
    } catch (e) {
      // Surface the error to the UI rather than silently discarding it
      debugPrint('[ReminderProvider] Failed to load reminders: $e');
      state = state.copyWith(
        errorMessage: 'Could not load saved reminders. Please restart the app.',
      );
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encodedList =
          jsonEncode(state.reminders.map((r) => r.toJson()).toList());
      await prefs.setString(_prefsKey, encodedList);
    } catch (e) {
      debugPrint('[ReminderProvider] Failed to save reminders: $e');
      state = state.copyWith(
        errorMessage: 'Could not save reminders. Changes may be lost.',
      );
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  Future<void> addReminder(ReminderModel reminder) async {
    state = state.copyWith(reminders: [...state.reminders, reminder]);
    await _saveToPrefs();
    await _notificationService.scheduleReminder(reminder);
  }

  Future<void> updateReminder(ReminderModel updatedReminder) async {
    state = state.copyWith(
      reminders: [
        for (final reminder in state.reminders)
          if (reminder.id == updatedReminder.id) updatedReminder else reminder
      ],
    );
    await _saveToPrefs();
    await _notificationService.scheduleReminder(updatedReminder);
  }

  Future<void> deleteReminder(String id) async {
    await _notificationService.cancelReminder(id);
    state = state.copyWith(
      reminders: state.reminders.where((r) => r.id != id).toList(),
    );
    await _saveToPrefs();
  }

  Future<void> toggleReminderActive(String id) async {
    state = state.copyWith(
      reminders: [
        for (final r in state.reminders)
          if (r.id == id) r.copyWith(isActive: !r.isActive) else r
      ],
    );
    await _saveToPrefs();

    final updated = state.reminders.firstWhere((r) => r.id == id);
    if (updated.isActive) {
      await _notificationService.scheduleReminder(updated);
    } else {
      await _notificationService.cancelReminder(id);
    }
  }
}

final reminderProvider =
    StateNotifierProvider<ReminderNotifier, ReminderState>((ref) {
  final notifService = ref.watch(notificationServiceProvider);
  return ReminderNotifier(notifService);
});

/// Convenience provider that exposes only the reminders list.
/// Use this in screens that only need the list (not error state).
/// Use [reminderProvider] when you also need to react to errorMessage.
final reminderListProvider = Provider<List<ReminderModel>>((ref) {
  return ref.watch(reminderProvider).reminders;
});
