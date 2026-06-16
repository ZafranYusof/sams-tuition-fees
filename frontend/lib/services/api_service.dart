import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../config/api_config.dart';

class ApiService {
  static const int _maxRetries = 3;
  static const List<int> _retryDelays = [1, 2, 4]; // seconds for exponential backoff

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Handle 401 - clear token and signal re-login needed
  static Future<void> _handleUnauthorized() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  /// Check if device is online
  static Future<bool> _isOnline() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return !connectivityResult.contains(ConnectivityResult.none);
    } catch (e) {
      // If connectivity check fails, assume we're online and let the request try
      return true;
    }
  }

  /// Determine if an exception is retryable (network-related)
  static bool _isRetryableError(dynamic error) {
    if (error is SocketException) return true;
    if (error is TimeoutException) return true;
    if (error is http.ClientException) return true;
    
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('connection') ||
           errorStr.contains('network') ||
           errorStr.contains('timeout') ||
           errorStr.contains('socket');
  }

  /// Retry wrapper with exponential backoff
  static Future<T> _withRetry<T>(Future<T> Function() operation) async {
    // Check connectivity before attempting
    if (!await _isOnline()) {
      throw Exception('No internet connection. Please check your network and try again.');
    }

    int attempt = 0;

    while (attempt < _maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempt++;

        // Don't retry for non-network errors (e.g., 401, 404, validation errors)
        if (!_isRetryableError(e)) {
          rethrow;
        }

        // If we've exhausted retries, throw the error
        if (attempt >= _maxRetries) {
          break;
        }

        // Wait before retrying with exponential backoff
        await Future.delayed(Duration(seconds: _retryDelays[attempt - 1]));
      }
    }

    // All retries exhausted
    throw Exception('Connection failed after $_maxRetries attempts. Please check your internet connection and try again.');
  }

  static Future<dynamic> get(String endpoint) async {
    return _withRetry(() async {
      try {
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}$endpoint'),
          headers: await _headers(),
        ).timeout(const Duration(seconds: 30));
        return await _handleResponse(response);
      } on TimeoutException {
        throw Exception('Request timed out. Please check your connection.');
      } on SocketException {
        throw Exception('Network error. Please check your connection.');
      }
    });
  }

  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    return _withRetry(() async {
      try {
        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}$endpoint'),
          headers: await _headers(),
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 30));
        return await _handleResponse(response);
      } on TimeoutException {
        throw Exception('Request timed out. Please check your connection.');
      } on SocketException {
        throw Exception('Network error. Please check your connection.');
      }
    });
  }

  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    return _withRetry(() async {
      try {
        final response = await http.put(
          Uri.parse('${ApiConfig.baseUrl}$endpoint'),
          headers: await _headers(),
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 30));
        return await _handleResponse(response);
      } on TimeoutException {
        throw Exception('Request timed out. Please check your connection.');
      } on SocketException {
        throw Exception('Network error. Please check your connection.');
      }
    });
  }

  static Future<dynamic> _handleResponse(http.Response response) async {
    // Handle 401 - token expired or invalid
    if (response.statusCode == 401) {
      await _handleUnauthorized();
      throw Exception('Session expired. Please login again.');
    }

    // Try to parse JSON, handle non-JSON responses gracefully
    dynamic data;
    try {
      data = jsonDecode(response.body);
    } on FormatException {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'message': 'Success'};
      }
      throw Exception('Server error. Please try again later.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      // Handle both 'error' and 'reason' fields from backend
      final msg = data['error'] ?? data['reason'] ?? data['message'] ?? 'Something went wrong';
      throw Exception(msg);
    }
  }
}
