import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/fcm_service.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final bool isInitializing; // true until first auth check completes
  final String? error;
  final Map<String, dynamic>? user;

  AuthState({this.isAuthenticated = false, this.isLoading = false, this.isInitializing = true, this.error, this.user});

  AuthState copyWith({bool? isAuthenticated, bool? isLoading, bool? isInitializing, String? error, Map<String, dynamic>? user, bool clearUser = false}) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      isInitializing: isInitializing ?? this.isInitializing,
      error: error,
      user: clearUser ? null : (user ?? this.user),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState(isInitializing: true)) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      try {
        final user = await ApiService.get('/auth/profile');
        final userMap = Map<String, dynamic>.from(user);
        // Normalize: ensure both 'id' and '_id' exist
        userMap['id'] = userMap['id'] ?? userMap['_id'] ?? '';
        userMap['_id'] = userMap['_id'] ?? userMap['id'] ?? '';
        state = AuthState(isAuthenticated: true, user: userMap, isInitializing: false);
      } catch (e) {
        // Only remove token on 401 — network errors should preserve session
        if (e.toString().contains('401') || e.toString().contains('Session expired')) {
          await prefs.remove('token');
          state = AuthState(isInitializing: false);
        } else {
          // Network error or other transient issue — keep token, stay authenticated
          state = state.copyWith(isAuthenticated: true, isInitializing: false, error: 'Unable to verify session. Please check your connection.');
        }
      }
    } else {
      state = AuthState(isInitializing: false);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await ApiService.post('/auth/login', {'email': email, 'password': password});
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      final userMap = Map<String, dynamic>.from(data['user']);
      // Normalize ID fields
      userMap['id'] = userMap['id'] ?? userMap['_id'] ?? '';
      userMap['_id'] = userMap['_id'] ?? userMap['id'] ?? '';
      state = AuthState(isAuthenticated: true, user: userMap, isInitializing: false);
      // Register FCM token with backend (fire-and-forget)
      FcmService().registerTokenAfterLogin();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> register(String studentId, String name, String email, String password, String faculty, String program, String financingType) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await ApiService.post('/auth/register', {
        'studentId': studentId,
        'name': name,
        'email': email,
        'password': password,
        'faculty': faculty,
        'program': program,
        'financingType': financingType,
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      final userMap = Map<String, dynamic>.from(data['user']);
      // Normalize ID fields
      userMap['id'] = userMap['id'] ?? userMap['_id'] ?? '';
      userMap['_id'] = userMap['_id'] ?? userMap['id'] ?? '';
      state = AuthState(isAuthenticated: true, user: userMap, isInitializing: false);
      // Register FCM token with backend (fire-and-forget)
      FcmService().registerTokenAfterLogin();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> refreshProfile() async {
    try {
      final user = await ApiService.get('/auth/profile');
      final userMap = Map<String, dynamic>.from(user);
      userMap['id'] = userMap['id'] ?? userMap['_id'] ?? '';
      userMap['_id'] = userMap['_id'] ?? userMap['id'] ?? '';
      state = AuthState(isAuthenticated: true, user: userMap, isInitializing: false);
    } catch (e) {
      // If 401, ApiService already removed token — clear auth state too
      if (e.toString().contains('401') || e.toString().contains('Session expired')) {
        state = AuthState(isInitializing: false);
      }
    }
  }

  void updateStudentStatus(String newStatus) {
    if (state.user != null) {
      final updatedUser = Map<String, dynamic>.from(state.user!);
      updatedUser['studentStatus'] = newStatus;
      state = state.copyWith(user: updatedUser);
    }
  }

    Future<void> logout() async {
    // Unregister FCM token before clearing auth (fire-and-forget)
    FcmService().unregisterToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    state = AuthState(isInitializing: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
