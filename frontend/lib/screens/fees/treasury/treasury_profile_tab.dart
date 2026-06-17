import 'package:flutter/material.dart';
import 'package:moon_design/moon_design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/auth_provider.dart';
import '../../auth/login_screen.dart';

class TreasuryProfileTab extends ConsumerStatefulWidget {
  const TreasuryProfileTab({super.key});

  @override
  ConsumerState<TreasuryProfileTab> createState() => _TreasuryProfileTabState();
}

class _TreasuryProfileTabState extends ConsumerState<TreasuryProfileTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _staggerCtrl;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _staggerCtrl.forward();
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;
    const ink = Color(0xFF000000);
    const brass = Color(0xFF5C33CF);
    final muted = isDark ? const Color(0xFF94989E) : const Color(0xFF6B7280);
    final surface = isDark ? const Color(0xFF000000) : const Color(0xFFF6F6F8);
    final onSurface = t.colorScheme.onSurface;

    final name = user?['name'] ?? 'Treasury Admin';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'T';
    final email = user?['email'] ?? '';
    final role = user?['role'] ?? 'Treasury Administrator';
    final department = user?['department'] ?? 'Finance & Treasury';

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
          style: GoogleFonts.inter(
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
                      color: isDark ? ink : const Color(0xFF1F1F1F),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: GoogleFonts.inter(
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
                    style: GoogleFonts.inter(
                      color: onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                if (email.isNotEmpty)
                  Center(
                    child: Text(
                      email,
                      style: GoogleFonts.inter(
                        color: muted.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 36),

          // ACCOUNT section header
          _staggerItem(idx++, _sectionHeader('ACCOUNT', brass, muted)),
          const SizedBox(height: 16),

          // Account items
          _staggerItem(
            idx++,
            _profileItem(
              Icons.email_outlined,
              'Email',
              email,
              muted,
              onSurface,
              isDark,
            ),
          ),
          _staggerItem(
            idx++,
            _profileItem(
              Icons.verified_user_outlined,
              'Role',
              role,
              muted,
              onSurface,
              isDark,
            ),
          ),
          _staggerItem(
            idx++,
            _profileItem(
              Icons.business_outlined,
              'Department',
              department,
              muted,
              onSurface,
              isDark,
            ),
          ),

          const SizedBox(height: 32),

          // PREFERENCES section header
          _staggerItem(idx++, _sectionHeader('PREFERENCES', brass, muted)),
          const SizedBox(height: 16),

          _staggerItem(
            idx++,
            _notificationToggle(muted, onSurface, isDark, brass),
          ),

          const SizedBox(height: 48),

          // Sign out - subtle text button
          _staggerItem(
            idx++,
            Center(
              child: MoonTextButton(
                onTap: () {
                  ref.read(authProvider.notifier).logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                leading: Icon(
                  Icons.logout_outlined,
                  size: 16,
                  color: muted.withValues(alpha: 0.7),
                ),
                label: Text(
                  'Sign out',
                  style: GoogleFonts.inter(
                    color: muted.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    decoration: TextDecoration.underline,
                    decorationColor: muted.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
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
            color: muted.withValues(alpha: 0.15),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: muted.withValues(alpha: 0.6), size: 18),
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

  Widget _notificationToggle(
    Color muted,
    Color onSurface,
    bool isDark,
    Color brass,
  ) {
    bool notificationsEnabled = false;
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: muted.withValues(alpha: 0.15),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.notifications_none_outlined, color: muted.withValues(alpha: 0.6), size: 18),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notifications',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: muted,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notificationsEnabled ? 'Enabled' : 'Disabled',
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
                  value: notificationsEnabled,
                  onChanged: (val) {
                    setLocalState(() => notificationsEnabled = val);
                  },
                  activeThumbColor: brass,
                  inactiveTrackColor: muted.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
