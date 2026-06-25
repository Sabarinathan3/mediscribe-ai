import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_service.dart';
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
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

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
    try {
      final token = await _service.getAccessToken();
      if (token == null) {
        state = const Unauthenticated();
        return;
      }
      
      state = const AuthLoading();
      final user = await _service.getMe();
      state = Authenticated(user);
    } catch (e) {
      // Token might be expired or invalid
      await _service.logout();
      state = const Unauthenticated();
    }
  }

  Future<void> login(String phone, String password) async {
    state = const AuthLoading();
    try {
      await _service.login(phone, password);
      final user = await _service.getMe();
      state = Authenticated(user);
    } catch (e) {
      state = AuthError(e.toString().replaceAll('Exception: ', ''));
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
      await _service.register(fullName, phone, password, role);
      final user = await _service.getMe();
      state = Authenticated(user);
    } catch (e) {
      state = AuthError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> logout() async {
    state = const AuthLoading();
    await _service.logout();
    state = const Unauthenticated();
  }
}
