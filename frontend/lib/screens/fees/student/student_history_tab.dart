import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:figma_squircle/figma_squircle.dart';
import '../../../config/theme.dart';
import '../../../services/api_service.dart';
import '../../../services/cache_service.dart';
import '../../../config/api_config.dart';

class StudentHistoryTab extends StatefulWidget {
  const StudentHistoryTab({super.key});

  @override
  State<StudentHistoryTab> createState() => _StudentHistoryTabState();
}

class _StudentHistoryTabState extends State<StudentHistoryTab> with TickerProviderStateMixin {
  List<dynamic> _payments = [];
  bool _loading = true;
  String _query = '';
  String _filter = 'all';
  String _sort = 'date_desc';
  bool _summaryFlipped = false;

  late AnimationController _staggerCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _shimmerCtrl;
  late AnimationController _counterCtrl;
  late AnimationController _flipCtrl;
  late Animation<double> _counterAnim;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat();
    _counterCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _flipCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _counterAnim = CurvedAnimation(parent: _counterCtrl, curve: Curves.easeOutCubic);
    _load();
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    _counterCtrl.dispose();
    _flipCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final payments = await ApiService.get('/fees/payments/history');
      setState(() { _payments = payments; _loading = false; });
      _staggerCtrl.forward(from: 0);
      _counterCtrl.forward(from: 0);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _continuePay(Map<String, dynamic> p) async {
    HapticFeedback.lightImpact();
    final txnId = p['transactionId'] ?? '';
    final method = p['method'] ?? 'fpx';
    String paymentUrl;

    if (method == 'card' && txnId.startsWith('cs_')) {
      paymentUrl = 'https://checkout.stripe.com/c/pay/$txnId';
    } else {
      final baseUrl = 'https://dev.toyyibpay.com';
      paymentUrl = '$baseUrl/$txnId';
    }

    await Navigator.push<bool>(context, MaterialPageRoute(
      builder: (_) => _ContinuePayWebView(url: paymentUrl, title: 'Continue Payment'),
    ));
    await _load();
  }

  List<dynamic> get _filtered {
    final list = _payments.where((p) {
      final q = _query.toLowerCase();
      final matchQ = q.isEmpty || (p['transactionId'] ?? '').toLowerCase().contains(q) || (p['bank'] ?? '').toLowerCase().contains(q);
      final matchF = _filter == 'all' || p['status'] == _filter;
      return matchQ && matchF;
    }).toList();

    list.sort((a, b) {
      switch (_sort) {
        case 'date_asc': return (a['paidAt'] ?? '').compareTo(b['paidAt'] ?? '');
        case 'amount_desc': return ((b['amount'] ?? 0) as num).compareTo((a['amount'] ?? 0) as num);
        case 'amount_asc': return ((a['amount'] ?? 0) as num).compareTo((b['amount'] ?? 0) as num);
        default: return (b['paidAt'] ?? '').compareTo(a['paidAt'] ?? '');
      }
    });
    return list;
  }

