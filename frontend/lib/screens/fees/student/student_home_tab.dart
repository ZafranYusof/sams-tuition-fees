import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme.dart';
import '../../../services/api_service.dart';
import '../../../services/cache_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/premium_widgets.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../widgets/pressable_card.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter_tilt/flutter_tilt.dart';
import '../../../providers/language_provider.dart' as lp;
import 'student_fees_shell.dart';

class StudentHomeTab extends ConsumerStatefulWidget {
  const StudentHomeTab({super.key});

  @override
  ConsumerState<StudentHomeTab> createState() => _StudentHomeTabState();
}

class _StudentHomeTabState extends ConsumerState<StudentHomeTab> with TickerProviderStateMixin {
  List<dynamic> _fees = [];
  List<dynamic> _payments = [];
  bool _loading = true;
  Timer? _pollTimer;

  late AnimationController _staggerController;
  late AnimationController _ringController;
  late List<Animation<double>> _staggerAnims;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _ringController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _staggerAnims = List.generate(6, (i) => CurvedAnimation(
      parent: _staggerController,
      curve: Interval(i * 0.12, 0.4 + i * 0.12, curve: Curves.easeOutCubic),
    ));
    _loadCachedThenFresh();
    // #2 Real-time polling every 30s (fees + user status)
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await _load();
      await _refreshUserStatus();
    });
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _ringController.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCachedThenFresh() async {
    // Show cached data instantly while fetching fresh
    final cachedFees = await CacheService.get('my_fees', maxAgeMinutes: 60);
    final cachedPayments = await CacheService.get('my_payments', maxAgeMinutes: 60);
    if (cachedFees != null) {
      List<dynamic> fees;
      if (cachedFees is Map && cachedFees.containsKey('fees')) {
        fees = cachedFees['fees'] ?? [];
      } else if (cachedFees is List) {
        fees = cachedFees;
      } else {
        fees = [];
      }
      if (!mounted) return;
      setState(() { _fees = fees; _payments = cachedPayments ?? []; _loading = false; });
      _staggerController.forward();
    }
    await _load();
  }

  Future<void> _load() async {
    try {
      final response = await ApiService.get('/fees/my');
      // API returns { fees: [...], summary: {...} } or just a list
      List<dynamic> fees;
      if (response is Map && response.containsKey('fees')) {
        fees = response['fees'] ?? [];
      } else if (response is List) {
        fees = response;
      } else {
        fees = [];
      }
      List<dynamic> payments = [];
      try { payments = await ApiService.get('/fees/payments/history'); } catch (_) {}
      // Cache results
      await CacheService.save('my_fees', fees);
      await CacheService.save('my_payments', payments);
      if (!mounted) return;
      setState(() { _fees = fees; _payments = payments; _loading = false; });
      _ringController.reset();
      _ringController.forward();
      if (!_staggerController.isAnimating && _staggerController.value == 0) {
        _staggerController.forward();
      }
    } catch (e) {
      setState(() { _loading = false; });
      if (!_staggerController.isAnimating && _staggerController.value == 0 && _fees.isNotEmpty) {
        _staggerController.forward();
      }
    }
  }

  Future<void> _refreshUserStatus() async {
    try {
      final response = await ApiService.get('/auth/me');
      if (response != null && response is Map) {
        final newStatus = response['studentStatus'] as String?;
        if (newStatus != null && mounted) {
          // Update AuthProvider with fresh status
          ref.read(authProvider.notifier).updateStudentStatus(newStatus);
        }
      }
    } catch (e) {
      // Silent fail - don't disrupt UI if status refresh fails
    }
  }

  Widget _fadeSlide(Animation<double> anim, {required Widget child}) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Opacity(
        opacity: anim.value,
        child: Transform.translate(offset: Offset(0, 16 * (1 - anim.value)), child: child),
      ),
    );
  }

  double get _totalDue => _fees.fold(0.0, (s, f) => s + ((f['totalAmount'] ?? 0) as num).toDouble());
  double get _totalPaid => _fees.fold(0.0, (s, f) => s + ((f['paidAmount'] ?? 0) as num).toDouble());
  double get _balance => _totalDue - _totalPaid;
  double get _pct => _totalDue > 0 ? (_totalPaid / _totalDue).clamp(0.0, 1.0) : 0.0;

  String get _semester {
    if (_fees.isEmpty) return 'Sem 1, 2025/2026';
    final f = _fees.first;
    final sem = f['semester'] ?? 1;
    final year = f['academicYear'] ?? '2025/2026';
    return 'Sem $sem, $year';
  }

  DateTime? get _dueDate {
    for (var f in _fees) {
      if ((f['status'] ?? '') != 'paid' && f['dueDate'] != null) {
        return DateTime.tryParse(f['dueDate'].toString());
      }
    }
    return null;
  }

  int get _daysLeft {
    final due = _dueDate;
    if (due == null) return 0;
    return due.difference(DateTime.now()).inDays.clamp(0, 999);
  }

  int get _week {
    // Derive semester start from fee data, fallback to earliest fee createdAt
    DateTime start = DateTime(2026, 5, 12); // default fallback (shifted +10 weeks for testing)
    for (var f in _fees) {
      if (f['semesterStart'] != null) {
        final parsed = DateTime.tryParse(f['semesterStart'].toString());
        if (parsed != null) { start = parsed; break; }
      }
      if (f['createdAt'] != null) {
        final parsed = DateTime.tryParse(f['createdAt'].toString());
        if (parsed != null && parsed.isBefore(start)) { start = parsed; }
      }
    }
    return (DateTime.now().difference(start).inDays ~/ 7 + 1).clamp(1, 16);
  }

  Map<String, dynamic>? get _lastPayment {
    if (_payments.isEmpty) return null;
    final successful = _payments.where((p) => p['status'] == 'success').toList();
    return successful.isNotEmpty ? successful.first : null;
  }


  String get _studentStatus => (ref.read(authProvider).user?['studentStatus'] ?? 'active').toString();
  String get _financingType => (ref.read(authProvider).user?['financingType'] ?? 'unfinanced').toString();

  String _statusLabel(String status) {
    switch (status) {
      case 'warning':
        return 'Payment warning';
      case 'restricted_1':
        return 'Restriction level 1';
      case 'restricted_2':
        return 'Restriction level 2';
      case 'restricted_3':
        return 'Restriction level 3';
      case 'deferred':
        return 'Deferred';
      default:
        return 'Active';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'warning':
        return SAMsTheme.warning;
      case 'restricted_1':
      case 'restricted_2':
      case 'restricted_3':
      case 'deferred':
        return SAMsTheme.error;
      default:
        return SAMsTheme.success;
    }
  }

  String _financingLabel(String type) {
    switch (type) {
      case 'ptptn':
        return 'PTPTN';
      case 'sponsored':
        return 'Sponsored';
      default:
        return 'Self-funded';
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final loc = ref.watch(lp.languageProvider).locale;
    final user = ref.watch(authProvider).user;
    final studentId = user?['studentId'] ?? 'CB23109';

    // While loading with no cached data, inject dummy fees so Skeletonizer has
    // a realistic UI tree to render placeholders against.
    if (_loading && _fees.isEmpty) {
      _fees = List.generate(3, (i) => {
        '_id': 'skeleton_$i',
        'status': 'unpaid',
        'items': [{'description': 'Loading fee item', 'amount': 1234.0}],
        'totalAmount': 1234.0,
        'paidAmount': 0.0,
        'semester': 1,
        'academicYear': '2025/2026',
        'dueDate': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      });
    }

    final daysLeft = _daysLeft;
    // legacy 'blocked' check no longer used — status now sourced from backend studentStatus
    final dueDateStr = _dueDate != null ? '${_dueDate!.day} ${_monthName(_dueDate!.month)} ${_dueDate!.year}' : 'N/A';

    return Scaffold(
      backgroundColor: t.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: t.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(lp.t('tuition_fees', loc), style: GoogleFonts.inter(color: t.colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w600)),
        leading: IconButton(icon: Icon(Icons.arrow_back, color: t.colorScheme.onSurface), onPressed: () => Navigator.pop(context)),
      ),
      body: PremiumRefreshIndicator(
        onRefresh: _load,
        child: Skeletonizer(
          enabled: _loading,
          child: ListView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 8),

            // --- HEADER ---
            _fadeSlide(_staggerAnims[0], child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lp.t('student', loc).toUpperCase(), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: SAMsTheme.accent, letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Text(studentId, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: t.colorScheme.onSurface)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _HeaderChip(label: _statusLabel(_studentStatus), color: _statusColor(_studentStatus)),
                    _HeaderChip(label: _financingLabel(_financingType), color: SAMsTheme.accent),
                  ],
                ),
                const SizedBox(height: 8),
                Text('$_semester  ·  ${lp.t('week', loc)} $_week', style: GoogleFonts.inter(fontSize: 12, color: t.textTheme.bodySmall?.color ?? Colors.grey)),
              ],
            )),

            const SizedBox(height: 20),

            // --- WARNING BANNER ---
            if (_balance > 0 && daysLeft <= 30)
              _fadeSlide(_staggerAnims[1], child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: t.cardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border(left: BorderSide(color: daysLeft <= 7 ? SAMsTheme.error : SAMsTheme.warning, width: 3)),
                ),
                child: Row(children: [
                  Icon(daysLeft <= 7 ? Icons.error_outline_rounded : Icons.schedule_rounded, color: daysLeft <= 7 ? SAMsTheme.error : SAMsTheme.warning, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    daysLeft <= 7
                      ? '${lp.t('payment', loc)} ${lp.t('overdue_days', loc)} $daysLeft ${lp.t('days', loc)}.'
                      : '${lp.t('payment_due', loc)} $daysLeft ${lp.t('days', loc)}. ${lp.t('pay_before', loc)} $dueDateStr.',
                    style: TextStyle(color: daysLeft <= 7 ? SAMsTheme.error : SAMsTheme.warning, fontSize: 12, fontWeight: FontWeight.w500),
                  )),
                ]),
              ))
            else if (_week < 5 && _balance > 0)
              _fadeSlide(_staggerAnims[1], child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: t.cardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: const Border(left: BorderSide(color: SAMsTheme.warning, width: 3)),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline_rounded, color: SAMsTheme.warning, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text('${lp.t('pay_before', loc)} ${lp.t('week', loc)} 5 ${lp.t('maintain_access', loc)}', style: const TextStyle(color: SAMsTheme.warning, fontSize: 12, fontWeight: FontWeight.w500))),
                ]),
              )),

            // --- BALANCE OVERVIEW (glassmorphism) ---
            _fadeSlide(_staggerAnims[2], child: Tilt(
              tiltConfig: const TiltConfig(angle: 8, leaveDuration: Duration(milliseconds: 600), leaveCurve: Curves.easeOutCubic),
              child: Stack(
              children: [
                // Gradient backdrop so the blur has something to read through
                Positioned.fill(child: Container(
                  decoration: ShapeDecoration(
                    shape: SmoothRectangleBorder(
                      borderRadius: SmoothBorderRadius(cornerRadius: 16, cornerSmoothing: 0.8),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        SAMsTheme.accent.withValues(alpha: 0.28),
                        SAMsTheme.accent.withValues(alpha: 0.08),
                      ],
                    ),
                  ),
                )),
                GlassmorphicCard(
                  padding: const EdgeInsets.all(20),
                  cornerRadius: 16,
                  blurSigma: 20,
                  child: Row(
                    children: [
                      // #5 Progress ring
                      SizedBox(
                        width: 80, height: 80,
                        child: AnimatedBuilder(
                          animation: _ringController,
                          builder: (_, __) => CustomPaint(
                            painter: _ProgressRingPainter(
                              progress: _pct * Curves.easeOutCubic.transform(_ringController.value),
                              bgColor: SAMsTheme.surfaceLight,
                              fgColor: _pct >= 1 ? SAMsTheme.success : SAMsTheme.accent,
                              strokeWidth: 6,
                            ),
                            child: Center(
                              child: Text(
                                '${(_pct * 100 * Curves.easeOutCubic.transform(_ringController.value)).toStringAsFixed(0)}%',
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: t.colorScheme.onSurface),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(lp.t('balance_due', loc), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: t.textTheme.bodySmall?.color ?? Colors.grey)),
                          const SizedBox(height: 6),
                          FlipCurrencyText(
                            value: _balance,
                            style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w700, color: _balance > 0 ? t.colorScheme.onSurface : SAMsTheme.success),
                          ),
                          const SizedBox(height: 4),
                          Text('${lp.t('of', loc)} ${_fmtRm(_totalDue)} ${lp.t('total', loc)}', style: GoogleFonts.inter(fontSize: 12, color: t.textTheme.bodySmall?.color ?? Colors.grey)),
                          const SizedBox(height: 8),
                          Row(children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: SAMsTheme.success, borderRadius: BorderRadius.circular(2))),
                            const SizedBox(width: 6),
                            Text('${_fmtRm(_totalPaid)} ${lp.t('paid', loc).toLowerCase()}', style: GoogleFonts.inter(fontSize: 10, color: t.textTheme.bodySmall?.color ?? Colors.grey)),
                          ]),
                        ],
                      )),
                    ],
                  ),
                ),
              ],
            ))),

            const SizedBox(height: 12),

            // --- METRIC CARDS (2x2) ---
            _fadeSlide(_staggerAnims[3], child: Column(children: [
              Row(children: [
                Expanded(child: _MetricTile(icon: Icons.account_balance_wallet_outlined, label: lp.t('total_due', loc), value: _fmtRm(_totalDue))),
                const SizedBox(width: 10),
                Expanded(child: _MetricTile(icon: Icons.check_circle_outline_rounded, label: lp.t('paid', loc), value: _fmtRm(_totalPaid), accent: SAMsTheme.success)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _MetricTile(icon: Icons.hourglass_empty_rounded, label: lp.t('balance', loc), value: _fmtRm(_balance), accent: _balance > 0 ? SAMsTheme.warning : SAMsTheme.success)),
                const SizedBox(width: 10),
                Expanded(child: _MetricTile(icon: Icons.calendar_today_rounded, label: lp.t('days_left', loc), value: '$daysLeft', accent: daysLeft <= 7 ? SAMsTheme.error : SAMsTheme.accent)),
              ]),
            ])),

            const SizedBox(height: 24),

            // --- FEE BREAKDOWN ---
            _fadeSlide(_staggerAnims[4], child: Builder(builder: (context) {
              // Compute outstanding fees once for both header and empty state.
              final outstanding = _fees.where((fee) {
                final feeStatus = fee['status']?.toString() ?? '';
                final totalAmt = ((fee['totalAmount'] ?? 0) as num).toDouble();
                final paidAmt = ((fee['paidAmount'] ?? 0) as num).toDouble();
                return feeStatus != 'paid' && (totalAmt - paidAmt) > 0.01;
              }).toList();

              if (outstanding.isEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lp.t('fee_breakdown', loc), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: t.colorScheme.onSurface)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: t.cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: t.dividerColor),
                      ),
                      child: Row(children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: SAMsTheme.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.check_circle_rounded, color: SAMsTheme.success, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(lp.t('all_settled', loc), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: t.colorScheme.onSurface)),
                          const SizedBox(height: 2),
                          Text(lp.t('no_outstanding', loc), style: GoogleFonts.inter(fontSize: 12, color: t.textTheme.bodySmall?.color)),
                        ])),
                      ]),
                    ),
                  ],
                );
              }

              return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lp.t('fee_breakdown', loc), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: t.colorScheme.onSurface)),
                const SizedBox(height: 12),
                // Filter out fully-paid fees - only show outstanding ones.
                ...outstanding.map((fee) {
                  final feeId = fee['_id']?.toString() ?? '';
                  final feeStatus = fee['status']?.toString() ?? '';
                  final isPaidFee = feeStatus == 'paid';
                  final items = (fee['items'] as List?) ?? [];
                  final totalAmt = ((fee['totalAmount'] ?? 0) as num).toDouble();
                  final paidAmt = ((fee['paidAmount'] ?? 0) as num).toDouble();
                  final balanceAmt = totalAmt - paidAmt;
                  final semLabel = 'Sem ${fee['semester'] ?? '-'}, ${fee['academicYear'] ?? ''}';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Hero(
                      tag: 'fee_$feeId',
                      flightShuttleBuilder: (_, __, ___, ____, _____) => Material(
                        color: Colors.transparent,
                        child: Container(
                          decoration: BoxDecoration(
                            color: t.cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: t.dividerColor),
                          ),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: PressableCard(
                          onTap: isPaidFee ? null : () {
                            HapticFeedback.lightImpact();
                            Navigator.pushReplacement(context, PageRouteBuilder(
                              transitionDuration: const Duration(milliseconds: 450),
                              reverseTransitionDuration: const Duration(milliseconds: 350),
                              pageBuilder: (_, __, ___) => StudentFeesShell(initialTab: 1, targetFeeId: feeId),
                              transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
                            ));
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: t.cardColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: t.dividerColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                                  child: Row(children: [
                                    Container(
                                      width: 4, height: 32,
                                      decoration: BoxDecoration(
                                        color: isPaidFee ? SAMsTheme.success : SAMsTheme.accent,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(semLabel, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: t.colorScheme.onSurface)),
                                        const SizedBox(height: 2),
                                        Text(isPaidFee ? lp.t('fully_paid', loc) : '${lp.t('tap_to_pay', loc)} RM ${balanceAmt.toStringAsFixed(2)}',
                                          style: GoogleFonts.inter(fontSize: 11, color: isPaidFee ? SAMsTheme.success : t.textTheme.bodySmall?.color)),
                                      ],
                                    )),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: (isPaidFee ? SAMsTheme.success : SAMsTheme.accent).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text('RM ${totalAmt.toStringAsFixed(0)}',
                                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700,
                                          color: isPaidFee ? SAMsTheme.success : SAMsTheme.accent)),
                                    ),
                                  ]),
                                ),
                                Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 16), color: t.dividerColor),
                                ...items.asMap().entries.map((entry) {
                                  final item = entry.value as Map;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    child: Row(children: [
                                      Expanded(child: Text(item['description']?.toString() ?? '',
                                        style: GoogleFonts.inter(fontSize: 12, color: t.textTheme.bodySmall?.color))),
                                      Text('RM ${((item['amount'] ?? 0) as num).toStringAsFixed(2)}',
                                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500,
                                          color: isPaidFee ? SAMsTheme.success : t.colorScheme.onSurface,
                                          decoration: isPaidFee ? TextDecoration.lineThrough : null)),
                                    ]),
                                  );
                                }),
                                const SizedBox(height: 6),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
            })),

            const SizedBox(height: 24),

            // --- LAST PAYMENT & DEADLINE ---
            _fadeSlide(_staggerAnims[5], child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_lastPayment != null) ...[
                  Text(lp.t('last_payment', loc), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: t.colorScheme.onSurface)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: t.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: t.dividerColor),
                    ),
                    child: Row(children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: SAMsTheme.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.receipt_long_rounded, color: SAMsTheme.success, size: 18),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_fmtRm(((_lastPayment!['amount'] ?? 0) as num).toDouble()), style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: t.colorScheme.onSurface)),
                        const SizedBox(height: 2),
                        Text(
                          _lastPayment!['paidAt'] != null
                            ? _lastPayment!['paidAt'].toString().length >= 10
                              ? _lastPayment!['paidAt'].toString().substring(0, 10)
                              : _lastPayment!['paidAt'].toString()
                            : '',
                          style: GoogleFonts.inter(fontSize: 11, color: t.textTheme.bodySmall?.color ?? Colors.grey),
                        ),
                      ])),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: SAMsTheme.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                        child: Text('via ${_lastPayment!['method']?.toUpperCase() ?? 'FPX'}', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: SAMsTheme.accent)),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 24),
                ],

                // --- PAYMENT DEADLINE ---
                if (_dueDate != null && _balance > 0) ...[
                  Text(lp.t('deadline', loc), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: t.colorScheme.onSurface)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: t.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border(left: BorderSide(color: daysLeft <= 7 ? SAMsTheme.error : SAMsTheme.accent, width: 3)),
                    ),
                    child: Row(children: [
                      Icon(Icons.event_rounded, color: daysLeft <= 7 ? SAMsTheme.error : SAMsTheme.accent, size: 22),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(lp.t('payment_due', loc), style: GoogleFonts.inter(fontSize: 11, color: t.textTheme.bodySmall?.color ?? Colors.grey)),
                        const SizedBox(height: 2),
                        Text(dueDateStr, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: t.colorScheme.onSurface)),
                      ])),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: (daysLeft <= 7 ? SAMsTheme.error : SAMsTheme.accent).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('$daysLeft ${lp.t('days', loc)}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: daysLeft <= 7 ? SAMsTheme.error : SAMsTheme.accent)),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            )),

            const SizedBox(height: 16),
          ],
        ),
        ),
      ),
    );
  }

  String _fmtRm(double n) => 'RM ${n.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  String _monthName(int m) => ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m];

}

// --- METRIC TILE ---

class _HeaderChip extends StatelessWidget {
  final String label;
  final Color color;
  const _HeaderChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.2),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  const _MetricTile({required this.icon, required this.label, required this.value, this.accent = SAMsTheme.accent});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: ShapeDecoration(
        color: t.cardColor,
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(cornerRadius: 14, cornerSmoothing: 0.8),
          side: BorderSide(color: t.dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(height: 10),
          Text(value, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: t.colorScheme.onSurface)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: t.textTheme.bodySmall?.color ?? Colors.grey)),
        ],
      ),
    );
  }
}

// #5 Progress ring painter
class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color bgColor, fgColor;
  final double strokeWidth;
  _ProgressRingPainter({required this.progress, required this.bgColor, required this.fgColor, this.strokeWidth = 6});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    // Background ring
    canvas.drawCircle(center, radius, Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth);
    
    // Foreground arc
    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(rect, -1.5708, progress * 6.2832, false, Paint()
        ..color = fgColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter old) => old.progress != progress;
}
