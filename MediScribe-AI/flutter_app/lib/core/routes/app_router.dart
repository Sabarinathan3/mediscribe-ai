import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import 'nav_shell.dart';

// ==========================================
// Global router provider (for redirect access to Riverpod)
// ==========================================
final _routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRouter.splash,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isOnAuth = state.matchedLocation == AppRouter.login ||
          state.matchedLocation == AppRouter.register;
      final isOnSplash = state.matchedLocation == AppRouter.splash;

      // While loading auth, stay on splash
      if (authState is AuthInitial || authState is AuthLoading) {
        if (!isOnSplash) return AppRouter.splash;
        return null;
      }

      // If unauthenticated and not on auth screens, redirect to login
      if (authState is Unauthenticated || authState is AuthError) {
        if (!isOnAuth && !isOnSplash) return AppRouter.login;
        return null;
      }

      // If authenticated and trying to access auth/splash, redirect to dashboard
      if (authState is Authenticated) {
        if (isOnAuth || isOnSplash) return AppRouter.dashboard;
        return null;
      }

      return null;
    },
    routes: [
      // Splash
      GoRoute(
        path: AppRouter.splash,
        pageBuilder: (context, state) => _fadeTransition(
          state,
          const SplashScreen(),
        ),
      ),

      // Auth routes
      GoRoute(
        path: AppRouter.login,
        pageBuilder: (context, state) => _slideTransition(
          state,
          const LoginScreen(),
        ),
      ),
      GoRoute(
        path: AppRouter.register,
        pageBuilder: (context, state) => _slideTransition(
          state,
          const RegisterScreen(),
        ),
      ),

      // Main Shell (Bottom Nav)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainNavigationShell(navigationShell: navigationShell),
        branches: [
          // Tab 0: Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRouter.dashboard,
                pageBuilder: (context, state) => _noTransition(
                  state,
                  const DashboardScreen(),
                ),
              ),
            ],
          ),
          // Tab 1: Prescriptions
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRouter.prescriptions,
                pageBuilder: (context, state) => _noTransition(
                  state,
                  const PrescriptionResultScreen(),
                ),
              ),
            ],
          ),
          // Tab 2: Reminders
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRouter.reminders,
                pageBuilder: (context, state) => _noTransition(
                  state,
                  const ReminderScreen(),
                ),
              ),
            ],
          ),
          // Tab 3: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRouter.profile,
                pageBuilder: (context, state) => _noTransition(
                  state,
                  const ProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      ),

      // Full-screen flows pushed over the shell
      GoRoute(
        path: AppRouter.scan,
        pageBuilder: (context, state) => _slideTransition(
          state,
          const UploadPrescriptionScreen(),
        ),
      ),
      GoRoute(
        path: AppRouter.ocrReview,
        pageBuilder: (context, state) {
          final ocrData = state.extra as Map<String, dynamic>? ?? {};
          return _slideTransition(state, OCRResultScreen(ocrData: ocrData));
        },
      ),
      GoRoute(
        path: AppRouter.medicineDetails,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final medicineData = extra['medicineData'] as Map<String, dynamic>? ?? {};
          final otherMedicines = (extra['otherMedicines'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const <String>[];
          return _slideTransition(
            state,
            MedicineDetailsScreen(
              medicineData: medicineData,
              otherMedicines: otherMedicines,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRouter.schedule,
        pageBuilder: (context, state) => _slideTransition(
          state,
          const MedicineScheduleScreen(),
        ),
      ),
    ],
  );
});

// ==========================================
// App Router
// ==========================================
class AppRouter {
  AppRouter._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String prescriptions = '/prescriptions';
  static const String reminders = '/reminders';
  static const String profile = '/profile';
  static const String scan = '/scan';
  static const String ocrReview = '/ocr-review';
  static const String medicineDetails = '/medicine-details';
  static const String schedule = '/schedule';

  static GoRouter routerOf(WidgetRef ref) => ref.read(_routerProvider);

  /// Convenience: returns a GoRouter that watches auth changes for redirects.
  static GoRouter createRouter(WidgetRef ref) {
    return GoRouter(
      initialLocation: splash,
      debugLogDiagnostics: false,
      refreshListenable: _GoRouterRefreshStream(ref.read(authProvider.notifier).stream),
      redirect: (context, state) {
        final authState = ref.read(authProvider);
        final isOnAuth = state.matchedLocation == login ||
            state.matchedLocation == register;
        final isOnSplash = state.matchedLocation == splash;

        if (authState is AuthInitial || authState is AuthLoading) {
          return isOnSplash ? null : splash;
        }
        if (authState is Unauthenticated || authState is AuthError) {
          return (!isOnAuth && !isOnSplash) ? login : null;
        }
        if (authState is Authenticated) {
          return (isOnAuth || isOnSplash) ? dashboard : null;
        }
        return null;
      },
      routes: [
        GoRoute(
          path: splash,
          pageBuilder: (c, s) => _fadeTransition(s, const SplashScreen()),
        ),
        GoRoute(
          path: login,
          pageBuilder: (c, s) => _slideTransition(s, const LoginScreen()),
        ),
        GoRoute(
          path: register,
          pageBuilder: (c, s) => _slideTransition(s, const RegisterScreen()),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => MainNavigationShell(navigationShell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(path: dashboard, pageBuilder: (c, s) => _noTransition(s, const DashboardScreen())),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: prescriptions, pageBuilder: (c, s) => _noTransition(s, const PrescriptionResultScreen())),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: reminders, pageBuilder: (c, s) => _noTransition(s, const ReminderScreen())),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: profile, pageBuilder: (c, s) => _noTransition(s, const ProfileScreen())),
            ]),
          ],
        ),
        GoRoute(path: scan, pageBuilder: (c, s) => _slideTransition(s, const UploadPrescriptionScreen())),
        GoRoute(
          path: ocrReview,
          pageBuilder: (c, s) {
            final data = s.extra as Map<String, dynamic>? ?? {};
            return _slideTransition(s, OCRResultScreen(ocrData: data));
          },
        ),
        GoRoute(
          path: medicineDetails,
          pageBuilder: (c, s) {
            final extra = s.extra as Map<String, dynamic>? ?? {};
            return _slideTransition(
              s,
              MedicineDetailsScreen(
                medicineData: extra['medicineData'] as Map<String, dynamic>? ?? {},
                otherMedicines: (extra['otherMedicines'] as List?)?.map((e) => e.toString()).toList() ?? [],
              ),
            );
          },
        ),
        GoRoute(path: schedule, pageBuilder: (c, s) => _slideTransition(s, const MedicineScheduleScreen())),
      ],
    );
  }
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

// ==========================================
// ChangeNotifier wrapper for GoRouter refresh
// ==========================================
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<AuthState> stream) {
    notifyListeners();
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
