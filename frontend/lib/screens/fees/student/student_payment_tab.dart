import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:confetti/confetti.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter_tilt/flutter_tilt.dart';
import 'package:lottie/lottie.dart';
import 'package:moon_design/moon_design.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../providers/language_provider.dart' as lp;
import '../../../providers/language_provider.dart';
import '../../../services/api_service.dart';
import '../../../widgets/app_toast.dart';
import '../../../widgets/premium_widgets.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../services/cache_service.dart';

class StudentPaymentTab extends ConsumerStatefulWidget {
  final String? targetFeeId;
  const StudentPaymentTab({super.key, this.targetFeeId});

  @override
  ConsumerState<StudentPaymentTab> createState() => _StudentPaymentTabState();
}

class _StudentPaymentTabState extends ConsumerState<StudentPaymentTab> with TickerProviderStateMixin {
  List<dynamic> _fees = [];
  bool _loading = true;
  int _selFeeIndex = 0;
  String _selMethod = 'fpx';
  String _selBank = 'Maybank';
  bool _paying = false;
  Map<String, dynamic>? _receipt;
  late ConfettiController _confettiCtrl;

  /// Step indicator: 0 = Select, 1 = Pay, 2 = Done
  int _currentStep = 0;

  late AnimationController _btnController;
  late AnimationController _amountController;
  late Animation<double> _btnScale;

  final _banks = ['Maybank', 'CIMB', 'RHB', 'Bank Islam', 'AmBank', 'Hong Leong', 'Public Bank'];

  static const _prefKeyLastBank = 'sams_last_used_bank';

