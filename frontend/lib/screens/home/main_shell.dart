import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import 'dashboard_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  late final PageController _pageController;
  int _currentView = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final role = user?['role'] ?? 'student';
    final isAdmin = role == 'admin';
    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;
    final accent = isDark ? SAMsTheme.brass : const Color(0xFFB28A3E);
    final muted = t.textTheme.bodyMedium?.color ?? SAMsTheme.textSecondary;

    // Non-admin: just show student dashboard
    if (!isAdmin) {
      return const DashboardScreen();
    }

    // Admin: go straight to dashboard (no role switcher)
    return const DashboardScreen();
  }
}

// Admin overview dashboard
class _AdminDashboardView extends StatelessWidget {
  final Color accent;
  final Color muted;
  final bool isDark;
  final ThemeData t;

  const _AdminDashboardView({
    required this.accent,
    required this.muted,
    required this.isDark,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Admin header
            Row(children: [
              Container(width: 22, height: 1, color: accent),
              const SizedBox(width: 10),
              Text('ADMIN OVERVIEW', style: GoogleFonts.inter(color: muted, fontSize: 10.5, letterSpacing: 2.4, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 20),
            Text('Quick Actions', style: GoogleFonts.fraunces(fontSize: 22, fontWeight: FontWeight.w400, color: t.colorScheme.onSurface)),
            const SizedBox(height: 16),

            // Quick action grid
            Row(children: [
              Expanded(child: _QuickAction(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Treasury',
                subtitle: 'Fees & Payments',
                accent: accent,
                isDark: isDark,
                t: t,
                onTap: () => Navigator.pushNamed(context, '/fees'),
              )),
              const SizedBox(width: 12),
              Expanded(child: _QuickAction(
                icon: Icons.people_outline_rounded,
                label: 'Students',
                subtitle: 'Manage Users',
                accent: accent,
                isDark: isDark,
                t: t,
                onTap: () => Navigator.pushNamed(context, '/fees'),
              )),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _QuickAction(
                icon: Icons.notifications_none_rounded,
                label: 'Reminders',
                subtitle: 'Send Alerts',
                accent: accent,
                isDark: isDark,
                t: t,
                onTap: () => Navigator.pushNamed(context, '/fees'),
              )),
              const SizedBox(width: 12),
              Expanded(child: _QuickAction(
                icon: Icons.assessment_outlined,
                label: 'Reports',
                subtitle: 'Analytics',
                accent: accent,
                isDark: isDark,
                t: t,
                onTap: () {},
              )),
            ]),

            const SizedBox(height: 32),
            // Tips strip
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? t.colorScheme.surface : const Color(0xFFF5F0E8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Container(width: 18, height: 1, color: accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Swipe right for Student view. Use Treasury tab below for full fee management.',
                      style: GoogleFonts.inter(color: muted, fontSize: 12, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color accent;
  final bool isDark;
  final ThemeData t;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.accent,
    required this.isDark,
    required this.t,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: t.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: accent),
            const SizedBox(height: 12),
            Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: t.colorScheme.onSurface)),
            const SizedBox(height: 2),
            Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: (isDark ? const Color(0xFF8A9BB5) : const Color(0xFF6B7280)).withOpacity(0.6))),
          ],
        ),
      ),
    );
  }
}

class _ViewTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final Color accent;
  final Color muted;
  final bool isDark;
  final VoidCallback onTap;

  const _ViewTab({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.accent,
    required this.muted,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? accent.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? accent.withOpacity(0.3) : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isActive ? accent : muted.withOpacity(0.4)),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.inter(
              color: isActive ? (isDark ? Colors.white : const Color(0xFF0B1B2C)) : muted.withOpacity(0.4),
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              letterSpacing: 0.3,
            )),
          ],
        ),
      ),
    );
  }
}
