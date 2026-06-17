import 'dart:io';
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
import '../auth/login_screen.dart';
import '../home/profile_screen.dart';
import '../fees/fees_screen.dart';
import '../../widgets/page_transitions.dart';
import '../../widgets/premium_widgets.dart';
import '../../widgets/pressable_card.dart';
import '../../widgets/shimmer_loading.dart';

class LecturerDashboard extends ConsumerStatefulWidget {
  const LecturerDashboard({super.key});

  @override
  ConsumerState<LecturerDashboard> createState() => _LecturerDashboardState();
}

class _LecturerDashboardState extends ConsumerState<LecturerDashboard> with TickerProviderStateMixin {
  String? _profileImage;
  Map<String, dynamic>? _stats;

  late AnimationController _staggerController;
  late AnimationController _balancePulse;
  late AnimationController _flipController;
  late AnimationController _countController;
  late AnimationController _pulseController;
  late Animation<double> _flipAnim;
  bool _isFlipped = false;
  late List<Animation<double>> _staggerAnims;

  // Dynamic state
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
    
    _loadAll();
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

  Future<void> _loadAll() async {
    await Future.wait([_loadProfileImage(), _loadStats()]);
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final user = ref.read(authProvider).user;
    final id = user?['lecturerId'] ?? user?['lecturer_id'] ?? user?['_id'] ?? user?['id'] ?? 'guest';
    final path = prefs.getString('profile_image_$id');
    if (path != null && File(path).existsSync()) {
      setState(() => _profileImage = path);
    }
  }