  @override
  void initState() {
    super.initState();
    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 3));
    _btnController = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _amountController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _btnScale = Tween<double>(begin: 1.0, end: 0.96).animate(CurvedAnimation(parent: _btnController, curve: Curves.easeInOut));
    _loadLastBank();
    _load();
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _btnController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  /// Load last-used bank from SharedPreferences
  Future<void> _loadLastBank() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKeyLastBank);
    if (saved != null && _banks.contains(saved)) {
      setState(() => _selBank = saved);
    }
  }

  /// Save selected bank to SharedPreferences
  Future<void> _saveLastBank(String bank) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyLastBank, bank);
  }

  Future<void> _load() async {
    try {
      final response = await ApiService.get('/fees/my');
      // Normalize response: API may return {fees: [...]} or a plain list
      List<dynamic> fees;
      if (response is Map && response.containsKey('fees')) {
        fees = response['fees'] ?? [];
      } else if (response is List) {
        fees = response;
      } else {
        fees = [];
      }
      // Determine which chip to pre-select if a targetFeeId was passed.
      // Chips are built from _unpaidItems (flat list of all unpaid items
      // across all fees), so we must find the first unpaid item that
      // belongs to targetFeeId, not the fee's position in _fees.
      int initialIdx = 0;
      if (widget.targetFeeId != null && fees.isNotEmpty) {
        int itemCounter = 0;
        for (var f in fees) {
          final fid = f['_id']?.toString() ?? '';
          final items = (f['items'] as List?) ?? [];
          bool foundInFee = false;
          for (var idx = 0; idx < items.length; idx++) {
            final item = items[idx] as Map?;
            if (item == null) continue;
            final amount = ((item['amount'] ?? 0) as num).toDouble();
            final paid = ((item['paidAmount'] ?? 0) as num).toDouble();
            if (amount - paid > 0.01) {
              if (fid == widget.targetFeeId) {
                initialIdx = itemCounter + 1; // +1 because chip 0 = "All"
                foundInFee = true;
                break;
              }
              itemCounter++;
            }
          }
          if (foundInFee) break;
          // Count remaining unpaid items in this fee even if not target
          // (already counted above, nothing extra needed).
        }
      }
      setState(() { _fees = fees; _selFeeIndex = initialIdx; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  double get _balance {
    double total = 0;
    for (var f in _fees) {
      total += ((f['totalAmount'] ?? 0) as num).toDouble() - ((f['paidAmount'] ?? 0) as num).toDouble();
    }
    return total;
  }

  double get _amount {
    if (_fees.isEmpty) return 0;
    if (_selFeeIndex == 0) return _balance;
    final items = _unpaidItems;
    final idx = _selFeeIndex - 1;
    if (idx < 0 || idx >= items.length) return _balance;
    return (items[idx]['balance'] as num).toDouble();
  }

  String get _deadlineStr {
    for (var f in _fees) {
      if (f['dueDate'] != null) {
        final d = DateTime.tryParse(f['dueDate'].toString());
        if (d != null) {
          final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          return '${d.day} ${months[d.month]} ${d.year}';
        }
      }
    }
    return 'N/A';
  }

  int get _daysLeft {
    for (var f in _fees) {
      if (f['dueDate'] != null) {
        final d = DateTime.tryParse(f['dueDate'].toString());
        if (d != null) return d.difference(DateTime.now()).inDays.clamp(0, 999);
      }
    }
    return 0;
  }

  void _selectFee(int index) {
    HapticFeedback.selectionClick();
    _amountController.forward(from: 0);
    setState(() => _selFeeIndex = index);
  }

  /// Flatten unpaid items across all fees into a list of pickable rows.
  /// Each row carries: feeId, itemIndex (within fee.items[]), description, balance.
  List<Map<String, dynamic>> get _unpaidItems {
    final List<Map<String, dynamic>> out = [];
    for (var fee in _fees) {
      final feeId = fee['_id']?.toString() ?? '';
      final items = (fee['items'] as List?) ?? [];
      for (var idx = 0; idx < items.length; idx++) {
        final item = items[idx] as Map?;
        if (item == null) continue;
        final amount = ((item['amount'] ?? 0) as num).toDouble();
        final paid = ((item['paidAmount'] ?? 0) as num).toDouble();
        final bal = amount - paid;
        if (bal <= 0.01) continue; // skip fully paid items
        out.add({
          'feeId': feeId,
          'itemIndex': idx,
          'description': item['description']?.toString() ?? 'Item',
          'category': item['category']?.toString() ?? 'other',
          'balance': bal,
          'totalAmount': amount,
          'paidAmount': paid,
        });
      }
    }
    return out;
  }

  /// ALL items including paid (for display in "Pay for" chips).
  List<Map<String, dynamic>> get _allItems {
    final List<Map<String, dynamic>> out = [];
    for (var fee in _fees) {
      final feeId = fee['_id']?.toString() ?? '';
      final items = (fee['items'] as List?) ?? [];
      for (var idx = 0; idx < items.length; idx++) {
        final item = items[idx] as Map?;
        if (item == null) continue;
        final amount = ((item['amount'] ?? 0) as num).toDouble();
        final paid = ((item['paidAmount'] ?? 0) as num).toDouble();
        out.add({
          'feeId': feeId,
          'itemIndex': idx,
          'description': item['description']?.toString() ?? 'Item',
          'category': item['category']?.toString() ?? 'other',
          'balance': amount - paid,
          'totalAmount': amount,
          'paidAmount': paid,
        });
      }
    }
    return out;
  }

  /// Returns the fee id for the currently-selected chip.
  /// Index 0 = "All outstanding" → uses first unpaid fee id, falls back to 'all'.
  /// Index 1+ = per-item selection → returns the fee id that owns that item.
  String _currentFeeId() {
    if (_selFeeIndex == 0) {
      for (var f in _fees) {
        final bal = ((f['totalAmount'] ?? 0) as num).toDouble() - ((f['paidAmount'] ?? 0) as num).toDouble();
        if (bal > 0) return f['_id']?.toString() ?? 'all';
      }
      return widget.targetFeeId ?? 'all';
    }
    final items = _unpaidItems;
    final idx = _selFeeIndex - 1;
    if (idx >= 0 && idx < items.length) {
      return (items[idx]['feeId'] as String?) ?? 'all';
    }
    return 'all';
  }

  /// Premium multi-step payment bottom sheet.
  /// Step 1: Select bank (FPX) / card method
  /// Step 2: Confirm amount
  /// Step 3: Processing → triggers _pay()
  void _showPaymentConfirmation() {
    if (_amount <= 0) return;
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => _PaymentSheet(
        amount: _amount,
        deadline: _deadlineStr,
        feeLabel: _selFeeIndex == 0
            ? 'All outstanding fees'
            : (() {
                final items = _unpaidItems;
                final idx = _selFeeIndex - 1;
                if (idx >= 0 && idx < items.length) {
                  return items[idx]['description'] as String;
                }
                return 'Tuition Fee';
              })(),
        initialMethod: _selMethod,
        initialBank: _selBank,
        onConfirm: (method, bank) async {
          setState(() { _selMethod = method; _selBank = bank; });
          if (method == 'fpx') await _saveLastBank(bank);
          // _pay returns success bool. Sheet stays mounted on Step 3 while we wait.
          return await _pay();
        },
        onSuccessDismissed: () {
          // Confetti is triggered inside _pay after success;
          // sheet has already auto-dismissed when we returned true.
        },
      ),
    );
  }

  Future<bool> _pay() async {
    if (_paying) return false;
    if (_amount <= 0) return false;
    // Haptic owned by _handleConfirm in the payment sheet to avoid duplicate buzz.
    setState(() {
      _paying = true;
      _currentStep = 1; // Move to "Pay" step
    });

    // Save bank preference
    if (_selMethod == 'fpx') {
      _saveLastBank(_selBank);
    }

    try {
      String targetFeeId = '';
      double payAmount = _amount;

      if (_selFeeIndex == 0) {
        for (var f in _fees) {
          final bal = ((f['totalAmount'] ?? 0) as num).toDouble() - ((f['paidAmount'] ?? 0) as num).toDouble();
          if (bal > 0) { targetFeeId = f['_id']; break; }
        }
      } else {
        final items = _unpaidItems;
        final idx = _selFeeIndex - 1;
        if (idx >= 0 && idx < items.length) {
          targetFeeId = items[idx]['feeId'] as String;
          payAmount = (items[idx]['balance'] as num).toDouble();
        }
      }

      if (targetFeeId.isEmpty || payAmount <= 0) { setState(() { _paying = false; _currentStep = 0; }); return false; }

      String? txnId;
      bool success = false;

      if (_selMethod == 'fpx') {
        final result = await ApiService.post('/payment/fpx/create', {
          'feeId': targetFeeId,
          'amount': payAmount,
          'description': 'UMPSA Tuition Fee',
          'bank': 'FPX',
        });
        final paymentUrl = result['paymentUrl'];
        final billCode = result['billCode'];
        if (paymentUrl != null && mounted) {
          final webResult = await Navigator.push<bool>(context, MaterialPageRoute(
            builder: (_) => _PaymentWebView(url: paymentUrl, title: 'FPX Payment'),
          ));
          if (webResult == true || webResult == null) {
            final status = await ApiService.get('/payment/fpx/status/$billCode');
            if (status['status'] == 'success') { success = true; txnId = billCode; }
            else { if (mounted) AppToast.warning(context, 'Payment pending or failed'); }
          }
        }
      } else {
        final result = await ApiService.post('/payment/card/create-intent', {
          'feeId': targetFeeId,
          'amount': payAmount,
        });
        final paymentUrl = result['paymentUrl'];
        final sessionId = result['paymentIntentId'];
        if (paymentUrl != null && mounted) {
          final webResult = await Navigator.push<bool>(context, MaterialPageRoute(
            builder: (_) => _PaymentWebView(url: paymentUrl, title: 'Card Payment'),
          ));
          if (webResult == true || webResult == null) {
            final confirm = await ApiService.post('/payment/card/confirm', {'paymentIntentId': sessionId});
            if (confirm['status'] == 'success') { success = true; txnId = sessionId; }
            else { if (mounted) AppToast.warning(context, 'Card payment pending or failed'); }
          }
        }
      }

      if (!mounted) return false;
      if (success) {
        HapticFeedback.heavyImpact();
        _confettiCtrl.play();
        setState(() {
          _receipt = {'status': 'paid', 'amount': payAmount, 'txn_id': txnId ?? '', 'bank': _selMethod == 'fpx' ? 'FPX' : 'Card'};
          _currentStep = 2; // Move to "Done" step
        });
      } else {
        setState(() => _currentStep = 0); // Reset on failure
      }
      setState(() => _paying = false);
      await CacheService.save('my_fees', []);
      await CacheService.save('my_payments', []);
      await _load();
      return success;
    } catch (e) {
      setState(() { _paying = false; _currentStep = 0; });
      if (mounted) AppToast.error(context, e.toString());
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;
    final locale = ref.watch(languageProvider).locale;
    if (_receipt != null) return _buildReceipt(t);

    // Inject dummy fees so Skeletonizer has UI to placeholder against.
    if (_loading && _fees.isEmpty) {
      _fees = List.generate(2, (i) => {
        '_id': 'skeleton_$i',
        'status': 'unpaid',
        'items': [{'description': 'Loading fee item', 'amount': 1234.0}],
        'totalAmount': 1234.0,
        'paidAmount': 0.0,
        'semester': 1,
        'academicYear': '2025/2026',
        'dueDate': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      });
    }

    final daysLeft = _daysLeft;
    final isUrgent = daysLeft <= 14;
    final unpaidCount = _fees.where((f) => ((f['totalAmount'] ?? 0) as num).toDouble() - ((f['paidAmount'] ?? 0) as num).toDouble() > 0).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(lp.t('make_payment', locale)),
        actions: [
          if (unpaidCount > 0) Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: SAMsTheme.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Text('$unpaidCount ${lp.t('unpaid', locale)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SAMsTheme.error)),
            )),
          ),
        ],
      ),
      body: Skeletonizer(
        enabled: _loading,
        child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          // Step indicator
          _buildStepIndicator(t, locale),
          const SizedBox(height: 20),

          // Amount hero - shared element transition from home tab fee card
          AnimatedBuilder(
            animation: _amountController,
            builder: (_, __) => Transform.scale(
              scale: 1.0 - (_amountController.value * 0.02),
              child: Opacity(
                opacity: 1.0 - (_amountController.value * 0.3),
                child: Hero(
                  tag: 'fee_${_currentFeeId()}',
                  flightShuttleBuilder: (_, __, ___, ____, _____) => Material(
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: t.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: t.dividerColor),
                      ),
                    ),
                  ),
                  child: _buildAmountCard(t),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Deadline - only show if there's outstanding balance
          if (daysLeft > 0 && _balance > 0.01) ...[
            _buildDeadlineRow(t, daysLeft, isUrgent),
            const SizedBox(height: 16),
          ],

          // Payment method
          _buildMethodSection(t, isDark),

          const SizedBox(height: 28),

          // Pay button with press animation — now triggers confirmation sheet
          GestureDetector(
            onTapDown: (_) => _btnController.forward(),
            onTapUp: (_) => _btnController.reverse(),
            onTapCancel: () => _btnController.reverse(),
            child: AnimatedBuilder(
              animation: _btnScale,
              builder: (_, __) => Transform.scale(
                scale: _btnScale.value,
                child: _buildPayButton(t, isDark),
              ),
            ),
          ),

          const SizedBox(height: 14),
          // Security footer
          Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.verified_user_outlined, size: 13, color: t.textTheme.bodySmall?.color),
            const SizedBox(width: 5),
            Text('Bank-grade encryption', style: TextStyle(fontSize: 11, color: t.textTheme.bodySmall?.color, letterSpacing: 0.2)),
          ])),
        ],
      ),
      ),
    );
  }

  Widget _buildStepIndicator(ThemeData t, String locale) {
    return Row(children: [
      _stepDot(t, lp.t('select', locale), 0),
      Expanded(child: Container(height: 1, color: _currentStep >= 1 ? SAMsTheme.brass : t.dividerColor)),
      _stepDot(t, lp.t('pay', locale), 1),
      Expanded(child: Container(height: 1, color: _currentStep >= 2 ? SAMsTheme.brass : t.dividerColor)),
      _stepDot(t, lp.t('done', locale), 2),
    ]);
  }

  Widget _stepDot(ThemeData t, String label, int step) {
    final active = _currentStep >= step;
    final isCurrent = _currentStep == step;
    return Column(children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 24, height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? SAMsTheme.brass : Colors.transparent,
          border: Border.all(color: active ? SAMsTheme.brass : t.dividerColor, width: 1.5),
        ),
        child: active ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: isCurrent ? FontWeight.w700 : (active ? FontWeight.w600 : FontWeight.w400),
          color: active ? SAMsTheme.brass : t.textTheme.bodySmall?.color,
        ),
      ),
    ]);
  }

  Widget _buildAmountCard(ThemeData t) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: t.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.dividerColor),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('TOTAL DUE', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: t.textTheme.bodySmall?.color, letterSpacing: 1)),
          if (_amount <= 0) Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: SAMsTheme.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
            child: Text('CLEARED', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: SAMsTheme.success, letterSpacing: 0.5)),
          ),
        ]),
        const SizedBox(height: 6),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Text('RM', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: t.colorScheme.onSurface)),
          const SizedBox(width: 4),
          // Wrap in Expanded + Align so the flip counter's width changes
          // don't reflow siblings or the parent container (was causing
          // a brief "vibrate" when switching between fees with different
          // digit counts, e.g. RM 1,200 → RM 200).
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: CrossfadeCurrencyText(
                value: _amount,
                prefix: '',
                style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w800, color: t.colorScheme.onSurface, letterSpacing: -1.5, height: 1),
              ),
            ),
          ),
        ]),

        if (_allItems.length > 1 || _fees.length > 1) ...[
          const SizedBox(height: 18),
          Container(height: 1, color: t.dividerColor),
          const SizedBox(height: 14),
          Text('Pay for', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: t.textTheme.bodySmall?.color)),
          const SizedBox(height: 8),
          _feeChip('All outstanding', _balance, 0),
          ...List.generate(_allItems.length, (i) {
            final item = _allItems[i];
            return _feeChip(
              item['description'] as String,
              (item['balance'] as num).toDouble(),
              i + 1,
            );
          }),
        ],
      ]),
    );
  }

  Widget _feeChip(String label, double bal, int index) {
    final t = Theme.of(context);
    final active = _selFeeIndex == index;
    final disabled = bal <= 0;
    return GestureDetector(
      onTap: disabled ? null : () => _selectFee(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: disabled ? SAMsTheme.success.withValues(alpha: 0.04) : (active ? SAMsTheme.primary.withValues(alpha: 0.06) : Colors.transparent),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: disabled ? SAMsTheme.success.withValues(alpha: 0.2) : (active ? SAMsTheme.primary.withValues(alpha: 0.4) : t.dividerColor), width: active ? 1.5 : 1),
        ),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 18, height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: disabled ? SAMsTheme.success : (active ? SAMsTheme.primary : Colors.transparent),
              border: Border.all(color: disabled ? SAMsTheme.success : (active ? SAMsTheme.primary : (t.textTheme.bodySmall?.color ?? Colors.grey).withValues(alpha: 0.4)), width: 1.5),
            ),
            child: (disabled || active) ? const Icon(Icons.check, size: 11, color: Colors.white) : null,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.w400, color: disabled ? t.textTheme.bodySmall?.color : t.colorScheme.onSurface))),
          Text(disabled ? 'Paid' : 'RM ${bal.toStringAsFixed(0)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: disabled ? SAMsTheme.success : (active ? SAMsTheme.primary : t.textTheme.bodySmall?.color))),
        ]),
      ),
    );
  }

  Widget _buildDeadlineRow(ThemeData t, int daysLeft, bool isUrgent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: (isUrgent ? SAMsTheme.error : SAMsTheme.success).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: (isUrgent ? SAMsTheme.error : SAMsTheme.success).withValues(alpha: 0.15)),
      ),
      child: Row(children: [
        Icon(isUrgent ? Icons.schedule : Icons.event_available_outlined, size: 16, color: isUrgent ? SAMsTheme.error : SAMsTheme.success),
        const SizedBox(width: 10),
        Expanded(child: Text('Due $_deadlineStr', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: t.colorScheme.onSurface))),
        Text('${daysLeft}d left', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isUrgent ? SAMsTheme.error : SAMsTheme.success)),
      ]),
    );
  }

  Widget _buildMethodSection(ThemeData t, bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Payment channel', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: t.textTheme.bodySmall?.color, letterSpacing: 0.3)),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: isDark ? SAMsTheme.surfaceLight : t.dividerColor.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          _methodToggle('fpx', Icons.account_balance_outlined, 'Online Banking', t),
          const SizedBox(width: 4),
          _methodToggle('card', Icons.credit_card_outlined, 'Debit/Credit', t),
        ]),
      ),
      if (_selMethod == 'fpx') ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: t.cardColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: t.dividerColor)),
          child: Row(children: [
            Icon(Icons.info_outline_rounded, size: 16, color: t.textTheme.bodySmall?.color),
            const SizedBox(width: 8),
            Expanded(child: Text(
              'Choose your bank in the next step',
              style: GoogleFonts.inter(color: t.textTheme.bodySmall?.color, fontSize: 12),
            )),
          ]),
        ),
      ],
    ]);
  }

  Widget _methodToggle(String key, IconData icon, String label, ThemeData t) {
    final active = _selMethod == key;
    return Expanded(child: GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); setState(() => _selMethod = key); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? t.cardColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: active ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))] : null,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: active ? SAMsTheme.primary : t.textTheme.bodySmall?.color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: active ? FontWeight.w600 : FontWeight.w400, color: active ? t.colorScheme.onSurface : t.textTheme.bodySmall?.color)),
        ]),
      ),
    ));
  }

  Widget _buildPayButton(ThemeData t, bool isDark) {
    // Settled state: intentional empty state, not a disabled button
    if (!_paying && _amount <= 0) {
      return Container(
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: SAMsTheme.success.withValues(alpha: 0.08),
          border: Border.all(color: SAMsTheme.success.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Center(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_circle_rounded, size: 20, color: SAMsTheme.success),
            const SizedBox(width: 8),
            Text(
              'All fees cleared',
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: SAMsTheme.success),
            ),
          ]),
        ),
      );
    }
    final disabled = _paying;
    return Container(
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(colors: [SAMsTheme.primary, SAMsTheme.primary.withValues(alpha: 0.85)]),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : _showPaymentConfirmation,
          borderRadius: BorderRadius.circular(12),
          child: Center(child: _paying
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Proceed to pay RM ${_amount.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ]),
          ),
        ),
      ),
    );
  }

  Widget _buildReceipt(ThemeData t) {
    final locale = ref.read(languageProvider).locale;
    return Scaffold(
      appBar: AppBar(title: Text(lp.t('receipt', locale))),
      body: Stack(children: [
        SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
        const SizedBox(height: 16),
        // Animated success ring
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (_, value, __) => Transform.scale(
            scale: value,
            child: SizedBox(
              width: 200, height: 200,
              child: Lottie.asset(
                'assets/lottie/success_check.json',
                repeat: false,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: SAMsTheme.success.withValues(alpha: 0.08),
                    border: Border.all(color: SAMsTheme.success.withValues(alpha: 0.3), width: 2),
                  ),
                  child: const Icon(Icons.check_rounded, size: 36, color: SAMsTheme.success),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          builder: (_, value, __) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 10 * (1 - value)),
              child: Column(children: [
                Text('Payment Successful', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: t.colorScheme.onSurface)),
                const SizedBox(height: 4),
                Text('Transaction processed', style: GoogleFonts.inter(fontSize: 13, color: t.textTheme.bodySmall?.color)),
              ]),
            ),
          ),
        ),

        const SizedBox(height: 16),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: ShapeDecoration(
            color: t.cardColor,
            shape: SmoothRectangleBorder(
              borderRadius: SmoothBorderRadius(cornerRadius: 12, cornerSmoothing: 0.8),
              side: BorderSide(color: t.dividerColor),
            ),
          ),
          child: Column(children: [
            _receiptRow(t, 'Reference', _receipt!['txn_id']),
            _receiptRow(t, 'Amount', 'RM ${((_receipt!['amount'] as num).toDouble()).toStringAsFixed(2)}'),
            _receiptRow(t, 'Channel', _receipt!['bank']),
            _receiptRow(t, 'Date', DateTime.now().toString().substring(0, 16)),
            _receiptRow(t, 'Status', 'Completed', isLast: true, valueColor: SAMsTheme.success),
          ]),
        ),

        const SizedBox(height: 24),

        // Download Receipt & Share buttons
        Row(children: [
          Expanded(
            child: MoonOutlinedButton(
              isFullWidth: true,
              buttonSize: MoonButtonSize.lg,
              borderColor: SAMsTheme.brass.withValues(alpha: 0.4),
              onTap: () async {
                HapticFeedback.mediumImpact();
                try {
                  final dir = await getApplicationDocumentsDirectory();
                  final txnId = _receipt!['txn_id'] ?? 'unknown';
                  final amount = ((_receipt!['amount'] as num?)?.toDouble() ?? 0).toStringAsFixed(2);
                  final bank = _receipt!['bank'] ?? 'FPX';
                  final date = DateTime.now().toString().substring(0, 16);
                  final receiptText = '═══════════════════════════════\n'
                      '       UMPSA PAYMENT RECEIPT\n'
                      '═══════════════════════════════\n\n'
                      'Reference:  $txnId\n'
                      'Amount:     RM $amount\n'
                      'Channel:    $bank\n'
                      'Date:       $date\n'
                      'Status:     Completed\n\n'
                      '═══════════════════════════════\n'
                      '  SAMs Tuition Fee Management\n'
                      '═══════════════════════════════\n';
                  final file = File('${dir.path}/receipt_$txnId.txt');
                  await file.writeAsString(receiptText);
                  if (mounted) {
                    AppToast.success(context, 'Receipt saved', desc: file.path);
                  }
                } catch (e) {
                  if (mounted) {
                    AppToast.error(context, 'Failed to save receipt');
                  }
                }
              },
              leading: const Icon(Icons.download_rounded, size: 18, color: SAMsTheme.brass),
              label: Text('Download', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: SAMsTheme.brass)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: MoonOutlinedButton(
              isFullWidth: true,
              buttonSize: MoonButtonSize.lg,
              borderColor: SAMsTheme.brass.withValues(alpha: 0.4),
              onTap: () async {
                HapticFeedback.lightImpact();
                final txnId = _receipt!['txn_id'] ?? 'unknown';
                final amount = ((_receipt!['amount'] as num?)?.toDouble() ?? 0).toStringAsFixed(2);
                final bank = _receipt!['bank'] ?? 'FPX';
                final date = DateTime.now().toString().substring(0, 16);

                // Generate PDF receipt
                final pdf = pw.Document();
                pdf.addPage(pw.Page(
                  pageFormat: PdfPageFormat.a4,
                  build: (pw.Context context) => pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Center(child: pw.Text('UMPSA', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
                      pw.Center(child: pw.Text('Student Academic Management System', style: const pw.TextStyle(fontSize: 12))),
                      pw.SizedBox(height: 8),
                      pw.Center(child: pw.Text('PAYMENT RECEIPT', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold))),
                      pw.SizedBox(height: 20),
                      pw.Divider(thickness: 1),
                      pw.SizedBox(height: 12),
                      _pdfRow('Reference No.', txnId),
                      _pdfRow('Amount', 'RM $amount'),
                      _pdfRow('Payment Channel', bank),
                      _pdfRow('Date & Time', date),
                      _pdfRow('Status', 'Completed'),
                      pw.SizedBox(height: 12),
                      pw.Divider(thickness: 1),
                      pw.SizedBox(height: 20),
                      pw.Text('This is a computer-generated receipt. No signature is required.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      pw.SizedBox(height: 8),
                      pw.Text('SAMs Tuition Fee Management', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
                    ],
                  ),
                ));

                final dir = await getTemporaryDirectory();
                final file = File('${dir.path}/receipt_$txnId.pdf');
                await file.writeAsBytes(await pdf.save());
                await Share.shareXFiles([XFile(file.path)], subject: 'Payment Receipt - $txnId');
              },
              leading: const Icon(Icons.share_rounded, size: 18, color: SAMsTheme.brass),
              label: Text('Share', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: SAMsTheme.brass)),
            ),
          ),
        ]),

        const SizedBox(height: 16),
        MoonFilledButton(
          isFullWidth: true,
          buttonSize: MoonButtonSize.lg,
          backgroundColor: SAMsTheme.primary,
          onTap: () { setState(() { _receipt = null; _currentStep = 0; }); _load(); },
          label: Text('Back to Fees', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ])),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiCtrl,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 20,
            maxBlastForce: 30,
            minBlastForce: 10,
            gravity: 0.2,
            colors: const [Color(0xFF5C33CF), Color(0xFF8B5FFF), Colors.white],
          ),
        ),
      ]),
    );
  }

  Widget _receiptRow(ThemeData t, String label, String value, {bool isLast = false, Color? valueColor}) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: t.dividerColor.withValues(alpha: 0.5)))),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: GoogleFonts.inter(fontSize: 13, color: t.textTheme.bodySmall?.color)),
      Flexible(child: Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor ?? t.colorScheme.onSurface), textAlign: TextAlign.right)),
    ]),
  );

  pw.Widget _pdfRow(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 6),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
        pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
      ],
    ),
  );
}

