import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../providers/attendance_provider.dart';
import 'LecturerClass.dart';

class LecturerAttendance extends ConsumerStatefulWidget {
  final Map<String, dynamic> section;
  final Map<String, dynamic> course;

  const LecturerAttendance({
    super.key,
    required this.section,
    required this.course,
  });

  @override
  ConsumerState<LecturerAttendance> createState() => _LecturerAttendanceState();
}

class _LecturerAttendanceState extends ConsumerState<LecturerAttendance> {
  static const _navy = Color(0xFF0B1B2C);
  static const _brass = Color(0xFFC9A961);

  String? _selectedSessionId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sectionId = widget.section['_id'] ?? '';
      ref.read(attendanceProvider.notifier).loadLecturerSessions(sectionId);
    });
  }

  Future<void> _generateCode(String sessionId) async {
    final code = await ref.read(attendanceProvider.notifier).generateCode(sessionId);
    if (code != null && mounted) {
      _showCodeDialog(code);
    }
  }

  Future<void> _endClass(String sessionId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'End Class?',
          style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w400),
        ),
        content: Text(
          'This will terminate the attendance code. Students will no longer be able to check in.',
          style: GoogleFonts.inter(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: Text('End Class', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(attendanceProvider.notifier).terminateCode(sessionId);
    }
  }

  void _showCodeDialog(String code) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Attendance Code',
          style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w400),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Share this code with your students:',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            // Big code display
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
              decoration: BoxDecoration(
                color: _navy,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                code,
                style: GoogleFonts.inter(
                  color: _brass,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 8,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Copy button
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Code copied to clipboard',
                      style: GoogleFonts.inter(fontSize: 13),
                    ),
                    backgroundColor: _navy,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.copy, size: 14, color: _brass),
                  const SizedBox(width: 6),
                  Text(
                    'Copy code',
                    style: GoogleFonts.inter(
                      color: _brass,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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
            child: Text('Close', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;
    final state = ref.watch(attendanceProvider);
    final courseCode = widget.course['courseCode'] ?? '';
    final sectionName = widget.section['sectionName'] ?? widget.section['sectionCode'] ?? '';

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
                      '$courseCode · SECTION $sectionName',
                      style: GoogleFonts.inter(
                        color: _brass,
                        fontSize: 10.5,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    'Sessions',
                    style: GoogleFonts.fraunces(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w400,
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
                            'No sessions found.',
                            style: GoogleFonts.inter(
                              color: t.textTheme.bodyMedium?.color?.withOpacity(0.4),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: state.sessions.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final session = state.sessions[i];
                            final sessionId = session['_id'] ?? '';
                            final isToday = session['isToday'] == true;
                            final hasCode = session['hasActiveCode'] == true;

                            return Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: t.colorScheme.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isToday
                                      ? _brass.withOpacity(0.4)
                                      : t.dividerColor,
                                  width: isToday ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              session['sessionDate'] ?? '',
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: t.colorScheme.onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              session['sessionTime'] ?? '',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: t.textTheme.bodyMedium
                                                    ?.color
                                                    ?.withOpacity(0.5),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Today badge
                                      if (isToday)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _brass.withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'TODAY',
                                            style: GoogleFonts.inter(
                                              color: _brass,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),

                                  // Buttons only for today's session
                                  if (isToday) ...[
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        // Generate / View code button
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => _generateCode(sessionId),
                                            icon: const Icon(
                                              Iconsax.key,
                                              size: 15,
                                              color: Colors.white,
                                            ),
                                            label: Text(
                                              hasCode ? 'View Code' : 'Generate Code',
                                              style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: _navy,
                                              padding: const EdgeInsets.symmetric(
                                                vertical: 10,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (hasCode) ...[
                                          const SizedBox(width: 10),
                                          // End class button
                                          OutlinedButton.icon(
                                            onPressed: () => _endClass(sessionId),
                                            icon: Icon(
                                              Iconsax.stop_circle,
                                              size: 15,
                                              color: Colors.red.shade600,
                                            ),
                                            label: Text(
                                              'End Class',
                                              style: GoogleFonts.inter(
                                                color: Colors.red.shade600,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(
                                                color: Colors.red.shade300,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 10,
                                                horizontal: 12,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // View students button
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => LecturerClass(
                                              session: session,
                                              course: widget.course,
                                            ),
                                          ),
                                        ),
                                        icon: Icon(
                                          Iconsax.people,
                                          size: 15,
                                          color: t.colorScheme.onSurface
                                              .withOpacity(0.6),
                                        ),
                                        label: Text(
                                          'View Students',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    // Past session: just a view button
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton(
                                        onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => LecturerClass(
                                              session: session,
                                              course: widget.course,
                                            ),
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: Text(
                                          'View Attendance',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
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