  String _shortId(String id) {
    if (id.length <= 12) return id;
    return '${id.substring(0, 8)}...';
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    final d = DateTime.tryParse(raw.toString());
    if (d == null) return '';
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _smartDate(dynamic raw) {
    if (raw == null) return '';
    final d = DateTime.tryParse(raw.toString())?.toLocal();
    if (d == null) return '';
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24 && now.day == d.day) return 'Today, ${_formatTime(raw)}';
    if (diff.inDays == 1 || (now.day - d.day == 1 && now.month == d.month)) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 14) return 'Last week';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    return _formatDate(raw);
  }

  bool _isRecent(dynamic raw) {
    if (raw == null) return false;
    final d = DateTime.tryParse(raw.toString())?.toLocal();
    if (d == null) return false;
    return DateTime.now().difference(d).inHours < 24;
  }

  String _formatTime(dynamic raw) {
    if (raw == null) return '';
    final d = DateTime.tryParse(raw.toString())?.toLocal();
    if (d == null) return '';
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  // BANK LOGO WIDGET
  Widget _bankLogo(String bank, double size) {
    final logoAsset = _bankLogoAsset(bank);
    if (logoAsset != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(size * 0.25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.25),
          child: Image.asset(logoAsset, fit: BoxFit.contain),
        ),
      );
    }
    // Fallback: colored circle with letter
    final config = _bankConfig(bank);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: config['color'] as Color,
        borderRadius: BorderRadius.circular(size * 0.25),
        boxShadow: [
          BoxShadow(
            color: (config['color'] as Color).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        config['letter'] as String,
        style: GoogleFonts.fraunces(
          color: Colors.white,
          fontSize: size * 0.45,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
  }

  String? _bankLogoAsset(String bank) {
    final b = bank.toLowerCase();
    if (b.contains('maybank')) return 'assets/banks/maybank.png';
    if (b.contains('rhb')) return 'assets/banks/rhb.png';
    if (b.contains('cimb')) return 'assets/banks/cimb.png';
    if (b.contains('public')) return 'assets/banks/public.png';
    if (b.contains('hong leong')) return 'assets/banks/hong_leong.png';
    if (b.contains('bank islam') || b.contains('islam')) return 'assets/banks/bank_islam.png';
    if (b.contains('ambank') || b.contains('am bank')) return 'assets/banks/ambank.png';
    if (b.contains('alliance')) return 'assets/banks/alliance.png';
    if (b.contains('uob')) return 'assets/banks/uob.png';
    if (b.contains('ocbc')) return 'assets/banks/ocbc.png';
    if (b.contains('hsbc')) return 'assets/banks/hsbc.png';
    if (b.contains('card') || b.contains('stripe')) return 'assets/banks/stripe.png';
    if (b.contains('online banking') || b.contains('fpx') || b.contains('b2c')) return 'assets/banks/fpx.png';
    return null;
  }

  Map<String, dynamic> _bankConfig(String bank) {
    final b = bank.toLowerCase();
    if (b.contains('maybank')) return {'color': const Color(0xFFFFC72C), 'letter': 'M'};
    if (b.contains('rhb')) return {'color': const Color(0xFF003087), 'letter': 'R'};
    if (b.contains('cimb')) return {'color': const Color(0xFFCC1F2A), 'letter': 'C'};
    if (b.contains('public')) return {'color': const Color(0xFFE60000), 'letter': 'P'};
    if (b.contains('hong leong')) return {'color': const Color(0xFF00529B), 'letter': 'H'};
    if (b.contains('bank islam') || b.contains('islam')) return {'color': const Color(0xFF008B47), 'letter': 'BI'};
    if (b.contains('ambank') || b.contains('am bank')) return {'color': const Color(0xFFE60012), 'letter': 'A'};
    if (b.contains('alliance')) return {'color': const Color(0xFFEC1B23), 'letter': 'AL'};
    if (b.contains('uob')) return {'color': const Color(0xFF003087), 'letter': 'U'};
    if (b.contains('ocbc')) return {'color': const Color(0xFFE60012), 'letter': 'O'};
    if (b.contains('hsbc')) return {'color': const Color(0xFFDB0011), 'letter': 'H'};
    if (b.contains('card') || b.contains('stripe')) return {'color': const Color(0xFF635BFF), 'letter': 'S'};
    return {'color': SAMsTheme.accent, 'letter': bank.isNotEmpty ? bank[0].toUpperCase() : '?'};
  }

  // QUICK ACTIONS BOTTOM SHEET
  void _showQuickActions(Map<String, dynamic> p) {
    HapticFeedback.mediumImpact();
    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;
    final muted = isDark ? const Color(0xFFB0BEC5) : const Color(0xFF4A5568);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0B1B2C) : const Color(0xFFF5F0E8),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: SAMsTheme.accent.withOpacity(0.3), width: 1.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32, height: 3,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: muted.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
            ),
            _quickAction(Iconsax.eye, 'View Details', muted, () { Navigator.pop(context); _viewPaymentDetail(p); }),
            _quickAction(Iconsax.share, 'Share Receipt', muted, () { Navigator.pop(context); _shareReceipt(p); }),
            _quickAction(Iconsax.copy, 'Copy Reference', muted, () {
              Clipboard.setData(ClipboardData(text: p['transactionId'] ?? ''));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Reference copied', style: GoogleFonts.inter(fontSize: 12)),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
              ));
            }),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(IconData icon, String label, Color muted, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Row(children: [
          Icon(icon, size: 18, color: muted),
          const SizedBox(width: 16),
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  void _shareReceipt(Map<String, dynamic> p) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Sharing receipt for ${_shortId(p['transactionId'] ?? '')}', style: GoogleFonts.inter(fontSize: 12)),
      duration: const Duration(seconds: 1),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _viewPaymentDetail(Map<String, dynamic> p) {
    HapticFeedback.lightImpact();
    final status = p['status'] ?? 'pending';
    final isSuccess = status == 'success';
    final isFailed = status == 'failed';
    final col = isSuccess ? const Color(0xFF2E7D32) : (isFailed ? const Color(0xFFC62828) : SAMsTheme.accent);

    final bank = p['bank'] as String? ?? (p['method'] == 'card' ? 'Card Payment' : 'FPX Bank');
    String description = 'Tuition Fee Payment';
    if (p['fee'] != null && p['fee'] is Map) {
      final fee = p['fee'] as Map<String, dynamic>;
      if (fee['items'] != null && (fee['items'] as List).isNotEmpty) {
        description = (fee['items'] as List).map((item) => item['description'] ?? '').where((d) => d.isNotEmpty).join(', ');
      } else if (fee['semester'] != null) {
        description = 'Semester ${fee['semester']} Fees';
      }
      if (description.isEmpty) description = 'Tuition Fee Payment';
    }

    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;
    final accent = SAMsTheme.accent;
    final muted = isDark ? const Color(0xFFB0BEC5) : const Color(0xFF4A5568);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0B1B2C) : const Color(0xFFF5F0E8),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: accent.withOpacity(0.3), width: 1.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 32, height: 3, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: muted.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
            Row(children: [
              Container(width: 18, height: 1, color: accent),
              const SizedBox(width: 8),
              Text('TRANSACTION DETAIL', style: GoogleFonts.inter(color: muted, fontSize: 10, letterSpacing: 1.8, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 20),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('RM', style: GoogleFonts.fraunces(color: muted, fontSize: 16, fontWeight: FontWeight.w400)),
              const SizedBox(width: 4),
              Text(((p['amount'] ?? 0) as num).toStringAsFixed(2), style: GoogleFonts.fraunces(color: t.colorScheme.onSurface, fontSize: 32, fontWeight: FontWeight.w400, letterSpacing: -1, height: 1)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: col.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: col.withOpacity(0.3))),
                child: Text(status[0].toUpperCase() + status.substring(1), style: GoogleFonts.inter(color: col, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              ),
            ]),
            const SizedBox(height: 20),
            Divider(color: muted.withOpacity(0.15), height: 1),
            const SizedBox(height: 16),
            _sheetRow('Reference', _shortId(p['transactionId'] ?? ''), muted, t),
            _sheetRow('Date', _formatDate(p['paidAt']), muted, t),
            _sheetRow('Time', _formatTime(p['paidAt']), muted, t),
            _sheetRow('Method', p['method'] == 'card' ? 'Card (Stripe)' : 'FPX Online Banking', muted, t),
            _sheetRow('Bank', bank, muted, t),
            _sheetRow('Description', description, muted, t),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: muted.withOpacity(0.2)))),
              child: Text('Close', style: GoogleFonts.inter(color: muted, fontSize: 13, fontWeight: FontWeight.w500)),
            )),
          ],
        ),
      ),
    );
  }

  Widget _sheetRow(String label, String value, Color muted, ThemeData t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.inter(color: muted, fontSize: 12)),
        const SizedBox(width: 16),
        Flexible(child: Text(value, style: GoogleFonts.inter(color: t.colorScheme.onSurface, fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.end)),
      ]),
    );
  }

  double get _totalPaid => _payments.where((p) => p['status'] == 'success').fold(0.0, (sum, p) => sum + ((p['amount'] ?? 0) as num).toDouble());
  double get _totalPending => _payments.where((p) => p['status'] == 'pending').fold(0.0, (sum, p) => sum + ((p['amount'] ?? 0) as num).toDouble());
  double get _totalFailed => _payments.where((p) => p['status'] == 'failed').fold(0.0, (sum, p) => sum + ((p['amount'] ?? 0) as num).toDouble());

  // SPARKLINE DATA - last 30 days payment amounts
  List<double> _sparklineData() {
    final now = DateTime.now();
    final buckets = List<double>.filled(30, 0);
    for (final p in _payments) {
      if (p['status'] != 'success') continue;
      final d = DateTime.tryParse(p['paidAt']?.toString() ?? '')?.toLocal();
      if (d == null) continue;
      final daysAgo = now.difference(d).inDays;
      if (daysAgo >= 0 && daysAgo < 30) {
        buckets[29 - daysAgo] += ((p['amount'] ?? 0) as num).toDouble();
      }
    }
    return buckets;
  }

  PopupMenuItem<String> _sortMenuItem(String value, String label, Color muted, ThemeData t) {
    final isActive = _sort == value;
    return PopupMenuItem<String>(
      value: value,
      child: Row(children: [
        if (isActive) ...[Icon(Icons.check_rounded, size: 14, color: SAMsTheme.accent), const SizedBox(width: 8)],
        Text(label, style: GoogleFonts.inter(color: isActive ? t.colorScheme.onSurface : muted, fontSize: 12, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;
    final accent = SAMsTheme.accent;
    final muted = isDark ? const Color(0xFFB0BEC5) : const Color(0xFF4A5568);
    final cardBg = isDark ? const Color(0xFF0F2235) : const Color(0xFFEDE5D4);

    return Scaffold(
      backgroundColor: t.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: t.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Row(children: [
          Container(width: 14, height: 1, color: accent),
          const SizedBox(width: 8),
          Text('HISTORY', style: GoogleFonts.inter(color: muted, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w600)),
        ]),
        titleSpacing: 20,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Iconsax.sort, color: muted, size: 20),
            tooltip: 'Sort',
            color: isDark ? const Color(0xFF0F2235) : const Color(0xFFF5F0E8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            onSelected: (v) { HapticFeedback.selectionClick(); setState(() => _sort = v); },
            itemBuilder: (_) => [
              _sortMenuItem('date_desc', 'Date (Newest)', muted, t),
              _sortMenuItem('date_asc', 'Date (Oldest)', muted, t),
              _sortMenuItem('amount_desc', 'Amount (High)', muted, t),
              _sortMenuItem('amount_asc', 'Amount (Low)', muted, t),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: accent, strokeWidth: 1.5)))
          : Column(children: [
              // HERO SUMMARY - flippable
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: GestureDetector(
                  onTap: () { HapticFeedback.lightImpact(); setState(() => _summaryFlipped = !_summaryFlipped); _summaryFlipped ? _flipCtrl.forward() : _flipCtrl.reverse(); },
                  child: AnimatedBuilder(
                    animation: _flipCtrl,
                    builder: (_, __) {
                      final showFront = _flipCtrl.value < 0.5;
                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(_flipCtrl.value * 3.14159),
                        child: showFront ? _buildSummaryFront(cardBg, muted, accent, t) : Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..rotateY(3.14159),
                          child: _buildSummaryBack(cardBg, muted, accent, t),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // SEARCH BAR with glass blur
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: cardBg.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _query.isNotEmpty ? accent.withOpacity(0.4) : muted.withOpacity(0.12)),
                      ),
                      child: TextField(
                        onChanged: (v) => setState(() => _query = v),
                        style: GoogleFonts.inter(color: t.colorScheme.onSurface, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search by reference or bank',
                          hintStyle: GoogleFonts.inter(color: muted.withOpacity(0.5), fontSize: 12),
                          prefixIcon: Icon(Iconsax.search_normal, size: 16, color: _query.isNotEmpty ? accent : muted.withOpacity(0.4)),
                          suffixIcon: _query.isNotEmpty ? IconButton(
                            icon: Icon(Iconsax.close_circle, size: 14, color: muted.withOpacity(0.5)),
                            onPressed: () => setState(() => _query = ''),
                          ) : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // FILTER PILLS - animated underline
              _buildFilterTabs(muted, accent, t),
              Divider(color: muted.withOpacity(0.1), height: 1),
              const SizedBox(height: 8),
              // LIST
              Expanded(
                child: _filtered.isEmpty
                    ? _buildEmptyState(muted, accent, t)
                    : RefreshIndicator(
                        color: accent,
                        backgroundColor: t.scaffoldBackgroundColor,
                        onRefresh: () { HapticFeedback.mediumImpact(); return _load(); },
                        child: AnimationLimiter(
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) => _buildPaymentCard(_filtered[i], i, muted, accent, cardBg, t, isDark),
                          ),
                        ),
                      ),
              ),
            ]),
    );
  }

  // SUMMARY FRONT
  Widget _buildSummaryFront(Color cardBg, Color muted, Color accent, ThemeData t) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accent, width: 3)),
        boxShadow: [BoxShadow(color: accent.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('TOTAL PAID', style: GoogleFonts.inter(color: muted, fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            AnimatedBuilder(
              animation: _counterAnim,
              builder: (_, __) {
                final val = _totalPaid * _counterAnim.value;
                return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('RM ', style: GoogleFonts.fraunces(color: muted, fontSize: 13, fontWeight: FontWeight.w400)),
                  Text(val.toStringAsFixed(2), style: GoogleFonts.fraunces(color: const Color(0xFF2E7D32), fontSize: 22, fontWeight: FontWeight.w500, height: 1)),
                ]);
              },
            ),
          ])),
          const SizedBox(width: 12),
          // SPARKLINE
          SizedBox(width: 80, height: 36, child: CustomPaint(painter: _SparklinePainter(_sparklineData(), const Color(0xFF2E7D32)))),
        ]),
        const SizedBox(height: 10),
        Divider(color: muted.withOpacity(0.12), height: 1),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: Row(children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text('Pending', style: GoogleFonts.inter(color: muted, fontSize: 10, letterSpacing: 0.5)),
            const SizedBox(width: 6),
            Text('RM ${_totalPending.toStringAsFixed(2)}', style: GoogleFonts.fraunces(color: accent, fontSize: 12, fontWeight: FontWeight.w600)),
          ])),
          Icon(Iconsax.refresh, size: 11, color: muted.withOpacity(0.4)),
          const SizedBox(width: 4),
          Text('Tap to flip', style: GoogleFonts.inter(color: muted.withOpacity(0.4), fontSize: 9, letterSpacing: 0.5)),
        ]),
      ]),
    );
  }

  // SUMMARY BACK - breakdown
  Widget _buildSummaryBack(Color cardBg, Color muted, Color accent, ThemeData t) {
    final successCount = _payments.where((p) => p['status'] == 'success').length;
    final pendingCount = _payments.where((p) => p['status'] == 'pending').length;
    final failedCount = _payments.where((p) => p['status'] == 'failed').length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accent, width: 3)),
        boxShadow: [BoxShadow(color: accent.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('BREAKDOWN', style: GoogleFonts.inter(color: muted, fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _breakdownRow('Successful', successCount, _totalPaid, const Color(0xFF2E7D32), muted),
        const SizedBox(height: 8),
        _breakdownRow('Pending', pendingCount, _totalPending, accent, muted),
        const SizedBox(height: 8),
        _breakdownRow('Failed', failedCount, _totalFailed, const Color(0xFFC62828), muted),
      ]),
    );
  }

  Widget _breakdownRow(String label, int count, double amount, Color color, Color muted) {
    return Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Expanded(child: Text(label, style: GoogleFonts.inter(color: muted, fontSize: 11, fontWeight: FontWeight.w500))),
      Text('$count', style: GoogleFonts.inter(color: muted.withOpacity(0.6), fontSize: 10)),
      const SizedBox(width: 12),
      Text('RM ${amount.toStringAsFixed(2)}', style: GoogleFonts.fraunces(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    ]);
  }

  // FILTER TABS
  Widget _buildFilterTabs(Color muted, Color accent, ThemeData t) {
    final filters = ['all', 'success', 'failed', 'pending'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: filters.map((f) {
          final active = _filter == f;
          final label = f == 'all' ? 'All' : f[0].toUpperCase() + f.substring(1);
          final count = f == 'all' ? _payments.length : _payments.where((p) => p['status'] == f).length;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _filter = f); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 20),
              padding: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: active ? accent : Colors.transparent, width: 2)),
              ),
              child: Row(children: [
                Text(label, style: GoogleFonts.inter(color: active ? t.colorScheme.onSurface : muted.withOpacity(0.5), fontSize: 12, fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
                if (count > 0) ...[
                  const SizedBox(width: 4),
                  Text('$count', style: GoogleFonts.inter(color: active ? accent : muted.withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.w500)),
                ],
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }

  // EMPTY STATE
  Widget _buildEmptyState(Color muted, Color accent, ThemeData t) {
    final messages = {
      'all': {'title': 'No transactions yet', 'sub': 'Your payment history will appear here'},
      'success': {'title': 'No successful payments', 'sub': 'Once you pay, they\'ll show up here'},
      'failed': {'title': 'No failed transactions', 'sub': 'You\'re all paid up'},
      'pending': {'title': 'No pending payments', 'sub': 'Everything is settled'},
    };
    final msg = messages[_filter] ?? messages['all']!;
    final iconData = _filter == 'failed' ? Iconsax.shield_tick : (_filter == 'pending' ? Iconsax.tick_circle : Iconsax.receipt_text);
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
        builder: (_, val, child) => Opacity(opacity: val, child: Transform.scale(scale: 0.9 + 0.1 * val, child: child)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(alignment: Alignment.center, children: [
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Container(
                width: 96 + (_pulseCtrl.value * 16), height: 96 + (_pulseCtrl.value * 16),
                decoration: BoxDecoration(color: accent.withOpacity(0.04 + (_pulseCtrl.value * 0.04)), shape: BoxShape.circle),
              ),
            ),
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: accent.withOpacity(0.08), shape: BoxShape.circle),
              child: Icon(iconData, size: 32, color: accent.withOpacity(0.6)),
            ),
          ]),
          const SizedBox(height: 20),
          Text(msg['title']!, style: GoogleFonts.fraunces(color: t.colorScheme.onSurface.withOpacity(0.7), fontSize: 17, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(msg['sub']!, style: GoogleFonts.inter(color: muted.withOpacity(0.5), fontSize: 12)),
        ]),
      ),
    );
  }

  // PAYMENT CARD - the meat
  Widget _buildPaymentCard(dynamic p, int i, Color muted, Color accent, Color cardBg, ThemeData t, bool isDark) {
    final status = p['status'] ?? 'pending';
    final isSuccess = status == 'success';
    final isFailed = status == 'failed';
    final isPending = status == 'pending';
    final statusColor = isSuccess ? const Color(0xFF2E7D32) : (isFailed ? const Color(0xFFC62828) : accent);

    final txnId = p['transactionId'] ?? '';
    final amount = ((p['amount'] ?? 0) as num).toStringAsFixed(2);
    final bank = p['bank'] as String? ?? (p['method'] == 'card' ? 'Card' : 'FPX');
    final smartDateStr = _smartDate(p['paidAt']);
    final isRecent = _isRecent(p['paidAt']);

    // Spotlight: dim non-matching when searching
    final isMatch = _query.isEmpty || (txnId).toString().toLowerCase().contains(_query.toLowerCase()) || bank.toLowerCase().contains(_query.toLowerCase());
    final cardOpacity = (_query.isNotEmpty && !isMatch) ? 0.3 : 1.0;
    final hasGlow = _query.isNotEmpty && isMatch;

    return AnimationConfiguration.staggeredList(
      position: i,
      duration: const Duration(milliseconds: 500),
      child: SlideAnimation(
        verticalOffset: 30,
        child: FadeInAnimation(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: cardOpacity,
            child: _PressableCard(
              onTap: () => isPending ? _continuePay(p) : _viewPaymentDetail(p),
              onLongPress: () => _showQuickActions(p),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: ShapeDecoration(
                  color: cardBg.withOpacity(isDark ? 0.6 : 0.7),
                  shape: SmoothRectangleBorder(
                    borderRadius: SmoothBorderRadius(cornerRadius: 14, cornerSmoothing: 0.8),
                    side: BorderSide(
                      color: hasGlow ? accent.withOpacity(0.5) : (isPending ? statusColor.withOpacity(0.25) : muted.withOpacity(0.08)),
                      width: hasGlow ? 1.2 : 1,
                    ),
                  ),
                  shadows: [
                    BoxShadow(
                      color: hasGlow ? accent.withOpacity(0.2) : (isFailed ? statusColor.withOpacity(0.06) : Colors.black.withOpacity(0.03)),
                      blurRadius: hasGlow ? 12 : 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(children: [
                  // BANK LOGO with status indicator overlay
                  Stack(children: [
                    _bankLogo(bank, 42),
                    // Pulse for pending
                    if (isPending) Positioned(
                      right: -2, top: -2,
                      child: AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (_, __) => Container(
                          width: 12, height: 12,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                            border: Border.all(color: cardBg, width: 2),
                            boxShadow: [BoxShadow(color: accent.withOpacity(0.4 + (_pulseCtrl.value * 0.4)), blurRadius: 4 + (_pulseCtrl.value * 4), spreadRadius: _pulseCtrl.value * 2)],
                          ),
                        ),
                      ),
                    ),
                    if (isFailed) Positioned(
                      right: -2, top: -2,
                      child: Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: cardBg, width: 2),
                          boxShadow: [BoxShadow(color: statusColor.withOpacity(0.5), blurRadius: 6)],
                        ),
                      ),
                    ),
                    if (isSuccess) Positioned(
                      right: -2, top: -2,
                      child: Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle, border: Border.all(color: cardBg, width: 2)),
                        child: const Icon(Icons.check_rounded, size: 8, color: Colors.white),
                      ),
                    ),
                  ]),
                  const SizedBox(width: 12),
                  // INFO
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Flexible(child: Text(bank, style: GoogleFonts.inter(color: t.colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                        if (isRecent) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: accent.withOpacity(0.15), borderRadius: BorderRadius.circular(4), border: Border.all(color: accent.withOpacity(0.3))),
                            child: Text('NEW', style: GoogleFonts.inter(color: accent, fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                          ),
                        ],
                      ]),
                      const SizedBox(height: 2),
                      Row(children: [
                        Text(_shortId(txnId), style: GoogleFonts.jetBrainsMono(color: muted.withOpacity(0.45), fontSize: 10)),
                        const SizedBox(width: 8),
                        Container(width: 2, height: 2, decoration: BoxDecoration(color: muted.withOpacity(0.3), shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text(smartDateStr, style: GoogleFonts.inter(color: muted.withOpacity(0.6), fontSize: 10)),
                      ]),
                    ]),
                  ),
                  // AMOUNT - hero typography
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(isSuccess ? '+' : (isFailed ? '−' : '•'), style: GoogleFonts.fraunces(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600, height: 1.4)),
                      const SizedBox(width: 2),
                      Text('RM', style: GoogleFonts.fraunces(color: statusColor.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.w500, height: 2)),
                      const SizedBox(width: 3),
                      Text(amount, style: GoogleFonts.fraunces(color: statusColor, fontSize: 16, fontWeight: FontWeight.w600, height: 1, letterSpacing: -0.3)),
                    ]),
                    const SizedBox(height: 3),
                    // Status indicator with shimmer for success
                    if (isSuccess) AnimatedBuilder(
                      animation: _shimmerCtrl,
                      builder: (_, __) => ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          begin: Alignment(_shimmerCtrl.value * 2 - 1, 0),
                          end: Alignment(_shimmerCtrl.value * 2, 0),
                          colors: [statusColor.withOpacity(0.5), statusColor, statusColor.withOpacity(0.5)],
                        ).createShader(bounds),
                        child: Text('Success', style: GoogleFonts.inter(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                      ),
                    )
                    else Text(
                      status[0].toUpperCase() + status.substring(1),
                      style: GoogleFonts.inter(color: statusColor.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                    ),
                  ]),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// PRESSABLE CARD WIDGET - haptic + scale animation
