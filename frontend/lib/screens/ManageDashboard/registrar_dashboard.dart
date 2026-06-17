import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/language_provider.dart' as lp;
import '../../services/api_service.dart';
import '../ManageAuth/login_screen.dart';
import '../../widgets/page_transitions.dart';
import '../../widgets/premium_widgets.dart';
import '../../widgets/pressable_card.dart';
import '../../widgets/shimmer_loading.dart';

class RegistrarDashboard extends ConsumerStatefulWidget {
  final VoidCallback? onViewStudents;
  final VoidCallback? onViewRegistrations;
  const RegistrarDashboard({super.key, this.onViewStudents, this.onViewRegistrations});

  @override
  ConsumerState<RegistrarDashboard> createState() => _RegistrarDashboardState();
}

class _RegistrarDashboardState extends ConsumerState<RegistrarDashboard> with TickerProviderStateMixin {
  List<dynamic> _students = [];
  List<dynamic> _registrations = [];
  bool _loading = true;
  String? _profileImage;
  bool _hasUnread = false;

  late AnimationController _staggerController;
  late AnimationController _balancePulse;
  late AnimationController _flipController;
  late AnimationController _countController;
  late AnimationController _pulseController;
  late Animation<double> _flipAnim;
  late List<Animation<double>> _staggerAnims;

