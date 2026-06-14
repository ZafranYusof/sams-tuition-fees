import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme.dart';
import '../../../services/api_service.dart';
import '../../../widgets/shimmer_loading.dart';
import '../../../widgets/empty_state.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class TreasuryStudentsTab extends StatefulWidget {
  const TreasuryStudentsTab({super.key});

  @override
  State<TreasuryStudentsTab> createState() => _TreasuryStudentsTabState();
}

class _TreasuryStudentsTabState extends State<TreasuryStudentsTab>
    with TickerProviderStateMixin {
  List<dynamic> _fees = [];
  bool _loading = true;
  String _query = '';
  String _filter = 'all';

  // Stagger animation
  late AnimationController _staggerController;
  int _prevFilteredCount = 0;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _load();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  void _playStagger(int count) {
    _staggerController.reset();
    _staggerController.forward();
    _prevFilteredCount = count;
  }

  Future<void> _load() async {
    try {
      final fees = await ApiService.get('/fees');
      setState(() { _fees = fees; _loading = false; });
      // Stagger in after data loads
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _playStagger(_filtered.length);
      });
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
    if (_loading) return const ShimmerFeeList(count: 5);

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Portal')),
      body: Column(children: [
        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() {
              _query = v;
              // Replay stagger on filter change
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final count = _filtered.length;
                if (count != _prevFilteredCount) _playStagger(count);
              });
            }),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Search by ID or Name...',
              prefixIcon: Icon(Icons.search_rounded, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
            ),
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
              ? EmptyState.noStudents()
              : _buildAnimatedList(),
        ),
      ]),
    );
  }

  Widget _buildAnimatedList() {
    return AnimatedBuilder(
      animation: _staggerController,
      builder: (context, _) {
        return ListView.separated(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
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

            // Stagger interval: each item gets a slice of the 800ms
            final count = _filtered.length.clamp(1, 20);
            final start = (i / count).clamp(0.0, 0.7);
            final end = ((i + 1) / count).clamp(0.0, 1.0);
            final interval = Interval(start, end, curve: Curves.easeOutCubic);

            final fadeAnim = CurvedAnimation(
              parent: _staggerController,
              curve: interval,
            );
            final slideAnim = CurvedAnimation(
              parent: _staggerController,
              curve: interval,
            );

            return FadeTransition(
              opacity: fadeAnim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.15),
                  end: Offset.zero,
                ).animate(slideAnim),
                // #12 Long-press preview
                child: GestureDetector(
                  onLongPress: () => _showStudentPreview(context, student),
                  child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: ShapeDecoration(
                                        color: Theme.of(context).cardColor,
                                        shape: SmoothRectangleBorder(
                                          borderRadius: SmoothBorderRadius(cornerRadius: 16, cornerSmoothing: 0.8),
                                          side: BorderSide(color: Theme.of(context).dividerColor),
                                        ),
                                      ),
                  child: Row(children: [
                    // Avatar
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(color: SAMsTheme.primary.withOpacity(0.15), shape: BoxShape.circle),
                      child: Center(child: Text(((student['name'] ?? 'S') as String).isNotEmpty ? (student['name'] as String)[0].toUpperCase() : 'S', style: const TextStyle(color: SAMsTheme.primary, fontWeight: FontWeight.w700, fontSize: 16))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        student['name'] ?? 'Unknown',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${student['studentId'] ?? ''} \u00b7 ${student['program'] ?? ''} \u00b7 $feeCount fee(s)',
                        style: GoogleFonts.jetBrainsMono(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color),
                      ),
                      const SizedBox(height: 6),
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                          child: Text(status.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: _statusColor(status))),
                        ),
                        const SizedBox(width: 10),
                        if (!isPaid) Text('Due: RM ${balance.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface))
                        else Text('Cleared', style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
                      ]),
                    ])),
                    if (!isPaid) const Icon(Icons.notification_important, color: SAMsTheme.accent, size: 20),
                  ]),
                ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // #12 Long-press preview popup
  void _showStudentPreview(BuildContext context, Map<String, dynamic> student) {
    final t = Theme.of(context);
    final fees = (student['fees'] as List?) ?? [];
    final totalDue = fees.fold<double>(0, (sum, f) => sum + ((f['amount'] ?? 0) as num).toDouble());
    final totalPaid = fees.fold<double>(0, (sum, f) => sum + ((f['paidAmount'] ?? 0) as num).toDouble());
    
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: t.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: SAMsTheme.primary.withOpacity(0.15), shape: BoxShape.circle),
                child: Center(child: Text(((student['name'] ?? 'S') as String).isNotEmpty ? (student['name'] as String)[0].toUpperCase() : 'S', style: const TextStyle(color: SAMsTheme.primary, fontWeight: FontWeight.w700, fontSize: 20))),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(student['name'] ?? 'Unknown', style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.w700, color: t.colorScheme.onSurface)),
                Text(student['studentId'] ?? '', style: GoogleFonts.jetBrainsMono(fontSize: 12, color: t.textTheme.bodySmall?.color)),
              ])),
            ]),
            const SizedBox(height: 16),
            Container(width: double.infinity, height: 1, color: t.dividerColor),
            const SizedBox(height: 16),
            _previewRow('Program', student['program'] ?? 'N/A', t),
            _previewRow('Total Due', 'RM ${totalDue.toStringAsFixed(2)}', t),
            _previewRow('Total Paid', 'RM ${totalPaid.toStringAsFixed(2)}', t),
            _previewRow('Balance', 'RM ${(totalDue - totalPaid).toStringAsFixed(2)}', t),
            _previewRow('Fees', '${fees.length} item(s)', t),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Close', style: GoogleFonts.inter(color: SAMsTheme.accent, fontWeight: FontWeight.w600)),
            )),
          ]),
        ),
      ),
    );
  }

  Widget _previewRow(String label, String value, ThemeData t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: t.textTheme.bodySmall?.color)),
        Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: t.colorScheme.onSurface)),
      ]),
    );
  }

  Widget _chip(String label, String value) {
    final active = _filter == value;
    return GestureDetector(
      onTap: () => setState(() {
        _filter = value;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _playStagger(_filtered.length);
        });
      }),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? SAMsTheme.primary.withOpacity(0.15) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? SAMsTheme.primary.withOpacity(0.5) : Theme.of(context).dividerColor),
        ),
        child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: active ? SAMsTheme.primary : Theme.of(context).textTheme.bodyMedium?.color)),
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
