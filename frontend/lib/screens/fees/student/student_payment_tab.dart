import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../config/theme.dart';
import '../../../services/api_service.dart';

class StudentPaymentTab extends StatefulWidget {
  const StudentPaymentTab({super.key});

  @override
  State<StudentPaymentTab> createState() => _StudentPaymentTabState();
}

class _StudentPaymentTabState extends State<StudentPaymentTab> with TickerProviderStateMixin {
  List<dynamic> _fees = [];
  bool _loading = true;
  int _selFeeIndex = 0;
  String _selMethod = 'fpx';
  String _selBank = 'Maybank';
  bool _paying = false;
  Map<String, dynamic>? _receipt;

  late AnimationController _btnController;
  late AnimationController _amountController;
  late Animation<double> _btnScale;

  final _banks = ['Maybank', 'CIMB', 'RHB', 'Bank Islam', 'AmBank', 'Hong Leong', 'Public Bank'];

  @override
  void initState() {
    super.initState();
    _btnController = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _amountController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _btnScale = Tween<double>(begin: 1.0, end: 0.96).animate(CurvedAnimation(parent: _btnController, curve: Curves.easeInOut));
    _load();
  }

  @override
  void dispose() {
    _btnController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final fees = await ApiService.get('/fees/my');
      setState(() { _fees = fees; _loading = false; });
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
    final fee = _fees[_selFeeIndex - 1];
    return ((fee['totalAmount'] ?? 0) as num).toDouble() - ((fee['paidAmount'] ?? 0) as num).toDouble();
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

  Future<void> _pay() async {
    if (_amount <= 0) return;
    HapticFeedback.mediumImpact();
    setState(() => _paying = true);
    try {
      String targetFeeId = '';
      double payAmount = _amount;

      if (_selFeeIndex == 0) {
        for (var f in _fees) {
          final bal = ((f['totalAmount'] ?? 0) as num).toDouble() - ((f['paidAmount'] ?? 0) as num).toDouble();
          if (bal > 0) { targetFeeId = f['_id']; break; }
        }
      } else {
        final fee = _fees[_selFeeIndex - 1];
        targetFeeId = fee['_id'];
        payAmount = ((fee['totalAmount'] ?? 0) as num).toDouble() - ((fee['paidAmount'] ?? 0) as num).toDouble();
      }

      if (targetFeeId.isEmpty || payAmount <= 0) { setState(() => _paying = false); return; }

      String? txnId;
      bool success = false;

      if (_selMethod == 'fpx') {
        final result = await ApiService.post('/payment/fpx/create', {
          'feeId': targetFeeId,
          'amount': payAmount,
          'description': 'UMPSA Tuition Fee',
          'bank': _selBank,
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
            else { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Payment pending or failed'), backgroundColor: SAMsTheme.warning)); }
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
            else { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Card payment pending or failed'), backgroundColor: SAMsTheme.warning)); }
          }
        }
      }

      if (success) {
        HapticFeedback.heavyImpact();
        setState(() { _receipt = {'status': 'paid', 'amount': payAmount, 'txn_id': txnId ?? '', 'bank': _selMethod == 'fpx' ? _selBank : 'Card'}; });
      }
      setState(() => _paying = false);
      await _load();
    } catch (e) {
      setState(() => _paying = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: SAMsTheme.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;
    if (_loading) return Center(child: CircularProgressIndicator(color: SAMsTheme.primary, strokeWidth: 2));
    if (_receipt != null) return _buildReceipt(t);

    final daysLeft = _daysLeft;
    final isUrgent = daysLeft <= 14;
    final unpaidCount = _fees.where((f) => ((f['totalAmount'] ?? 0) as num).toDouble() - ((f['paidAmount'] ?? 0) as num).toDouble() > 0).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Make Payment'),
        actions: [
          if (unpaidCount > 0) Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: SAMsTheme.error.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Text('$unpaidCount unpaid', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SAMsTheme.error)),
            )),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          // Step indicator
          _buildStepIndicator(t),
          const SizedBox(height: 20),

          // Amount hero
          AnimatedBuilder(
            animation: _amountController,
            builder: (_, __) => Transform.scale(
              scale: 1.0 - (_amountController.value * 0.02),
              child: Opacity(
                opacity: 1.0 - (_amountController.value * 0.3) + (_amountController.value * 0.3),
                child: _buildAmountCard(t),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Deadline
          if (daysLeft > 0) ...[
            _buildDeadlineRow(t, daysLeft, isUrgent),
            const SizedBox(height: 16),
          ],

          // Payment method
          _buildMethodSection(t, isDark),

          const SizedBox(height: 28),

          // Pay button with press animation
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
    );
  }

  Widget _buildStepIndicator(ThemeData t) {
    return Row(children: [
      _stepDot(t, 'Select', true),
      Expanded(child: Container(height: 1, color: SAMsTheme.primary)),
      _stepDot(t, 'Pay', false),
      Expanded(child: Container(height: 1, color: t.dividerColor)),
      _stepDot(t, 'Done', false),
    ]);
  }

  Widget _stepDot(ThemeData t, String label, bool active) {
    return Column(children: [
      Container(
        width: 24, height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? SAMsTheme.primary : Colors.transparent,
          border: Border.all(color: active ? SAMsTheme.primary : t.dividerColor, width: 1.5),
        ),
        child: active ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
      ),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 10, fontWeight: active ? FontWeight.w600 : FontWeight.w400, color: active ? SAMsTheme.primary : t.textTheme.bodySmall?.color)),
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
          Text('TOTAL DUE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.textTheme.bodySmall?.color, letterSpacing: 1)),
          if (_amount <= 0) Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: SAMsTheme.success.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
            child: const Text('CLEARED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: SAMsTheme.success, letterSpacing: 0.5)),
          ),
        ]),
        const SizedBox(height: 6),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Text('RM', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: t.colorScheme.onSurface)),
          const SizedBox(width: 4),
          Text(_amount.toStringAsFixed(2), style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: t.colorScheme.onSurface, letterSpacing: -1.5, height: 1)),
        ]),