  // Computed stats
  int get _totalStudents => _students.length;
  int get _totalRegistrations => _registrations.length;
  int get _pendingRegistrations => _registrations.where((r) => r['status'] == 'pending').length;
  int get _approvedRegistrations => _registrations.where((r) => r['status'] == 'approved' || r['status'] == 'verified').length;
  int get _rejectedRegistrations => _registrations.where((r) => r['status'] == 'rejected').length;
  double get _approvalRate => _totalRegistrations > 0 ? (_approvedRegistrations / _totalRegistrations * 100) : 0;
  double get _pct => _totalRegistrations > 0 ? (_approvedRegistrations / _totalRegistrations).clamp(0.0, 1.0) : 0.0;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _balancePulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _flipController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _countController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _flipAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutBack),
    );

    // 5 staggered items: header, greeting, info card, stats, quick access
    _staggerAnims = List.generate(5, (i) => CurvedAnimation(
      parent: _staggerController,
      curve: Interval(i * 0.15, 0.4 + i * 0.15, curve: Curves.easeOutCubic),
    ));

    _load();
    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _balancePulse.dispose();
    _flipController.dispose();
    _countController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        ApiService.get('/students'),
        ApiService.get('/registrations'),
      ]);

      List<dynamic> students;
      List<dynamic> registrations;

      if (results[0] is Map && results[0].containsKey('students')) {
        students = results[0]['students'] ?? [];
      } else if (results[0] is List) {
        students = results[0];
      } else {
        students = [];
      }

      if (results[1] is Map && results[1].containsKey('registrations')) {
        registrations = results[1]['registrations'] ?? [];
      } else if (results[1] is List) {
        registrations = results[1];
      } else {
        registrations = [];
      }

      if (!mounted) return;
      setState(() {
        _students = students;
        _registrations = registrations;
        _loading = false;
        _hasUnread = _pendingRegistrations > 0;
      });
      // Animated counter
      _countController.reset();
      _countController.forward();
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    await _load();
    ref.read(authProvider.notifier).refreshProfile();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final user = ref.read(authProvider).user;
    final id = user?['registrarId'] ?? user?['_id'] ?? user?['id'] ?? 'guest';
    final path = prefs.getString('profile_image_$id');
    if (path != null && path.isNotEmpty) {
      setState(() => _profileImage = path);
    }
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

  String _smartTimestamp(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${dt.day}/${dt.month}/${dt.year.toString().substring(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final name = user?['name'] ?? 'Registrar';
    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;
    const accent = SAMsTheme.accent;
    final muted = t.textTheme.bodyMedium?.color ?? SAMsTheme.textSecondary;
    final today = DateFormat('EEEE, d MMMM').format(DateTime.now());
    final faculty = user?['faculty'] ?? user?['department'] ?? 'Faculty';
    final registrarId = user?['registrarId'] ?? user?['_id'] ?? user?['id'] ?? '—';

    return Scaffold(
      body: SafeArea(
        child: PremiumRefreshIndicator(
          backgroundColor: t.scaffoldBackgroundColor,
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
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
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _IconBtn(icon: Icons.notifications_none_rounded, onTap: () {
                            setState(() => _hasUnread = false);
                          }),
                          if (_hasUnread) Positioned(
                            right: 2, top: 2,
                            child: AnimatedBuilder(
                              animation: _pulseController,
                              builder: (_, __) => Transform.scale(
                                scale: 1.0 + _pulseController.value * 0.4,
                                child: Opacity(
                                  opacity: 1.0 - _pulseController.value * 0.4,
                                  child: Container(
                                    width: 6, height: 6,
                                    decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _showProfileMenu(context, ref),
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: accent.withValues(alpha: 0.6), width: 1),
                            color: t.colorScheme.surface,
                          ),
                          child: Center(child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'R',
                            style: GoogleFonts.inter(color: accent, fontSize: 15, fontWeight: FontWeight.w600),
                          )),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_greeting,\n${name.split(' ').first}.',
                        style: t.textTheme.displayMedium?.copyWith(height: 1.05),
                      ),
                    ],
                  ),
                )),

                // ─── REGISTRAR INFO STRIP ───
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
                              Text('FACULTY REGISTRAR',
                                style: GoogleFonts.inter(color: muted, fontSize: 9.5, letterSpacing: 1.6, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(name,
                                style: GoogleFonts.inter(color: t.colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 2),
                              Text(faculty.toString().toUpperCase(),
                                style: GoogleFonts.inter(color: muted, fontSize: 11, letterSpacing: 0.8),
                              ),
                            ],
                          ),
                        ),
                        Text(registrarId.toString(),
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
                        title: 'Open Registration',
                        subtitle: 'Manage course registrations',
                        accent: accent,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),

                // ─── STATS CARD ───
                _fadeSlide(_staggerAnims[3], child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF6F6F8),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: t.dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(width: 18, height: 1, color: accent),
                            const SizedBox(width: 8),
                            Text('REGISTRATION OVERVIEW',
                              style: GoogleFonts.inter(color: muted, fontSize: 10, letterSpacing: 1.8, fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            AnimatedIntText(
                              value: _approvalRate,
                              decimals: 1,
                              suffix: '%',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: accent),
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
                                  Text('$_totalStudents',
                                    style: GoogleFonts.inter(color: t.colorScheme.onSurface, fontSize: 28, fontWeight: FontWeight.w700, height: 1),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Total Students',
                                    style: GoogleFonts.inter(color: muted, fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 36, color: t.dividerColor),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('$_pendingRegistrations',
                                    style: GoogleFonts.inter(color: SAMsTheme.warning, fontSize: 28, fontWeight: FontWeight.w700, height: 1),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Pending',
                                    style: GoogleFonts.inter(color: muted, fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 36, color: t.dividerColor),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('$_approvedRegistrations',
                                    style: GoogleFonts.inter(color: SAMsTheme.success, fontSize: 28, fontWeight: FontWeight.w700, height: 1),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Approved',
                                    style: GoogleFonts.inter(color: muted, fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: AnimatedBuilder(
                            animation: _countController,
                            builder: (_, __) => LinearProgressIndicator(
                              value: _pct * _countController.value,
                              minHeight: 6,
                              backgroundColor: muted.withValues(alpha: 0.15),
                              valueColor: AlwaysStoppedAnimation<Color>(accent),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('${_pct.toStringAsFixed(0)}% approved',
                          style: GoogleFonts.inter(color: muted, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
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
                      _QuickItem(icon: Iconsax.people, label: 'Students', accent: accent, muted: muted, onTap: () => widget.onViewStudents?.call()),
                      _QuickItem(icon: Iconsax.document_normal, label: 'Registrations', accent: accent, muted: muted, onTap: () => widget.onViewRegistrations?.call()),
                      _QuickItem(icon: Iconsax.chart_21, label: 'Reports', accent: accent, muted: muted, onTap: () {}),
                      _QuickItem(icon: Iconsax.calendar_1, label: 'Calendar', accent: accent, muted: muted, onTap: () {}),
                      _QuickItem(icon: Iconsax.notification, label: 'Alerts', accent: accent, muted: muted, onTap: () {}),
                      _QuickItem(icon: Iconsax.chart_1, label: 'Analytics', accent: accent, muted: muted, onTap: () {}),
                      _QuickItem(icon: Iconsax.message, label: 'Messages', accent: accent, muted: muted, onTap: () {}),
                      _QuickItem(icon: Iconsax.setting_2, label: 'Settings', accent: accent, muted: muted, onTap: () {}),
                    ],
                  ),
                ),

                // ─── RECENT REGISTRATIONS ───
                _SectionLabel(text: 'RECENT REGISTRATIONS', muted: muted, accent: accent, top: 32),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Column(
                    children: _registrations.take(5).map((r) {
                      final status = r['status'] ?? 'pending';
                      final studentName = r['student']?['name'] ?? r['studentName'] ?? 'Student';
                      final type = r['type'] ?? 'registration';
                      final col = status == 'approved' || status == 'verified'
                          ? SAMsTheme.success
                          : (status == 'pending' ? SAMsTheme.warning : SAMsTheme.error);
                      final tsRaw = (status == 'pending' ? r['createdAt'] : (r['updatedAt'] ?? r['createdAt']))?.toString();
                      final ts = _smartTimestamp(tsRaw);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: t.colorScheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: t.dividerColor),
                        ),
                        child: Row(children: [
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: col, shape: BoxShape.circle)),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(studentName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.colorScheme.onSurface)),
                            const SizedBox(height: 2),
                            Text(type[0].toUpperCase() + type.substring(1), style: TextStyle(fontSize: 12, color: t.textTheme.bodySmall?.color ?? Colors.grey)),
                          ])),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text(status[0].toUpperCase() + status.substring(1), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: col)),
                            if (ts.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(ts, style: TextStyle(fontSize: 10, color: t.textTheme.bodySmall?.color ?? Colors.grey)),
                            ],
                          ]),
                        ]),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 36),
                // Footer mark
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Column(
                      children: [
                        Container(width: 24, height: 1, color: accent.withValues(alpha: 0.5)),
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
              leading: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
              title: Text(isDark ? 'Light Mode' : 'Dark Mode'),
              onTap: () { Navigator.pop(ctx); ref.read(themeProvider.notifier).toggle(); },
            ),
            ListTile(
              leading: const Icon(Icons.translate_rounded),
              title: Text(lang == 'en' ? 'Bahasa Melayu' : 'English'),
              onTap: () { Navigator.pop(ctx); ref.read(languageProvider.notifier).toggle(); },
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: SAMsTheme.error),
              title: Text('Logout', style: const TextStyle(color: SAMsTheme.error)),
              onTap: () { Navigator.pop(ctx); ref.read(authProvider.notifier).logout(); Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => LoginScreen()), (route) => false); },
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
          color: _pressed ? widget.accent.withValues(alpha: 0.04) : Colors.transparent,
        ),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 36,
              child: Text(widget.index,
                style: GoogleFonts.inter(color: widget.accent, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title,
                    style: GoogleFonts.inter(
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
class _QuickItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent, muted;
  final VoidCallback onTap;
  const _QuickItem({required this.icon, required this.label, required this.accent, required this.muted, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return PressableCard(
      onTap: onTap,
      scale: 0.88,
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
            child: Icon(icon, color: t.colorScheme.onSurface, size: 20),
          ),
          const SizedBox(height: 8),
          Text(label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(color: muted, fontSize: 10.5, fontWeight: FontWeight.w500),
          ),
        ],
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
