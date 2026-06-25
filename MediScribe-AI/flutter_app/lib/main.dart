import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'services/tts_service.dart';
import 'services/notification_service.dart';

// ==========================================
// Global Providers
// ==========================================
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

// ==========================================
// Application entry point
// ==========================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone data (required for scheduled notifications)
  tz.initializeTimeZones();

  runApp(
    const ProviderScope(
      child: MediScribeApp(),
    ),
  );
}

class MediScribeApp extends ConsumerWidget {
  const MediScribeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode currentThemeMode = ref.watch(themeModeProvider);

    // Eagerly initialize notification and TTS providers
    ref.read(localNotificationsProvider);
    ref.read(flutterTtsProvider);

    // Build the auth-aware router
    final router = AppRouter.createRouter(ref);

    return MaterialApp.router(
      title: 'MediScribe AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: currentThemeMode,
      routerConfig: router,
    );
  }
}