        if (_fees.length > 1) ...[
          const SizedBox(height: 18),
          Container(height: 1, color: t.dividerColor),
          const SizedBox(height: 14),
          Text('Pay for', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: t.textTheme.bodySmall?.color)),
          const SizedBox(height: 8),
          _feeChip('All outstanding', _balance, 0),
          ...List.generate(_fees.length, (i) {
            final f = _fees[i];
            final bal = ((f['totalAmount'] ?? 0) as num).toDouble() - ((f['paidAmount'] ?? 0) as num).toDouble();
            final name = (f['items'] != null && (f['items'] as List).isNotEmpty) ? f['items'][0]['description'] ?? 'Semester ${f['semester']}' : 'Semester ${f['semester']}';
            return _feeChip(name, bal, i + 1);
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
          color: active ? SAMsTheme.primary.withOpacity(0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? SAMsTheme.primary.withOpacity(0.4) : t.dividerColor, width: active ? 1.5 : 1),
        ),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 18, height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? SAMsTheme.primary : Colors.transparent,
              border: Border.all(color: active ? SAMsTheme.primary : (t.textTheme.bodySmall?.color ?? Colors.grey).withOpacity(0.4), width: 1.5),
            ),
            child: active ? const Icon(Icons.check, size: 11, color: Colors.white) : null,
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
        color: (isUrgent ? SAMsTheme.error : SAMsTheme.success).withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: (isUrgent ? SAMsTheme.error : SAMsTheme.success).withOpacity(0.15)),
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
      Text('Payment channel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: t.textTheme.bodySmall?.color, letterSpacing: 0.3)),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: t.dividerColor.withOpacity(0.3), borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          _methodToggle('fpx', Icons.account_balance_outlined, 'Online Banking', t),
          const SizedBox(width: 4),
          _methodToggle('card', Icons.credit_card_outlined, 'Debit/Credit', t),
        ]),
      ),
      if (_selMethod == 'fpx') ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(color: t.cardColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: t.dividerColor)),
          child: DropdownButtonHideUnderline(child: DropdownButton<String>(
            value: _selBank,
            isExpanded: true,
            dropdownColor: t.cardColor,
            icon: Icon(Icons.keyboard_arrow_down, color: t.textTheme.bodySmall?.color, size: 20),
            style: TextStyle(color: t.colorScheme.onSurface, fontSize: 14),
            items: _banks.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
            onChanged: (v) { HapticFeedback.selectionClick(); setState(() => _selBank = v!); },
          )),
        ),
      ],
    ]);
  }

  Widget _methodToggle(String key, IconData icon, String label, ThemeData t) {
    final active = _selMethod == key;
    return Expanded(child: GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); setState(() => _selMethod = key); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? t.cardColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 1))] : null,
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
    final disabled = _paying || _amount <= 0;
    return Container(
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: disabled ? null : LinearGradient(colors: [SAMsTheme.primary, SAMsTheme.primary.withOpacity(0.85)]),
        color: disabled ? t.dividerColor : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : _pay,
          borderRadius: BorderRadius.circular(12),
          child: Center(child: _paying
            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? SAMsTheme.ink : Colors.white))
            : Row(mainAxisSize: MainAxisSize.min, children: [
                if (_amount > 0) ...[
                  Icon(Icons.arrow_forward_rounded, size: 18, color: isDark ? SAMsTheme.ink : Colors.white),
                  const SizedBox(width: 8),
                ],
                Text(
                  _amount <= 0 ? 'All fees cleared' : 'Proceed to pay RM ${_amount.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? SAMsTheme.ink : Colors.white),
                ),
              ]),
          ),
        ),
      ),
    );
  }

  Widget _buildReceipt(ThemeData t) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receipt')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
        const SizedBox(height: 32),
        // Animated success ring
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (_, value, __) => Transform.scale(
            scale: value,
            child: Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SAMsTheme.success.withOpacity(0.08),
                border: Border.all(color: SAMsTheme.success.withOpacity(0.3), width: 2),
              ),
              child: const Icon(Icons.check_rounded, size: 36, color: SAMsTheme.success),
            ),
          ),
        ),
        const SizedBox(height: 20),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          builder: (_, value, __) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 10 * (1 - value)),
              child: Column(children: [
                Text('Payment Successful', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: t.colorScheme.onSurface)),
                const SizedBox(height: 4),
                Text('Transaction processed', style: TextStyle(fontSize: 13, color: t.textTheme.bodySmall?.color)),
              ]),
            ),
          ),
        ),

        const SizedBox(height: 28),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: t.cardColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: t.dividerColor)),
          child: Column(children: [
            _receiptRow(t, 'Reference', _receipt!['txn_id']),
            _receiptRow(t, 'Amount', 'RM ${((_receipt!['amount'] as num).toDouble()).toStringAsFixed(2)}'),
            _receiptRow(t, 'Channel', _receipt!['bank']),
            _receiptRow(t, 'Date', DateTime.now().toString().substring(0, 16)),
            _receiptRow(t, 'Status', 'Completed', isLast: true, valueColor: SAMsTheme.success),
          ]),
        ),

        const SizedBox(height: 28),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
          onPressed: () { setState(() => _receipt = null); _load(); },
          style: ElevatedButton.styleFrom(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('Back to Fees'),
        )),
      ])),
    );
  }

  Widget _receiptRow(ThemeData t, String label, String value, {bool isLast = false, Color? valueColor}) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: t.dividerColor.withOpacity(0.5)))),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: 13, color: t.textTheme.bodySmall?.color)),
      Flexible(child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor ?? t.colorScheme.onSurface), textAlign: TextAlign.right)),
    ]),
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
          TextButton(onPressed: () { Navigator.pop(context); _timeoutShown = false; }, child: const Text('Wait')),
          TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context, false); }, child: Text('Check History', style: TextStyle(color: SAMsTheme.primary, fontWeight: FontWeight.w700))),
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
        if (_loading) Center(child: CircularProgressIndicator(color: SAMsTheme.primary, strokeWidth: 2)),
        if (_hasError) Center(child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.wifi_off_rounded, size: 40, color: t.textTheme.bodySmall?.color),
            const SizedBox(height: 14),
            Text('Connection failed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t.colorScheme.onSurface)),
            const SizedBox(height: 6),
            Text(_errorMessage.isNotEmpty ? _errorMessage : 'Check your connection and try again.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: t.textTheme.bodySmall?.color)),
            const SizedBox(height: 20),
            OutlinedButton(onPressed: () { setState(() { _hasError = false; _loading = true; }); _controller.loadRequest(Uri.parse(widget.url)); }, child: const Text('Retry')),
          ]),
        )),
      ]),
    );
  }
}
