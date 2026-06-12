import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';
import '../fees/fees_screen.dart';
import 'profile_screen.dart';
import '../../widgets/page_transitions.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with TickerProviderStateMixin {
  String? _profileImage;
  List<dynamic> _announcements = [];
  Map<String, dynamic>? _feeSummary;

  late AnimationController _staggerController;
  late AnimationController _balancePulse;
  late List<Animation<double>> _staggerAnims;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _balancePulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    
    // 5 staggered items: header, greeting, info card, balance, quick access
    _staggerAnims = List.generate(5, (i) => CurvedAnimation(
      parent: _staggerController,
      curve: Interval(i * 0.15, 0.4 + i * 0.15, curve: Curves.easeOutCubic),
    ));
    
    _loadAll();
    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _balancePulse.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadProfileImage(), _loadFeeSummary()]);
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('profile_image');
    // Verify file exists before setting
    if (path != null && File(path).existsSync()) {
      setState(() => _profileImage = path);
    }
  }

  Future<void> _loadFeeSummary() async {
    try {
      final user = ref.read(authProvider).user;
      final sid = user?['studentId'] ?? user?['student_id'] ?? '';
      // Skip for admin users
      if (sid.isNotEmpty && user?['role'] != 'admin') {
        final data = await ApiService.get('/fees/$sid/summary');
        setState(() => _feeSummary = data['summary']);
      }
    } catch (_) {}
  }

  Future<void> _refresh() async {
    await _loadAll();
    ref.read(authProvider.notifier).refreshProfile();
  }

  // Stagger animation wrapper
  Widget _fadeSlide(Animation<double> anim, {required Widget child}) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - anim.value)),
          child: child,
        ),
      ),
    );
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final name = user?['name'] ?? 'Student';
    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;
    final accent = isDark ? SAMsTheme.brass : const Color(0xFFB28A3E);
    final muted = t.textTheme.bodyMedium?.color ?? SAMsTheme.textSecondary;
    final today = DateFormat('EEEE, d MMMM').format(DateTime.now());

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: accent,
          backgroundColor: t.scaffoldBackgroundColor,
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── HEADER (editorial top strip) ───
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Container(width: 22, height: 1, color: accent),
                          const SizedBox(width: 10),
                          Text('UMPSA · SAMs',
                            style: GoogleFonts.inter(color: muted, fontSize: 10.5, letterSpacing: 2.4, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const Spacer(),
                      _IconBtn(icon: Icons.notifications_none_rounded, onTap: () {}),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _showProfileMenu(context, ref),
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: accent.withOpacity(0.6), width: 1),
                            color: t.colorScheme.surface,
                            image: _profileImage != null ? DecorationImage(image: FileImage(File(_profileImage!)), fit: BoxFit.cover) : null,
                          ),
                          child: _profileImage == null
                              ? Center(child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'S',
                                  style: GoogleFonts.fraunces(color: accent, fontSize: 15, fontWeight: FontWeight.w600),
                                ))
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),

                // ─── GREETING (serif hero) ───
                _fadeSlide(_staggerAnims[0], child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 4),
                  child: Text(today.toUpperCase(),
                    style: GoogleFonts.inter(color: muted, fontSize: 10.5, letterSpacing: 2.4, fontWeight: FontWeight.w600),
                  ),
                )),
                _fadeSlide(_staggerAnims[1], child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
                  child: Text(
                    '$_greeting,\n${name.split(' ').first}.',
                    style: t.textTheme.displayMedium?.copyWith(height: 1.05),
                  ),
                )),

                // ─── STUDENT INFO STRIP ───
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                    decoration: BoxDecoration(
                      color: t.colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: t.dividerColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 4, height: 36, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text((user?['program'] ?? 'Software Engineering').toString().toUpperCase(),
                                style: GoogleFonts.inter(color: muted, fontSize: 9.5, letterSpacing: 1.6, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(name,
                                style: GoogleFonts.fraunces(color: t.colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        Text(user?['studentId']?.toString() ?? user?['student_id']?.toString() ?? '—',
                          style: GoogleFonts.jetBrainsMono(color: muted, fontSize: 12, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── SECTION RULE: MODULES ───
                _SectionLabel(text: 'MODULES', muted: muted, accent: accent, top: 36),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Column(
                    children: [
                      _ModuleRow(
                        index: '01',
                        title: 'Tuition Fees',
                        subtitle: 'Balance, payments, receipts',
                        accent: accent,
                        onTap: () => Navigator.push(context, SlidePageRoute(page: const FeesScreen())),
                      ),
                    ],
                  ),
                ),

                // ─── FEE SUMMARY: editorial composition ───
                _fadeSlide(_staggerAnims[3], child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                  child: GestureDetector(
                    onTap: () => Navigator.push(context, SlidePageRoute(page: const FeesScreen())),
                    child: AnimatedBuilder(
                      animation: _balancePulse,
                      builder: (_, child) => Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F2235) : const Color(0xFFEDE5D4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: accent.withOpacity(0.15 + _balancePulse.value * 0.1)),
                        ),
                        child: child,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(width: 18, height: 1, color: accent),
                              const SizedBox(width: 8),
                              Text('OUTSTANDING BALANCE',
                                style: GoogleFonts.inter(color: muted, fontSize: 10, letterSpacing: 1.8, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('RM',
                                style: GoogleFonts.fraunces(color: muted, fontSize: 18, fontWeight: FontWeight.w400, height: 1.4),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                ((_feeSummary?['balance'] ?? 0) is num
                                  ? (_feeSummary?['balance'] ?? 0) as num
                                  : 0).toStringAsFixed(2),
                                style: GoogleFonts.fraunces(
                                  color: t.colorScheme.onSurface,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: -1.2,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _feeSummary != null && ((_feeSummary!['balance'] ?? 0) as num) <= 0
                                    ? 'Fully settled — no action needed.'
                                    : 'View breakdown and make a payment.',
                                  style: t.textTheme.bodyMedium?.copyWith(fontSize: 13),
                                ),
                              ),
                              Icon(Icons.arrow_forward_rounded, size: 18, color: accent),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                )),

                // ─── QUICK ACCESS ───
                _SectionLabel(text: 'QUICK ACCESS', muted: muted, accent: accent, top: 32),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 0.95,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 14,
                    children: [
                      _QuickItem(icon: Icons.fastfood_outlined, label: 'e-Kupon', accent: accent, muted: muted, onTap: () {}),
                      _QuickItem(icon: Icons.emergency_outlined, label: 'Emergency', accent: accent, muted: muted, onTap: () {}),
                      _QuickItem(icon: Icons.laptop_mac_outlined, label: 'EDasar', accent: accent, muted: muted, onTap: () {}),
                      _QuickItem(icon: Icons.school_outlined, label: 'Alumni', accent: accent, muted: muted, onTap: () {}),
                      _QuickItem(icon: Icons.directions_bus_outlined, label: 'Bus', accent: accent, muted: muted, onTap: () {}),
                      _QuickItem(icon: Icons.help_outline_rounded, label: 'FAQ', accent: accent, muted: muted, onTap: () {}),
                      _QuickItem(icon: Icons.cloud_outlined, label: 'Weather', accent: accent, muted: muted, onTap: () {}),
                      _QuickItem(icon: Icons.map_outlined, label: 'Map', accent: accent, muted: muted, onTap: () {}),
                      _QuickItem(icon: Icons.calendar_today_outlined, label: 'Calendar', accent: accent, muted: muted, onTap: () {}),
                      _QuickItem(icon: Icons.restaurant_outlined, label: 'Cafetaria', accent: accent, muted: muted, onTap: () {}),
                      _QuickItem(icon: Icons.article_outlined, label: 'News', accent: accent, muted: muted, onTap: () {}),
                      _QuickItem(icon: Icons.access_time_rounded, label: 'Prayer', accent: accent, muted: muted, onTap: () {}),
                    ],
                  ),
                ),

                // ─── ANNOUNCEMENTS ───
                _SectionLabel(text: 'ANNOUNCEMENTS', muted: muted, accent: accent, top: 32),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                    decoration: BoxDecoration(
                      color: t.colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: t.dividerColor),
                    ),
                    child: Column(
                      children: _announcements.isEmpty
                        ? [_AnnouncementRow(title: 'No new announcements', meta: 'Check back later.', muted: muted, isFirst: true)]
                        : _announcements.take(3).toList().asMap().entries.map((e) =>
                            _AnnouncementRow(
                              title: e.value['title']?.toString() ?? '',
                              meta: e.value['time']?.toString() ?? '',
                              muted: muted,
                              isFirst: e.key == 0,
                            ),
                          ).toList(),
                    ),
                  ),
                ),

                // ─── FACILITIES ───
                _SectionLabel(text: 'FACILITIES', muted: muted, accent: accent, top: 32),
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: ['Residency', 'Sport Complex', 'Library', 'Health Centre', 'Lab', 'Dewan', 'Mosque'].map((f) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: t.dividerColor),
                        ),
                        child: Text(f,
                          style: GoogleFonts.inter(color: muted, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    )).toList(),
                  ),
                ),

                const SizedBox(height: 36),
                // Footer mark
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Column(
                      children: [
                        Container(width: 24, height: 1, color: accent.withOpacity(0.5)),
                        const SizedBox(height: 10),
                        Text('UMPSA · ${DateTime.now().year}',
                          style: GoogleFonts.inter(color: muted, fontSize: 10, letterSpacing: 2.4, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProfileMenu(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: t.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final isDark = ref.read(themeProvider).isDark;
        final lang = ref.read(languageProvider).locale;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Drag handle
            Container(width: 40, height: 4, decoration: BoxDecoration(color: t.dividerColor, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              onTap: () async { Navigator.pop(ctx); await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())); _loadProfileImage(); },
            ),
            ListTile(
              leading: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
              title: Text(isDark ? 'Light mode' : 'Dark mode'),
              onTap: () { Navigator.pop(ctx); ref.read(themeProvider.notifier).toggle(); },
            ),
            ListTile(
              leading: const Icon(Icons.translate_rounded),
              title: Text(lang == 'en' ? 'Bahasa Melayu' : 'English'),
              onTap: () { Navigator.pop(ctx); ref.read(languageProvider.notifier).toggle(); },
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: SAMsTheme.error),
              title: const Text('Logout', style: TextStyle(color: SAMsTheme.error)),
              onTap: () { Navigator.pop(ctx); ref.read(authProvider.notifier).logout(); Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false); },
            ),
          ]),
        );
      },
    );
  }
}

