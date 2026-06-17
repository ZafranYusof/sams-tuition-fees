import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../config/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../../services/location_service.dart';

class StudentAttendance extends ConsumerStatefulWidget {
  final Map<String, dynamic> course;
  const StudentAttendance({super.key, required this.course});

  @override
  ConsumerState<StudentAttendance> createState() => _StudentAttendanceState();
}

class _StudentAttendanceState extends ConsumerState<StudentAttendance> {
  static const _navy = Color(0xFF0B1B2C);
  static const _brass = Color(0xFFC9A961);

  final _codeController = TextEditingController();
  bool _isCheckingIn = false;
  double? _currentLat;
  double? _currentLng;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      final studId = user?['_id'] ?? '';
      final courseId = widget.course['_id'] ?? '';
      ref.read(attendanceProvider.notifier).loadStudentSessions(studId, courseId);
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  // ── Step 1: get GPS, then show code dialog ─────────────────────────────────
  Future<void> _startCheckIn() async {
    setState(() => _isCheckingIn = true);

    try {
      final position = await LocationService.getCurrentPosition();
      setState(() {
        _currentLat = position.latitude;
        _currentLng = position.longitude;
        _isCheckingIn = false;
      });
      _showCodeDialog();
    } on LocationException catch (e) {
      setState(() => _isCheckingIn = false);
      if (!mounted) return;
      switch (e.reason) {
        case LocationFailReason.serviceDisabled:
          _showLocationDialog(
            title: 'GPS is disabled',
            message: 'Please enable GPS on your device to check in.',
            buttonLabel: 'Open Settings',
            onButton: () {
              Navigator.pop(context);
              LocationService.openSettings();
            },
          );
          break;
        case LocationFailReason.permissionDenied:
        case LocationFailReason.permissionPermanentlyDenied:
          _showLocationDialog(
            title: 'Location permission needed',
            message: e.message,
            buttonLabel: 'Open Settings',
            onButton: () {
              Navigator.pop(context);
              LocationService.openSettings();
            },
          );
          break;
      }
    }
  }

  // ── Step 2: user enters code, we submit ───────────────────────────────────
  Future<void> _submitCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    final user = ref.read(authProvider).user;
    final studId = user?['_id'] ?? '';

    // Get the current active session
    final sessions = ref.read(attendanceProvider).sessions;
    final activeSession = sessions.firstWhere(
      (s) => s['isActive'] == true,
      orElse: () => null,
    );
    if (activeSession == null) {
      Navigator.pop(context);
      _showResultDialog(success: false, message: 'No active session found.');
      return;
    }

    setState(() => _isCheckingIn = true);

    final result = await ref.read(attendanceProvider.notifier).checkIn(
          studId: studId,
          sessionId: activeSession['_id'],
          code: code,
          latitude: _currentLat!,
          longitude: _currentLng!,
        );

    setState(() => _isCheckingIn = false);

    if (!mounted) return;
    Navigator.pop(context); // close code dialog

