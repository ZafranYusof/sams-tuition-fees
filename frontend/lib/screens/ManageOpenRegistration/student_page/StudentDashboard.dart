import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/api_service.dart';
import '../../../widgets/glass_card.dart';
import 'SubjectRegistration.dart';

class StudentDashboard extends ConsumerStatefulWidget {
  const StudentDashboard({super.key});

  @override
  ConsumerState<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends ConsumerState<StudentDashboard> {
  List<Map<String, dynamic>> _enrollments = [];
  Map<String, dynamic>? _session;
  bool _loading = true;
  int _totalCredits = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.get('/registration/my'),
        ApiService.get('/registration/session').catchError((_) => null),
      ]);

      final enrollData = results[0];
      final sessionData = results[1];

      final List<dynamic> enrollList = enrollData is List ? enrollData : [];
      final enrollments = enrollList.map((e) => Map<String, dynamic>.from(e)).toList();

      int credits = 0;
      for (final e in enrollments) {
        final course = e['course'];
        if (course is Map) {
          credits += ((course['credits'] ?? 0) as num).toInt();
        }
      }

      if (!mounted) return;
      setState(() {
        _enrollments = enrollments;
        _totalCredits = credits;
        _session = (sessionData is Map && sessionData.isNotEmpty) ? Map<String, dynamic>.from(sessionData) : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: t.scaffoldBackgroundColor,
      body: SafeArea(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: SAMsTheme.accent))
            : RefreshIndicator(
                onRefresh: _loadData,
                color: SAMsTheme.accent,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ── header ──
                    _header(t),
                    const SizedBox(height: 24),

                    // ── registration status ──
                    _registrationStatusCard(t),
                    const SizedBox(height: 20),

                    // ── registered subjects ──
                    _sectionTitle(t, 'REGISTERED SUBJECTS'),
                    const SizedBox(height: 10),
                    if (_enrollments.isEmpty)
                      _emptyCard(t, 'No registered subjects yet.')
                    else
                      ..._enrollments.map((e) => _subjectCard(t, e)),

                    // ── total credits ──
                    if (_enrollments.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _totalCreditsRow(t),
                    ],

                    const SizedBox(height: 24),

                    // ── register button ──
                    _registerButton(t),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
      ),
    );
  }

  // ── header ──────────────────────────────────────────
  Widget _header(ThemeData t) {
    return Row(
      children: [
        Container(width: 12, height: 2, color: SAMsTheme.accent),
        const SizedBox(width: 8),
        Text(
          'UMPSA • SAMs',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.0,
            color: t.textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  // ── section title ───────────────────────────────────
  Widget _sectionTitle(ThemeData t, String text) {
    return Row(
      children: [
        Container(width: 18, height: 1, color: SAMsTheme.accent),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Inter',
            color: t.textTheme.bodySmall?.color,
            fontSize: 10.5,
            letterSpacing: 2.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── registration status card ────────────────────────
  Widget _registrationStatusCard(ThemeData t) {
    final isOpen = _session != null;
    final sessionName = _session?['sessionName'] ?? '';
    final startDate = _session?['startDate'];
    final endDate = _session?['endDate'];

    String dateRange = '';
    if (startDate != null && endDate != null) {
      final start = DateTime.tryParse(startDate.toString());
      final end = DateTime.tryParse(endDate.toString());
      if (start != null && end != null) {
        dateRange = '${DateFormat('d MMM').format(start)} - ${DateFormat('d MMM yyyy').format(end)}';
      }
    }

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isOpen
                    ? SAMsTheme.success.withValues(alpha: 0.12)
                    : SAMsTheme.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isOpen ? Iconsax.unlock : Iconsax.lock,
                color: isOpen ? SAMsTheme.success : SAMsTheme.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            // text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Registration ',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: t.colorScheme.onSurface,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isOpen
                              ? SAMsTheme.success.withValues(alpha: 0.15)
                              : SAMsTheme.error.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isOpen ? 'Open' : 'Closed',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isOpen ? SAMsTheme.success : SAMsTheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (sessionName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      sessionName,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: t.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                  if (dateRange.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      dateRange,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: t.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── subject card ────────────────────────────────────
  Widget _subjectCard(ThemeData t, Map<String, dynamic> enrollment) {
    final course = enrollment['course'];
    final courseId = course is Map ? (course['courseId'] ?? '') : '';
    final courseName = course is Map ? (course['courseName'] ?? 'Unknown') : 'Unknown';
    final credits = course is Map ? ((course['credits'] ?? 0) as num).toInt() : 0;
    final status = enrollment['status'] ?? 'active';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // course code tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: SAMsTheme.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  courseId,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: SAMsTheme.accent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // name + credits
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      courseName,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: t.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$credits hrs',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: t.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              // status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: SAMsTheme.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Accepted',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: SAMsTheme.success,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── total credits row ───────────────────────────────
  Widget _totalCreditsRow(ThemeData t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Credits',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: t.colorScheme.onSurface,
            ),
          ),
          Text(
            '$_totalCredits hrs',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: SAMsTheme.accent,
            ),
          ),
        ],
      ),
    );
  }

  // ── empty card ──────────────────────────────────────
  Widget _emptyCard(ThemeData t, String message) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            message,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: t.textTheme.bodySmall?.color,
            ),
          ),
        ),
      ),
    );
  }

  // ── register button ─────────────────────────────────
  Widget _registerButton(ThemeData t) {
    final isOpen = _session != null;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          if (!isOpen) {
            _showClosedDialog();
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SubjectRegistration()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isOpen ? SAMsTheme.accent : t.dividerColor,
          foregroundColor: isOpen ? Colors.white : t.textTheme.bodySmall?.color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isOpen ? Iconsax.add_square : Iconsax.lock, size: 18),
            const SizedBox(width: 8),
            Text(
              isOpen ? 'Register New Subject' : 'Registration Closed',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── closed dialog ───────────────────────────────────
  void _showClosedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Row(
          children: [
            Icon(Iconsax.lock, color: SAMsTheme.error, size: 20),
            const SizedBox(width: 8),
            const Text('Registration Closed', style: TextStyle(fontFamily: 'Inter', fontSize: 16)),
          ],
        ),
        content: Text(
          'Registration is currently closed. Please check back during the next registration period.',
          style: TextStyle(fontFamily: 'Inter', color: Theme.of(context).textTheme.bodySmall?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: SAMsTheme.accent, fontFamily: 'Inter')),
          ),
        ],
      ),
    );
  }
}
