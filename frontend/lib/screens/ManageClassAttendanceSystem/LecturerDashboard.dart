import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/attendance_provider.dart';
import 'LecturerCourses.dart';

class LecturerDashboard extends ConsumerStatefulWidget {
  const LecturerDashboard({super.key});

  @override
  ConsumerState<LecturerDashboard> createState() => _LecturerDashboardState();
}

class _LecturerDashboardState extends ConsumerState<LecturerDashboard> {
  static const _navy = Color(0xFF0B1B2C);
  static const _brass = Color(0xFFC9A961);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      final lectId = user?['_id'] ?? '';
      ref.read(attendanceProvider.notifier).loadLecturerCourses(lectId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;
    final state = ref.watch(attendanceProvider);
    final user = ref.watch(authProvider).user;
    final lectName = user?['name'] ?? 'Lecturer';

    return Scaffold(
      backgroundColor: isDark ? null : const Color(0xFFF7F5F0),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Container(
                color: _navy,
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(width: 22, height: 1, color: _brass),
                      const SizedBox(width: 10),
                      Text(
                        'LECTURER PORTAL',
                        style: GoogleFonts.inter(
                          color: _brass,
                          fontSize: 10.5,
                          letterSpacing: 2.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 14),
                    Text(
                      'Welcome back,',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lectName,
                      style: GoogleFonts.fraunces(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Quick stats row
                    Row(
                      children: [
                        _StatChip(
                          label: 'Courses',
                          value: '${state.courses.length}',
                        ),
                        const SizedBox(width: 12),
                        _StatChip(
                          label: 'Sessions',
                          value: '${state.sessions.length}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Section label ────────────────────────────────────
                    Row(children: [
                      Container(width: 22, height: 1, color: _brass),
                      const SizedBox(width: 10),
                      Text(
                        'QUICK ACCESS',
                        style: GoogleFonts.inter(
                          color: t.textTheme.bodyMedium?.color?.withOpacity(0.5),
                          fontSize: 10.5,
                          letterSpacing: 2.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),

                    // ── Manage Attendance card ───────────────────────────
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LecturerCourses(),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _navy,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _brass.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Iconsax.calendar_tick,
                                color: _brass,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Manage Attendance',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Generate codes, view student check-ins',
                                    style: GoogleFonts.inter(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Iconsax.arrow_right_3,
                              color: _brass,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Today's courses section ──────────────────────────
                    Row(children: [
                      Container(width: 22, height: 1, color: _brass),
                      const SizedBox(width: 10),
                      Text(
                        'MY COURSES',
                        style: GoogleFonts.inter(
                          color: t.textTheme.bodyMedium?.color?.withOpacity(0.5),
                          fontSize: 10.5,
                          letterSpacing: 2.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 14),

                    if (state.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (state.courses.isEmpty)
                      Text(
                        'No courses assigned.',
                        style: GoogleFonts.inter(
                          color: t.textTheme.bodyMedium?.color?.withOpacity(0.4),
                          fontSize: 14,
                        ),
                      )
                    else
                      ...state.courses.map((course) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: t.colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: t.dividerColor),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _brass.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      course['courseCode'] ?? '',
                                      style: GoogleFonts.inter(
                                        color: _brass,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      course['courseName'] ?? '',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: t.colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  static const _brass = Color(0xFFC9A961);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.fraunces(
              color: _brass,
              fontSize: 22,
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}