class _PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  const _PressableCard({required this.child, required this.onTap, this.onLongPress});
  @override
  State<_PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<_PressableCard> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) { setState(() => _pressed = true); HapticFeedback.lightImpact(); },
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// SPARKLINE PAINTER
class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  _SparklinePainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) {
      // flat baseline
      final paint = Paint()..color = color.withOpacity(0.2)..strokeWidth = 1.2..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
      return;
    }
    final stepX = size.width / (data.length - 1);
    final path = Path();
    final fillPath = Path();
    for (var i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i] / maxVal * size.height * 0.85) - size.height * 0.075;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Gradient fill
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.25), color.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, linePaint);

    // End dot
    final lastIdx = data.length - 1;
    final lastX = lastIdx * stepX;
    final lastY = size.height - (data[lastIdx] / maxVal * size.height * 0.85) - size.height * 0.075;
    canvas.drawCircle(Offset(lastX, lastY), 2.5, Paint()..color = color);
    canvas.drawCircle(Offset(lastX, lastY), 4.5, Paint()..color = color.withOpacity(0.2));
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) => old.data != data;
}

// CONTINUE PAYMENT WEBVIEW
class _ContinuePayWebView extends StatefulWidget {
  final String url;
  final String title;
  const _ContinuePayWebView({required this.url, required this.title});

  @override
  State<_ContinuePayWebView> createState() => _ContinuePayWebViewState();
}

class _ContinuePayWebViewState extends State<_ContinuePayWebView> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
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
            Navigator.pop(context, success);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context, false)),
      ),
      body: Stack(children: [
        WebViewWidget(controller: _controller),
        if (_loading) const Center(child: CircularProgressIndicator(color: SAMsTheme.primary)),
        if (_hasError) Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.wifi_off_rounded, size: 48, color: SAMsTheme.error),
              const SizedBox(height: 16),
              const Text('Network Error', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(_errorMessage.isNotEmpty ? _errorMessage : 'Failed to load payment page.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 24),
              ElevatedButton(
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
