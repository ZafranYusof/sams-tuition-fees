import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? user;

  AuthState({this.isAuthenticated = false, this.isLoading = false, this.error, this.user});

  AuthState copyWith({bool? isAuthenticated, bool? isLoading, String? error, Map<String, dynamic>? user}) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      try {
        final user = await ApiService.get('/auth/profile');
        state = AuthState(isAuthenticated: true, user: Map<String, dynamic>.from(user));
      } catch (_) {
        await prefs.remove('token');
        state = AuthState();
      }
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await ApiService.post('/auth/login', {'email': email, 'password': password});
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      state = AuthState(isAuthenticated: true, user: Map<String, dynamic>.from(data['user']));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> register(String studentId, String name, String email, String password, String faculty, String program) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await ApiService.post('/auth/register', {
        'studentId': studentId,
        'name': name,
        'email': email,
        'password': password,
        'faculty': faculty,
        'program': program,
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      state = AuthState(isAuthenticated: true, user: Map<String, dynamic>.from(data['user']));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> refreshProfile() async {
    try {
      final user = await ApiService.get('/auth/profile');
      state = AuthState(isAuthenticated: true, user: Map<String, dynamic>.from(user));
    } catch (_) {}
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