// ─── Editorial section label ───
class _SectionLabel extends StatelessWidget {
  final String text;
  final Color muted, accent;
  final double top;
  const _SectionLabel({required this.text, required this.muted, required this.accent, this.top = 24});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, top, 24, 0),
      child: Row(
        children: [
          Container(width: 18, height: 1, color: accent),
          const SizedBox(width: 8),
          Text(text,
            style: GoogleFonts.inter(color: muted, fontSize: 10.5, letterSpacing: 2.4, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─── Module row: numbered serif title, subtitle, hairline divider ───
class _ModuleRow extends StatefulWidget {
  final String index, title, subtitle;
  final Color accent;
  final VoidCallback onTap;
  const _ModuleRow({required this.index, required this.title, required this.subtitle, required this.accent, required this.onTap});

  @override
  State<_ModuleRow> createState() => _ModuleRowState();
}

class _ModuleRowState extends State<_ModuleRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final muted = t.textTheme.bodyMedium?.color ?? SAMsTheme.textSecondary;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); HapticFeedback.lightImpact(); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: t.dividerColor)),
          color: _pressed ? widget.accent.withOpacity(0.04) : Colors.transparent,
        ),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 36,
              child: Text(widget.index,
                style: GoogleFonts.fraunces(color: widget.accent, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title,
                    style: GoogleFonts.fraunces(
                      color: t.colorScheme.onSurface,
                      fontSize: 19,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(widget.subtitle,
                    style: GoogleFonts.inter(color: muted, fontSize: 12.5, height: 1.3),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_outward_rounded, size: 18, color: muted),
          ],
        ),
      ),
    );
  }
}

