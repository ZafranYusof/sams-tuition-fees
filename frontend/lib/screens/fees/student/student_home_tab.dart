import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../services/api_service.dart';
import '../../../services/cache_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/shimmer_loading.dart';
import '../../../widgets/empty_state.dart';

class StudentHomeTab extends ConsumerStatefulWidget {
  const StudentHomeTab({super.key});

  @override
  ConsumerState<StudentHomeTab> createState() => _StudentHomeTabState();
}

class _StudentHomeTabState extends ConsumerState<StudentHomeTab> {
  List<dynamic> _fees = [];
  List<dynamic> _payments = [];
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadCachedThenFresh();
  }

  Future<void> _loadCachedThenFresh() async {
    // Show cached data instantly while fetching fresh
    final cachedFees = await CacheService.get('my_fees', maxAgeMinutes: 60);
    final cachedPayments = await CacheService.get('my_payments', maxAgeMinutes: 60);
    if (cachedFees != null) {
      setState(() { _fees = cachedFees; _payments = cachedPayments ?? []; _loading = false; });
    }
    await _load();
  }

  Future<void> _load() async {
    try {
      final fees = await ApiService.get('/fees/my');
      List<dynamic> payments = [];
      try { payments = await ApiService.get('/fees/payments/history'); } catch (_) {}
      // Cache results
      await CacheService.save('my_fees', fees);
      await CacheService.save('my_payments', payments);
      setState(() { _fees = fees; _payments = payments; _loading = false; _hasError = false; });
    } catch (e) {
      setState(() { _loading = false; _hasError = _fees.isEmpty; });
    }
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
        title: Text('Tuition Fees', style: TextStyle(color: t.colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w600)),
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
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 8),

            // --- HEADER ---
            const Text('Student', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SAMsTheme.primary, letterSpacing: 1.2)),
            const SizedBox(height: 4),
            Text(studentId, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: t.colorScheme.onSurface)),
            const SizedBox(height: 4),
            Text('$_semester  ·  Week $_week', style: TextStyle(fontSize: 12, color: t.textTheme.bodySmall?.color ?? Colors.grey)),

            const SizedBox(height: 20),

            // --- WARNING BANNER ---
            if (_balance > 0 && daysLeft <= 30)
              Container(
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
              )
            else if (_week < 5 && _balance > 0)
              Container(
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
              ),

            // --- BALANCE OVERVIEW ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: t.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: t.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Balance Due', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: t.textTheme.bodySmall?.color ?? Colors.grey)),
                      Text('${(_pct * 100).toStringAsFixed(1)}% paid', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SAMsTheme.primary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(_fmtRm(_balance), style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: _balance > 0 ? t.colorScheme.onSurface : SAMsTheme.success)),
                  const SizedBox(height: 4),
                  Text('of ${_fmtRm(_totalDue)} total fees', style: TextStyle(fontSize: 12, color: t.textTheme.bodySmall?.color ?? Colors.grey)),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: _pct,
                      minHeight: 4,
                      backgroundColor: t.dividerColor,
                      valueColor: AlwaysStoppedAnimation<Color>(_pct >= 1 ? SAMsTheme.success : SAMsTheme.primary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${_fmtRm(_totalPaid)} paid', style: TextStyle(fontSize: 11, color: t.textTheme.bodySmall?.color ?? Colors.grey)),
                      Text(_fmtRm(_totalDue), style: TextStyle(fontSize: 11, color: t.textTheme.bodySmall?.color ?? Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // --- METRIC CARDS (2x2) ---
            Row(children: [
              Expanded(child: _MetricTile(icon: Icons.account_balance_wallet_outlined, label: 'Total Due', value: _fmtRm(_totalDue))),
              const SizedBox(width: 10),
              Expanded(child: _MetricTile(icon: Icons.check_circle_outline_rounded, label: 'Paid', value: _fmtRm(_totalPaid), accent: SAMsTheme.success)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _MetricTile(icon: Icons.hourglass_empty_rounded, label: 'Balance', value: _fmtRm(_balance), accent: _balance > 0 ? SAMsTheme.warning : SAMsTheme.success)),
              const SizedBox(width: 10),
              Expanded(child: _MetricTile(icon: Icons.calendar_today_rounded, label: 'Days Left', value: '$daysLeft', accent: daysLeft <= 7 ? SAMsTheme.error : SAMsTheme.primary)),
            ]),

            const SizedBox(height: 24),

            // --- FEE BREAKDOWN ---
            Text('Fee Breakdown', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t.colorScheme.onSurface)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: t.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: t.dividerColor),
              ),
              child: Column(
                children: [
                  ..._fees.expand((fee) {
                    final items = (fee['items'] as List?) ?? [];
                    return items.map((item) => item);
                  }).toList().asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    final total = _fees.expand((f) => (f['items'] as List?) ?? []).length;
                    return Column(children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(item['description'] ?? '', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: t.colorScheme.onSurface))),
                            Text('RM ${((item['amount'] ?? 0) as num).toStringAsFixed(2)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.colorScheme.onSurface)),
                          ],
                        ),
                      ),
                      if (i < total - 1) Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 16), color: t.dividerColor),
                    ]);
                  }),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- LAST PAYMENT ---
            if (_lastPayment != null) ...[
              Text('Last Payment', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t.colorScheme.onSurface)),
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
                    Text(_fmtRm(((_lastPayment!['amount'] ?? 0) as num).toDouble()), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: t.colorScheme.onSurface)),
                    const SizedBox(height: 2),
                    Text(
                      _lastPayment!['paidAt'] != null
                        ? _lastPayment!['paidAt'].toString().length >= 10
                          ? _lastPayment!['paidAt'].toString().substring(0, 10)
                          : _lastPayment!['paidAt'].toString()
                        : '',
                      style: TextStyle(fontSize: 11, color: t.textTheme.bodySmall?.color ?? Colors.grey),
                    ),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: t.dividerColor, borderRadius: BorderRadius.circular(6)),
                    child: Text('via ${_lastPayment!['method']?.toUpperCase() ?? 'FPX'}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: t.textTheme.bodySmall?.color ?? Colors.grey)),
                  ),
                ]),
              ),
              const SizedBox(height: 24),
            ],

            // --- PAYMENT DEADLINE ---
            if (_dueDate != null && _balance > 0) ...[
              Text('Deadline', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t.colorScheme.onSurface)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: t.cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border(left: BorderSide(color: daysLeft <= 7 ? SAMsTheme.error : SAMsTheme.primary, width: 3)),
                ),
                child: Row(children: [
                  Icon(Icons.event_rounded, color: daysLeft <= 7 ? SAMsTheme.error : SAMsTheme.primary, size: 22),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Payment Due', style: TextStyle(fontSize: 11, color: t.textTheme.bodySmall?.color ?? Colors.grey)),
                    const SizedBox(height: 2),
                    Text(dueDateStr, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t.colorScheme.onSurface)),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: t.dividerColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('$daysLeft days', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: daysLeft <= 7 ? SAMsTheme.error : SAMsTheme.primary)),
                  ),
                ]),
              ),
              const SizedBox(height: 24),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _fmtRm(double n) => 'RM ${n.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  String _monthName(int m) => ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m];
}

// --- METRIC TILE ---
class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  const _MetricTile({required this.icon, required this.label, required this.value, this.accent = SAMsTheme.primary});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: t.colorScheme.onSurface)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: t.textTheme.bodySmall?.color ?? Colors.grey)),
        ],
      ),
    );
  }
}
