import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../services/api_service.dart';
import '../../../providers/auth_provider.dart';

class TreasuryDashboardTab extends ConsumerStatefulWidget {
  final VoidCallback? onViewStudents;
  const TreasuryDashboardTab({super.key, this.onViewStudents});

  @override
  ConsumerState<TreasuryDashboardTab> createState() => _TreasuryDashboardTabState();
}

class _TreasuryDashboardTabState extends ConsumerState<TreasuryDashboardTab> {
  List<dynamic> _fees = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final fees = await ApiService.get('/fees');
      setState(() { _fees = fees; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  int get _totalStudents => _fees.map((f) => f['student']?['_id'] ?? f['student']).toSet().length;
  double get _totalDue => _fees.fold(0.0, (s, f) => s + ((f['totalAmount'] ?? 0) as num).toDouble());
  double get _totalPaid => _fees.fold(0.0, (s, f) => s + ((f['paidAmount'] ?? 0) as num).toDouble());
  double get _outstanding => _totalDue - _totalPaid;
  double get _collectionRate => _totalDue > 0 ? (_totalPaid / _totalDue * 100) : 0;
  int get _fullyPaid => _fees.where((f) => f['status'] == 'paid').length;
  int get _partialPaid => _fees.where((f) => f['status'] == 'partial').length;
  int get _unpaid => _fees.where((f) => f['status'] == 'unpaid' || f['status'] == 'overdue').length;
  double get _pct => _totalDue > 0 ? (_totalPaid / _totalDue).clamp(0.0, 1.0) : 0.0;

  void _showAllPayments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) => Column(children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(padding: const EdgeInsets.all(16), child: Text('All Payments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface))),
          Expanded(child: ListView.builder(
            controller: controller,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _fees.length,
            itemBuilder: (_, i) {
              final f = _fees[i];
              final status = f['status'] ?? 'unpaid';
              final studentName = f['student']?['name'] ?? f['student']?['studentId'] ?? 'Student';
              final amount = ((f['totalAmount'] ?? 0) as num).toDouble();
              final paid = ((f['paidAmount'] ?? 0) as num).toDouble();
              final col = status == 'paid' ? SAMsTheme.success : (status == 'partial' ? SAMsTheme.accent : SAMsTheme.error);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor)),
                child: Row(children: [
                  Container(width: 40, height: 40, decoration: BoxDecoration(color: col.withOpacity(0.12), shape: BoxShape.circle), child: Icon(status == 'paid' ? Icons.check_rounded : Icons.timelapse_rounded, color: col, size: 20)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(studentName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                    Text('RM ${paid.toStringAsFixed(0)} / RM ${amount.toStringAsFixed(0)}', style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
                  ])),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: col.withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: Text(status[0].toUpperCase() + status.substring(1), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: col))),
                ]),
              );
            },
          )),
        ]),
      ),
    );
  }

  void _showAddFeeDialog(BuildContext context) {
    final studentIdCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController(text: 'Tuition Fee');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Fee'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: studentIdCtrl, decoration: const InputDecoration(labelText: 'Student ID (e.g. CB23109)')),
          const SizedBox(height: 12),
          TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
          const SizedBox(height: 12),
          TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (RM)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await ApiService.post('/fees', {
                  'studentId': studentIdCtrl.text.trim(),
                  'items': [{'description': descCtrl.text.trim(), 'amount': double.tryParse(amountCtrl.text) ?? 0, 'category': 'tuition'}],
                  'semester': 2,
                  'academicYear': '2025/2026',
                  'dueDate': '2026-06-30',
                });
                Navigator.pop(ctx);
                _load();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fee added successfully'), backgroundColor: SAMsTheme.success));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: SAMsTheme.error));
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _sendReminder(BuildContext context) {
    final unpaidFees = _fees.where((f) => f['status'] == 'unpaid' || f['status'] == 'overdue').toList();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send Reminder'),
        content: Text('Send payment reminder to ${unpaidFees.length} student(s) with unpaid fees?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reminder sent to ${unpaidFees.length} student(s)'), backgroundColor: SAMsTheme.success));
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final name = user?['name'] ?? 'Admin';

    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: SAMsTheme.primary)));

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: SAMsTheme.primary,
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── GRADIENT HEADER ───
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF003566), Color(0xFF0077B6), Color(0xFF00B4D8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('$_greeting 👋', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                      ])),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                        child: const Text('Treasury', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ]),
                    const SizedBox(height: 20),
                    // Collection summary
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.15))),
                      child: Column(children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('Total Collection', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                          Text('${_collectionRate.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                        ]),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(value: _pct, minHeight: 8, backgroundColor: Colors.white.withOpacity(0.2), valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF48CAE4))),
                        ),
                        const SizedBox(height: 10),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('RM ${_totalPaid.toStringAsFixed(0)} collected', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
                          Text('RM ${_totalDue.toStringAsFixed(0)} total', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
                        ]),
                      ]),
                    ),
                  ]),
                ),

                // ─── STATS CARDS ───
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(children: [
                    Expanded(child: _StatCard(emoji: '👥', label: 'Students', value: '$_totalStudents', color: SAMsTheme.primary)),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard(emoji: '💰', label: 'Outstanding', value: 'RM ${_outstanding.toStringAsFixed(0)}', color: SAMsTheme.error)),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Row(children: [
                    Expanded(child: _StatCard(emoji: '✅', label: 'Collected', value: 'RM ${_totalPaid.toStringAsFixed(0)}', color: SAMsTheme.success)),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard(emoji: '📊', label: 'Total Fees', value: '${_fees.length}', color: const Color(0xFFA855F7))),
                  ]),
                ),

                // ─── FEE STATUS ───
                Padding(padding: const EdgeInsets.fromLTRB(20, 24, 20, 12), child: Text('Fee Status', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 17, fontWeight: FontWeight.w700))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: Theme.of(context).dividerColor)),
                    child: Column(children: [
                      _StatusRow(icon: Icons.check_circle_rounded, label: 'Fully Paid', count: _fullyPaid, total: _fees.length, color: SAMsTheme.success),
                      const SizedBox(height: 14),
                      _StatusRow(icon: Icons.timelapse_rounded, label: 'Partial', count: _partialPaid, total: _fees.length, color: SAMsTheme.accent),
                      const SizedBox(height: 14),
                      _StatusRow(icon: Icons.cancel_rounded, label: 'Unpaid', count: _unpaid, total: _fees.length, color: SAMsTheme.error),
                    ]),
                  ),
                ),

                // ─── QUICK ACTIONS ───
                Padding(padding: const EdgeInsets.fromLTRB(20, 24, 20, 12), child: Text('Quick Actions', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 17, fontWeight: FontWeight.w700))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    Expanded(child: _ActionCard(icon: Icons.people_rounded, label: 'View Students', gradient: const [Color(0xFF667EEA), Color(0xFF764BA2)], onTap: () {
                      widget.onViewStudents?.call();
                    })),
                    const SizedBox(width: 10),
                    Expanded(child: _ActionCard(icon: Icons.receipt_long_rounded, label: 'All Payments', gradient: const [Color(0xFF11998E), Color(0xFF38EF7D)], onTap: () => _showAllPayments(context))),
                  ]),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    Expanded(child: _ActionCard(icon: Icons.add_circle_rounded, label: 'Add Fee', gradient: const [Color(0xFFFC5C7D), Color(0xFF6A82FB)], onTap: () => _showAddFeeDialog(context))),
                    const SizedBox(width: 10),
                    Expanded(child: _ActionCard(icon: Icons.notifications_rounded, label: 'Send Reminder', gradient: const [Color(0xFFF7971E), Color(0xFFFFD200)], onTap: () => _sendReminder(context))),
                  ]),
                ),

                // ─── RECENT ACTIVITY ───
                Padding(padding: const EdgeInsets.fromLTRB(20, 24, 20, 12), child: Text('Recent Fees', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 17, fontWeight: FontWeight.w700))),
                ..._fees.take(5).map((f) {
                  final status = f['status'] ?? 'unpaid';
                  final studentName = f['student']?['name'] ?? f['student']?['studentId'] ?? 'Student';
                  final amount = ((f['totalAmount'] ?? 0) as num).toDouble();
                  final paid = ((f['paidAmount'] ?? 0) as num).toDouble();
                  final col = status == 'paid' ? SAMsTheme.success : (status == 'partial' ? SAMsTheme.accent : SAMsTheme.error);
                  return Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor)),
                    child: Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: col.withOpacity(0.12), shape: BoxShape.circle),
                        child: Icon(status == 'paid' ? Icons.check_rounded : (status == 'partial' ? Icons.timelapse_rounded : Icons.close_rounded), color: col, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(studentName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                        Text('RM ${paid.toStringAsFixed(0)} / RM ${amount.toStringAsFixed(0)}', style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
                      ])),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: col.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                        child: Text(status[0].toUpperCase() + status.substring(1), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: col)),
                      ),
                    ]),
                  );
                }),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── STAT CARD ───
class _StatCard extends StatelessWidget {
  final String emoji, label, value;
  final Color color;
  const _StatCard({required this.emoji, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withOpacity(0.15), color.withOpacity(0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight),
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

// ─── STATUS ROW ───
class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count, total;
  final Color color;
  const _StatusRow({required this.icon, required this.label, required this.count, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? count / total : 0.0;
    return Row(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
          Text('$count', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(value: pct, minHeight: 5, backgroundColor: Theme.of(context).dividerColor, valueColor: AlwaysStoppedAnimation<Color>(color)),
        ),
      ])),
    ]);
  }
}

// ─── ACTION CARD ───
class _ActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.label, required this.gradient, required this.onTap});

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) { setState(() => _scale = 1.0); HapticFeedback.lightImpact(); widget.onTap(); },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: widget.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: widget.gradient[0].withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(widget.icon, color: Colors.white, size: 24),
            const SizedBox(height: 10),
            Text(widget.label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }
}
