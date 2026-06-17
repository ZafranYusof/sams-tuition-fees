import 'dart:math' as math;
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
import '../../widgets/page_transitions.dart';
import '../../widgets/premium_widgets.dart';
import '../../widgets/pressable_card.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/app_toast.dart';

class PusatAdabDashboard extends ConsumerStatefulWidget {
  final VoidCallback? onViewStudents;
  const PusatAdabDashboard({super.key, this.onViewStudents});

  @override
  ConsumerState<PusatAdabDashboard> createState() => _PusatAdabDashboardState();
}

class _PusatAdabDashboardState extends ConsumerState<PusatAdabDashboard> with TickerProviderStateMixin {
  List<dynamic> _cases = [];
  bool _loading = true;

  late AnimationController _staggerController;
  late AnimationController _balancePulse;
  late AnimationController _flipController;
  late AnimationController _countController;
  late AnimationController _pulseController;
  late Animation<double> _flipAnim;
  bool _isFlipped = false;
  late List<Animation<double>> _staggerAnims;

  bool _hasUnread = false;

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
      final response = await ApiService.get('/adab/cases');
      List<dynamic> cases;
      if (response is Map && response.containsKey('cases')) {
        cases = response['cases'] ?? [];
      } else if (response is List) {
        cases = response;
      } else {
        cases = [];
      }
      if (!mounted) return;
      setState(() { _cases = cases; _loading = false; });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _staggerController.forward();
          _countController.reset();
          _countController.forward();
        }
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    await _load();
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

  // Computed stats
  int get _totalStudents => _cases.map((c) => c['student']?['_id'] ?? c['student']).toSet().length;
  int get _openCases => _cases.where((c) => c['status'] == 'open' || c['status'] == 'pending').length;
  int get _resolvedCases => _cases.where((c) => c['status'] == 'resolved' || c['status'] == 'closed').length;
  int get _warningCases => _cases.where((c) => c['severity'] == 'warning').length;
  int get _minorCases => _cases.where((c) => c['severity'] == 'minor').length;
  int get _majorCases => _cases.where((c) => c['severity'] == 'major' || c['severity'] == 'critical').length;
  double get _resolutionRate => _cases.isNotEmpty ? (_resolvedCases / _cases.length * 100) : 0;
  double get _resolutionPct => _cases.isNotEmpty ? (_resolvedCases / _cases.length).clamp(0.0, 1.0) : 0.0;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// Smart relative timestamp
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

  void _showEditorialSnack(BuildContext context, String message, {bool isError = false, bool isLoading = false}) {
    if (isError) {
      AppToast.error(context, message);
    } else if (isLoading) {
      AppToast.info(context, message);
    } else {
      AppToast.success(context, message);
    }
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
              title: Text(isDark ? lp.t('light_mode', lang) : lp.t('dark_mode', lang)),
              onTap: () { Navigator.pop(ctx); ref.read(themeProvider.notifier).toggle(); },
            ),
            ListTile(
              leading: const Icon(Icons.translate_rounded),
              title: Text(lang == 'en' ? 'Bahasa Melayu' : 'English'),
              onTap: () { Navigator.pop(ctx); ref.read(languageProvider.notifier).toggle(); },
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: SAMsTheme.error),
              title: Text(lp.t('logout', lang), style: const TextStyle(color: SAMsTheme.error)),
              onTap: () { Navigator.pop(ctx); ref.read(authProvider.notifier).logout(); },
            ),
          ]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;
    const accent = SAMsTheme.accent;
    final muted = t.textTheme.bodyMedium?.color ?? SAMsTheme.textSecondary;
    final user = ref.watch(authProvider).user;
    final name = user?['name'] ?? 'Admin';
    final staffId = user?['staffId'] ?? user?['staff_id'] ?? user?['_id'] ?? '—';
    final locale = ref.watch(lp.languageProvider).locale;
    String tr(String k) => lp.translations[locale]?[k] ?? lp.translations['en']?[k] ?? k;
    final today = DateFormat('EEEE, d MMMM').format(DateTime.now());

    // Inject dummy cases so Skeletonizer has UI to render placeholders against.
    if (_loading && _cases.isEmpty) {
      _cases = List.generate(4, (i) => (<String, dynamic>{
        '_id': 'skeleton_$i',
        'status': i.isEven ? 'resolved' : 'open',
        'severity': i.isEven ? 'minor' : 'warning',
        'category': 'discipline',
        'student': {'_id': 'stu_$i', 'name': 'Loading Student', 'studentId': 'CB00000'},
        'description': 'Loading case details...',
        'createdAt': DateTime.now().toIso8601String(),
      }));
    }

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
                            name.isNotEmpty ? name[0].toUpperCase() : 'A',
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

                // ─── STAFF INFO STRIP ───
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
                              Text('PUSAT ADAB',
                                style: GoogleFonts.inter(color: muted, fontSize: 9.5, letterSpacing: 1.6, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(name,
                                style: GoogleFonts.inter(color: t.colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        Text(staffId.toString(),
                          style: GoogleFonts.jetBrainsMono(color: muted, fontSize: 12, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── SECTION LABEL: MODULES ───
                _SectionLabel(text: 'MODULES', muted: muted, accent: accent, top: 36),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Column(
                    children: [
                      _ModuleRow(
                        index: '01',
                        title: 'Curriculum Activity',
                        subtitle: 'Manage curriculum activities and credit claims',
                        accent: accent,
                        onTap: () => widget.onViewStudents?.call(),
                      ),
                    ],
                  ),
                ),

                // ─── STATS CARD ───
                _fadeSlide(_staggerAnims[3], child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                  child: AnimatedBuilder(
                    animation: _balancePulse,
                    builder: (_, child) => Stack(
                      children: [
                        Positioned.fill(child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                accent.withValues(alpha: 0.30 + _balancePulse.value * 0.06),
                                accent.withValues(alpha: 0.08),
                              ],
                            ),
                          ),
                        )),
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.white.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: accent.withValues(alpha: 0.20 + _balancePulse.value * 0.10)),
                          ),
                          child: child!,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(width: 18, height: 1, color: accent),
                            const SizedBox(width: 8),
                            Text('CASE OVERVIEW',
                              style: GoogleFonts.inter(color: muted, fontSize: 10, letterSpacing: 1.8, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FlipCurrencyText(
                                  value: _resolvedCases.toDouble(),
                                  fractionDigits: 0,
                                  prefix: '',
                                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: t.colorScheme.onSurface),
                                ),
                                const SizedBox(height: 2),
                                Text('${tr('of')} ${_cases.length} ${tr('total_cases')}', style: TextStyle(fontSize: 12, color: t.textTheme.bodySmall?.color ?? Colors.grey)),
                              ],
                            )),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Animated progress bar
                        AnimatedBuilder(
                          animation: _countController,
                          builder: (_, __) => ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: _resolutionPct * _countController.value,
                              minHeight: 4,
                              backgroundColor: SAMsTheme.surfaceLight,
                              valueColor: const AlwaysStoppedAnimation<Color>(SAMsTheme.primary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Stats row
                        Row(
                          children: [
                            _StatItem(
                              label: 'Students',
                              value: '$_totalStudents',
                              color: accent,
                            ),
                            Container(width: 1, height: 28, color: t.dividerColor),
                            _StatItem(
                              label: 'Open',
                              value: '$_openCases',
                              color: SAMsTheme.error,
                            ),
                            Container(width: 1, height: 28, color: t.dividerColor),
                            _StatItem(
                              label: 'Resolved',
                              value: '$_resolvedCases',
                              color: SAMsTheme.success,
                            ),
                          ],
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
                      _QuickItem(icon: Iconsax.document_text, label: 'Cases', accent: accent, muted: muted, onTap: () {}),
                      _QuickItem(icon: Iconsax.people, label: 'Students', accent: accent, muted: muted, onTap: () {}),
                      _QuickItem(icon: Iconsax.chart_2, label: 'Reports', accent: accent, muted: muted, onTap: () {}),
                      _QuickItem(icon: Iconsax.calendar_1, label: 'Calendar', accent: accent, muted: muted, onTap: () {}),
                      _QuickItem(icon: Iconsax.warning_2, label: 'Alerts', accent: accent, muted: muted, onTap: () {}),
                      _QuickItem(icon: Iconsax.status, label: 'Analytics', accent: accent, muted: muted, onTap: () {}),
                      _QuickItem(icon: Iconsax.message, label: 'Messages', accent: accent, muted: muted, onTap: () {}),
                      _QuickItem(icon: Iconsax.setting_2, label: 'Settings', accent: accent, muted: muted, onTap: () {}),
                    ],
                  ),
                ),

                // ─── RECENT CASES ───
                _SectionLabel(text: 'RECENT CASES', muted: muted, accent: accent, top: 32),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Column(
                    children: [
                      ..._cases.take(5).map((c) {
                        final status = c['status'] ?? 'open';
                        final studentName = c['student']?['name'] ?? c['student']?['studentId'] ?? 'Student';
                        final category = (c['category'] ?? 'General').toString().replaceAll('_', ' ');
                        final severity = c['severity'] ?? 'minor';
                        final col = status == 'resolved' || status == 'closed'
                            ? SAMsTheme.success
                            : (status == 'pending' ? SAMsTheme.warning : SAMsTheme.error);
                        final sevCol = severity == 'major' || severity == 'critical'
                            ? SAMsTheme.error
                            : (severity == 'warning' ? SAMsTheme.warning : SAMsTheme.primary);
                        final tsRaw = (status == 'resolved' || status == 'closed'
                            ? (c['updatedAt'] ?? c['createdAt'])
                            : c['createdAt'])?.toString();
                        final ts = _smartTimestamp(tsRaw);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: t.cardColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: t.dividerColor),
                          ),
                          child: Row(children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: col, shape: BoxShape.circle)),
                            const SizedBox(width: 14),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(studentName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.colorScheme.onSurface)),
                              const SizedBox(height: 2),
                              Text('$category · ${severity[0].toUpperCase() + severity.substring(1)}', style: TextStyle(fontSize: 12, color: sevCol.withValues(alpha: 0.8))),
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
                      }),
                    ],
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

// ─── Stat item for the overview card ───
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
            style: GoogleFonts.inter(color: color, fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(label,
            style: GoogleFonts.inter(color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
