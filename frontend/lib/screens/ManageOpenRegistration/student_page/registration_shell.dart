import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'StudentDashboard.dart';
import 'SubjectRegistration.dart';

class RegistrationShell extends StatefulWidget {
  const RegistrationShell({super.key});

  @override
  State<RegistrationShell> createState() => _RegistrationShellState();
}

class _RegistrationShellState extends State<RegistrationShell>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final PageController _pageController;

  late final List<Widget> _screens = [
    const StudentDashboard(),
    const SubjectRegistration(),
    const _MyCoursesTab(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (i) => setState(() => _currentIndex = i),
        children: _screens,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 6, top: 4),
            color: const Color(0xFF000000),
            child: Center(
              child: SmoothPageIndicator(
                controller: _pageController,
                count: 3,
                effect: const WormEffect(
                  dotWidth: 6,
                  dotHeight: 6,
                  spacing: 8,
                  activeDotColor: Color(0xFF5C33CF),
                  dotColor: Color(0xFF292929),
                ),
              ),
            ),
          ),
          _EditorialBottomNav(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
          ),
        ],
      ),
    );
  }
}

// ─── My Courses Tab ──────────────────────────────────────────────────────────

class _MyCoursesTab extends StatefulWidget {
  const _MyCoursesTab();

  @override
  State<_MyCoursesTab> createState() => _MyCoursesTabState();
}

class _MyCoursesTabState extends State<_MyCoursesTab> {
  List<Map<String, dynamic>> _enrollments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEnrollments();
  }

  Future<void> _loadEnrollments() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.get('/registration/my');
      if (data is List) {
        setState(() {
          _enrollments = data.map((e) => Map<String, dynamic>.from(e)).toList();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;
    final muted = isDark ? const Color(0xFF94989E) : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: t.colorScheme.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(children: [
              Container(width: 12, height: 2, color: const Color(0xFF5C33CF)),
              const SizedBox(width: 8),
              Text('UMPSA \u2022 SAMs', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 2.0, color: muted)),
            ]),
            const SizedBox(height: 24),
            _SectionLabel(text: 'MY REGISTERED COURSES', muted: muted, accent: const Color(0xFF5C33CF)),
            const SizedBox(height: 16),
            _loading
              ? Center(child: CircularProgressIndicator(color: const Color(0xFF5C33CF), strokeWidth: 2))
              : _enrollments.isEmpty
                ? Center(child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text('No courses enrolled yet.', style: TextStyle(fontFamily: 'Inter', color: muted)),
                  ))
                : Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: t.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: t.dividerColor),
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < _enrollments.length; i++) ...[
                          if (i > 0) Divider(color: t.dividerColor, height: 1),
                          _courseRow(
                            _enrollments[i]['course']?['courseId'] ?? '',
                            _enrollments[i]['course']?['courseName'] ?? 'Unknown',
                            '${_enrollments[i]['course']?['creditHours'] ?? 0} hrs',
                            _enrollments[i]['status'] == 'active' ? 'Accepted' : _enrollments[i]['status'] ?? '',
                            t,
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

  Widget _courseRow(String code, String name, String credits, String status, ThemeData t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF5C33CF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(code, style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF5C33CF))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: t.colorScheme.onSurface)),
                Text(credits, style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: t.textTheme.bodySmall?.color)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(status, style: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF4CAF50))),
          ),
        ],
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color muted;
  final Color accent;

  const _SectionLabel({required this.text, required this.muted, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 18, height: 1, color: accent),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontFamily: 'Inter', color: muted, fontSize: 10.5, letterSpacing: 2.4, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ─── Bottom Navigation ───────────────────────────────────────────────────────

class _EditorialBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _EditorialBottomNav({required this.currentIndex, required this.onTap});

  static const _moonBlack = Color(0xFF000000);
  static const _piccolo = Color(0xFF5C33CF);

  static const _items = <_NavItemData>[
    _NavItemData(icon: Iconsax.home_2, activeIcon: Iconsax.home_2_copy, label: 'Home'),
    _NavItemData(icon: Iconsax.add_square, activeIcon: Iconsax.add_square_copy, label: 'Register'),
    _NavItemData(icon: Iconsax.book_1, activeIcon: Iconsax.book_1_copy, label: 'My Courses'),
  ];

  @override
  Widget build(BuildContext context) {
    final double navWidth = MediaQuery.of(context).size.width;
    final double tabWidth = navWidth / _items.length;
    const double indicatorWidth = 32.0;

    return Container(
      decoration: BoxDecoration(
        color: _moonBlack,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                top: 0,
                left: (tabWidth * currentIndex) + (tabWidth - indicatorWidth) / 2,
                child: Container(width: indicatorWidth, height: 3, decoration: BoxDecoration(color: _piccolo, borderRadius: BorderRadius.circular(2))),
              ),
              Row(
                children: List.generate(_items.length, (index) {
                  final item = _items[index];
                  final isActive = index == currentIndex;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(index),
                      child: _NavItem(data: item, isActive: isActive),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _NavItemData data;
  final bool isActive;

  const _NavItem({required this.data, required this.isActive});

  static const _piccolo = Color(0xFF5C33CF);

  @override
  Widget build(BuildContext context) {
    final color = isActive ? _piccolo : Colors.white.withValues(alpha: 0.45);

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: isActive ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: Icon(isActive ? data.activeIcon : data.icon, color: color, size: 22),
          ),
          const SizedBox(height: 4),
          Text(data.label, style: GoogleFonts.inter(fontSize: 10, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400, color: color, letterSpacing: 0.6)),
        ],
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItemData({required this.icon, required this.activeIcon, required this.label});
}
