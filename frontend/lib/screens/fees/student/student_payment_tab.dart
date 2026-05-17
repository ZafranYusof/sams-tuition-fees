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
      total += ((f['totalAmount'] ?? 0) - (f['paidAmount'] ?? 0)).toDouble();
    }
    return total;
  }

  double get _amount {
    if (_fees.isEmpty) return 0;
    if (_selFeeIndex == 0) return _balance;
    final fee = _fees[_selFeeIndex - 1];
    return ((fee['totalAmount'] ?? 0) - (fee['paidAmount'] ?? 0)).toDouble();
  }

  Future<void> _pay() async {
    if (_amount <= 0) return;
    setState(() => _paying = true);
    try {
      // Determine which fees to pay
      List<Map<String, dynamic>> feesToPay = [];
      if (_selFeeIndex == 0) {
        // Pay all unpaid fees
        for (var f in _fees) {
          final bal = ((f['totalAmount'] ?? 0) - (f['paidAmount'] ?? 0)).toDouble();
          if (bal > 0) feesToPay.add({'id': f['_id'], 'amount': bal});
        }
      } else {
        final fee = _fees[_selFeeIndex - 1];
        final bal = ((fee['totalAmount'] ?? 0) - (fee['paidAmount'] ?? 0)).toDouble();
        if (bal > 0) feesToPay.add({'id': fee['_id'], 'amount': bal});
      }

      if (feesToPay.isEmpty) {
        setState(() => _paying = false);
        return;
      }

      // For simplicity, pay the first fee (gateway creates one bill per fee)
      final targetFee = feesToPay.first;
      
      if (_selMethod == 'fpx') {
        // Toyyibpay FPX flow
        final result = await ApiService.post('/payment/fpx/create', {
          'feeId': targetFee['id'],
          'amount': targetFee['amount'],
          'description': 'UMPSA Tuition Fee Payment',
          'bank': _selBank,
        });
        
        final paymentUrl = result['paymentUrl'];
        final billCode = result['billCode'];
        
        if (paymentUrl != null && mounted) {
          // Open WebView for FPX payment
          final success = await Navigator.push<bool>(context, MaterialPageRoute(
            builder: (_) => _PaymentWebView(url: paymentUrl, title: 'FPX Payment'),
          ));
          
          // Check payment status after returning
          if (success == true || success == null) {
            final status = await ApiService.get('/payment/fpx/status/$billCode');
            if (status['status'] == 'success') {
              setState(() {
                _receipt = {'status': 'paid', 'amount': targetFee['amount'], 'txn_id': billCode, 'bank': _selBank};
              });
            } else {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment pending or failed. Check history.'), backgroundColor: SAMsTheme.warning));
            }
          }
        }
      } else {
        // Stripe Card flow (Checkout Session)
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
          
          // Confirm payment status
          if (success == true || success == null) {
            final confirm = await ApiService.post('/payment/card/confirm', {'paymentIntentId': sessionId});
            if (confirm['status'] == 'success') {
              setState(() {
                _receipt = {'status': 'paid', 'amount': targetFee['amount'], 'txn_id': sessionId, 'bank': 'Card'};
              });
            } else {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Card payment pending or failed.'), backgroundColor: SAMsTheme.warning));
            }
          }
        }
      }
      setState(() => _paying = false);
    } catch (e) {
      setState(() => _paying = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: SAMsTheme.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: SAMsTheme.primary));
    if (_receipt != null) return _buildReceipt();

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Deadline
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: SAMsTheme.error.withOpacity(0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: SAMsTheme.error.withOpacity(0.3))),
            child: const Column(children: [
              Text('⏰ Payment Deadline', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: SAMsTheme.accent)),
              SizedBox(height: 4),
              Text('30 June 2026', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: SAMsTheme.error)),
            ]),
          ),

          // Select fee
          _card('Select Fee to Pay', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _feeOption('Full Outstanding Balance', _balance, 0),
            ...List.generate(_fees.length, (i) {
              final f = _fees[i];
              final bal = ((f['totalAmount'] ?? 0) - (f['paidAmount'] ?? 0)).toDouble();
              final name = (f['items'] != null && (f['items'] as List).isNotEmpty) ? f['items'][0]['description'] ?? 'Semester ${f['semester']}' : 'Semester ${f['semester']}';
              return _feeOption(name, bal, i + 1);
            }),
          ])),
          const SizedBox(height: 12),

          // Method
          _card('Payment Method', Row(children: [
            _methodBtn('fpx', '🏦', 'FPX'),
            const SizedBox(width: 8),
            _methodBtn('card', '💳', 'Card'),
          ])),
          if (_selMethod == 'fpx') ...[
            const SizedBox(height: 12),
            _card('Select Bank', DropdownButtonFormField<String>(
              value: _selBank,
              dropdownColor: Theme.of(context).cardColor,
              items: _banks.map((b) => DropdownMenuItem(value: b, child: Text(b, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => _selBank = v!),
            )),
          ],
          const SizedBox(height: 16),

          // Summary + Pay
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: SAMsTheme.primary.withOpacity(0.3))),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Total', style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurface)),
                Text('RM ${_amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, color: SAMsTheme.primary, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 6),
              Text('🔒 Secured by SSL Encryption', style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
            ]),
          ),
          const SizedBox(height: 16),
          SizedBox(height: 56, width: double.infinity, child: ElevatedButton(
            onPressed: (_paying || _amount <= 0) ? null : _pay,
            style: ElevatedButton.styleFrom(backgroundColor: SAMsTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: _paying
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(_amount <= 0 ? '✅  Fully Paid' : '💳  Pay Now', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          )),
        ],
      ),
    );
  }

  Widget _card(String title, Widget child) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: Theme.of(context).dividerColor)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w700, fontSize: 14)),
      const SizedBox(height: 12),
      child,
    ]),
  );

  Widget _feeOption(String label, double bal, int index) {
    final active = _selFeeIndex == index;
    return GestureDetector(
      onTap: bal > 0 ? () => setState(() => _selFeeIndex = index) : null,
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(children: [
        Container(width: 18, height: 18, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: active ? SAMsTheme.primary : (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey), width: 2)),
          child: active ? Center(child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: SAMsTheme.primary, shape: BoxShape.circle))) : null),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: active ? SAMsTheme.primary : Theme.of(context).textTheme.bodyMedium?.color))),
        Text('RM ${bal.toStringAsFixed(2)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: active ? SAMsTheme.primary : Theme.of(context).textTheme.bodyMedium?.color)),
      ])),
    );
  }

  Widget _methodBtn(String key, String icon, String label) {
    final active = _selMethod == key;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _selMethod = key),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: active ? SAMsTheme.primary.withOpacity(0.1) : Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: active ? SAMsTheme.primary : Theme.of(context).dividerColor, width: 1.5)),
        child: Column(children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? SAMsTheme.primary : Theme.of(context).textTheme.bodyMedium?.color)),
        ]),
      ),
    ));
  }

  Widget _buildReceipt() {
    return Scaffold(
      appBar: AppBar(title: const Text('Receipt')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor)),
        child: Column(children: [
          const Text('✅', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          Text('Payment Successful!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 24),
          _receiptRow('Receipt No.', _receipt!['txn_id']),
          _receiptRow('Amount', 'RM ${(_receipt!['amount'] as double).toStringAsFixed(2)}'),
          _receiptRow('Bank', _receipt!['bank']),
          _receiptRow('Date', DateTime.now().toString().substring(0, 16)),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 48, child: ElevatedButton(
            onPressed: () { setState(() => _receipt = null); _load(); },
            child: const Text('Done'),
          )),
        ]),
      )),
    );
  }

  Widget _receiptRow(String l, String v) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor))),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(l, style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color)),
      Flexible(child: Text(v, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface), textAlign: TextAlign.right)),
    ]),
  );
}

// ─── PAYMENT WEBVIEW ───
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
  static const _timeoutDuration = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    _startTimeoutTimer();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _loading = true),
        onPageFinished: (_) => setState(() => _loading = false),
        onNavigationRequest: (request) {
          // Intercept callback/deep link
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
        title: const Row(children: [
          Text('⏱️ ', style: TextStyle(fontSize: 22)),
          Text('Payment Timeout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ]),
        content: const Text(
          'Your transaction is taking longer than expected. It may still be processing.\n\nPlease check your payment history for the latest status.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); _timeoutShown = false; },
            child: const Text('Keep Waiting'),
          ),
          TextButton(
            onPressed: () { Navigator.pop(context); Navigator.pop(context, false); },
            child: const Text('Check History', style: TextStyle(color: SAMsTheme.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Stack(children: [
        WebViewWidget(controller: _controller),
        if (_loading) const Center(child: CircularProgressIndicator(color: SAMsTheme.primary)),
      ]),
    );
  }
}
