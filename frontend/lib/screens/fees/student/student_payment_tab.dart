import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../config/theme.dart';
import '../../../services/api_service.dart';

class StudentPaymentTab extends StatefulWidget {
  const StudentPaymentTab({super.key});

  @override
  State<StudentPaymentTab> createState() => _StudentPaymentTabState();
}

class _StudentPaymentTabState extends State<StudentPaymentTab> {
  List<dynamic> _fees = [];
  bool _loading = true;
  int _selFeeIndex = 0;
  String _selMethod = 'fpx';
  String _selBank = 'Maybank';
  bool _paying = false;
  Map<String, dynamic>? _receipt;

  final _banks = ['Maybank', 'CIMB', 'RHB', 'Bank Islam', 'AmBank', 'Hong Leong', 'Public Bank'];

  @override
  void initState() {
    super.initState();
    _load();
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

  Future<void> _pay() async {
    if (_amount <= 0) return;
    setState(() => _paying = true);
    try {
      List<Map<String, dynamic>> feesToPay = [];
      if (_selFeeIndex == 0) {
        for (var f in _fees) {
          final bal = ((f['totalAmount'] ?? 0) as num).toDouble() - ((f['paidAmount'] ?? 0) as num).toDouble();
          if (bal > 0) feesToPay.add({'id': f['_id'], 'amount': bal});
        }
      } else {
        final fee = _fees[_selFeeIndex - 1];
        final bal = ((fee['totalAmount'] ?? 0) as num).toDouble() - ((fee['paidAmount'] ?? 0) as num).toDouble();
        if (bal > 0) feesToPay.add({'id': fee['_id'], 'amount': bal});
      }

      if (feesToPay.isEmpty) { setState(() => _paying = false); return; }

      bool anySuccess = false;
      String? lastTxnId;
      
      for (final targetFee in feesToPay) {
        if (_selMethod == 'fpx') {
          final result = await ApiService.post('/payment/fpx/create', {
            'feeId': targetFee['id'],
            'amount': targetFee['amount'],
            'description': 'UMPSA Tuition Fee Payment',
            'bank': _selBank,
          });
          final paymentUrl = result['paymentUrl'];
          final billCode = result['billCode'];
          if (paymentUrl != null && mounted) {
            final success = await Navigator.push<bool>(context, MaterialPageRoute(
              builder: (_) => _PaymentWebView(url: paymentUrl, title: 'FPX Payment'),
            ));
            if (success == true || success == null) {
              final status = await ApiService.get('/payment/fpx/status/$billCode');
              if (status['status'] == 'success') { anySuccess = true; lastTxnId = billCode; }
              else { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Payment pending or failed'), backgroundColor: SAMsTheme.warning)); break; }
            } else { break; }
          }
        } else {
          final result = await ApiService.post('/payment/card/create-intent', {
            'feeId': targetFee['id'],
            'amount': targetFee['amount'],
          });
          final paymentUrl = result['paymentUrl'];
          final sessionId = result['paymentIntentId'];
          if (paymentUrl != null && mounted) {
            final success = await Navigator.push<bool>(context, MaterialPageRoute(
              builder: (_) => _PaymentWebView(url: paymentUrl, title: 'Card Payment'),
            ));
            if (success == true || success == null) {
              final confirm = await ApiService.post('/payment/card/confirm', {'paymentIntentId': sessionId});
              if (confirm['status'] == 'success') { anySuccess = true; lastTxnId = sessionId; }
              else { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Card payment pending or failed'), backgroundColor: SAMsTheme.warning)); break; }
            } else { break; }
          }
        }
      }

      if (anySuccess) {
        setState(() { _receipt = {'status': 'paid', 'amount': _amount, 'txn_id': lastTxnId ?? '', 'bank': _selMethod == 'fpx' ? _selBank : 'Card'}; });
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
    if (_loading) return Center(child: CircularProgressIndicator(color: t.colorScheme.primary, strokeWidth: 2));
    if (_receipt != null) return _buildReceipt(t);

    final daysLeft = _daysLeft;
    final isUrgent = daysLeft <= 14;

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          // Deadline strip - minimal, left-accent
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: t.cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: t.dividerColor),
            ),
            child: Row(children: [
              Container(width: 3, height: 36, decoration: BoxDecoration(color: isUrgent ? SAMsTheme.error : SAMsTheme.success, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Due $_deadlineStr', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: t.colorScheme.onSurface)),
                const SizedBox(height: 2),
                Text('$daysLeft days remaining', style: TextStyle(fontSize: 12, color: isUrgent ? SAMsTheme.error : t.textTheme.bodySmall?.color)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: (isUrgent ? SAMsTheme.error : SAMsTheme.success).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(isUrgent ? 'URGENT' : 'ON TRACK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: isUrgent ? SAMsTheme.error : SAMsTheme.success)),
              ),
            ]),
          ),

          const SizedBox(height: 20),

          // Amount display - large, clean
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: t.cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: t.dividerColor),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Amount to pay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: t.textTheme.bodySmall?.color, letterSpacing: 0.3)),
              const SizedBox(height: 8),
              Text('RM ${_amount.toStringAsFixed(2)}', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: t.colorScheme.onSurface, letterSpacing: -1)),
              if (_fees.length > 1) ...[
                const SizedBox(height: 16),
                Container(height: 1, color: t.dividerColor),
                const SizedBox(height: 12),
                // Fee selection
                _feeOption('Full balance', _balance, 0),
                ...List.generate(_fees.length, (i) {
                  final f = _fees[i];
                  final bal = ((f['totalAmount'] ?? 0) as num).toDouble() - ((f['paidAmount'] ?? 0) as num).toDouble();
                  final name = (f['items'] != null && (f['items'] as List).isNotEmpty) ? f['items'][0]['description'] ?? 'Sem ${f['semester']}' : 'Sem ${f['semester']}';
                  return _feeOption(name, bal, i + 1);
                }),
              ],
            ]),
          ),

          const SizedBox(height: 16),

          // Payment method - horizontal toggle, no emoji
          Text('Method', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.colorScheme.onSurface)),
          const SizedBox(height: 8),
          Row(children: [
            _methodBtn('fpx', Icons.account_balance_outlined, 'FPX'),
            const SizedBox(width: 10),
            _methodBtn('card', Icons.credit_card_outlined, 'Card'),
          ]),

          if (_selMethod == 'fpx') ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(color: t.cardColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: t.dividerColor)),
              child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                value: _selBank,
                isExpanded: true,
                dropdownColor: t.cardColor,
                style: TextStyle(color: t.colorScheme.onSurface, fontSize: 14),
                items: _banks.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                onChanged: (v) => setState(() => _selBank = v!),
              )),
            ),
          ],

          const SizedBox(height: 24),

          // Pay button - full width, solid
          SizedBox(height: 52, child: ElevatedButton(
            onPressed: (_paying || _amount <= 0) ? null : _pay,
            style: ElevatedButton.styleFrom(
              backgroundColor: SAMsTheme.primary,
              foregroundColor: SAMsTheme.ink,
              disabledBackgroundColor: t.dividerColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: _paying
                ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: SAMsTheme.ink))
                : Text(_amount <= 0 ? 'Fully Paid' : 'Pay RM ${_amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          )),

          const SizedBox(height: 12),
          Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.lock_outline, size: 12, color: t.textTheme.bodySmall?.color),
            const SizedBox(width: 4),
            Text('256-bit encrypted', style: TextStyle(fontSize: 11, color: t.textTheme.bodySmall?.color)),
          ])),
        ],
      ),
    );
  }

  Widget _feeOption(String label, double bal, int index) {
    final t = Theme.of(context);
    final active = _selFeeIndex == index;
    return GestureDetector(
      onTap: bal > 0 ? () => setState(() => _selFeeIndex = index) : null,
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [
        Container(
          width: 16, height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: active ? SAMsTheme.primary : (t.textTheme.bodySmall?.color ?? Colors.grey), width: 1.5),
            color: active ? SAMsTheme.primary : Colors.transparent,
          ),
          child: active ? const Center(child: Icon(Icons.check, size: 10, color: Colors.white)) : null,
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: t.colorScheme.onSurface))),
        Text('RM ${bal.toStringAsFixed(2)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? SAMsTheme.primary : t.textTheme.bodySmall?.color)),
      ])),
    );
  }

  Widget _methodBtn(String key, IconData icon, String label) {
    final t = Theme.of(context);
    final active = _selMethod == key;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _selMethod = key),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: active ? SAMsTheme.primary.withOpacity(0.08) : t.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? SAMsTheme.primary : t.dividerColor, width: active ? 1.5 : 1),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 18, color: active ? SAMsTheme.primary : t.textTheme.bodySmall?.color),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? SAMsTheme.primary : t.colorScheme.onSurface)),
        ]),
      ),
    ));
  }

  Widget _buildReceipt(ThemeData t) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receipt')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
        const SizedBox(height: 24),
        // Success indicator - clean circle with check
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(shape: BoxShape.circle, color: SAMsTheme.success.withOpacity(0.1)),
          child: const Icon(Icons.check_rounded, size: 32, color: SAMsTheme.success),
        ),
        const SizedBox(height: 16),
        Text('Payment Complete', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: t.colorScheme.onSurface)),
        const SizedBox(height: 4),
        Text('Your transaction has been processed', style: TextStyle(fontSize: 13, color: t.textTheme.bodySmall?.color)),

        const SizedBox(height: 28),

        // Receipt card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: t.cardColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: t.dividerColor)),
          child: Column(children: [
            _receiptRow(t, 'Transaction ID', _receipt!['txn_id']),
            _receiptRow(t, 'Amount', 'RM ${((_receipt!['amount'] as num).toDouble()).toStringAsFixed(2)}'),
            _receiptRow(t, 'Method', _receipt!['bank']),
            _receiptRow(t, 'Date', DateTime.now().toString().substring(0, 16)),
            _receiptRow(t, 'Status', 'Successful', isLast: true, valueColor: SAMsTheme.success),
          ]),
        ),

        const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 48, child: ElevatedButton(
          onPressed: () { setState(() => _receipt = null); _load(); },
          style: ElevatedButton.styleFrom(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('Done'),
        )),
      ])),
    );
  }

  Widget _receiptRow(ThemeData t, String label, String value, {bool isLast = false, Color? valueColor}) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: t.dividerColor))),
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
        onWebResourceError: (error) {
          setState(() { _hasError = true; _loading = false; _errorMessage = error.description; });
        },
        onNavigationRequest: (request) {
          if (request.url.contains('samsapp://') || request.url.contains('/payment/success') || request.url.contains('/payment/failed')) {
            final success = request.url.contains('success') || request.url.contains('status_id=1');
            _done = true;
            Navigator.pop(context, success);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  void _startTimeoutTimer() {
    Future.delayed(_timeoutDuration, () {
      if (!mounted || _done || _timeoutShown) return;
      _handleTimeout();
    });
  }

  void _handleTimeout() {
    if (_done || _timeoutShown) return;
    _timeoutShown = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Taking longer than expected', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        content: const Text('Your transaction may still be processing. Check payment history for the latest status.', style: TextStyle(height: 1.5)),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); _timeoutShown = false; }, child: const Text('Keep Waiting')),
          TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context, false); }, child: Text('Check History', style: TextStyle(color: SAMsTheme.primary, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context, false)),
      ),
      body: Stack(children: [
        WebViewWidget(controller: _controller),
        if (_loading) Center(child: CircularProgressIndicator(color: t.colorScheme.primary, strokeWidth: 2)),
        if (_hasError) Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.wifi_off_rounded, size: 40, color: t.textTheme.bodySmall?.color),
              const SizedBox(height: 14),
              Text('Connection failed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t.colorScheme.onSurface)),
              const SizedBox(height: 6),
              Text(_errorMessage.isNotEmpty ? _errorMessage : 'Check your internet connection and try again.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: t.textTheme.bodySmall?.color)),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () { setState(() { _hasError = false; _loading = true; }); _controller.loadRequest(Uri.parse(widget.url)); },
                child: const Text('Retry'),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
