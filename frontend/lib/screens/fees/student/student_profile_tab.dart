import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/api_service.dart';
import '../../../services/cache_service.dart';
import '../../auth/login_screen.dart';
import 'package:figma_squircle/figma_squircle.dart';

class StudentProfileTab extends ConsumerStatefulWidget {
  const StudentProfileTab({super.key});

  @override
  ConsumerState<StudentProfileTab> createState() => _StudentProfileTabState();
}

class _StudentProfileTabState extends ConsumerState<StudentProfileTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _staggerCtrl;

  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  // Fee summary
  double _totalPaid = 0;
  double _outstanding = 0;
  bool _feesLoaded = false;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _staggerCtrl.forward();
    _loadFeeSummary();
  }

  Future<void> _loadFeeSummary() async {
    try {
      // Try cache first
      final cached = await CacheService.get('my_fees', maxAgeMinutes: 60);
      if (cached != null) {
        _computeFees(cached);
      }
      // Fetch fresh
      final fees = await ApiService.get('/fees/my');
      _computeFees(fees);
    } catch (_) {
      // Silently fail — card shows dashes
    }
  }

  void _computeFees(List<dynamic> fees) {
    final due = fees.fold<double>(0.0, (s, f) => s + ((f['totalAmount'] ?? 0) as num).toDouble());
    final paid = fees.fold<double>(0.0, (s, f) => s + ((f['paidAmount'] ?? 0) as num).toDouble());
    if (mounted) {
      setState(() {
        _totalPaid = paid;
        _outstanding = due - paid;
        _feesLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    super.dispose();
  }

  Widget _staggerItem(int index, Widget child) {
    final begin = (index * 0.1).clamp(0.0, 0.6);
    final end = (begin + 0.4).clamp(0.0, 1.0);
    final curve = CurvedAnimation(
      parent: _staggerCtrl,
      curve: Interval(begin, end, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(curve),
        child: child,
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, Color brass, Color muted, Color onSurface, Color surface) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 32, height: 2, color: brass),
            const SizedBox(height: 12),
            Text(
              'SIGN OUT',
              style: GoogleFonts.inter(
                fontSize: 11,
                letterSpacing: 1.8,
                fontWeight: FontWeight.w600,
                color: muted,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Are you sure you want to sign out of your account?',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: onSurface,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: muted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(authProvider.notifier).logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: Text(
              'Sign out',
              style: GoogleFonts.inter(
                color: brass,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;
    final ink = const Color(0xFF0B1B2C);
    final brass = const Color(0xFFC9A961);
    final muted = isDark ? const Color(0xFF8A9BB5) : const Color(0xFF6B7280);
    final surface = isDark ? const Color(0xFF0B1B2C) : const Color(0xFFF5F0E8);
    final onSurface = t.colorScheme.onSurface;

    final name = user?['name'] ?? '—';
    final initial = (name.isNotEmpty && name != '—') ? name[0].toUpperCase() : 'S';
    final studentId = user?['studentId'] ?? '';
    final email = user?['email'] ?? '';

    int idx = 0;

    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          'Profile',
          style: GoogleFonts.fraunces(
            color: onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          // Avatar + Identity
          _staggerItem(
            idx++,
            Column(
              children: [
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: isDark ? ink : const Color(0xFF1A2B3C),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: GoogleFonts.fraunces(
                          color: brass,
                          fontSize: 32,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    name,
                    style: GoogleFonts.fraunces(
                      color: onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                if (studentId.isNotEmpty)
                  Center(
                    child: Text(
                      studentId,
                      style: GoogleFonts.inter(
                        color: muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                if (email.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Center(
                      child: Text(
                        email,
                        style: GoogleFonts.inter(
                          color: muted.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Fee Payment Summary Card
          _staggerItem(idx++, _feeSummaryCard(brass, muted, onSurface, isDark)),

          const SizedBox(height: 36),

          // ACCOUNT section header
          _staggerItem(idx++, _sectionHeader('ACCOUNT', brass, muted)),
          const SizedBox(height: 16),

          // Account items — show dash when data missing
          _staggerItem(
            idx++,
            _profileItem(
              Icons.school_outlined,
              'Faculty',
              user?['faculty'] ?? 'Not set',
              muted,
              onSurface,
              isDark,
            ),
          ),
          _staggerItem(
            idx++,
            _profileItem(
              Icons.menu_book_outlined,
              'Program',
              user?['program'] ?? 'Not set',
              muted,
              onSurface,
              isDark,
            ),
          ),
          _staggerItem(
            idx++,
            _profileItem(
              Icons.calendar_today_outlined,
              'Semester',
              user?['semester']?.toString() ?? '—',
              muted,
              onSurface,
              isDark,
            ),
          ),

          const SizedBox(height: 32),

          // PREFERENCES section header
          _staggerItem(idx++, _sectionHeader('PREFERENCES', brass, muted)),
          const SizedBox(height: 16),

          // Notifications toggle
          _staggerItem(
            idx++,
            _toggleItem(
              Icons.notifications_none_outlined,
              'Notifications',
              _notificationsEnabled ? 'Enabled' : 'Disabled',
              _notificationsEnabled,
              (val) => setState(() => _notificationsEnabled = val),
              muted,
              onSurface,
              isDark,
              brass,
            ),
          ),

          // Dark mode toggle
          _staggerItem(
            idx++,
            _toggleItem(
              Icons.dark_mode_outlined,
              'Dark Mode',
              _darkModeEnabled ? 'On' : 'Off',
              _darkModeEnabled,
              (val) => setState(() => _darkModeEnabled = val),
              muted,
              onSurface,
              isDark,
              brass,
            ),
          ),

          _staggerItem(
            idx++,
            _profileItem(
              Icons.language_outlined,
              'Language',
              'English',
              muted,
              onSurface,
              isDark,
            ),
          ),

          const SizedBox(height: 48),

          // Logout - subtle text button with confirmation
          _staggerItem(
            idx++,
            Center(
              child: TextButton.icon(
                onPressed: () => _showSignOutDialog(context, brass, muted, onSurface, surface),
                icon: Icon(
                  Icons.logout_outlined,
                  size: 16,
                  color: muted.withOpacity(0.7),
                ),
                label: Text(
                  'Sign out',
                  style: GoogleFonts.inter(
                    color: muted.withOpacity(0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    decoration: TextDecoration.underline,
                    decorationColor: muted.withOpacity(0.4),
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Fee payment summary card at top
  Widget _feeSummaryCard(Color brass, Color muted, Color onSurface, bool isDark) {
    final cardBg = isDark ? const Color(0xFF132236) : Colors.white;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: brass.withOpacity(0.25), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 18, height: 1.5, color: brass),
              const SizedBox(width: 8),
              Text(
                'THIS SEMESTER',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w600,
                  color: muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Paid',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _feesLoaded ? 'RM ${_totalPaid.toStringAsFixed(2)}' : '—',
                      style: GoogleFonts.fraunces(
                        fontSize: 18,
                        color: SAMsTheme.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 36, color: muted.withOpacity(0.15)),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Outstanding',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _feesLoaded ? 'RM ${_outstanding.toStringAsFixed(2)}' : '—',
                      style: GoogleFonts.fraunces(
                        fontSize: 18,
                        color: _outstanding > 0 ? SAMsTheme.error : onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label, Color brass, Color muted) {
    return Row(
      children: [
        Container(width: 18, height: 1.5, color: brass),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            color: muted,
            fontSize: 10,
            letterSpacing: 1.8,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _profileItem(
    IconData icon,
    String label,
    String value,
    Color muted,
    Color onSurface,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: muted.withOpacity(0.15),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: muted.withOpacity(0.6), size: 18),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: muted,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Toggle item with inline switch (notifications, dark mode)
  Widget _toggleItem(
    IconData icon,
    String label,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    Color muted,
    Color onSurface,
    bool isDark,
    Color brass,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: muted.withOpacity(0.15),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: muted.withOpacity(0.6), size: 18),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: muted,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: brass,
              inactiveTrackColor: muted.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }
}
