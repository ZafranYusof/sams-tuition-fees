import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme.dart';
import '../../../services/api_service.dart';
import '../../../services/cache_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/shimmer_loading.dart';
import '../../../widgets/empty_state.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
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
  bool _hasError = false;
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
    // #2 Real-time polling every 30s
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
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
      setState(() { _fees = fees; _payments = payments; _loading = false; _hasError = false; });
      _ringController.reset();
      _ringController.forward();
      if (!_staggerController.isAnimating && _staggerController.value == 0) {
        _staggerController.forward();
      }
    } catch (e) {
      setState(() { _loading = false; _hasError = _fees.isEmpty; });
      if (!_staggerController.isAnimating && _staggerController.value == 0 && _fees.isNotEmpty) {
        _staggerController.forward();
      }
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
    DateTime start = DateTime(2026, 2, 9); // default fallback
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

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final user = ref.watch(authProvider).user;
    final studentId = user?['studentId'] ?? 'CB23109';

    if (_loading) return Scaffold(appBar: AppBar(title: const Text('Tuition Fees')), body: const ShimmerCards());

    final daysLeft = _daysLeft;
    final blocked = _week >= 5 && _balance > 0;
    final dueDateStr = _dueDate != null ? '${_dueDate!.day} ${_monthName(_dueDate!.month)} ${_dueDate!.year}' : 'N/A';

    return Scaffold(
      backgroundColor: t.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: t.scaffoldBackgroundColor,
        elevation: 0,
        title: Text('Tuition Fees', style: GoogleFonts.fraunces(color: t.colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w600)),
        leading: IconButton(icon: Icon(Icons.arrow_back, color: t.colorScheme.onSurface), onPressed: () => Navigator.pop(context)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: t.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: blocked ? SAMsTheme.error.withOpacity(0.4) : SAMsTheme.success.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: blocked ? SAMsTheme.error : SAMsTheme.success, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(blocked ? 'Blocked' : 'Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: blocked ? SAMsTheme.error : SAMsTheme.success)),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: SAMsTheme.primary,
        onRefresh: _load,
        child: ListView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 8),

            // --- HEADER ---
            _fadeSlide(_staggerAnims[0], child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('STUDENT', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: SAMsTheme.accent, letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Text(studentId, style: GoogleFonts.fraunces(fontSize: 22, fontWeight: FontWeight.w700, color: t.colorScheme.onSurface)),
                const SizedBox(height: 4),
                Text('$_semester  ·  Week $_week', style: GoogleFonts.inter(fontSize: 12, color: t.textTheme.bodySmall?.color ?? Colors.grey)),
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
                      ? 'Payment overdue in $daysLeft days. Pay now to avoid penalties.'
                      : 'Payment due in $daysLeft days. Pay before $dueDateStr.',
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
                  const Expanded(child: Text('Pay before Week 5 to maintain academic access', style: TextStyle(color: SAMsTheme.warning, fontSize: 12, fontWeight: FontWeight.w500))),
                ]),
              )),

            // --- BALANCE OVERVIEW ---
            _fadeSlide(_staggerAnims[2], child: Container(
              padding: const EdgeInsets.all(20),
              decoration: ShapeDecoration(
                color: t.cardColor,
                shape: SmoothRectangleBorder(
                  borderRadius: SmoothBorderRadius(cornerRadius: 16, cornerSmoothing: 0.8),
                  side: BorderSide(color: t.dividerColor),
                ),
              ),
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
                          bgColor: t.dividerColor,
                          fgColor: _pct >= 1 ? SAMsTheme.success : SAMsTheme.accent,
                          strokeWidth: 6,
                        ),
                        child: Center(
                          child: Text(
                            '${(_pct * 100 * Curves.easeOutCubic.transform(_ringController.value)).toStringAsFixed(0)}%',
                            style: GoogleFonts.fraunces(fontSize: 16, fontWeight: FontWeight.w700, color: t.colorScheme.onSurface),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Balance Due', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: t.textTheme.bodySmall?.color ?? Colors.grey)),
                      const SizedBox(height: 6),
                      AnimatedTextKit(
                        animatedTexts: [
                          TyperAnimatedText(
                            _fmtRm(_balance),
                            textStyle: GoogleFonts.fraunces(fontSize: 26, fontWeight: FontWeight.w700, color: _balance > 0 ? t.colorScheme.onSurface : SAMsTheme.success),
                            speed: const Duration(milliseconds: 60),
                          ),
                        ],
                        isRepeatingAnimation: false,
                        totalRepeatCount: 1,
                      ),
                      const SizedBox(height: 4),
                      Text('of ${_fmtRm(_totalDue)} total', style: GoogleFonts.inter(fontSize: 12, color: t.textTheme.bodySmall?.color ?? Colors.grey)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: SAMsTheme.success, borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 6),
                        Text('${_fmtRm(_totalPaid)} paid', style: GoogleFonts.inter(fontSize: 10, color: t.textTheme.bodySmall?.color ?? Colors.grey)),
                      ]),
                    ],
                  )),
                ],
              ),
            )),

            const SizedBox(height: 12),

            // --- METRIC CARDS (2x2) ---
            _fadeSlide(_staggerAnims[3], child: Column(children: [
              Row(children: [
                Expanded(child: _MetricTile(icon: Icons.account_balance_wallet_outlined, label: 'Total Due', value: _fmtRm(_totalDue))),
                const SizedBox(width: 10),
                Expanded(child: _MetricTile(icon: Icons.check_circle_outline_rounded, label: 'Paid', value: _fmtRm(_totalPaid), accent: SAMsTheme.success)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _MetricTile(icon: Icons.hourglass_empty_rounded, label: 'Balance', value: _fmtRm(_balance), accent: _balance > 0 ? SAMsTheme.warning : SAMsTheme.success)),
                const SizedBox(width: 10),
                Expanded(child: _MetricTile(icon: Icons.calendar_today_rounded, label: 'Days Left', value: '$daysLeft', accent: daysLeft <= 7 ? SAMsTheme.error : SAMsTheme.accent)),
              ]),
            ])),

            const SizedBox(height: 24),

            // --- FEE BREAKDOWN ---
            _fadeSlide(_staggerAnims[4], child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fee Breakdown', style: GoogleFonts.fraunces(fontSize: 14, fontWeight: FontWeight.w600, color: t.colorScheme.onSurface)),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: t.cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: t.dividerColor),
                  ),
                  child: Column(
                    children: [
                      // #8 Dynamic reordering: unpaid first, then paid
                      ..._sortedFeeItems().where((item) => item['paid'] != true).toList().asMap().entries.map((entry) {
                        final i = entry.key;
                        final item = entry.value;
                        final total = _sortedFeeItems().where((item) => item['paid'] != true).length;
                        final isPaid = item['paid'] == true;
                        return Column(children: [
                          // #6 Swipe-to-pay
                          Dismissible(
                            key: Key('fee_${item['description']}_$i'),
                            direction: isPaid ? DismissDirection.none : DismissDirection.startToEnd,
                            background: Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 20),
                              decoration: BoxDecoration(
                                color: SAMsTheme.accent.withOpacity(0.15),
                                borderRadius: i == 0 ? const BorderRadius.vertical(top: Radius.circular(14)) : null,
                              ),
                              child: Row(children: [
                                Icon(Icons.payment_rounded, color: SAMsTheme.accent, size: 18),
                                const SizedBox(width: 8),
                                Text('Pay now', style: GoogleFonts.inter(color: SAMsTheme.accent, fontSize: 12, fontWeight: FontWeight.w600)),
                              ]),
                            ),
                            confirmDismiss: (_) async {
                              // Navigate to Payment tab (index 1)
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => const StudentFeesShell(initialTab: 1),
                              ));
                              return false;
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 4, height: 28,
                                    decoration: BoxDecoration(
                                      color: isPaid ? SAMsTheme.success : SAMsTheme.warning,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item['description'] ?? '', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: t.colorScheme.onSurface)),
                                      if (!isPaid) Text('Swipe right to pay', style: GoogleFonts.inter(fontSize: 10, color: t.textTheme.bodySmall?.color?.withOpacity(0.5))),
                                    ],
                                  )),
                                  Text('RM ${((item['amount'] ?? 0) as num).toStringAsFixed(2)}',
                                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600,
                                      color: isPaid ? SAMsTheme.success : t.colorScheme.onSurface,
                                      decoration: isPaid ? TextDecoration.lineThrough : null)),
                                ],
                              ),
                            ),
                          ),
                          if (i < total - 1) Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 16), color: t.dividerColor),
                        ]);
                      }),
                    ],
                  ),
                ),
              ],
            )),

            const SizedBox(height: 24),

            // --- LAST PAYMENT & DEADLINE ---
            _fadeSlide(_staggerAnims[5], child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_lastPayment != null) ...[
                  Text('Last Payment', style: GoogleFonts.fraunces(fontSize: 14, fontWeight: FontWeight.w600, color: t.colorScheme.onSurface)),
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
                          color: t.dividerColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.receipt_long_rounded, color: SAMsTheme.success, size: 18),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_fmtRm(((_lastPayment!['amount'] ?? 0) as num).toDouble()), style: GoogleFonts.fraunces(fontSize: 15, fontWeight: FontWeight.w700, color: t.colorScheme.onSurface)),
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
                        decoration: BoxDecoration(color: t.dividerColor, borderRadius: BorderRadius.circular(6)),
                        child: Text('via ${_lastPayment!['method']?.toUpperCase() ?? 'FPX'}', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: t.textTheme.bodySmall?.color ?? Colors.grey)),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 24),
                ],

                // --- PAYMENT DEADLINE ---
                if (_dueDate != null && _balance > 0) ...[
                  Text('Deadline', style: GoogleFonts.fraunces(fontSize: 14, fontWeight: FontWeight.w600, color: t.colorScheme.onSurface)),
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
                        Text('Payment Due', style: GoogleFonts.inter(fontSize: 11, color: t.textTheme.bodySmall?.color ?? Colors.grey)),
                        const SizedBox(height: 2),
                        Text(dueDateStr, style: GoogleFonts.fraunces(fontSize: 16, fontWeight: FontWeight.w700, color: t.colorScheme.onSurface)),
                      ])),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: t.dividerColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('$daysLeft days', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: daysLeft <= 7 ? SAMsTheme.error : SAMsTheme.accent)),
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
    );
  }

  String _fmtRm(double n) => 'RM ${n.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  String _monthName(int m) => ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m];

  // #8 Dynamic reordering: unpaid items first, paid items last
  List<Map<String, dynamic>> _sortedFeeItems() {
    final allItems = <Map<String, dynamic>>[];
    for (var fee in _fees) {
      final items = (fee['items'] as List?) ?? [];
      final feeStatus = fee['status']?.toString() ?? '';
      for (var item in items) {
        final map = Map<String, dynamic>.from(item as Map);
        map['paid'] = feeStatus == 'paid' || map['paid'] == true;
        allItems.add(map);
      }
    }
    // Sort: unpaid first
    allItems.sort((a, b) {
      if (a['paid'] == true && b['paid'] != true) return 1;
      if (a['paid'] != true && b['paid'] == true) return -1;
      return 0;
    });
    return allItems;
  }
}

// --- METRIC TILE ---
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
          Text(value, style: GoogleFonts.fraunces(fontSize: 15, fontWeight: FontWeight.w700, color: t.colorScheme.onSurface)),
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
