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

  List<dynamic> get _filtered => _fees.where((f) {
    final student = f['student'] ?? {};
    final q = _query.toLowerCase();
    final matchQ = q.isEmpty || (student['name'] ?? '').toLowerCase().contains(q) || (student['studentId'] ?? '').toLowerCase().contains(q);
    final status = f['status'] ?? 'unpaid';
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
                    final f = _filtered[i];
                    final student = f['student'] ?? {};
                    final status = f['status'] ?? 'unpaid';
                    final balance = ((f['totalAmount'] ?? 0) - (f['paidAmount'] ?? 0)).toDouble();
                    final isPaid = status == 'paid';

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: Theme.of(context).dividerColor)),
                      child: Row(children: [
                        // Avatar
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(color: SAMsTheme.primary.withOpacity(0.15), shape: BoxShape.circle),
                          child: Center(child: Text((student['name'] ?? 'S')[0].toUpperCase(), style: const TextStyle(color: SAMsTheme.primary, fontWeight: FontWeight.w700, fontSize: 16))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(student['name'] ?? 'Unknown', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                          const SizedBox(height: 2),
                          Text('${student['studentId'] ?? ''} · ${student['program'] ?? ''}', style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
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
