import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_service.dart';
import 'mock_auth_service.dart';
import '../models/user_model.dart';

// ==========================================
// Authentication State definition
// ==========================================
abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Authenticated extends AuthState {
  final UserModel user;
  const Authenticated(this.user);
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

// ==========================================
// Providers
// ==========================================
final authServiceProvider = Provider<AuthService>((ref) => MockAuthService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final service = ref.watch(authServiceProvider);
  return AuthNotifier(service);
});

// ==========================================
// Notifier implementation
// ==========================================
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _service;

  AuthNotifier(this._service) : super(const AuthInitial()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    debugPrint('[Auth] checkAuthStatus started');
    try {
      // Safety net: 8 s hard cap — splash can NEVER hang indefinitely.
      await _checkAuthStatusInternal().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          debugPrint('[Auth] checkAuthStatus TIMED OUT — forcing Unauthenticated');
          state = const Unauthenticated();
        },
      );
    } catch (e) {
      debugPrint('[Auth] checkAuthStatus unhandled error: $e');
      state = const Unauthenticated();
    }
  }

  Future<void> _checkAuthStatusInternal() async {
    final token = await _service.getAccessToken();
    debugPrint('[Auth] token present: ${token != null}');

    if (token == null) {
      state = const Unauthenticated();
      return;
    }

    // FIX: Do NOT emit AuthLoading before getMe().
    // AuthLoading causes the GoRouter redirect to hold the user on the splash
    // screen for the entire duration of the network call (up to 30 s).
    // Instead, call getMe() directly and transition straight to
    // Authenticated or Unauthenticated — never passing through AuthLoading.
    try {
      final user = await _service.getMe().timeout(const Duration(seconds: 6));
      debugPrint('[Auth] getMe() succeeded — user: ${user.phone}');
      state = Authenticated(user);
    } catch (e) {
      debugPrint('[Auth] getMe() failed: $e — clearing tokens');
      // Use local-only clear to avoid a second blocking network call in catch.
      await _service.clearTokensLocally();
      state = const Unauthenticated();
    }
  }

  Future<void> login(String phone, String password) async {
    state = const AuthLoading();
    try {
      final data = await _service.login(phone, password);
      final userJson = data['user'];
      if (userJson is Map<String, dynamic>) {
        state = Authenticated(UserModel.fromJson(userJson));
        return;
      }
      final user = await _service.getMe();
      state = Authenticated(user);
    } catch (e) {
      state = AuthError(_formatAuthError(e));
    }
  }

  Future<void> register(
    String fullName, 
    String phone, 
    String password, 
    String role
  ) async {
    state = const AuthLoading();
    try {
      final data = await _service.register(fullName, phone, password, role);
      final userJson = data['user'];
      if (userJson is Map<String, dynamic>) {
        state = Authenticated(UserModel.fromJson(userJson));
        return;
      }
      final user = await _service.getMe();
      state = Authenticated(user);
    } catch (e) {
      state = AuthError(_formatAuthError(e));
    }
  }

  String _formatAuthError(Object e) {
    return e.toString().replaceAll(RegExp(r'^(\w+Exception:\s*)+'), '').trim();
  }

  Future<void> logout() async {
    // Do NOT emit AuthLoading here — it causes every screen watching authProvider
    // to re-render its loading guard (e.g. profile shows bare CircularProgressIndicator
    // on a black Scaffold) before GoRouter's deferred redirect fires to /login.
    // Go straight to Unauthenticated so the redirect is the only visible transition.
    await _service.logout();
    state = const Unauthenticated();
  }
}
