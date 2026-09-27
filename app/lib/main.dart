import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'services/tts_service.dart';
import 'services/notification_service.dart';
import 'services/auth_provider.dart';
import 'services/onboarding_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  final prefs = await SharedPreferences.getInstance();
  final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

  runApp(
    ProviderScope(
      overrides: [
        onboardingCompletedProvider.overrideWith((ref) => onboardingCompleted),
      ],
      child: const MediScribeApp(),
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

    // Build the auth-aware router (created once, never recreated)
    final router = ref.watch(routerProvider);

    // ─── Post-startup auth redirects ──────────────────────────────────────
    // GoRouter's `redirect` function handles the very first route (before any
    // frame is rendered). For ALL subsequent auth state changes we listen here
    // and call router.go() inside addPostFrameCallback.
    //
    // WHY NOT refreshListenable?
    // refreshListenable fires notifyListeners() → GoRouter calls redirect() →
    // GoRouter immediately tries Navigator._pushEntry() → if the Navigator is
    // still building/animating the assertion '!_debugLocked' is thrown.
    //
    // addPostFrameCallback guarantees: the current frame has been fully
    // committed to the screen, all builds are done, no locks are held.
    // router.go() at that point is always safe.
    ref.listen<AuthState>(authProvider, (_, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Read the current path from GoRouter's route information provider.
        final path = router.routeInformationProvider.value.uri.path;
        final isOnAuth = path == AppRouter.login || path == AppRouter.register;
        final isOnSplash = path == AppRouter.splash;

        debugPrint('[AuthListener] state=${next.runtimeType} | path=$path');

        if (next is Unauthenticated || next is AuthError) {
          // User logged out or session expired → go to login/onboarding.
          final onboardingCompleted = ref.read(onboardingCompletedProvider);
          if (!onboardingCompleted) {
            if (path != AppRouter.onboarding) {
              debugPrint('[AuthListener] → router.go(/onboarding)');
              router.go(AppRouter.onboarding);
            }
          } else {
            if (!isOnAuth) {
              debugPrint('[AuthListener] → router.go(/login)');
              router.go(AppRouter.login);
            }
          }
        } else if (next is Authenticated) {
          // Login / register succeeded → go to dashboard.
          if (isOnSplash || isOnAuth || path == AppRouter.onboarding) {
            debugPrint('[AuthListener] → router.go(/dashboard)');
            router.go(AppRouter.dashboard);
          }
        }
        // AuthInitial / AuthLoading: splash is shown, nothing to do.
      });
    });

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
