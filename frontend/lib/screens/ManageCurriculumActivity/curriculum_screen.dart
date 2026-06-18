import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../widgets/glass_card.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'curriculum_activity.dart';
import 'credit_claim.dart';

class CurriculumScreen extends ConsumerStatefulWidget {
  const CurriculumScreen({super.key});

  @override
  ConsumerState<CurriculumScreen> createState() => _CurriculumScreenState();
}

class _CurriculumScreenState extends ConsumerState<CurriculumScreen> {
  int _activitiesJoined = 0;
  int _creditHoursEarned = 0;
  int _claimPending = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final my = await ApiService.get('/curriculum/my/joined');
      final claimData = await ApiService.get('/curriculum/my/claims');
      final List<dynamic> list = my is List ? my : (my['activities'] ?? []);
      final List<dynamic> claims = claimData is List ? claimData : (claimData['claims'] ?? []);

      // Credit hours only from APPROVED claims
      final approvedClaims = claims.where((c) => c['claimStatus'] == 'approved');
      int hours = 0;
      for (final c in approvedClaims) {
        final activity = c['activity'];
        if (activity is Map) {
          hours += ((activity['points'] ?? activity['creditHours'] ?? 0) as num).toInt();
        }
      }

      // Pending claims count
      final pending = claims.where((c) => c['claimStatus'] == 'pending').length;

      if (!mounted) return;
      setState(() {
        _activitiesJoined = list.length;
        _creditHoursEarned = hours;
        _claimPending = pending;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      backgroundColor: t.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Curriculum Module', style: TextStyle(color: t.colorScheme.onSurface)),
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left, color: t.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: SAMsTheme.accent))
          : RefreshIndicator(
              onRefresh: _loadStats,
              color: SAMsTheme.accent,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 3 stat cards ──
                    Row(
                      children: [
                        Expanded(child: _statCard(Iconsax.calendar_tick, 'Activities Joined', _activitiesJoined)),
                        const SizedBox(width: 10),
                        Expanded(child: _statCard(Iconsax.medal_star, 'Credit Hours\nEarned', _creditHoursEarned)),
                        const SizedBox(width: 10),
                        Expanded(child: _statCard(Iconsax.clipboard_text, 'Claim Pending', _claimPending)),
                      ],
                    ),
                    const SizedBox(height: 28),
                    // ── section header ──
                    Text(
                      'WHAT WOULD YOU LIKE TO DO?',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        fontSize: 12,
                        color: t.textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 14),
                    // ── Curriculum Activity ──
                    _actionCard(
                      icon: Iconsax.calendar,
                      iconBg: SAMsTheme.accent.withValues(alpha: 0.12),
                      iconColor: SAMsTheme.accent,
                      title: 'Curriculum Activity',
                      subtitle: 'Browse and register activities',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CurriculumActivityScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // ── Credit Claim ──
                    _actionCard(
                      icon: Iconsax.clipboard,
                      iconBg: SAMsTheme.success.withValues(alpha: 0.12),
                      iconColor: SAMsTheme.success,
                      title: 'Credit Claim',
                      subtitle: 'Submit and track claims',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CreditClaimScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _statCard(IconData icon, String label, int value) {
    final t = Theme.of(context);
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: SAMsTheme.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: SAMsTheme.accent, size: 18),
            ),
            const SizedBox(height: 12),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: t.colorScheme.onSurface,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: t.textTheme.bodySmall?.color,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final t = Theme.of(context);
    return GlassCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: t.colorScheme.onSurface,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: t.textTheme.bodySmall?.color,
                        fontSize: 12,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Iconsax.arrow_right_3, color: t.textTheme.bodySmall?.color, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
