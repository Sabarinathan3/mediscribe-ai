import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../screens/ai_chat_screen.dart';
import '../../screens/splash_screen.dart';
import '../../screens/login_screen.dart';
import '../../screens/register_screen.dart';
import '../../screens/dashboard_screen.dart';
import '../../screens/upload_prescription_screen.dart';
import '../../screens/ocr_result_screen.dart';
import '../../screens/medicine_details_screen.dart';
import '../../screens/reminder_screen.dart';
import '../../screens/medicine_schedule_screen.dart';
import '../../screens/profile_screen.dart';
import '../../screens/prescription_result_screen.dart';
import '../../services/auth_provider.dart';
import '../../screens/onboarding_screen.dart';
import '../../services/onboarding_provider.dart';
import 'nav_shell.dart';
 
// ==========================================
// App Router
//
// ARCHITECTURE NOTE — why no refreshListenable:
//
// The original design used GoRouter's refreshListenable to trigger redirect()
// whenever authProvider changed. This caused the '!_debugLocked' assertion:
//
//   authProvider changes
//   └─ notifyListeners()  (sync OR microtask)
//        └─ GoRouter calls redirect() → returns new location
//             └─ GoRouter calls Navigator._pushEntry()
//                  └─ CRASH if navigator is mid-build / mid-animation 💥
//
// Fix: remove refreshListenable entirely.
// • redirect()  → handles the INITIAL route check (runs once, before any frame)
// • ref.listen  → handles POST-STARTUP auth changes (see MediScribeApp in main.dart)
//                 calls router.go() inside addPostFrameCallback, guaranteeing
//                 the Navigator is idle before any navigation is attempted.
// ==========================================
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRouter.splash,
    debugLogDiagnostics: true,
    // NO refreshListenable — see architecture note above.
    redirect: (context, state) {
      // This redirect runs only for the initial route resolution and for
      // explicit navigations (e.g. deep links). It does NOT run on auth
      // state changes — those are handled by MediScribeApp's ref.listen.
      final authState = ref.read(authProvider);
      final loc = state.matchedLocation;
      final isOnAuth = loc == AppRouter.login || loc == AppRouter.register;
      final isOnSplash = loc == AppRouter.splash;

      debugPrint('[Router] initial redirect — loc: $loc | auth: ${authState.runtimeType}');

      if (authState is AuthInitial || authState is AuthLoading) {
        // Still initialising — hold on splash.
        if (isOnAuth || loc == AppRouter.onboarding) return null;
        return isOnSplash ? null : AppRouter.splash;
      }
      
      final onboardingCompleted = ref.read(onboardingCompletedProvider);
      if (authState is Unauthenticated || authState is AuthError) {
        if (!onboardingCompleted) {
          if (loc == AppRouter.onboarding) return null;
          return AppRouter.onboarding;
        }
        if (!isOnAuth) return AppRouter.login;
        return null;
      }
      if (authState is Authenticated) {
        if (isOnSplash || isOnAuth || loc == AppRouter.onboarding) return AppRouter.dashboard;
        return null;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRouter.splash,
        pageBuilder: (c, s) => _fadeTransition(s, const SplashScreen()),
      ),
      GoRoute(
        path: AppRouter.login,
        pageBuilder: (c, s) => _slideTransition(s, const LoginScreen()),
      ),
      GoRoute(
        path: AppRouter.register,
        pageBuilder: (c, s) => _slideTransition(s, const RegisterScreen()),
      ),
      GoRoute(
        path: AppRouter.onboarding,
        pageBuilder: (c, s) => _fadeTransition(s, const OnboardingScreen()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainNavigationShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRouter.dashboard,
              pageBuilder: (c, s) => _noTransition(s, const DashboardScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRouter.aiChat,
              pageBuilder: (c, s) => _noTransition(s, const AIChatScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRouter.prescriptions,
              pageBuilder: (c, s) => _noTransition(s, const PrescriptionResultScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRouter.profile,
              pageBuilder: (c, s) => _noTransition(s, const ProfileScreen()),
            ),
          ]),
        ],
      ),
      GoRoute(
        path: AppRouter.reminders,
        pageBuilder: (c, s) => _slideTransition(s, const ReminderScreen()),
      ),
      GoRoute(
        path: AppRouter.scan,
        pageBuilder: (c, s) => _slideTransition(s, const UploadPrescriptionScreen()),
      ),
      GoRoute(
        path: AppRouter.ocrReview,
        pageBuilder: (c, s) {
          final data = s.extra as Map<String, dynamic>? ?? {};
          return _slideTransition(s, OCRResultScreen(ocrData: data));
        },
      ),
      GoRoute(
        path: AppRouter.medicineDetails,
        pageBuilder: (c, s) {
          final extra = s.extra as Map<String, dynamic>? ?? {};
          return _slideTransition(
            s,
            MedicineDetailsScreen(
              medicineData: extra['medicineData'] as Map<String, dynamic>? ?? {},
              otherMedicines: (extra['otherMedicines'] as List?)
                      ?.map((e) => e.toString())
                      .toList() ??
                  const <String>[],
            ),
          );
        },
      ),
      GoRoute(
        path: AppRouter.schedule,
        pageBuilder: (c, s) => _slideTransition(s, const MedicineScheduleScreen()),
      ),
    ],
  );
});

// ==========================================
// Route Name Constants
// ==========================================
class AppRouter {
  AppRouter._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String onboarding = '/onboarding';
  static const String dashboard = '/dashboard';
  static const String aiChat = '/ai-chat';
  static const String prescriptions = '/prescriptions';
  static const String reminders = '/reminders';
  static const String profile = '/profile';
  static const String scan = '/scan';
  static const String ocrReview = '/ocr-review';
  static const String medicineDetails = '/medicine-details';
  static const String schedule = '/schedule';
}

// ==========================================
// Page Transition Builders
// ==========================================
CustomTransitionPage<void> _fadeTransition(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 350),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

CustomTransitionPage<void> _slideTransition(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      );
    },
  );
}

CustomTransitionPage<void> _noTransition(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: Duration.zero,
    transitionsBuilder: (_, __, ___, child) => child,
  );
}