// Payment WebView
class _PaymentWebView extends StatefulWidget {
  final String url;
  final String title;
  const _PaymentWebView({required this.url, required this.title});

  @override
  State<_PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<_PaymentWebView> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _done = false;
  bool _timeoutShown = false;
  bool _hasError = false;
  String _errorMessage = '';
  static const _timeoutDuration = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    _startTimeoutTimer();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() { _loading = true; _hasError = false; }),
        onPageFinished: (_) => setState(() => _loading = false),
        onWebResourceError: (error) { setState(() { _hasError = true; _loading = false; _errorMessage = error.description; }); },
        onNavigationRequest: (request) {
          if (request.url.contains('samsapp://') || request.url.contains('/payment/success') || request.url.contains('/payment/failed')) {
            _done = true;
            Navigator.pop(context, request.url.contains('success') || request.url.contains('status_id=1'));
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  void _startTimeoutTimer() {
    Future.delayed(_timeoutDuration, () { if (!mounted || _done || _timeoutShown) return; _handleTimeout(); });
  }

  void _handleTimeout() {
    if (_done || _timeoutShown) return;
    _timeoutShown = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Taking longer than expected', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        content: const Text('Your transaction may still be processing.\nCheck payment history for status.', style: TextStyle(height: 1.5)),
        actions: [
          MoonTextButton(onTap: () { Navigator.pop(context); _timeoutShown = false; }, label: const Text('Wait')),
          MoonTextButton(onTap: () { Navigator.pop(context); Navigator.pop(context, false); }, label: const Text('Check History', style: TextStyle(color: SAMsTheme.primary, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context, false))),
      body: Stack(children: [
        WebViewWidget(controller: _controller),
        if (_loading) const Center(child: CircularProgressIndicator(color: SAMsTheme.primary, strokeWidth: 2)),
        if (_hasError) Center(child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.wifi_off_rounded, size: 40, color: t.textTheme.bodySmall?.color),
            const SizedBox(height: 14),
            Text('Connection failed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t.colorScheme.onSurface)),
            const SizedBox(height: 6),
            Text(_errorMessage.isNotEmpty ? _errorMessage : 'Check your connection and try again.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: t.textTheme.bodySmall?.color)),
            const SizedBox(height: 20),
            MoonOutlinedButton(onTap: () { setState(() { _hasError = false; _loading = true; }); _controller.loadRequest(Uri.parse(widget.url)); }, label: const Text('Retry')),
            ]),
            )),
            ]),
            );
            }
            }

            // =====================================================================
            // _PaymentSheet — premium multi-step bottom sheet
            // Step 1: Select method (FPX banks grid)
            // Step 2: Confirm amount
            // Step 3: Processing
            // =====================================================================

            class _PaymentSheet extends ConsumerStatefulWidget {
            final double amount;
            final String deadline;
            final String feeLabel;
            final String initialMethod;
            final String initialBank;
            final Future<bool> Function(String method, String bank) onConfirm;
            final VoidCallback onSuccessDismissed;

            const _PaymentSheet({
            required this.amount,
            required this.deadline,
            required this.feeLabel,
            required this.initialMethod,
            required this.initialBank,
            required this.onConfirm,
            required this.onSuccessDismissed,
            });

            @override
            ConsumerState<_PaymentSheet> createState() => _PaymentSheetState();
            }

            class _PaymentSheetState extends ConsumerState<_PaymentSheet> {
            final PageController _pc = PageController();
            int _step = 0;
            late String _method;
            late String _bank;

            static const List<Map<String, String>> _banks = [
            {'key': 'maybank',     'name': 'Maybank2u'},
            {'key': 'cimb',        'name': 'CIMB Clicks'},
            {'key': 'public',      'name': 'Public Bank'},
            {'key': 'rhb',         'name': 'RHB Now'},
            {'key': 'hong_leong',  'name': 'Hong Leong'},
            {'key': 'bank_islam',  'name': 'Bank Islam'},
            {'key': 'ambank',      'name': 'AmBank'},
            {'key': 'alliance',    'name': 'Alliance'},
            {'key': 'uob',         'name': 'UOB'},
            {'key': 'ocbc',        'name': 'OCBC'},
            {'key': 'hsbc',        'name': 'HSBC'},
            {'key': 'fpx',         'name': 'Other FPX'},
            ];

            @override
            void initState() {
            super.initState();
            _method = widget.initialMethod.isNotEmpty ? widget.initialMethod : 'fpx';
            _bank = widget.initialBank.isNotEmpty ? widget.initialBank : 'maybank';
            }

            @override
            void dispose() {
            _pc.dispose();
            super.dispose();
            }

            void _go(int idx) {
            setState(() => _step = idx);
            _pc.animateToPage(idx, duration: const Duration(milliseconds: 400), curve: Curves.easeInOutCubic);
            }

            Future<void> _handleConfirm() async {
            HapticFeedback.mediumImpact();
            _go(2);
            final ok = await widget.onConfirm(_method, _bank);
            if (!mounted) return;
            if (ok) {
            // Success haptic (heavyImpact) is fired inside _pay() on the parent;
            // do not duplicate here.
            Navigator.of(context).pop(true);
            widget.onSuccessDismissed();
            } else {
            // Failure → return to confirm step so user can retry
            _go(1);
            }
            }

            @override
            Widget build(BuildContext ctx) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            final bg = isDark ? const Color(0xFF1F1F1F) : Colors.white;
            final fg = isDark ? Colors.white : const Color(0xFF111111);
            final subFg = isDark ? Colors.white70 : Colors.black54;

            return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, scrollCtrl) {
            return Container(
              decoration: ShapeDecoration(
                color: bg,
                shape: const SmoothRectangleBorder(
                  borderRadius: SmoothBorderRadius.only(
                    topLeft: SmoothRadius(cornerRadius: 28, cornerSmoothing: 0.8),
                    topRight: SmoothRadius(cornerRadius: 28, cornerSmoothing: 0.8),
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Drag handle: 4x40 grey pill
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 6),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black26,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pc,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildStep1(ctx, scrollCtrl, fg, subFg, isDark),
                        _buildStep2(ctx, scrollCtrl, fg, subFg, isDark),
                        _buildStep3(ctx, fg, subFg),
                      ],
                    ),
                  ),
                  if (_step != 2) _buildBottomBar(ctx, isDark),
                ],
              ),
            );
            },
            ),
            );
            }

            Widget _buildStep1(BuildContext ctx, ScrollController sc, Color fg, Color subFg, bool isDark) {
            final locale = ref.watch(languageProvider).locale;
            return ListView(
            controller: sc,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
            Text(lp.t('select_bank', locale), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: fg)),
            const SizedBox(height: 4),
            Text(lp.t('select_bank_desc', locale), style: TextStyle(fontSize: 13, color: subFg)),
            const SizedBox(height: 18),
            GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _banks.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (_, i) {
              final b = _banks[i];
              final selected = b['key'] == _bank && _method == 'fpx';
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _method = 'fpx';
                    _bank = b['key']!;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  decoration: ShapeDecoration(
                    color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F4FB),
                    shape: SmoothRectangleBorder(
                      borderRadius: SmoothBorderRadius(cornerRadius: 16, cornerSmoothing: 0.8),
                      side: BorderSide(
                        color: selected ? SAMsTheme.accent : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Image.asset(
                          'assets/banks/${b['key']}.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(Icons.account_balance_rounded, color: subFg, size: 28),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        b['name']!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
                      ),
                    ],
                  ),
                ),
              );
            },
            ),
            ],
            );
            }

            Widget _buildStep2(BuildContext ctx, ScrollController sc, Color fg, Color subFg, bool isDark) {
            final locale = ref.watch(languageProvider).locale;
            final fmt = NumberFormat.currency(symbol: 'RM', locale: 'en_MY');
            final selectedBank = _banks.firstWhere(
            (b) => b['key'] == _bank,
            orElse: () => _banks.first,
            );
            return ListView(
            controller: sc,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
            Text(lp.t('confirm_payment', locale), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: fg)),
            const SizedBox(height: 4),
            Text(lp.t('review_details', locale), style: TextStyle(fontSize: 13, color: subFg)),
            const SizedBox(height: 24),
            Center(
            child: Tilt(
              tiltConfig: const TiltConfig(angle: 12, leaveDuration: Duration(milliseconds: 500), leaveCurve: Curves.easeOutCubic),
              child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: widget.amount),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (_, val, __) => Text(
                fmt.format(val),
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: SAMsTheme.accent,
                  letterSpacing: -1,
                ),
              ),
            ),
            ),
            ),
            const SizedBox(height: 6),
            Center(
            child: Text(widget.feeLabel, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fg)),
            ),
            const SizedBox(height: 24),
            Container(
            decoration: ShapeDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F4FB),
              shape: SmoothRectangleBorder(
                borderRadius: SmoothBorderRadius(cornerRadius: 18, cornerSmoothing: 0.8),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _kv(ctx, lp.t('method', locale), _method == 'fpx' ? 'FPX Online Banking' : 'Credit/Debit Card', fg, subFg),
                const SizedBox(height: 10),
                if (_method == 'fpx') _kv(ctx, lp.t('bank', locale), selectedBank['name']!, fg, subFg),
                if (_method == 'fpx') const SizedBox(height: 10),
                _kv(ctx, lp.t('due_date', locale), widget.deadline, fg, subFg),
              ],
            ),
            ),
            ],
            );
            }

            Widget _kv(BuildContext ctx, String k, String v, Color fg, Color subFg) {
            return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
            Text(k, style: TextStyle(fontSize: 13, color: subFg)),
            Flexible(
            child: Text(
              v,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg),
            ),
            ),
            ],
            );
            }

            Widget _buildStep3(BuildContext ctx, Color fg, Color subFg) {
            final locale = ref.watch(languageProvider).locale;
            return Center(
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            const SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                color: SAMsTheme.accent,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              lp.t('processing_payment', locale),
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: fg),
            ),
            const SizedBox(height: 6),
            Text(
              lp.t('dont_close', locale),
              style: TextStyle(fontSize: 12, color: subFg),
            ),
            ],
            ),
            );
            }

            Widget _buildBottomBar(BuildContext ctx, bool isDark) {
            final locale = ref.watch(languageProvider).locale;
            return SafeArea(
            top: false,
            child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
            children: [
              if (_step == 1) ...[
                Expanded(
                  child: MoonOutlinedButton(
                    onTap: () { HapticFeedback.selectionClick(); _go(0); },
                    label: Text(lp.t('back', locale)),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: _step == 1 ? 2 : 1,
                child: MoonFilledButton(
                  backgroundColor: SAMsTheme.accent,
                  onTap: () {
                    if (_step == 0) {
                      HapticFeedback.lightImpact();
                      _go(1);
                    } else if (_step == 1) {
                      // _handleConfirm fires its own mediumImpact.
                      _handleConfirm();
                    }
                  },
                  label: Text(
                    _step == 1 ? lp.t('confirm_pay', locale) : lp.t('next', locale),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
            ),
            ),
            );
            }
            }
