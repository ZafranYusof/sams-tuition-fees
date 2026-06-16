import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moon_design/moon_design.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../config/theme.dart';
import '../../../services/api_service.dart';
import '../../../widgets/empty_state.dart';
import '../../../providers/language_provider.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:skeletonizer/skeletonizer.dart';

class TreasuryStudentsTab extends ConsumerStatefulWidget {
  const TreasuryStudentsTab({super.key});

  @override
  ConsumerState<TreasuryStudentsTab> createState() => _TreasuryStudentsTabState();
}

class _TreasuryStudentsTabState extends ConsumerState<TreasuryStudentsTab>
    with TickerProviderStateMixin {
  List<dynamic> _fees = [];
  bool _loading = true;
  String _query = '';
  String _filter = 'all';
  Timer? _debounce;

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
    _debounce?.cancel();
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
      final response = await ApiService.get('/fees');
      List<dynamic> fees;
      if (response is Map && response.containsKey('fees')) {
        fees = response['fees'] ?? [];
      } else if (response is List) {
        fees = response;
      } else {
        fees = [];
      }
      if (!mounted) return;
      setState(() { _fees = fees; _loading = false; });
      // Stagger in after data loads
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _playStagger(_filtered.length);
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
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
    final locale = ref.watch(languageProvider).locale;
    String tr(String k) => translations[locale]?[k] ?? translations['en']?[k] ?? k;
    // Inject dummy fees so Skeletonizer can render placeholder cards.
    if (_loading && _fees.isEmpty) {
      _fees = List.generate(5, (i) => {
        '_id': 'skeleton_$i',
        'status': 'unpaid',
        'student': {'_id': 'stu_$i', 'name': 'Loading Student', 'studentId': 'CB00000', 'program': 'Computer Science'},
        'totalAmount': 1234.0,
        'paidAmount': 0.0,
      });
    }

    return Skeletonizer(
      enabled: _loading,
      child: Scaffold(
      appBar: AppBar(title: Text(tr('admin_portal'))),
      body: Column(children: [
        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: MoonFormTextInput(
              onChanged: (v) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 280), () {
                  if (!mounted) return;
                  setState(() {
                    _query = v;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      final count = _filtered.length;
                      if (count != _prevFilteredCount) _playStagger(count);
                    });
                  });
                });
              },
              textColor: Theme.of(context).colorScheme.onSurface,
              hintText: tr('search_id_name'),
              activeBorderColor: SAMsTheme.accent.withValues(alpha: 0.4),
              inactiveBorderColor: _query.isNotEmpty
                  ? SAMsTheme.accent.withValues(alpha: 0.4)
                  : Theme.of(context).dividerColor,
              leading: Icon(Iconsax.search_normal, size: 16, color: _query.isNotEmpty ? SAMsTheme.accent : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
              trailing: _query.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _debounce?.cancel();
                        setState(() {
                          _query = '';
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _playStagger(_filtered.length);
                          });
                        });
                      },
                      child: Icon(Iconsax.close_circle, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                    )
                  : null,
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
              _chip(tr('all_students'), 'all'),
              _chip(tr('unpaid'), 'unpaid'),
              _chip(tr('partial_paid'), 'partial'),
              _chip(tr('paid'), 'paid'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Student list
        Expanded(
          child: _filtered.isEmpty
              ? (_query.isNotEmpty
                  ? EmptyState(
                      icon: Iconsax.search_status,
                      title: '${tr('no_students_found')} "$_query"',
                      subtitle: tr('try_different'),
                      actionLabel: tr('clear_search'),
                      onAction: () {
                        HapticFeedback.selectionClick();
                        _debounce?.cancel();
                        setState(() {
                          _query = '';
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _playStagger(_filtered.length);
                          });
                        });
                      },
                    )
                  : EmptyState.noStudents())
              : _buildAnimatedList(),
        ),
      ]),
    ),
    );
  }

  Widget _buildAnimatedList() {
    final locale = ref.watch(languageProvider).locale;
    String tr(String k) => translations[locale]?[k] ?? translations['en']?[k] ?? k;
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
                child: _PressableScale(
                  onTap: () => _showStudentPreview(context, s),
                  onLongPress: () => _showStudentPreview(context, s),
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
                      decoration: BoxDecoration(color: SAMsTheme.primary.withValues(alpha: 0.15), shape: BoxShape.circle),
                      child: Center(child: Text(((student['name'] ?? 'S') as String).isNotEmpty ? (student['name'] as String)[0].toUpperCase() : 'S', style: const TextStyle(color: SAMsTheme.primary, fontWeight: FontWeight.w700, fontSize: 16))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        student['name'] ?? tr('unknown'),
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${student['studentId'] ?? ''} \u00b7 ${student['program'] ?? ''} \u00b7 $feeCount ${tr('fees').toLowerCase()}',
                        style: GoogleFonts.jetBrainsMono(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color),
                      ),
                      const SizedBox(height: 6),
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: _statusColor(status).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                          child: Text(status.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: _statusColor(status))),
                        ),
                        const SizedBox(width: 10),
                        if (!isPaid) Text('${tr('balance')}: RM ${balance.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface))
                        else Text(tr('cleared'), style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
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
  // 'data' is the grouped student row from _students (has student submap + aggregates),
  // OR a raw student map (legacy fallback) — handle both.
  void _showStudentPreview(BuildContext context, Map<String, dynamic> data) {
    final t = Theme.of(context);
    final locale = ref.read(languageProvider).locale;
    String tr(String k) => translations[locale]?[k] ?? translations['en']?[k] ?? k;

    // Detect grouped row vs raw student
    final bool isGrouped = data.containsKey('student') && data['student'] is Map;
    final Map student = isGrouped ? (data['student'] as Map) : data;
    final double totalDue = isGrouped
        ? ((data['totalAmount'] ?? 0) as num).toDouble()
        : ((data['fees'] as List?) ?? []).fold<double>(0, (s, f) => s + ((f['totalAmount'] ?? f['amount'] ?? 0) as num).toDouble());
    final double totalPaid = isGrouped
        ? ((data['paidAmount'] ?? 0) as num).toDouble()
        : ((data['fees'] as List?) ?? []).fold<double>(0, (s, f) => s + ((f['paidAmount'] ?? 0) as num).toDouble());
    final int feeCount = isGrouped
        ? ((data['feeCount'] ?? 0) as int)
        : ((data['fees'] as List?) ?? []).length;
    
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
                decoration: BoxDecoration(color: SAMsTheme.primary.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Center(child: Text(((student['name'] ?? 'S') as String).isNotEmpty ? (student['name'] as String)[0].toUpperCase() : 'S', style: const TextStyle(color: SAMsTheme.primary, fontWeight: FontWeight.w700, fontSize: 20))),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(student['name'] ?? tr('unknown'), style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: t.colorScheme.onSurface)),
                Text(student['studentId'] ?? '', style: GoogleFonts.jetBrainsMono(fontSize: 12, color: t.textTheme.bodySmall?.color)),
              ])),
            ]),
            const SizedBox(height: 16),
            Container(width: double.infinity, height: 1, color: t.dividerColor),
            const SizedBox(height: 16),
            _previewRow(tr('program'), student['program'] ?? 'N/A', t),
            _previewRow(tr('total_due'), 'RM ${totalDue.toStringAsFixed(2)}', t),
            _previewRow(tr('total_paid'), 'RM ${totalPaid.toStringAsFixed(2)}', t),
            _previewRow(tr('balance'), 'RM ${(totalDue - totalPaid).toStringAsFixed(2)}', t),
            _previewRow(tr('fees'), '$feeCount', t),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: MoonTextButton(
              onTap: () => Navigator.pop(ctx),
              label: Text(tr('close'), style: GoogleFonts.inter(color: SAMsTheme.accent, fontWeight: FontWeight.w600)),
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
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _filter = value;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _playStagger(_filtered.length);
          });
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? SAMsTheme.primary.withValues(alpha: 0.15) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? SAMsTheme.primary.withValues(alpha: 0.5) : Theme.of(context).dividerColor),
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

// ─── Pressable scale wrapper: 1.0 -> 0.96 with haptic ───
class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  const _PressableScale({required this.child, this.onTap, this.onLongPress});

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.lightImpact();
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      onLongPress: widget.onLongPress == null ? null : () {
        HapticFeedback.mediumImpact();
        widget.onLongPress!();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
