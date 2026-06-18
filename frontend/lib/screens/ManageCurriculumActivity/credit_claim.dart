import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../widgets/glass_card.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'credit_claim_detail.dart';

class CreditClaimScreen extends ConsumerStatefulWidget {
  const CreditClaimScreen({super.key});

  @override
  ConsumerState<CreditClaimScreen> createState() => _CreditClaimScreenState();
}

class _CreditClaimScreenState extends ConsumerState<CreditClaimScreen> {
  List<Map<String, dynamic>> _activities = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final data = await ApiService.get('/curriculum/my/joined');
      final List<dynamic> list = data is List ? data : (data['activities'] ?? []);
      if (!mounted) return;
      setState(() {
        _activities = list.map((a) => Map<String, dynamic>.from(a)).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      backgroundColor: t.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Credit Claims'),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: SAMsTheme.ink),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh, color: SAMsTheme.ink, size: 20),
            onPressed: _loadActivities,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: SAMsTheme.accent))
          : _errorMessage != null
              ? _errorState()
              : _activities.isEmpty
                  ? Center(
                      child: Text(
                        'No activities to claim.',
                        style: TextStyle(color: SAMsTheme.muted, fontFamily: 'Inter'),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadActivities,
                      color: SAMsTheme.accent,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _activities.length,
                        itemBuilder: (ctx, i) => _claimCard(_activities[i]),
                      ),
                    ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: SAMsTheme.error, fontFamily: 'Inter')),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _loadActivities, child: const Text('Retry')),
        ],
      ),
    );
  }

  // ── claim card ─────────────────────────────────────────
  Widget _claimCard(Map<String, dynamic> activity) {
    final id = activity['_id'] ?? '';
    final name = activity['name'] ?? '-';
    final status = (activity['status'] ?? 'upcoming').toString();
    final isEligible = status == 'completed';

    // icon + color per status (match groupmate's screenshots)
    Color iconBg;
    Color iconColor;
    IconData icon;
    String statusLabel;

    if (isEligible) {
      iconBg = SAMsTheme.accent.withValues(alpha: 0.15);
      iconColor = SAMsTheme.accent;
      icon = Iconsax.clipboard_tick;
      statusLabel = 'Eligible for Claim';
    } else if (status == 'ongoing') {
      iconBg = SAMsTheme.warning.withValues(alpha: 0.15);
      iconColor = SAMsTheme.warning;
      icon = Iconsax.dollar_circle;
      statusLabel = 'Ongoing';
    } else {
      iconBg = SAMsTheme.success.withValues(alpha: 0.15);
      iconColor = SAMsTheme.success;
      icon = Iconsax.calendar_1;
      statusLabel = 'Upcoming';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // ── icon square ──
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              // ── name + status ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: SAMsTheme.ink,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      statusLabel,
                      style: const TextStyle(
                        color: SAMsTheme.muted,
                        fontSize: 12,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              // ── claim button ──
              if (isEligible)
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreditClaimDetailScreen(
                        activityId: id,
                        activityName: name,
                      ),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SAMsTheme.accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Claim',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