  Future<void> _loadStats() async {
    try {
      final user = ref.read(authProvider).user;
      final lid = user?['lecturerId'] ?? user?['lecturer_id'] ?? user?['_id'] ?? user?['id'] ?? '';
      if (lid.isNotEmpty) {
        final data = await ApiService.get('/lecturers/$lid/stats');
        setState(() {
          _stats = data['stats'] ?? data;
          _hasUnread = true;
        });
        _countController.reset();
        _countController.forward();
      }
    } catch (_) {
      // Gracefully handle — stats are optional
    }
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

  Widget _buildStatsFront(bool isDark, Color accent, Color muted, ThemeData t) {
    final totalStudents = (_stats?['totalStudents'] ?? 0) is num
        ? (_stats?['totalStudents'] ?? 0) as num
        : 0;
    final totalClasses = (_stats?['totalClasses'] ?? 0) is num
        ? (_stats?['totalClasses'] ?? 0) as num
        : 0;

    final innerChild = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 18, height: 1, color: accent),
            const SizedBox(width: 8),
            Text('OVERVIEW',
              style: GoogleFonts.inter(color: muted, fontSize: 10, letterSpacing: 1.8, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Icon(Icons.flip_rounded, size: 14, color: muted.withValues(alpha: 0.5)),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My Students',
                  style: GoogleFonts.inter(color: muted, fontSize: 11, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                FlipCurrencyText(
                  value: totalStudents.toDouble(),
                  prefix: '',
                  style: GoogleFonts.inter(
                    color: t.colorScheme.onSurface,
                    fontSize: 40,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -1.2,
                    height: 1,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Active Classes',
                  style: GoogleFonts.inter(color: muted, fontSize: 11, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(totalClasses.toString(),
                  style: GoogleFonts.inter(
                    color: accent,
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.8,
                    height: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                _stats != null
                  ? 'Tap to see fee collection details.'
                  : 'Loading statistics...',
                style: t.textTheme.bodyMedium?.copyWith(fontSize: 13),
              ),
            ),
            Icon(Icons.arrow_forward_rounded, size: 18, color: accent),
          ],
        ),
      ],
    );

    return AnimatedBuilder(
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
          GlassmorphicCard(
            padding: const EdgeInsets.all(22),
            cornerRadius: 14,
            blurSigma: 20,
            tint: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.45),
            borderColor: accent.withValues(alpha: 0.20 + _balancePulse.value * 0.10),
            child: child!,
          ),
        ],
      ),
      child: innerChild,
    );
  }

  Widget _buildStatsBack(bool isDark, Color accent, Color muted, ThemeData t) {
    final totalFeesCollected = (_stats?['totalFeesCollected'] ?? 0) is num
        ? (_stats?['totalFeesCollected'] ?? 0) as num
        : 0;
    final outstandingFees = (_stats?['outstandingFees'] ?? 0) is num
        ? (_stats?['outstandingFees'] ?? 0) as num
        : 0;
    final paidStudents = (_stats?['paidStudents'] ?? 0) is num
        ? (_stats?['paidStudents'] ?? 0) as num
        : 0;
    final totalStudents = (_stats?['totalStudents'] ?? 0) is num
        ? (_stats?['totalStudents'] ?? 0) as num
        : 0;
    final paidPercent = totalStudents > 0 ? (paidStudents / totalStudents) : 0.0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF6F6F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 18, height: 1, color: accent),
              const SizedBox(width: 8),
              Text('FEE COLLECTION',
                style: GoogleFonts.inter(color: muted, fontSize: 10, letterSpacing: 1.8, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Icon(Icons.flip_rounded, size: 14, color: muted.withValues(alpha: 0.5)),
            ],
          ),
          const SizedBox(height: 16),
          _breakdownRow('Collected', 'RM ${totalFeesCollected.toStringAsFixed(2)}', const Color(0xFF4CAF50), t),
          const SizedBox(height: 8),
          _breakdownRow('Outstanding', 'RM ${outstandingFees.toStringAsFixed(2)}', outstandingFees > 0 ? const Color(0xFFE53935) : const Color(0xFF4CAF50), t),
          const SizedBox(height: 8),
          _breakdownRow('Students Paid', '${paidStudents.toStringAsFixed(0)} / ${totalStudents.toStringAsFixed(0)}', accent, t),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: paidPercent.toDouble(),
              minHeight: 6,
              backgroundColor: muted.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 8),
          Text('${(paidPercent * 100).toStringAsFixed(0)}% students settled',
            style: GoogleFonts.inter(color: muted, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, String value, Color valueColor, ThemeData t) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: t.textTheme.bodyMedium?.copyWith(fontSize: 13)),
        Text(value, style: GoogleFonts.inter(color: valueColor, fontSize: 16, fontWeight: FontWeight.w500)),
      ],
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
    final name = user?['name'] ?? 'Lecturer';
    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;
    const accent = SAMsTheme.accent;
    final muted = t.textTheme.bodyMedium?.color ?? SAMsTheme.textSecondary;
    final today = DateFormat('EEEE, d MMMM').format(DateTime.now());

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
                            Navigator.pushNamed(context, '/fees', arguments: {'initialTab': 3});
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
                            image: _profileImage != null ? DecorationImage(image: FileImage(File(_profileImage!)), fit: BoxFit.cover) : null,
                          ),
                          child: _profileImage == null
                              ? Center(child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'L',
                                  style: GoogleFonts.inter(color: accent, fontSize: 15, fontWeight: FontWeight.w600),
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

                // ─── LECTURER INFO STRIP ───
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
                              Text((user?['faculty'] ?? 'Faculty of Computing').toString().toUpperCase(),
                                style: GoogleFonts.inter(color: muted, fontSize: 9.5, letterSpacing: 1.6, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(name,
                                style: GoogleFonts.inter(color: t.colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        Text(user?['lecturerId']?.toString() ?? user?['lecturer_id']?.toString() ?? user?['_id']?.toString() ?? '—',
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
                        title: 'Class Attendance',
                        subtitle: 'Mark and manage student attendance',
                        accent: accent,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),

                // ─── STATS: editorial composition ───
                _fadeSlide(_staggerAnims[3], child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                  child: _stats == null
                    ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                        SkeletonStatCard(height: 150),
                        SizedBox(height: 12),
                        Row(children: [
                          Expanded(child: SkeletonListItem()),
                        ]),
                      ])
                    : GestureDetector(
                        onTap: () {
                          setState(() => _isFlipped = !_isFlipped);
                          if (_isFlipped) {
                            _flipController.forward();
                          } else {
                            _flipController.reverse();
                          }
                        },
                        child: AnimatedBuilder(
                          animation: _flipAnim,
                          builder: (_, __) {
                            final angle = _flipAnim.value * math.pi;
                            final isFront = angle < math.pi / 2;
                            return Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001) // perspective
                                ..rotateY(angle),
                              child: isFront
                                ? _buildStatsFront(isDark, accent, muted, t)
                                : Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.identity()..rotateY(math.pi),
                                    child: _buildStatsBack(isDark, accent, muted, t),
                                  ),
                            );
                          },
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
                      _QuickItem(icon: Iconsax.user_search, label: 'Students', accent: accent, muted: muted, onTap: () {}),
                      _QuickItem(icon: Iconsax.document_text, label: 'Reports', accent: accent, muted: muted, onTap: () {}),
                      _QuickItem(icon: Iconsax.message_question, label: 'FAQ', accent: accent, muted: muted, onTap: () {}),
                      _QuickItem(icon: Iconsax.calendar_1, label: 'Calendar', accent: accent, muted: muted, onTap: () {}),
                      _QuickItem(icon: Iconsax.notification, label: 'Alerts', accent: accent, muted: muted, onTap: () {}),
                      _QuickItem(icon: Iconsax.chart_2, label: 'Analytics', accent: accent, muted: muted, onTap: () {}),
                      _QuickItem(icon: Iconsax.sms, label: 'Messages', accent: accent, muted: muted, onTap: () {}),
                      _QuickItem(icon: Iconsax.setting_2, label: 'Settings', accent: accent, muted: muted, onTap: () {}),
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
              title: Text(lp.t('profile', lang)),
              onTap: () async { Navigator.pop(ctx); await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())); _loadProfileImage(); },
            ),
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