    if (result['success'] == true) {
      _showResultDialog(success: true, message: 'Attendance recorded!');
      // Reload sessions to update the list
      ref.read(attendanceProvider.notifier).loadStudentSessions(studId, widget.course['_id']);
    } else {
      switch (result['reason']) {
        case 'invalid_code':
          _showResultDialog(success: false, message: 'Incorrect code. Please try again.');
          break;
        case 'outside_boundary':
          _showOutsideBoundaryDialog();
          break;
        default:
          _showResultDialog(success: false, message: result['message']);
      }
    }
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  void _showCodeDialog() {
    _codeController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Enter Class Code',
          style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w400),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show current GPS coordinates
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _brass.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _brass.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.location, size: 14, color: _brass),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lat: ${_currentLat?.toStringAsFixed(6)}\nLng: ${_currentLng?.toStringAsFixed(6)}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: _brass,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'CODE',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _codeController,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 6,
              ),
              decoration: InputDecoration(
                hintText: '······',
                hintStyle: GoogleFonts.inter(
                  fontSize: 22,
                  letterSpacing: 6,
                  color: Colors.grey.withOpacity(0.3),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          StatefulBuilder(
            builder: (ctx, setBtn) => ElevatedButton(
              onPressed: _isCheckingIn ? null : _submitCode,
              style: ElevatedButton.styleFrom(backgroundColor: _navy),
              child: _isCheckingIn
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Check In',
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationDialog({
    required String title,
    required String message,
    required String buttonLabel,
    required VoidCallback onButton,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Iconsax.location_slash, color: _brass, size: 20),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        content: Text(message, style: GoogleFonts.inter(fontSize: 14, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Dismiss', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: onButton,
            style: ElevatedButton.styleFrom(backgroundColor: _navy),
            child: Text(buttonLabel, style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showOutsideBoundaryDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Iconsax.location_slash, color: SAMsTheme.error, size: 20),
            const SizedBox(width: 10),
            Text(
              'Outside Campus',
              style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are outside the UMPSA campus boundary.',
              style: GoogleFonts.inter(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: SAMsTheme.error.withOpacity(0.07),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.location, size: 13, color: SAMsTheme.error),
                  const SizedBox(width: 8),
                  Text(
                    'Lat: ${_currentLat?.toStringAsFixed(6)}\nLng: ${_currentLng?.toStringAsFixed(6)}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: SAMsTheme.error,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: _navy),
            child: Text('OK', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showResultDialog({required bool success, required String message}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              success ? Iconsax.tick_circle : Iconsax.close_circle,
              color: success ? Colors.green : SAMsTheme.error,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              success ? 'Checked In!' : 'Check-in Failed',
              style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        content: Text(message, style: GoogleFonts.inter(fontSize: 14, height: 1.5)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: success ? _navy : SAMsTheme.error,
            ),
            child: Text('OK', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;
    final state = ref.watch(attendanceProvider);
    final courseName = widget.course['courseName'] ?? '';
    final courseCode = widget.course['courseCode'] ?? '';

    return Scaffold(
      backgroundColor: isDark ? null : const Color(0xFFF7F5F0),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Container(
              color: _navy,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Iconsax.arrow_left, color: Colors.white, size: 22),
                  ),
                  const SizedBox(height: 16),
                  Row(children: [
                    Container(width: 22, height: 1, color: _brass),
                    const SizedBox(width: 10),
                    Text(
                      courseCode,
                      style: GoogleFonts.inter(
                        color: _brass,
                        fontSize: 10.5,
                        letterSpacing: 2.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    courseName,
                    style: GoogleFonts.fraunces(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Attendance percentage bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Attendance',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${state.attendancePercentage}%  (${state.presentCount}/${state.totalCount})',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: state.attendancePercentage / 100,
                      backgroundColor: Colors.white.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        state.attendancePercentage >= 80
                            ? Colors.green
                            : state.attendancePercentage >= 60
                                ? _brass
                                : SAMsTheme.error,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),

            // ── Session list ──────────────────────────────────────────────
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.sessions.isEmpty
                      ? Center(
                          child: Text(
                            'No sessions found',
                            style: GoogleFonts.inter(
                              color: t.textTheme.bodyMedium?.color?.withOpacity(0.4),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: state.sessions.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final session = state.sessions[i];
                            final isActive = session['isActive'] == true;
                            final status = session['attendanceStatus'] ?? 'Absent';
                            final isPresent = status == 'Present';

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: t.colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isActive
                                      ? _brass.withOpacity(0.4)
                                      : t.dividerColor,
                                  width: isActive ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Status indicator
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isActive
                                          ? _brass
                                          : isPresent
                                              ? Colors.green
                                              : Colors.red.withOpacity(0.6),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          session['sessionDate'] ?? '',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: t.colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          isActive ? 'Session active' : status,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: isActive
                                                ? _brass
                                                : isPresent
                                                    ? Colors.green
                                                    : t.textTheme.bodyMedium?.color
                                                        ?.withOpacity(0.4),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isActive)
                                    ElevatedButton(
                                      onPressed: _isCheckingIn ? null : _startCheckIn,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _navy,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: _isCheckingIn
                                          ? const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 1.5,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Text(
                                              'Check In',
                                              style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}