import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../services/api_service.dart';

class TreasuryStudentsTab extends StatefulWidget {
  const TreasuryStudentsTab({super.key});

  @override
  State<TreasuryStudentsTab> createState() => _TreasuryStudentsTabState();
}

class _TreasuryStudentsTabState extends State<TreasuryStudentsTab> {
  List<dynamic> _fees = [];
  bool _loading = true;
  String _query = '';
  String _filter = 'all';

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

  /// Group fees by student and aggregate
  List<Map<String, dynamic>> get _students {
    final Map<String, Map<String, dynamic>> grouped = {};
    for (var f in _fees) {
      final student = f['student'] ?? {};
      final studentId = student is Map ? (student['_id'] ?? student['studentId'] ?? '') : (f['studentId'] ?? '');
      if (studentId.isEmpty) continue;
      
      if (!grouped.containsKey(studentId)) {
        grouped[studentId] = {
          'student': student is Map ? student : {'_id': studentId, 'studentId': studentId},
          'totalAmount': 0.0,
          'paidAmount': 0.0,
          'feeCount': 0,
          'status': 'paid',
        };
      }
      
      grouped[studentId]!['totalAmount'] = (grouped[studentId]!['totalAmount'] as double) + ((f['totalAmount'] ?? 0) as num).toDouble();
      grouped[studentId]!['paidAmount'] = (grouped[studentId]!['paidAmount'] as double) + ((f['paidAmount'] ?? 0) as num).toDouble();
      grouped[studentId]!['feeCount'] = (grouped[studentId]!['feeCount'] as int) + 1;
      
      // Determine worst status
      final feeStatus = f['status'] ?? 'unpaid';
      final currentStatus = grouped[studentId]!['status'] as String;
      if (feeStatus == 'unpaid' || feeStatus == 'overdue') {
        grouped[studentId]!['status'] = 'unpaid';
      } else if (feeStatus == 'partial' && currentStatus != 'unpaid') {
        grouped[studentId]!['status'] = 'partial';
      }
    }
    return grouped.values.toList();
  }

  List<Map<String, dynamic>> get _filtered => _students.where((s) {
    final student = s['student'] ?? {};
    final q = _query.toLowerCase();
    final matchQ = q.isEmpty || (student['name'] ?? '').toString().toLowerCase().contains(q) || (student['studentId'] ?? '').toString().toLowerCase().contains(q);
    final status = s['status'] ?? 'unpaid';
    final matchF = _filter == 'all' ||
        (_filter == 'paid' && status == 'paid') ||
        (_filter == 'partial' && status == 'partial') ||
        (_filter == 'unpaid' && (status == 'unpaid' || status == 'overdue'));
    return matchQ && matchF;
  }).toList();

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: SAMsTheme.primary));

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Portal')),
      body: Column(children: [
        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: const InputDecoration(hintText: '🔍 Search by ID or Name...'),
          ),
        ),
        // Filter chips
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _chip('All Students', 'all'),
              _chip('Unpaid', 'unpaid'),
              _chip('Partial Paid', 'partial'),
              _chip('Paid', 'paid'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Student list
        Expanded(
          child: _filtered.isEmpty
              ? Center(child: Text('No students found.', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final s = _filtered[i];
                    final student = s['student'] ?? {};
                    final status = s['status'] ?? 'unpaid';
                    final balance = ((s['totalAmount'] ?? 0) as num).toDouble() - ((s['paidAmount'] ?? 0) as num).toDouble();
                    final isPaid = status == 'paid';
                    final feeCount = s['feeCount'] ?? 0;

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: Theme.of(context).dividerColor)),
                      child: Row(children: [
                        // Avatar
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(color: SAMsTheme.primary.withOpacity(0.15), shape: BoxShape.circle),
                          child: Center(child: Text(((student['name'] ?? 'S') as String).isNotEmpty ? (student['name'] as String)[0].toUpperCase() : 'S', style: const TextStyle(color: SAMsTheme.primary, fontWeight: FontWeight.w700, fontSize: 16))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(student['name'] ?? 'Unknown', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                          const SizedBox(height: 2),
                          Text('${student['studentId'] ?? ''} · ${student['program'] ?? ''} · $feeCount fee(s)', style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
                          const SizedBox(height: 6),
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                              child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _statusColor(status))),
                            ),
                            const SizedBox(width: 10),
                            if (!isPaid) Text('Due: RM ${balance.toStringAsFixed(2)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface))
                            else Text('Cleared', style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
                          ]),
                        ])),
                        if (!isPaid) const Icon(Icons.notification_important, color: SAMsTheme.accent, size: 20),
                      ]),
                    );
                  },
                ),
        ),
      ]),
    );
  }

  Widget _chip(String label, String value) {
    final active = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? SAMsTheme.primary.withOpacity(0.15) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? SAMsTheme.primary.withOpacity(0.5) : Theme.of(context).dividerColor),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? SAMsTheme.primary : Theme.of(context).textTheme.bodyMedium?.color)),
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'paid': return SAMsTheme.success;
      case 'partial': return SAMsTheme.accent;
      default: return SAMsTheme.error;
    }
  }
}
