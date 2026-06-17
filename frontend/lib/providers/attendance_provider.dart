import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

// ─── State model ─────────────────────────────────────────────────────────────

class AttendanceState {
  final bool isLoading;
  final String? error;
  final List<dynamic> courses;
  final List<dynamic> sections;
  final List<dynamic> sessions;
  final List<dynamic> attendanceRecords;
  final String? activeCode;
  final bool hasActiveCode;
  final int attendancePercentage;
  final int presentCount;
  final int totalCount;

  const AttendanceState({
    this.isLoading = false,
    this.error,
    this.courses = const [],
    this.sections = const [],
    this.sessions = const [],
    this.attendanceRecords = const [],
    this.activeCode,
    this.hasActiveCode = false,
    this.attendancePercentage = 0,
    this.presentCount = 0,
    this.totalCount = 0,
  });

  AttendanceState copyWith({
    bool? isLoading,
    String? error,
    List<dynamic>? courses,
    List<dynamic>? sections,
    List<dynamic>? sessions,
    List<dynamic>? attendanceRecords,
    String? activeCode,
    bool? hasActiveCode,
    int? attendancePercentage,
    int? presentCount,
    int? totalCount,
    bool clearError = false,
    bool clearCode = false,
  }) {
    return AttendanceState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      courses: courses ?? this.courses,
      sections: sections ?? this.sections,
      sessions: sessions ?? this.sessions,
      attendanceRecords: attendanceRecords ?? this.attendanceRecords,
      activeCode: clearCode ? null : activeCode ?? this.activeCode,
      hasActiveCode: hasActiveCode ?? this.hasActiveCode,
      attendancePercentage: attendancePercentage ?? this.attendancePercentage,
      presentCount: presentCount ?? this.presentCount,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class AttendanceNotifier extends StateNotifier<AttendanceState> {
  AttendanceNotifier() : super(const AttendanceState());

  final _base = ApiConfig.baseUrl;

  // ── STUDENT: load enrolled courses ────────────────────────────────────────
  Future<void> loadStudentCourses(String studId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await http.get(Uri.parse('$_base/courses/student/$studId'));
      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        state = state.copyWith(isLoading: false, courses: body['data']);
      } else {
        state = state.copyWith(isLoading: false, error: body['message']);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Network error: $e');
    }
  }

  // ── STUDENT: get attendance percentage for a course ───────────────────────
  Future<void> loadStudentPercentage(String studId, List<String> sessionIds) async {
    try {
      final ids = sessionIds.join(',');
      final res = await http.get(
        Uri.parse('$_base/attendance/student/$studId/percentage?sessionIds=$ids'),
      );
      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        state = state.copyWith(
          attendancePercentage: body['percentage'],
          presentCount: body['present'],
          totalCount: body['total'],
        );
      }
    } catch (_) {}
  }

  // ── STUDENT: load sessions for a course ───────────────────────────────────
  Future<void> loadStudentSessions(String studId, String courseId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await http.get(
        Uri.parse('$_base/sessions/student/$studId/course/$courseId'),
      );
      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        state = state.copyWith(isLoading: false, sessions: body['data']);
      } else {
        state = state.copyWith(isLoading: false, error: body['message']);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Network error: $e');
    }
  }

  // ── STUDENT: check in ─────────────────────────────────────────────────────
  // Returns a map with 'success', 'reason', 'message'
  Future<Map<String, dynamic>> checkIn({
    required String studId,
    required String sessionId,
    required String code,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/attendance/checkin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'studId': studId,
          'sessionId': sessionId,
          'code': code,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );
      final body = jsonDecode(res.body);
      return {
        'success': body['success'] ?? false,
        'reason': body['reason'] ?? '',
        'message': body['message'] ?? 'Unknown error',
      };
    } catch (e) {
      return {'success': false, 'reason': 'network', 'message': 'Network error: $e'};
    }
  }

  // ── LECTURER: load teaching courses ───────────────────────────────────────
  Future<void> loadLecturerCourses(String lectId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await http.get(Uri.parse('$_base/courses/lecturer/$lectId'));
      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        state = state.copyWith(isLoading: false, courses: body['data']);
      } else {
        state = state.copyWith(isLoading: false, error: body['message']);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Network error: $e');
    }
  }

  // ── LECTURER: load sections for a course ──────────────────────────────────
  Future<void> loadLecturerSections(String lectId, String courseId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await http.get(
        Uri.parse('$_base/sections/lecturer/$lectId/course/$courseId'),
      );
      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        state = state.copyWith(isLoading: false, sections: body['data']);
      } else {
        state = state.copyWith(isLoading: false, error: body['message']);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Network error: $e');
    }
  }

  // ── LECTURER: load sessions for a section ─────────────────────────────────
  Future<void> loadLecturerSessions(String sectionId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await http.get(Uri.parse('$_base/sessions/section/$sectionId'));
      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        state = state.copyWith(isLoading: false, sessions: body['data']);
      } else {
        state = state.copyWith(isLoading: false, error: body['message']);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Network error: $e');
    }
  }

  // ── LECTURER: check if session has active code ────────────────────────────
  Future<void> loadActiveCode(String sessionId) async {
    try {
      final res = await http.get(
        Uri.parse('$_base/attendance/active-code/$sessionId'),
      );
      final body = jsonDecode(res.body);
      state = state.copyWith(
        hasActiveCode: body['hasActiveCode'] ?? false,
        activeCode: body['code'],
      );
    } catch (_) {}
  }

  // ── LECTURER: generate attendance code ────────────────────────────────────
  Future<String?> generateCode(String sessionId) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/attendance/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'sessionId': sessionId}),
      );
      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        state = state.copyWith(activeCode: body['code'], hasActiveCode: true);
        return body['code'];
      }
    } catch (_) {}
    return null;
  }

  // ── LECTURER: terminate code (end class) ──────────────────────────────────
  Future<void> terminateCode(String sessionId) async {
    try {
      await http.post(
        Uri.parse('$_base/attendance/terminate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'sessionId': sessionId}),
      );
      state = state.copyWith(hasActiveCode: false, clearCode: true);
    } catch (_) {}
  }

  // ── LECTURER: get all attendance records for a session ────────────────────
  Future<void> loadSessionAttendance(String sessionId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await http.get(
        Uri.parse('$_base/attendance/session/$sessionId'),
      );
      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        state = state.copyWith(
          isLoading: false,
          attendanceRecords: body['data'],
          presentCount: body['present'],
          totalCount: body['total'],
          attendancePercentage: body['percentage'],
        );
      } else {
        state = state.copyWith(isLoading: false, error: body['message']);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Network error: $e');
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

// ─── Provider ────────────────────────────────────────────────────────────────

final attendanceProvider =
    StateNotifierProvider<AttendanceNotifier, AttendanceState>(
  (ref) => AttendanceNotifier(),
);