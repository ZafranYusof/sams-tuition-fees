import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../config/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/attendance_provider.dart';
import 'StudentAttendance.dart';

class StudentCourses extends ConsumerStatefulWidget {
  const StudentCourses({super.key});

  @override
  ConsumerState<StudentCourses> createState() => _StudentCoursesState();
}

class _StudentCoursesState extends ConsumerState<StudentCourses> {
  static const _navy = Color(0xFF0B1B2C);
  static const _brass = Color(0xFFC9A961);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      final studId = user?['_id'] ?? '';
      ref.read(attendanceProvider.notifier).loadStudentCourses(studId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;
    final state = ref.watch(attendanceProvider);
    final user = ref.watch(authProvider).user;
    final studName = user?['name'] ?? 'Student';

    return Scaffold(
      backgroundColor: isDark ? null : const Color(0xFFF7F5F0),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Container(
              color: _navy,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(width: 22, height: 1, color: _brass),
                    const SizedBox(width: 10),
                    Text(
                      'ATTENDANCE',
                      style: GoogleFonts.inter(
                        color: _brass,
                        fontSize: 10.5,
                        letterSpacing: 2.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Text(
                    'My Courses',
                    style: GoogleFonts.fraunces(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    studName,
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────────────────────────
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.error != null
                      ? _ErrorView(message: state.error!)
                      : state.courses.isEmpty
                          ? _EmptyView()
                          : ListView.separated(
                              padding: const EdgeInsets.all(20),
                              itemCount: state.courses.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, i) {
                                final course = state.courses[i];
                                return _CourseCard(
                                  course: course,
                                  isDark: isDark,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => StudentAttendance(
                                        course: course,
                                      ),
                                    ),
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

// ─── Course card ─────────────────────────────────────────────────────────────

class _CourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  final bool isDark;
  final VoidCallback onTap;

  const _CourseCard({
    required this.course,
    required this.isDark,
    required this.onTap,
  });

  static const _brass = Color(0xFFC9A961);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: t.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.dividerColor),
        ),
        child: Row(
          children: [
            // Course code pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _brass.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _brass.withOpacity(0.3)),
              ),
              child: Text(
                course['courseCode'] ?? '',
                style: GoogleFonts.inter(
                  color: _brass,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course['courseName'] ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: t.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${course['creditHours'] ?? ''} credit hours',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: t.textTheme.bodyMedium?.color?.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Iconsax.arrow_right_3,
              size: 16,
              color: t.textTheme.bodyMedium?.color?.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: SAMsTheme.error,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Iconsax.book,
            size: 48,
            color: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.color
                ?.withOpacity(0.2),
          ),
          const SizedBox(height: 12),
          Text(
            'No courses enrolled',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}