// ─── Quick access item: scale bounce on tap ───
class _QuickItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color accent, muted;
  final VoidCallback onTap;
  const _QuickItem({required this.icon, required this.label, required this.accent, required this.muted, required this.onTap});

  @override
  State<_QuickItem> createState() => _QuickItemState();
}

class _QuickItemState extends State<_QuickItem> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); HapticFeedback.selectionClick(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, __) => Transform.scale(
          scale: _scale.value,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: t.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: t.dividerColor),
                ),
                child: Icon(widget.icon, color: t.colorScheme.onSurface, size: 20),
              ),
              const SizedBox(height: 8),
              Text(widget.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(color: widget.muted, fontSize: 10.5, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Header circular icon button ───
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: t.dividerColor),
        ),
        child: Icon(icon, size: 16, color: t.textTheme.bodyMedium?.color),
      ),
    );
  }
}

// ─── Announcement row in editorial style ───
class _AnnouncementRow extends StatelessWidget {
  final String title, meta;
  final Color muted;
  final bool isFirst;
  const _AnnouncementRow({required this.title, required this.meta, required this.muted, this.isFirst = false});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: isFirst ? null : Border(top: BorderSide(color: t.dividerColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 5, height: 5,
            decoration: BoxDecoration(color: muted, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                  style: t.textTheme.bodyLarge?.copyWith(fontSize: 13.5, height: 1.35),
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(meta,
                    style: GoogleFonts.inter(color: muted, fontSize: 10.5, letterSpacing: 0.4),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
