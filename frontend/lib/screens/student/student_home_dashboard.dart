import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../config/theme.dart';
import '../../../services/api_service.dart';
import '../../../widgets/premium_widgets.dart';
import '../../../widgets/pressable_card.dart';
import '../../../widgets/empty_state.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  STUDENT HOME DASHBOARD
//  Integrates: Fees · Registration · Activities · Attendance
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class StudentHomeDashboard extends StatefulWidget {
  const StudentHomeDashboard({super.key});

  @override
  State<StudentHomeDashboard> createState() => _StudentHomeDashboardState();
}

class _StudentHomeDashboardState extends State<StudentHomeDashboard>
    with TickerProviderStateMixin {
  // ── Animation ──────────────────────────────────────────────────────────
  late AnimationController _stagger;
  late Animation<double> _headerAnim;
  late Animation<double> _modulesAnim;
  late Animation<double> _statsAnim;
  late Animation<double> _upcomingAnim;
  late Animation<double> _recentAnim;

  // ── State ──────────────────────────────────────────────────────────────
  bool _loading = true;
  bool _refreshing = false;

  // Student info
  String _studentName = 'Student';
  String _studentId = '—';

  // Fees
  double _outstandingBalance = 0;
  String _feesStatus = 'active'; // active | warning | restricted

  // Registration
  int _enrolledCourses = 0;
  String _registrationStatus = 'Enrolled';

  // Activities
  int _upcomingActivities = 0;
  int _creditHoursEarned = 0;

  // Attendance
  double _attendanceRate = 0;
  int _sessionsAttended = 0;
  int _sessionsTotal = 0;

  // Upcoming items (combined timeline)
  List<Map<String, dynamic>> _upcomingItems = [];

  // Recent activity
  List<Map<String, dynamic>> _recentActivity = [];

  // ── Module accent colours ──────────────────────────────────────────────
  static const Color _feesColor = Color(0xFF9C6ADE); // purple
  static const Color _regColor = Color(0xFF5C9CE6); // blue
  static const Color _actColor = Color(0xFF6FB58A); // green
  static const Color _attColor = Color(0xFFE0A458); // orange

  // ──────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadData();
  }

  void _initAnimations() {
    _stagger = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _headerAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _stagger,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOutCubic),
      ),
    );
    _modulesAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _stagger,
        curve: const Interval(0.1, 0.45, curve: Curves.easeOutCubic),
      ),
    );
    _statsAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _stagger,
        curve: const Interval(0.3, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    _upcomingAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _stagger,
        curve: const Interval(0.45, 0.75, curve: Curves.easeOutCubic),
      ),
    );
    _recentAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _stagger,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
      ),
    );
  }

  // ── Data loading ──────────────────────────────────────────────────────
  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      final results = await Future.wait([
        ApiService.get('/fees').catchError((_) => null),
        ApiService.get('/registration/my').catchError((_) => null),
        ApiService.get('/activities/registrations/my').catchError((_) => null),
        ApiService.get('/attendance/student/me').catchError((_) => null),
      ]);

      _parseFees(results[0]);
      _parseRegistration(results[1]);
      _parseActivities(results[2]);
      _parseAttendance(results[3]);
      _buildUpcomingItems();
      _loadRecentActivity();
    } catch (_) {
      // Graceful fallback — show zeros
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        _stagger.forward(from: 0);
      }
    }
  }

  // ── Parsers ───────────────────────────────────────────────────────────
  void _parseFees(dynamic data) {
    if (data == null) return;
    final fees = data is Map ? data : {};
    setState(() {
      _studentName = fees['studentName'] ?? _studentName;
      _studentId = fees['studentId'] ?? _studentId;
      _outstandingBalance =
          (fees['outstandingBalance'] ?? fees['balance'] ?? 0).toDouble();
      final status = (fees['status'] ?? 'active').toString().toLowerCase();
      if (status == 'restricted' || status == 'blocked') {
        _feesStatus = 'restricted';
      } else if (status == 'warning' || _outstandingBalance > 1000) {
        _feesStatus = 'warning';
      } else {
        _feesStatus = 'active';
      }
    });
  }

  void _parseRegistration(dynamic data) {
    if (data == null) return;
    final reg = data is Map ? data : {};
    final courses = (reg['courses'] ?? reg['enrollments'] ?? []) as List;
    setState(() {
      _enrolledCourses = reg['totalEnrolled'] ?? courses.length;
      _registrationStatus =
          (reg['status'] ?? 'Enrolled').toString();
    });
  }

  void _parseActivities(dynamic data) {
    if (data == null) return;
    final act = data is Map ? data : {};
    final registrations = (act['registrations'] ?? act['data'] ?? []) as List;
    setState(() {
      _upcomingActivities =
          act['upcomingCount'] ?? registrations.length;
      _creditHoursEarned = act['creditHours'] ?? 0;
    });
  }

  void _parseAttendance(dynamic data) {
    if (data == null) return;
    final att = data is Map ? data : {};
    setState(() {
      _sessionsAttended = att['attended'] ?? 0;
      _sessionsTotal = att['total'] ?? 0;
      _attendanceRate = (att['rate'] ?? (_sessionsTotal > 0
              ? (_sessionsAttended / _sessionsTotal * 100)
              : 0))
          .toDouble();
    });
  }

  void _buildUpcomingItems() {
    final items = <Map<String, dynamic>>[];

    // Simulated upcoming items — in production these come from the APIs
    if (_sessionsTotal > 0) {
      items.add({
        'icon': Iconsax.tick_circle,
        'color': _attColor,
        'title': 'Next Class Session',
        'subtitle': 'CSC3123 — Software Engineering',
        'time': 'Tomorrow, 09:00 AM',
        'type': 'attendance',
      });
    }
    if (_upcomingActivities > 0) {
      items.add({
        'icon': Iconsax.cup,
        'color': _actColor,
        'title': 'Upcoming Activity',
        'subtitle': 'Programming Workshop',
        'time': 'Wed, 2:00 PM',
        'type': 'activity',
      });
    }
    if (_outstandingBalance > 0) {
      items.add({
        'icon': Iconsax.calendar,
        'color': _feesColor,
        'title': 'Payment Due',
        'subtitle': 'RM ${_outstandingBalance.toStringAsFixed(2)}',
        'time': '30 Jun 2026',
        'type': 'fees',
      });
    }

    setState(() => _upcomingItems = items.take(3).toList());
  }

  void _loadRecentActivity() {
    setState(() {
      _recentActivity = [
        {
          'icon': Iconsax.money_send,
          'color': _feesColor,
          'title': 'Tuition payment processed',
          'subtitle': 'RM 1,250.00 • Fees',
          'time': '2 hours ago',
        },
        {
          'icon': Iconsax.document_text,
          'color': _regColor,
          'title': 'Enrolled in CSC4013',
          'subtitle': 'Machine Learning • Registration',
          'time': 'Yesterday',
        },
        {
          'icon': Iconsax.cup,
          'color': _actColor,
          'title': 'Registered for Hackathon',
          'subtitle': 'TechFest 2026 • Activities',
          'time': '2 days ago',
        },
        {
          'icon': Iconsax.tick_circle,
          'color': _attColor,
          'title': 'Checked in to CSC3123',
          'subtitle': 'Lecture 12 • Attendance',
          'time': '3 days ago',
        },
        {
          'icon': Iconsax.document_upload,
          'color': _regColor,
          'title': 'Added MAT2013 to waitlist',
          'subtitle': 'Linear Algebra • Registration',
          'time': '5 days ago',
        },
      ];
    });
  }

  // ── Refresh ───────────────────────────────────────────────────────────
  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    setState(() => _refreshing = true);
    _stagger.reset();
    await _loadData();
    setState(() => _refreshing = false);
  }

  // ── Helpers ───────────────────────────────────────────────────────────
  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'restricted':
        return SAMsTheme.error;
      case 'warning':
        return SAMsTheme.warning;
      default:
        return SAMsTheme.success;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'restricted':
        return 'Restricted';
      case 'warning':
        return 'Warning';
      default:
        return 'Active';
    }
  }

  // ──────────────────────────────────────────────────────────────────────
  //  BUILD
  // ──────────────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _stagger.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SAMsTheme.background,
      body: SafeArea(
        child: Skeletonizer(
          enabled: _loading,
          child: PremiumRefreshIndicator(
            onRefresh: _onRefresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildModuleCards()),
                SliverToBoxAdapter(child: _buildQuickStats()),
                SliverToBoxAdapter(child: _buildUpcoming()),
                SliverToBoxAdapter(child: _buildRecentActivity()),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  1. HEADER
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _headerAnim,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _headerAnim.value)),
          child: Opacity(
            opacity: _headerAnim.value,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  // Avatar circle
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          SAMsTheme.primary,
                          SAMsTheme.primary.withValues(alpha:0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _studentName.isNotEmpty
                            ? _studentName[0].toUpperCase()
                            : 'S',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: SAMsTheme.background,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Greeting + name + ID
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_getGreeting()},',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: SAMsTheme.textSecondary,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _studentName,
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  color: SAMsTheme.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Student ID badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: SAMsTheme.primary.withValues(alpha:0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _studentId,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: SAMsTheme.primary,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Notification bell
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: SAMsTheme.surfaceLight,
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Iconsax.notification,
                          color: SAMsTheme.textPrimary,
                          size: 22,
                        ),
                        // Notification dot
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: SAMsTheme.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  2. MODULE CARDS (4 large cards)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildModuleCards() {
    return AnimatedBuilder(
      animation: _modulesAnim,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _modulesAnim.value)),
          child: Opacity(
            opacity: _modulesAnim.value,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Modules',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      color: SAMsTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 2×2 grid of module cards
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.92,
                    children: [
                      _buildModuleCard(
                        icon: Iconsax.wallet_3,
                        title: 'Tuition Fees',
                        accent: _feesColor,
                        mainValue: 'RM ${_outstandingBalance.toStringAsFixed(0)}',
                        mainLabel: 'Outstanding',
                        badge: _getStatusLabel(_feesStatus),
                        badgeColor: _getStatusColor(_feesStatus),
                        onTap: () => _navigateToModule('fees'),
                      ),
                      _buildModuleCard(
                        icon: Iconsax.document_text,
                        title: 'Registration',
                        accent: _regColor,
                        mainValue: '$_enrolledCourses',
                        mainLabel: 'Courses',
                        badge: _registrationStatus,
                        badgeColor: _regColor,
                        onTap: () => _navigateToModule('registration'),
                      ),
                      _buildModuleCard(
                        icon: Iconsax.cup,
                        title: 'Activities',
                        accent: _actColor,
                        mainValue: '$_upcomingActivities',
                        mainLabel: 'Upcoming',
                        badge: '${_creditHoursEarned}h earned',
                        badgeColor: _actColor,
                        onTap: () => _navigateToModule('activities'),
                      ),
                      _buildModuleCard(
                        icon: Iconsax.tick_circle,
                        title: 'Attendance',
                        accent: _attColor,
                        mainValue: '${_attendanceRate.toStringAsFixed(1)}%',
                        mainLabel: 'Rate',
                        badge: '$_sessionsAttended/$_sessionsTotal',
                        badgeColor: _attColor,
                        onTap: () => _navigateToModule('attendance'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModuleCard({
    required IconData icon,
    required String title,
    required Color accent,
    required String mainValue,
    required String mainLabel,
    required String badge,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return PressableCard(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SAMsTheme.surface,
          borderRadius: SmoothBorderRadius(cornerRadius: 18, cornerSmoothing: 0.6),
          border: Border.all(
            color: accent.withValues(alpha:0.15),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + badge row
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha:0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accent, size: 20),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha:0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: badgeColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Title
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: SAMsTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            // Main value
            Text(
              mainValue,
              style: GoogleFonts.inter(
                fontSize: 22,
                color: SAMsTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              mainLabel,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: SAMsTheme.textSecondary.withValues(alpha:0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  3. QUICK STATS (2×2 grid)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildQuickStats() {
    return AnimatedBuilder(
      animation: _statsAnim,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _statsAnim.value)),
          child: Opacity(
            opacity: _statsAnim.value,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Stats',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      color: SAMsTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatTile(
                          icon: Iconsax.wallet_3,
                          label: 'Total Balance',
                          value: 'RM ${_outstandingBalance.toStringAsFixed(0)}',
                          color: _feesColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatTile(
                          icon: Iconsax.book,
                          label: 'Courses Enrolled',
                          value: '$_enrolledCourses',
                          color: _regColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatTile(
                          icon: Iconsax.cup,
                          label: 'Activities Joined',
                          value: '$_upcomingActivities',
                          color: _actColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatTile(
                          icon: Iconsax.percentage_circle,
                          label: 'Attendance Rate',
                          value: '${_attendanceRate.toStringAsFixed(1)}%',
                          color: _attColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SAMsTheme.surface,
        borderRadius: SmoothBorderRadius(cornerRadius: 16, cornerSmoothing: 0.6),
        border: Border.all(color: SAMsTheme.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha:0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    color: SAMsTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: SAMsTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  4. UPCOMING (combined timeline)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildUpcoming() {
    return AnimatedBuilder(
      animation: _upcomingAnim,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _upcomingAnim.value)),
          child: Opacity(
            opacity: _upcomingAnim.value,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Upcoming',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          color: SAMsTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'View all',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: SAMsTheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_upcomingItems.isEmpty && !_loading)
                    _buildEmptyUpcoming()
                  else
                    ...List.generate(
                      _loading ? 3 : _upcomingItems.length,
                      (i) {
                        if (_loading) return _buildUpcomingSkeleton();
                        return _buildUpcomingItem(_upcomingItems[i], i);
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyUpcoming() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: SAMsTheme.surface,
        borderRadius: SmoothBorderRadius(cornerRadius: 16, cornerSmoothing: 0.6),
      ),
      child: Column(
        children: [
          Icon(
            Iconsax.calendar_tick,
            size: 40,
            color: SAMsTheme.textSecondary.withValues(alpha:0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'Nothing upcoming',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: SAMsTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'You\'re all caught up!',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: SAMsTheme.textSecondary.withValues(alpha:0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SAMsTheme.surface,
        borderRadius: SmoothBorderRadius(cornerRadius: 14, cornerSmoothing: 0.6),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: SAMsTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 140,
                  height: 14,
                  decoration: BoxDecoration(
                    color: SAMsTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 100,
                  height: 11,
                  decoration: BoxDecoration(
                    color: SAMsTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingItem(Map<String, dynamic> item, int index) {
    final color = item['color'] as Color;
    return PressableCard(
      onTap: () => HapticFeedback.selectionClick(),
      child: Container(
        margin: EdgeInsets.only(bottom: index < _upcomingItems.length - 1 ? 10 : 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: SAMsTheme.surface,
          borderRadius: SmoothBorderRadius(cornerRadius: 14, cornerSmoothing: 0.6),
          border: Border.all(
            color: color.withValues(alpha:0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha:0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item['icon'] as IconData, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: SAMsTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item['subtitle'] ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: SAMsTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Time
            Text(
              item['time'] ?? '',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: SAMsTheme.textSecondary.withValues(alpha:0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  5. RECENT ACTIVITY
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildRecentActivity() {
    return AnimatedBuilder(
      animation: _recentAnim,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _recentAnim.value)),
          child: Opacity(
            opacity: _recentAnim.value,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Activity',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          color: SAMsTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'See all',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: SAMsTheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_recentActivity.isEmpty && !_loading)
                    EmptyState(
                      icon: Iconsax.activity,
                      title: 'No recent activity',
                      subtitle: 'Your actions will appear here',
                    )
                  else
                    ...List.generate(
                      _loading ? 5 : _recentActivity.length,
                      (i) {
                        if (_loading) return _buildActivitySkeleton();
                        return _buildActivityItem(_recentActivity[i], i);
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivitySkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SAMsTheme.surface,
        borderRadius: SmoothBorderRadius(cornerRadius: 14, cornerSmoothing: 0.6),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: SAMsTheme.surfaceLight,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 160,
                  height: 13,
                  decoration: BoxDecoration(
                    color: SAMsTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 100,
                  height: 11,
                  decoration: BoxDecoration(
                    color: SAMsTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> item, int index) {
    final color = item['color'] as Color;
    return PressableCard(
      onTap: () => HapticFeedback.selectionClick(),
      child: Container(
        margin: EdgeInsets.only(
          bottom: index < _recentActivity.length - 1 ? 10 : 0,
        ),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: SAMsTheme.surface,
          borderRadius: SmoothBorderRadius(cornerRadius: 14, cornerSmoothing: 0.6),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha:0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item['icon'] as IconData, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: SAMsTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item['subtitle'] ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: SAMsTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              item['time'] ?? '',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: SAMsTheme.textSecondary.withValues(alpha:0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Navigation ────────────────────────────────────────────────────────
  void _navigateToModule(String module) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PlaceholderScreen(module: module),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  Placeholder screen for module navigation
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _PlaceholderScreen extends StatelessWidget {
  final String module;

  const _PlaceholderScreen({required this.module});

  IconData _icon() {
    switch (module) {
      case 'fees':
        return Iconsax.wallet_3;
      case 'registration':
        return Iconsax.document_text;
      case 'activities':
        return Iconsax.cup;
      case 'attendance':
        return Iconsax.tick_circle;
      default:
        return Iconsax.home;
    }
  }

  String _title() {
    switch (module) {
      case 'fees':
        return 'Tuition Fees';
      case 'registration':
        return 'Registration';
      case 'activities':
        return 'Curriculum Activities';
      case 'attendance':
        return 'Attendance';
      default:
        return module;
    }
  }

  Color _color() {
    switch (module) {
      case 'fees':
        return const Color(0xFF9C6ADE);
      case 'registration':
        return const Color(0xFF5C9CE6);
      case 'activities':
        return const Color(0xFF6FB58A);
      case 'attendance':
        return const Color(0xFFE0A458);
      default:
        return SAMsTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Scaffold(
      backgroundColor: SAMsTheme.background,
      appBar: AppBar(
        backgroundColor: SAMsTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: SAMsTheme.textPrimary),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Text(
          _title(),
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: SAMsTheme.textPrimary,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: color.withValues(alpha:0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon(), color: color, size: 32),
            ),
            const SizedBox(height: 20),
            Text(
              _title(),
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: SAMsTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming soon',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: SAMsTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
