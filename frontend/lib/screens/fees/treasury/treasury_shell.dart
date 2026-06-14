import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../config/theme.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'treasury_dashboard_tab.dart';
import 'treasury_students_tab.dart';

class TreasuryShell extends StatefulWidget {
  const TreasuryShell({super.key});

  @override
  State<TreasuryShell> createState() => _TreasuryShellState();
}

class _TreasuryShellState extends State<TreasuryShell>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final PageController _pageController;

  static const _inkNavy = Color(0xFF0B1B2C);
  static const _brassGold = Color(0xFFC9A961);

  final _screens = const [
    TreasuryDashboardTab(),
    TreasuryStudentsTab(),
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
            color: const Color(0xFF0B1B2C),
            child: Center(
              child: SmoothPageIndicator(
                controller: _pageController,
                count: 2,
                effect: const WormEffect(
                  dotWidth: 6,
                  dotHeight: 6,
                  spacing: 8,
                  activeDotColor: Color(0xFFC9A961),
                  dotColor: Color(0xFF2A3A4C),
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

// ─── Custom Editorial Bottom Navigation Bar ───────────────────────────────────

class _EditorialBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _EditorialBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  static const _inkNavy = Color(0xFF0B1B2C);
  static const _brassGold = Color(0xFFC9A961);

  static const _items = <_NavItemData>[
    _NavItemData(icon: Iconsax.chart_square, activeIcon: Iconsax.chart_square_copy, label: 'Dashboard'),
    _NavItemData(icon: Iconsax.people, activeIcon: Iconsax.people_copy, label: 'Students'),
  ];

  @override
  Widget build(BuildContext context) {
    final double navWidth = MediaQuery.of(context).size.width;
    final double tabWidth = navWidth / _items.length;
    final double indicatorWidth = 32.0;

    return Container(
      decoration: BoxDecoration(
        color: _inkNavy,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Stack(
            children: [
              // Sliding brass gold underline indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                top: 0,
                left: (tabWidth * currentIndex) + (tabWidth - indicatorWidth) / 2,
                child: Container(
                  width: indicatorWidth,
                  height: 3,
                  decoration: BoxDecoration(
                    color: _brassGold,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Tab items row
              Row(
                children: List.generate(_items.length, (index) {
                  final item = _items[index];
                  final isActive = index == currentIndex;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(index),
                      child: _NavItem(
                        data: item,
                        isActive: isActive,
                      ),
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

// ─── Single Nav Item with scale animation ─────────────────────────────────────

class _NavItem extends StatelessWidget {
  final _NavItemData data;
  final bool isActive;

  const _NavItem({
    required this.data,
    required this.isActive,
  });

  static const _brassGold = Color(0xFFC9A961);

  @override
  Widget build(BuildContext context) {
    final color = isActive ? _brassGold : Colors.white.withOpacity(0.45);

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: isActive ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: Icon(
              isActive ? data.activeIcon : data.icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: color,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Data model ───────────────────────────────────────────────────────────────

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
