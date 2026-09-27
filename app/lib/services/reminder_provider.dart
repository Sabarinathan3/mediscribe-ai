import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/reminder_model.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';

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
  final Ref _ref;
  static const String _prefsKey = 'mediscribe_reminders';

  ReminderNotifier(this._notificationService, this._ref) : super(const ReminderState()) {
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    try {
      // 1. Fetch from backend
      final apiService = _ref.read(apiServiceProvider);
      try {
        final serverSchedules = await apiService.getSchedules();
        final reminders = serverSchedules
            .map((item) => ReminderModel.fromJson(item))
            .toList();
        state = state.copyWith(reminders: reminders);
        await _saveToPrefs();
        
        // Ensure local notifications match the active state from backend
        for (final r in reminders) {
          if (r.isActive) {
            await _notificationService.scheduleReminder(r);
          } else {
            await _notificationService.cancelReminder(r.id);
          }
        }
        return;
      } catch (e) {
        debugPrint('[ReminderProvider] Backend sync failed, falling back to local: $e');
      }

      // 2. Fallback to local
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
      debugPrint('[ReminderProvider] Failed to save reminders to prefs: $e');
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  Future<void> addReminder(ReminderModel reminder) async {
    try {
      final apiService = _ref.read(apiServiceProvider);
      
      // We don't send 'id' because backend assigns it.
      final payload = reminder.toJson();
      payload.remove('id');
      
      final created = await apiService.createSchedule(payload);
      final syncedReminder = ReminderModel.fromJson(created);
      
      state = state.copyWith(reminders: [...state.reminders, syncedReminder]);
      await _saveToPrefs();
      await _notificationService.scheduleReminder(syncedReminder);
    } catch (e) {
      debugPrint('[ReminderProvider] Backend add failed: $e');
      // Optimistically add locally with temporary ID
      state = state.copyWith(reminders: [...state.reminders, reminder]);
      await _saveToPrefs();
      await _notificationService.scheduleReminder(reminder);
      state = state.copyWith(errorMessage: 'Added locally but failed to sync to server.');
    }
  }

  Future<void> updateReminder(ReminderModel updatedReminder) async {
    try {
      final apiService = _ref.read(apiServiceProvider);
      await apiService.updateSchedule(updatedReminder.id, updatedReminder.toJson());
      
      state = state.copyWith(
        reminders: [
          for (final reminder in state.reminders)
            if (reminder.id == updatedReminder.id) updatedReminder else reminder
        ],
      );
      await _saveToPrefs();
      await _notificationService.scheduleReminder(updatedReminder);
    } catch (e) {
      debugPrint('[ReminderProvider] Backend update failed: $e');
      state = state.copyWith(errorMessage: 'Failed to update reminder on server.');
    }
  }

  Future<void> deleteReminder(String id) async {
    try {
      final apiService = _ref.read(apiServiceProvider);
      // Attempt backend delete first if it's a UUID
      if (id.length > 20) { 
        await apiService.deleteSchedule(id);
      }
      
      await _notificationService.cancelReminder(id);
      state = state.copyWith(
        reminders: state.reminders.where((r) => r.id != id).toList(),
      );
      await _saveToPrefs();
    } catch (e) {
      debugPrint('[ReminderProvider] Backend delete failed: $e');
      state = state.copyWith(errorMessage: 'Failed to delete reminder on server.');
    }
  }

  Future<void> toggleReminderActive(String id) async {
    final original = state.reminders.firstWhere((r) => r.id == id);
    final updated = original.copyWith(isActive: !original.isActive, clearSnoozedUntil: true, snoozeCount: 0);
    
    try {
      final apiService = _ref.read(apiServiceProvider);
      if (id.length > 20) {
        await apiService.updateSchedule(id, {'is_active': updated.isActive});
      }

      state = state.copyWith(
        reminders: [
          for (final r in state.reminders)
            if (r.id == id) updated else r
        ],
      );
      await _saveToPrefs();

      if (updated.isActive) {
        await _notificationService.scheduleReminder(updated);
      } else {
        await _notificationService.cancelReminder(id);
      }
    } catch (e) {
      debugPrint('[ReminderProvider] Backend toggle failed: $e');
      state = state.copyWith(errorMessage: 'Failed to toggle reminder on server.');
    }
  }

  Future<bool> snoozeReminder(String id) async {
    final reminder = state.reminders.firstWhere((r) => r.id == id);

    if (!reminder.isActive) {
      state = state.copyWith(errorMessage: 'Cannot snooze an inactive reminder.');
      return false;
    }

    if (!reminder.canSnooze) {
      state = state.copyWith(
        errorMessage: 'Maximum snooze limit (${ReminderModel.maxSnoozeCount}) reached.',
      );
      return false;
    }

    final snoozedUntil = DateTime.now().add(ReminderModel.snoozeDuration);
    final updated = reminder.copyWith(
      snoozeCount: reminder.snoozeCount + 1,
      snoozedUntil: snoozedUntil,
    );

    // Snoozing is mostly local, we don't strictly need to sync it to the schedule backend
    // as it's a temporal state of the instance.
    state = state.copyWith(
      reminders: [
        for (final r in state.reminders)
          if (r.id == id) updated else r
      ],
      errorMessage: null,
    );
    await _saveToPrefs();
    await _notificationService.scheduleSnooze(updated, snoozedUntil);
    return true;
  }
}

final reminderProvider =
    StateNotifierProvider<ReminderNotifier, ReminderState>((ref) {
  final notifService = ref.watch(notificationServiceProvider);
  return ReminderNotifier(notifService, ref);
});

/// Convenience provider that exposes only the reminders list.
/// Use this in screens that only need the list (not error state).
/// Use [reminderProvider] when you also need to react to errorMessage.
final reminderListProvider = Provider<List<ReminderModel>>((ref) {
  return ref.watch(reminderProvider).reminders;
});
