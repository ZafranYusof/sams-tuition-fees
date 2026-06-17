import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../providers/attendance_provider.dart';

class LecturerClass extends ConsumerStatefulWidget {
  final Map<String, dynamic> session;
  final Map<String, dynamic> course;

  const LecturerClass({
    super.key,
    required this.session,
    required this.course,
  });

  @override
  ConsumerState<LecturerClass> createState() => _LecturerClassState();
}

class _LecturerClassState extends ConsumerState<LecturerClass> {
  static const _navy = Color(0xFF0B1B2C);
  static const _brass = Color(0xFFC9A961);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sessionId = widget.session['_id'] ?? '';
      ref.read(attendanceProvider.notifier).loadSessionAttendance(sessionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;
    final state = ref.watch(attendanceProvider);
    final courseCode = widget.course['courseCode'] ?? '';
    final sessionDate = widget.session['sessionDate'] ?? '';
    final records = state.attendanceRecords;

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
                    sessionDate,
                    style: GoogleFonts.fraunces(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Attendance summary row
                  Row(
                    children: [
                      _SummaryPill(
                        label: 'Present',
                        value: '${state.presentCount}',
                        color: Colors.green,
                      ),
                      const SizedBox(width: 10),
                      _SummaryPill(
                        label: 'Absent',
                        value: '${state.totalCount - state.presentCount}',
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(width: 10),
                      _SummaryPill(
                        label: 'Total',
                        value: '${state.totalCount}',
                        color: Colors.white.withOpacity(0.6),
                      ),
                      const Spacer(),
                      Text(
                        '${state.attendancePercentage}%',
                        style: GoogleFonts.fraunces(
                          color: _brass,
                          fontSize: 26,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Student list ──────────────────────────────────────────────
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : records.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Iconsax.people,
                                size: 48,
                                color: t.textTheme.bodyMedium?.color
                                    ?.withOpacity(0.2),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No students yet',
                                style: GoogleFonts.inter(
                                  color: t.textTheme.bodyMedium?.color
                                      ?.withOpacity(0.4),
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: records.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final record = records[i];
                            final isPresent = record['status'] == 'Present';
                            final checkInTime = record['checkInTime'];

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: t.colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: t.dividerColor),
                              ),
                              child: Row(
                                children: [
                                  // Avatar circle
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: isPresent
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.red.withOpacity(0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        (record['studName'] ?? record['studId'] ?? '?')
                                            .toString()
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: isPresent
                                              ? Colors.green.shade700
                                              : Colors.red.shade400,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          record['studName'] ?? record['studId'] ?? 'Unknown',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: t.colorScheme.onSurface,
                                          ),
                                        ),
                                        if (checkInTime != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'Checked in at $checkInTime',
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              color: t.textTheme.bodyMedium
                                                  ?.color
                                                  ?.withOpacity(0.45),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  // Status badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isPresent
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.red.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isPresent ? 'Present' : 'Absent',
                                      style: GoogleFonts.inter(
                                        color: isPresent
                                            ? Colors.green.shade700
                                            : Colors.red.shade500,
                                        fontSize: 11,
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

class _SummaryPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.4),
            fontSize: 10,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}