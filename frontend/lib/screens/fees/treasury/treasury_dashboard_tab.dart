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
      backgroundColor: SAMsTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) => Column(children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 36, height: 4,
            decoration: BoxDecoration(color: SAMsTheme.border, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('All Payments', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: SAMsTheme.textPrimary)),
                Text('${_fees.length} records', style: const TextStyle(fontSize: 12, color: SAMsTheme.textMuted)),
              ],
            ),
          ),
          Container(height: 1, color: SAMsTheme.border),
          Expanded(child: ListView.separated(
            controller: controller,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            itemCount: _fees.length,
            separatorBuilder: (_, __) => Container(height: 1, margin: const EdgeInsets.symmetric(vertical: 8), color: SAMsTheme.border),
            itemBuilder: (_, i) {
              final f = _fees[i];
              final status = f['status'] ?? 'unpaid';
              final studentName = f['student']?['name'] ?? f['student']?['studentId'] ?? 'Student';
              final amount = ((f['totalAmount'] ?? 0) as num).toDouble();
              final paid = ((f['paidAmount'] ?? 0) as num).toDouble();
              final col = status == 'paid' ? SAMsTheme.success : (status == 'partial' ? SAMsTheme.warning : SAMsTheme.error);
              return Row(children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: col, shape: BoxShape.circle)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(studentName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SAMsTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Text('RM ${paid.toStringAsFixed(0)} / RM ${amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: SAMsTheme.textMuted)),
                ])),
                Text(status[0].toUpperCase() + status.substring(1), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: col)),
              ]);
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
        backgroundColor: SAMsTheme.surface,
        title: const Text('Add Fee', style: TextStyle(color: SAMsTheme.textPrimary)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: studentIdCtrl, style: const TextStyle(color: SAMsTheme.textPrimary), decoration: const InputDecoration(labelText: 'Student ID (e.g. CB23109)')),
          const SizedBox(height: 12),
          TextField(controller: descCtrl, style: const TextStyle(color: SAMsTheme.textPrimary), decoration: const InputDecoration(labelText: 'Description')),
          const SizedBox(height: 12),
          TextField(controller: amountCtrl, style: const TextStyle(color: SAMsTheme.textPrimary), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (RM)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: SAMsTheme.textMuted))),
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
        backgroundColor: SAMsTheme.surface,
        title: const Text('Send Reminder', style: TextStyle(color: SAMsTheme.textPrimary)),
        content: Text('Send payment reminder to ${unpaidFees.length} student(s) with unpaid fees?', style: const TextStyle(color: SAMsTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: SAMsTheme.textMuted))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                // Get student IDs from unpaid fees - only use human-readable studentId
                final studentIds = unpaidFees.map((f) {
                  final student = f['student'];
                  if (student is Map) return (student['studentId'] ?? '').toString();
                  return ''; // Skip non-populated entries
                }).where((id) => id.isNotEmpty).toSet().toList();

                if (studentIds.isNotEmpty) {
                  await ApiService.post('/notifications/send-reminder', {
                    'studentIds': studentIds,
                  });
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reminder sent to ${studentIds.length} student(s)'), backgroundColor: SAMsTheme.success));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: SAMsTheme.error));
                }
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final name = user?['name'] ?? 'Admin';

    if (_loading) return const Scaffold(backgroundColor: SAMsTheme.background, body: Center(child: CircularProgressIndicator(color: SAMsTheme.primary, strokeWidth: 2)));

    return Scaffold(
      backgroundColor: SAMsTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: SAMsTheme.primary,
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 28),

                // --- HEADER ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Treasury', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SAMsTheme.primary, letterSpacing: 1.2)),
                        const SizedBox(height: 4),
                        Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: SAMsTheme.textPrimary)),
                      ],
                    )),
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: SAMsTheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: SAMsTheme.border),
                      ),
                      child: const Icon(Icons.account_balance_rounded, color: SAMsTheme.primary, size: 20),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // --- COLLECTION OVERVIEW ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: SAMsTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: SAMsTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Collection', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: SAMsTheme.textMuted)),
                          Text('${_collectionRate.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: SAMsTheme.primary)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('RM ${_totalPaid.toStringAsFixed(0)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: SAMsTheme.textPrimary)),
                              const SizedBox(height: 2),
                              Text('of RM ${_totalDue.toStringAsFixed(0)} total', style: const TextStyle(fontSize: 12, color: SAMsTheme.textMuted)),
                            ],
                          )),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: _pct,
                          minHeight: 4,
                          backgroundColor: SAMsTheme.surfaceLight,
                          valueColor: const AlwaysStoppedAnimation<Color>(SAMsTheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // --- STAT CARDS (2x2) ---
                Row(children: [
                  Expanded(child: _MetricTile(icon: Icons.people_outline_rounded, label: 'Students', value: '$_totalStudents')),
                  const SizedBox(width: 12),
                  Expanded(child: _MetricTile(icon: Icons.warning_amber_rounded, label: 'Outstanding', value: 'RM ${_outstanding.toStringAsFixed(0)}', accent: SAMsTheme.error)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _MetricTile(icon: Icons.check_circle_outline_rounded, label: 'Collected', value: 'RM ${_totalPaid.toStringAsFixed(0)}', accent: SAMsTheme.success)),
                  const SizedBox(width: 12),
                  Expanded(child: _MetricTile(icon: Icons.receipt_outlined, label: 'Total Fees', value: '${_fees.length}')),
                ]),

                const SizedBox(height: 28),

                // --- FEE STATUS ---
                const Text('Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: SAMsTheme.textPrimary)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: SAMsTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: SAMsTheme.border),
                  ),
                  child: Column(children: [
                    _StatusItem(label: 'Fully Paid', count: _fullyPaid, total: _fees.length, color: SAMsTheme.success),
                    Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 16), color: SAMsTheme.border),
                    _StatusItem(label: 'Partial', count: _partialPaid, total: _fees.length, color: SAMsTheme.warning),
                    Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 16), color: SAMsTheme.border),
                    _StatusItem(label: 'Unpaid', count: _unpaid, total: _fees.length, color: SAMsTheme.error),
                  ]),
                ),

                const SizedBox(height: 28),

                // --- ACTIONS ---
                const Text('Actions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: SAMsTheme.textPrimary)),
                const SizedBox(height: 12),
                _ActionRow(icon: Icons.people_outline_rounded, label: 'View Students', onTap: () => widget.onViewStudents?.call()),
                _ActionRow(icon: Icons.list_alt_rounded, label: 'All Payments', onTap: () => _showAllPayments(context)),
                _ActionRow(icon: Icons.add_rounded, label: 'Add Fee', onTap: () => _showAddFeeDialog(context)),
                _ActionRow(icon: Icons.notifications_none_rounded, label: 'Send Reminder', subtitle: '$_unpaid unpaid', onTap: () => _sendReminder(context)),

                const SizedBox(height: 28),

                // --- RECENT FEES ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recent', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: SAMsTheme.textPrimary)),
                    GestureDetector(
                      onTap: () => _showAllPayments(context),
                      child: const Text('View all', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: SAMsTheme.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._fees.take(5).map((f) {
                  final status = f['status'] ?? 'unpaid';
                  final studentName = f['student']?['name'] ?? f['student']?['studentId'] ?? 'Student';
                  final amount = ((f['totalAmount'] ?? 0) as num).toDouble();
                  final paid = ((f['paidAmount'] ?? 0) as num).toDouble();
                  final col = status == 'paid' ? SAMsTheme.success : (status == 'partial' ? SAMsTheme.warning : SAMsTheme.error);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: SAMsTheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: SAMsTheme.border),
                    ),
                    child: Row(children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: col, shape: BoxShape.circle)),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(studentName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SAMsTheme.textPrimary)),
                        const SizedBox(height: 2),
                        Text('RM ${paid.toStringAsFixed(0)} / RM ${amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: SAMsTheme.textMuted)),
                      ])),
                      Text(status[0].toUpperCase() + status.substring(1), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: col)),
                    ]),
                  );
                }),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SAMsTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SAMsTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 20),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: SAMsTheme.textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: SAMsTheme.textMuted)),
        ],
      ),
    );
  }
}

// --- STATUS ITEM ---
class _StatusItem extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  const _StatusItem({required this.label, required this.count, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: SAMsTheme.textPrimary))),
        Text('$count', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }
}

// --- ACTION ROW ---
class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  const _ActionRow({required this.icon, required this.label, required this.onTap, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: SAMsTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: SAMsTheme.border),
        ),
        child: Row(children: [
          Icon(icon, color: SAMsTheme.primary, size: 20),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: SAMsTheme.textPrimary))),
          if (subtitle != null) ...[
            Text(subtitle!, style: const TextStyle(fontSize: 11, color: SAMsTheme.textMuted)),
            const SizedBox(width: 8),
          ],
          const Icon(Icons.chevron_right_rounded, color: SAMsTheme.textMuted, size: 18),
        ]),
      ),
    );
  }
}
