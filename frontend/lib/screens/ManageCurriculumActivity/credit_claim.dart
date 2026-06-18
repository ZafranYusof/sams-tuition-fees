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
  Map<String, Map<String, dynamic>> _claimsByActivity = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final actData = await ApiService.get('/curriculum/my/joined');
      final claimData = await ApiService.get('/curriculum/my/claims');
      final List<dynamic> actList = actData is List ? actData : (actData['activities'] ?? []);
      final List<dynamic> claimList = claimData is List ? claimData : (claimData['claims'] ?? []);

      // Map claims by activityId
      final Map<String, Map<String, dynamic>> claimsMap = {};
      for (final c in claimList) {
        final activity = c['activity'];
        final activityId = activity is Map ? (activity['_id'] ?? '') : (c['activity'] ?? '');
        if (activityId.toString().isNotEmpty) {
          claimsMap[activityId.toString()] = Map<String, dynamic>.from(c);
        }
      }

      if (!mounted) return;
      setState(() {
        _activities = actList.map((a) => Map<String, dynamic>.from(a)).toList();
        _claimsByActivity = claimsMap;
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
        title: Text('Credit Claims', style: TextStyle(color: t.colorScheme.onSurface, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left, color: t.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Iconsax.refresh, color: t.colorScheme.onSurface, size: 20),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: SAMsTheme.accent))
          : _errorMessage != null
              ? _errorState()
              : _activities.isEmpty
                  ? Center(child: Text('No activities to claim.', style: TextStyle(color: t.textTheme.bodySmall?.color)))
                  : RefreshIndicator(
                      onRefresh: _loadData,
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
          Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: SAMsTheme.error)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _claimCard(Map<String, dynamic> activity) {
    final t = Theme.of(context);
    final id = activity['_id'] ?? '';
    final name = activity['name'] ?? '-';
    final status = (activity['status'] ?? 'upcoming').toString();

    // Check if claim exists for this activity
    final claim = _claimsByActivity[id];
    final claimStatus = claim?['claimStatus'];
    final isClaimed = claim != null;

    // Determine display state
    Color iconBg;
    Color iconColor;
    IconData icon;
    String statusLabel;
    bool showClaimButton = false;

    if (isClaimed) {
      if (claimStatus == 'approved') {
        iconBg = SAMsTheme.success.withValues(alpha: 0.15);
        iconColor = SAMsTheme.success;
        icon = Iconsax.tick_circle;
        statusLabel = 'Approved';
      } else if (claimStatus == 'rejected') {
        iconBg = SAMsTheme.error.withValues(alpha: 0.15);
        iconColor = SAMsTheme.error;
        icon = Iconsax.close_circle;
        statusLabel = 'Rejected';
      } else {
        iconBg = SAMsTheme.warning.withValues(alpha: 0.15);
        iconColor = SAMsTheme.warning;
        icon = Iconsax.timer_1;
        statusLabel = 'Pending Review';
      }
    } else if (status == 'completed') {
      iconBg = SAMsTheme.accent.withValues(alpha: 0.15);
      iconColor = SAMsTheme.accent;
      icon = Iconsax.clipboard_tick;
      statusLabel = 'Eligible for Claim';
      showClaimButton = true;
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: t.colorScheme.onSurface)),
                    const SizedBox(height: 3),
                    Text(statusLabel, style: TextStyle(color: t.textTheme.bodySmall?.color, fontSize: 12)),
                  ],
                ),
              ),
              if (showClaimButton)
                ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreditClaimDetailScreen(
                          activityId: id,
                          activityName: name,
                        ),
                      ),
                    );
                    if (result == true) _loadData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SAMsTheme.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const Text('Claim', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
