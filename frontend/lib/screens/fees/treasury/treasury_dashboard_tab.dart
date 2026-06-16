import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../config/theme.dart';
import '../../../services/api_service.dart';
import '../../../widgets/app_toast.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../widgets/premium_widgets.dart';
import '../../../widgets/pressable_card.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/language_provider.dart' as lp;
import 'package:moon_design/moon_design.dart';

class TreasuryDashboardTab extends ConsumerStatefulWidget {
  final VoidCallback? onViewStudents;
  const TreasuryDashboardTab({super.key, this.onViewStudents});

  @override
  ConsumerState<TreasuryDashboardTab> createState() => _TreasuryDashboardTabState();
}

class _TreasuryDashboardTabState extends ConsumerState<TreasuryDashboardTab> with TickerProviderStateMixin {
  List<dynamic> _fees = [];
  bool _loading = true;

  late AnimationController _staggerController;
  late AnimationController _progressController;
  late List<Animation<double>> _staggerAnims;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _progressController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _staggerAnims = List.generate(4, (i) => CurvedAnimation(
      parent: _staggerController,
      curve: Interval(i * 0.15, 0.5 + i * 0.15, curve: Curves.easeOutCubic),
    ));
    _load();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _progressController.dispose();
    super.dispose();
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
      // Start animations on next frame to ensure build completes first
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _staggerController.forward();
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) _progressController.forward();
          });
        }
      }));
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _fadeSlide(Animation<double> anim, {required Widget child}) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Opacity(
        opacity: anim.value.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, 14 * (1 - anim.value)), child: child),
      ),
    );
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
    final t = Theme.of(context);
    final locale = ref.read(lp.languageProvider).locale;
    String tr(String k) => lp.translations[locale]?[k] ?? lp.translations['en']?[k] ?? k;
    showMoonModalBottomSheet(
      context: context,
      isExpanded: false,
      builder: (ctx) => Container(
        decoration: ShapeDecoration(
          color: t.cardColor,
          shape: const SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius.only(
              topLeft: SmoothRadius(cornerRadius: 28, cornerSmoothing: 0.8),
              topRight: SmoothRadius(cornerRadius: 28, cornerSmoothing: 0.8),
            ),
          ),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (_, controller) => Column(children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(color: t.dividerColor, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(tr('all_payments'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: t.colorScheme.onSurface)),
                  Text('${_fees.length} records', style: TextStyle(fontSize: 12, color: t.textTheme.bodySmall?.color ?? Colors.grey)),
                ],
              ),
            ),
            Container(height: 1, color: t.dividerColor),
            Expanded(child: ListView.separated(
              controller: controller,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: _fees.length,
              separatorBuilder: (_, __) => Container(height: 1, margin: const EdgeInsets.symmetric(vertical: 8), color: t.dividerColor),
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
                    Text(studentName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.colorScheme.onSurface)),
                    const SizedBox(height: 2),
                    Text('RM ${paid.toStringAsFixed(0)} / RM ${amount.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, color: t.textTheme.bodySmall?.color ?? Colors.grey)),
                  ])),
                  Text(status[0].toUpperCase() + status.substring(1), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: col)),
                ]);
              },
            )),
          ]),
        ),
      ),
    );
  }

  void _showAddFeeDialog(BuildContext context) {
    final t = Theme.of(context);
    final locale = ref.read(lp.languageProvider).locale;
    final isDark = t.brightness == Brightness.dark;
    final studentIdCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController(text: 'Tuition Fee');
    showMoonModalBottomSheet(
      context: context,
      isExpanded: false,
      builder: (ctx) => Container(
        decoration: ShapeDecoration(
          color: t.cardColor,
          shape: const SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius.only(
              topLeft: SmoothRadius(cornerRadius: 28, cornerSmoothing: 0.8),
              topRight: SmoothRadius(cornerRadius: 28, cornerSmoothing: 0.8),
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(color: t.dividerColor, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(width: 18, height: 1, color: SAMsTheme.accent),
                    const SizedBox(width: 8),
                    Text(lp.t('add_fee', locale).toUpperCase(), style: GoogleFonts.inter(color: isDark ? const Color(0xFF94989E) : Colors.grey, fontSize: 10, letterSpacing: 1.8, fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 16),
                  MoonFormTextInput(
                    controller: studentIdCtrl,
                    style: GoogleFonts.inter(color: t.colorScheme.onSurface, fontSize: 13),
                    hintText: 'e.g. CB23109',
                    hintTextColor: isDark ? const Color(0xFF94989E) : Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  MoonFormTextInput(
                    controller: descCtrl,
                    style: GoogleFonts.inter(color: t.colorScheme.onSurface, fontSize: 13),
                    hintText: 'Description',
                    hintTextColor: isDark ? const Color(0xFF94989E) : Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  MoonFormTextInput(
                    controller: amountCtrl,
                    style: GoogleFonts.inter(color: t.colorScheme.onSurface, fontSize: 13),
                    keyboardType: TextInputType.number,
                    hintText: 'Amount (RM)',
                    hintTextColor: isDark ? const Color(0xFF94989E) : Colors.grey,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: MoonOutlinedButton(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(ctx);
                          },
                          isFullWidth: true,
                          label: Text(lp.t('cancel', locale), style: GoogleFonts.inter(color: isDark ? const Color(0xFF94989E) : Colors.grey, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MoonFilledButton(
                          isFullWidth: true,
                          backgroundColor: SAMsTheme.accent,
                          onTap: () async {
                            HapticFeedback.lightImpact();
                            final studentId = studentIdCtrl.text.trim();
                            final amount = double.tryParse(amountCtrl.text) ?? 0;
                            if (studentId.isEmpty || amount <= 0) {
                              _showEditorialSnack(context, 'Fill in all fields correctly', isError: true);
                              return;
                            }
                            try {
                              Navigator.pop(ctx);
                              _showEditorialSnack(context, 'Adding fee...', isLoading: true);
                              await ApiService.post('/fees', {
                                'studentId': studentId,
                                'items': [{'description': descCtrl.text.trim(), 'amount': amount, 'category': 'tuition'}],
                                'semester': 2,
                                        'academicYear': '2025/2026',
                                'dueDate': '2026-06-30',
                              });
                              if (mounted) {
                                _showEditorialSnack(this.context, 'Fee added for $studentId — RM ${amount.toStringAsFixed(2)}');
                                _load();
                              }
                            } catch (e) {
                              if (mounted) {
                                _showEditorialSnack(this.context, 'Failed to add fee', isError: true);
                              }
                            }
                          },
                          label: Text(lp.t('add_fee', locale), style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendReminder(BuildContext context) {
    final t = Theme.of(context);
    final locale = ref.read(lp.languageProvider).locale;
    final isDark = t.brightness == Brightness.dark;
    final unpaidFees = _fees.where((f) => f['status'] == 'unpaid' || f['status'] == 'overdue').toList();
    showMoonModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1F1F1F) : t.cardColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: t.dividerColor, borderRadius: BorderRadius.circular(2)))),
              Row(children: [
                Container(width: 18, height: 1, color: SAMsTheme.accent),
                const SizedBox(width: 8),
                Text(lp.t('send_reminder', locale).toUpperCase(), style: GoogleFonts.inter(color: isDark ? const Color(0xFF94989E) : Colors.grey, fontSize: 10, letterSpacing: 1.8, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 16),
              Text('Send payment reminder to ${unpaidFees.length} student(s) with unpaid fees?', style: GoogleFonts.inter(color: t.colorScheme.onSurface, fontSize: 13, height: 1.5)),
              if (unpaidFees.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...unpaidFees.take(3).map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: SAMsTheme.error, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text('${f['student']?['name'] ?? 'Student'} — RM ${((f['totalAmount'] ?? 0) as num).toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 11, color: isDark ? const Color(0xFF94989E) : Colors.grey)),
                  ]),
                )),
                if (unpaidFees.length > 3) Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('+ ${unpaidFees.length - 3} more', style: GoogleFonts.inter(fontSize: 11, color: isDark ? const Color(0xFF94989E) : Colors.grey)),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: MoonOutlinedButton(
                      onTap: () => Navigator.pop(ctx),
                      isFullWidth: true,
                      label: Text(lp.t('cancel', locale), style: GoogleFonts.inter(color: isDark ? const Color(0xFF94989E) : Colors.grey, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MoonFilledButton(
                      isFullWidth: true,
                      backgroundColor: SAMsTheme.accent,
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        Navigator.pop(ctx);
                        try {
                          final studentIds = unpaidFees.map((f) {
                            final student = f['student'];
                            if (student is Map) return (student['studentId'] ?? '').toString();
                            return '';
                          }).where((id) => id.isNotEmpty).toSet().toList();

                          if (studentIds.isEmpty) {
                            _showEditorialSnack(context, 'No valid student IDs found', isError: true);
                            return;
                          }

                          _showEditorialSnack(context, 'Sending reminders...', isLoading: true);
                          await ApiService.post('/notifications/send-reminder', {
                            'studentIds': studentIds,
                          });
                          if (mounted) {
                            _showEditorialSnack(this.context, 'Reminder sent to ${studentIds.length} student(s)');
                          }
                        } catch (e) {
                          if (mounted) {
                            _showEditorialSnack(this.context, 'Failed to send reminder', isError: true);
                          }
                        }
                      },
                      label: Text(lp.t('send_reminder', locale).split(' ').first, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
      ),
    );
  }

  void _showEditorialSnack(BuildContext context, String message, {bool isError = false, bool isLoading = false}) {
    if (isError) {
      AppToast.error(context, message);
    } else if (isLoading) {
      AppToast.info(context, message);
    } else {
      AppToast.success(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final user = ref.watch(authProvider).user;
    final name = user?['name'] ?? 'Admin';
    final locale = ref.watch(lp.languageProvider).locale;
    String tr(String k) => lp.translations[locale]?[k] ?? lp.translations['en']?[k] ?? k;

    // Inject dummy fees so Skeletonizer has UI to render placeholders against.
    if (_loading && _fees.isEmpty) {
      _fees = List.generate(4, (i) => (<String, dynamic>{
        '_id': 'skeleton_$i',
        'status': i.isEven ? 'paid' : 'unpaid',
        'student': {'_id': 'stu_$i', 'name': 'Loading Student', 'studentId': 'CB00000'},
        'items': [{'description': 'Loading fee', 'amount': 1234.0}],
        'totalAmount': 1234.0,
        'paidAmount': i.isEven ? 1234.0 : 0.0,
        'semester': 1,
                'academicYear': '2025/2026',
      }));
    }

    return Scaffold(
      backgroundColor: t.scaffoldBackgroundColor,
      body: SafeArea(
        child: PremiumRefreshIndicator(
          onRefresh: _load,
          child: Skeletonizer(
            enabled: _loading,
            child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 28),

                // --- HEADER ---
                _fadeSlide(_staggerAnims[0], child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(width: 14, height: 1.5, color: SAMsTheme.accent),
                          const SizedBox(width: 8),
                          Text(lp.t('treasury', locale).toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: SAMsTheme.accent, letterSpacing: 2)),
                        ]),
                        const SizedBox(height: 8),
                        Text(name, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w600, color: t.colorScheme.onSurface)),
                      ],
                    )),
                    Container(
                      width: 44, height: 44,
                      decoration: ShapeDecoration(
                        color: SAMsTheme.accent.withValues(alpha: 0.08),
                        shape: SmoothRectangleBorder(
                          borderRadius: SmoothBorderRadius(cornerRadius: 12, cornerSmoothing: 0.8),
                          side: BorderSide(color: SAMsTheme.accent.withValues(alpha: 0.2)),
                        ),
                      ),
                      child: const Icon(Iconsax.bank, color: SAMsTheme.accent, size: 20),
                    ),
                  ],
                )),

                const SizedBox(height: 28),

                // --- COLLECTION OVERVIEW (glassmorphism) ---
                _fadeSlide(_staggerAnims[1], child: Stack(
                  children: [
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
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(tr('collection'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: t.textTheme.bodySmall?.color ?? Colors.grey)),
                          AnimatedIntText(
                            value: _collectionRate,
                            decimals: 1,
                            suffix: '%',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: SAMsTheme.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FlipCurrencyText(
                                value: _totalPaid,
                                fractionDigits: 0,
                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: t.colorScheme.onSurface),
                              ),
                              const SizedBox(height: 2),
                              Text('${tr('of')} RM ${_totalDue.toStringAsFixed(0)} ${tr('total')}', style: TextStyle(fontSize: 12, color: t.textTheme.bodySmall?.color ?? Colors.grey)),
                            ],
                          )),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Animated progress bar
                      AnimatedBuilder(
                        animation: _progressController,
                        builder: (_, __) => ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: _pct * _progressController.value,
                            minHeight: 4,
                            backgroundColor: SAMsTheme.surfaceLight,
                            valueColor: const AlwaysStoppedAnimation<Color>(SAMsTheme.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                    ),
                  ],
                )),

                const SizedBox(height: 16),

                // --- STAT CARDS (2x2) ---
                _fadeSlide(_staggerAnims[2], child: Column(children: [
                Row(children: [
                  Expanded(child: _MetricTile(icon: Iconsax.people, label: tr('students'), value: '$_totalStudents')),
                  const SizedBox(width: 12),
                  Expanded(child: _MetricTile(icon: Iconsax.danger, label: tr('outstanding'), value: 'RM ${_outstanding.toStringAsFixed(0)}', accent: SAMsTheme.error)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _MetricTile(icon: Iconsax.tick_circle, label: tr('collected'), value: 'RM ${_totalPaid.toStringAsFixed(0)}', accent: SAMsTheme.success)),
                  const SizedBox(width: 12),
                  Expanded(child: _MetricTile(icon: Iconsax.document_text, label: tr('total_fees'), value: '${_fees.length}')),
                ]),
                ])),

                const SizedBox(height: 28),

                // --- FEE STATUS ---
                Text(tr('status'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t.colorScheme.onSurface)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: t.cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: t.dividerColor),
                  ),
                  child: Column(children: [
                    _StatusItem(label: tr('fully_paid'), count: _fullyPaid, total: _fees.length, color: SAMsTheme.success),
                    Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 16), color: t.dividerColor),
                    _StatusItem(label: tr('partial'), count: _partialPaid, total: _fees.length, color: SAMsTheme.warning),
                    Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 16), color: t.dividerColor),
                    _StatusItem(label: tr('unpaid'), count: _unpaid, total: _fees.length, color: SAMsTheme.error),
                  ]),
                ),

                const SizedBox(height: 28),

                // --- ACTIONS ---
                Text(tr('actions'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t.colorScheme.onSurface)),
                const SizedBox(height: 12),
                _ActionRow(icon: Iconsax.people, label: tr('view_students'), onTap: () => widget.onViewStudents?.call()),
                _ActionRow(icon: Iconsax.receipt_2, label: tr('all_payments'), onTap: () => _showAllPayments(context)),
                _ActionRow(icon: Iconsax.add_circle, label: tr('add_fee'), onTap: () => _showAddFeeDialog(context)),
                _ActionRow(icon: Iconsax.notification, label: tr('send_reminder'), subtitle: '$_unpaid ${tr('unpaid')}', onTap: () => _sendReminder(context)),

                const SizedBox(height: 28),

                // --- RECENT FEES ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(tr('recent'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t.colorScheme.onSurface)),
                    GestureDetector(
                      onTap: () => _showAllPayments(context),
                      child: Text(tr('view_all'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: SAMsTheme.primary)),
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
                  // Use updatedAt for paid/partial (last activity), createdAt for unpaid (when fee was created)
                  final tsRaw = (status == 'unpaid' ? f['createdAt'] : (f['updatedAt'] ?? f['createdAt']))?.toString();
                  final ts = _smartTimestamp(tsRaw);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: t.cardColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: t.dividerColor),
                    ),
                    child: Row(children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: col, shape: BoxShape.circle)),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(studentName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.colorScheme.onSurface)),
                        const SizedBox(height: 2),
                        Text('RM ${paid.toStringAsFixed(0)} / RM ${amount.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, color: t.textTheme.bodySmall?.color ?? Colors.grey)),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(status[0].toUpperCase() + status.substring(1), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: col)),
                        if (ts.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(ts, style: TextStyle(fontSize: 10, color: t.textTheme.bodySmall?.color ?? Colors.grey)),
                        ],
                      ]),
                    ]),
                  );
                }),
                const SizedBox(height: 32),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }

  /// Smart relative timestamp: "Just now", "5m ago", "2h ago", "Yesterday", "3d ago", or date string.
  String _smartTimestamp(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    // Older: show date
    return '${dt.day}/${dt.month}/${dt.year.toString().substring(2)}';
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
      decoration: ShapeDecoration(
        color: Theme.of(context).cardColor,
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(cornerRadius: 14, cornerSmoothing: 0.8),
          side: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accent, size: 16),
          ),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
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
        Expanded(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface))),
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
    return PressableCard(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: ShapeDecoration(
          color: Theme.of(context).cardColor,
          shape: SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius(cornerRadius: 12, cornerSmoothing: 0.8),
            side: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: SAMsTheme.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: SAMsTheme.accent, size: 17),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface))),
          if (subtitle != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: SAMsTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(subtitle!, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: SAMsTheme.error)),
            ),
            const SizedBox(width: 8),
          ],
          Icon(Iconsax.arrow_right_3, color: Theme.of(context).textTheme.bodySmall?.color, size: 16),
        ]),
      ),
    );
  }
}
