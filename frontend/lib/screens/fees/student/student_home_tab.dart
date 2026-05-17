import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../services/api_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/shimmer_loading.dart';

class StudentHomeTab extends ConsumerStatefulWidget {
  const StudentHomeTab({super.key});

  @override
  ConsumerState<StudentHomeTab> createState() => _StudentHomeTabState();
}

class _StudentHomeTabState extends ConsumerState<StudentHomeTab> {
  List<dynamic> _fees = [];
  List<dynamic> _payments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final fees = await ApiService.get('/fees/my');
      List<dynamic> payments = [];
      try { payments = await ApiService.get('/fees/payments/history'); } catch (_) {}
      setState(() { _fees = fees; _payments = payments; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  double get _totalDue => _fees.fold(0.0, (s, f) => s + ((f['totalAmount'] ?? 0) as num).toDouble());
  double get _totalPaid => _fees.fold(0.0, (s, f) => s + ((f['paidAmount'] ?? 0) as num).toDouble());
  double get _balance => _totalDue - _totalPaid;
  double get _pct => _totalDue > 0 ? (_totalPaid / _totalDue).clamp(0.0, 1.0) : 0.0;

  // Dynamic semester info from fee data
  String get _semester {
    if (_fees.isEmpty) return 'Sem 1, 2025/2026';
    final f = _fees.first;
    final sem = f['semester'] ?? 1;
    final year = f['academicYear'] ?? '2025/2026';
    return 'Sem $sem, $year';
  }

  // Due date from earliest unpaid fee
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
    final start = DateTime(2026, 2, 9);
    return (DateTime.now().difference(start).inDays ~/ 7 + 1).clamp(1, 16);
  }

  // Last payment
  Map<String, dynamic>? get _lastPayment {
    if (_payments.isEmpty) return null;
    final successful = _payments.where((p) => p['status'] == 'success').toList();
    return successful.isNotEmpty ? successful.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final studentId = user?['studentId'] ?? 'CB23109';

    if (_loading) return Scaffold(appBar: AppBar(title: const Text('Tuition Fees')), body: const ShimmerCards());

    final daysLeft = _daysLeft;
    final blocked = _week >= 5 && _balance > 0;
    final dueDateStr = _dueDate != null ? '${_dueDate!.day} ${_monthName(_dueDate!.month)} ${_dueDate!.year}' : 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tuition Fees'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: blocked ? SAMsTheme.error.withOpacity(0.15) : SAMsTheme.success.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: blocked ? SAMsTheme.error.withOpacity(0.3) : SAMsTheme.success.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 7, height: 7, decoration: BoxDecoration(color: blocked ? SAMsTheme.error : SAMsTheme.success, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(blocked ? 'Blocked' : 'Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: blocked ? SAMsTheme.error : SAMsTheme.success)),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: SAMsTheme.primary,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Text('Hello, $studentId 👋', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 2),
            Text('$_semester · Week $_week', style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
            const SizedBox(height: 16),

            // Dynamic warning based on status
            if (_balance > 0 && daysLeft <= 30)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (daysLeft <= 7 ? SAMsTheme.error : SAMsTheme.accent).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: (daysLeft <= 7 ? SAMsTheme.error : SAMsTheme.accent).withOpacity(0.3)),
                ),
                child: Text(
                  daysLeft <= 7
                    ? '🚨  Payment overdue in $daysLeft days! Pay now to avoid penalties.'
                    : '⚠️  Payment due in $daysLeft days. Pay before $dueDateStr.',
                  style: TextStyle(color: daysLeft <= 7 ? SAMsTheme.error : SAMsTheme.accent, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              )
            else if (_week < 5 && _balance > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: SAMsTheme.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: SAMsTheme.accent.withOpacity(0.3))),
                child: const Text('⚠️  Pay before Week 5 to maintain academic access', style: TextStyle(color: SAMsTheme.accent, fontSize: 12, fontWeight: FontWeight.w600)),
              ),

            // Summary cards
            Row(
              children: [
                Expanded(child: _SummaryCard(label: 'Total Due', value: _fmtRm(_totalDue), emoji: '💰', color: SAMsTheme.primary)),
                const SizedBox(width: 10),
                Expanded(child: _SummaryCard(label: 'Paid', value: _fmtRm(_totalPaid), emoji: '✅', color: SAMsTheme.success)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _SummaryCard(label: 'Balance', value: _fmtRm(_balance), emoji: '⏳', color: SAMsTheme.accent)),
                const SizedBox(width: 10),
                Expanded(child: _SummaryCard(label: 'Days Left', value: '$daysLeft', emoji: '📆', color: const Color(0xFFA855F7))),
              ],
            ),
            const SizedBox(height: 16),

            // Progress
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: Theme.of(context).dividerColor)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment Progress', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 10),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('${_fmtRm(_totalPaid)} paid', style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color)),
                    Text('${(_pct * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12, color: SAMsTheme.primary, fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 8),
                  ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: _pct, minHeight: 8, backgroundColor: Theme.of(context).dividerColor, valueColor: AlwaysStoppedAnimation<Color>(_pct >= 1 ? SAMsTheme.success : SAMsTheme.primary))),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('RM 0', style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
                    Text(_fmtRm(_totalDue), style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Fee breakdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: Theme.of(context).dividerColor)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fee Breakdown', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 12),
                  ..._fees.expand((fee) {
                    final items = (fee['items'] as List?) ?? [];
                    return items.map((item) => Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item['description'] ?? '', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                          Text('RM ${((item['amount'] ?? 0) as num).toStringAsFixed(2)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                        ],
                      ),
                    ));
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Last payment
            if (_lastPayment != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: Theme.of(context).dividerColor)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Last Payment', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: SAMsTheme.success.withOpacity(0.12), shape: BoxShape.circle),
                      child: const Icon(Icons.check_circle_rounded, color: SAMsTheme.success, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_fmtRm(((_lastPayment!['amount'] ?? 0) as num).toDouble()), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
                      Text(_lastPayment!['paidAt'] != null ? _lastPayment!['paidAt'].toString().length >= 10 ? _lastPayment!['paidAt'].toString().substring(0, 10) : _lastPayment!['paidAt'].toString() : '', style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
                    ])),
                    Text('via ${_lastPayment!['method']?.toUpperCase() ?? 'FPX'}', style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color, fontWeight: FontWeight.w600)),
                  ]),
                ]),
              ),

            // Payment deadline
            if (_dueDate != null && _balance > 0) ...[  
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: daysLeft <= 7
                      ? [SAMsTheme.error.withOpacity(0.15), SAMsTheme.error.withOpacity(0.05)]
                      : [SAMsTheme.primary.withOpacity(0.15), SAMsTheme.primary.withOpacity(0.05)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: (daysLeft <= 7 ? SAMsTheme.error : SAMsTheme.primary).withOpacity(0.3)),
                ),
                child: Row(children: [
                  Icon(daysLeft <= 7 ? Icons.warning_rounded : Icons.calendar_today_rounded, color: daysLeft <= 7 ? SAMsTheme.error : SAMsTheme.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Payment Deadline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodySmall?.color)),
                    const SizedBox(height: 2),
                    Text(dueDateStr, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: (daysLeft <= 7 ? SAMsTheme.error : SAMsTheme.primary).withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                    child: Text('$daysLeft days', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: daysLeft <= 7 ? SAMsTheme.error : SAMsTheme.primary)),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _fmtRm(double n) => 'RM ${n.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';  

  String _monthName(int m) => ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m];
}

class _SummaryCard extends StatelessWidget {
  final String label, value, emoji;
  final Color color;
  const _SummaryCard({required this.label, required this.value, required this.emoji, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withOpacity(0.2), color.withOpacity(0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 6),
        Text(label.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Theme.of(context).textTheme.bodySmall?.color, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
      ]),
    );
  }
}
