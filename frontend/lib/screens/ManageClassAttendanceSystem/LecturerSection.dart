import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../providers/attendance_provider.dart';
import 'LecturerAttendance.dart';

class LecturerSection extends ConsumerStatefulWidget {
  final Map<String, dynamic> course;
  final String lectId;

  const LecturerSection({
    super.key,
    required this.course,
    required this.lectId,
  });

  @override
  ConsumerState<LecturerSection> createState() => _LecturerSectionState();
}

class _LecturerSectionState extends ConsumerState<LecturerSection> {
  static const _navy = Color(0xFF0B1B2C);
  static const _brass = Color(0xFFC9A961);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(attendanceProvider.notifier).loadLecturerSections(
            widget.lectId,
            widget.course['_id'] ?? '',
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;
    final state = ref.watch(attendanceProvider);
    final courseCode = widget.course['courseCode'] ?? '';
    final courseName = widget.course['courseName'] ?? '';

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
                  const SizedBox(height: 4),
                  Text(
                    'Select a section',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // ── Section list ──────────────────────────────────────────────
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.sections.isEmpty
                      ? Center(
                          child: Text(
                            'No sections found.',
                            style: GoogleFonts.inter(
                              color: t.textTheme.bodyMedium?.color?.withOpacity(0.4),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: state.sections.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final section = state.sections[i];
                            return GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LecturerAttendance(
                                    section: section,
                                    course: widget.course,
                                  ),
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: t.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: t.dividerColor),
                                ),
                                child: Row(
                                  children: [
                                    // Section icon
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: _navy.withOpacity(0.07),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Iconsax.people,
                                          size: 20,
                                          color: _navy.withOpacity(0.6),
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
                                            'Section ${section['sectionName'] ?? section['sectionCode'] ?? ''}',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: t.colorScheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${section['studentCount'] ?? ''} students enrolled',
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
                                    Icon(
                                      Iconsax.arrow_right_3,
                                      size: 16,
                                      color: t.textTheme.bodyMedium?.color
                                          ?.withOpacity(0.3),
                                    ),
                                  ],
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