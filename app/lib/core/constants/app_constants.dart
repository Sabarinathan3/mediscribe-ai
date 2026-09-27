class AppConstants {
  AppConstants._();

  // ==========================================
  // API Configurations
  // ==========================================
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.10.249.89:8000/api/v1',
  );
  
  static const int connectionTimeoutMs = 15000;
  static const int receiveTimeoutMs = 30000;

  // ==========================================
  // Storage Keys
  // ==========================================
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyThemeMode = 'theme_mode';
  static const String keyUserLocale = 'user_locale';

  // ==========================================
  // Notification Channels
  // ==========================================
  static const String reminderChannelId = 'mediscribe_reminders';
  static const String reminderChannelName = 'Dose Reminders';
  static const String reminderChannelDesc = 'Notification channel for medicine adherence alerts';
}
