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
  List<Map<String, dynamic>> activities = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final data = await ApiService.get('/curriculum/my/joined');
      final List<dynamic> list = data is List ? data : (data['activities'] ?? []);
      setState(() {
        activities = list
            .where((a) => a['status'] == 'completed' || a['status'] == 'ongoing')
            .map((a) => Map<String, dynamic>.from(a))
            .toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceAll('Exception: ', '');
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Credit Claims'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: _loadActivities,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(errorMessage!,
                          style: const TextStyle(color: SAMsTheme.error),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadActivities,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : activities.isEmpty
                  ? const Center(
                      child: Text('No eligible activities to claim.'))
                  : RefreshIndicator(
                      onRefresh: _loadActivities,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: activities.length,
                        itemBuilder: (context, index) {
                          final activity = activities[index];
                          final id = activity['_id'] ?? '';
                          final name = activity['name'] ?? '-';
                          final status = activity['status'] ?? 'upcoming';
                          final isEligible = status == 'completed';

                          Color color;
                          IconData icon;

                          if (isEligible) {
                            color = SAMsTheme.accent;
                            icon = Iconsax.clipboard_tick;
                          } else if (status == 'ongoing') {
                            color = SAMsTheme.warning;
                            icon = Iconsax.timer_1;
                          } else {
                            color = SAMsTheme.primary;
                            icon = Iconsax.calendar_1;
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GlassCard(
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(icon, color: color),
                                ),
                                title: Text(name),
                                subtitle: Text(
                                  isEligible
                                      ? 'Eligible for Claim'
                                      : status[0].toUpperCase() +
                                          status.substring(1),
                                ),
                                trailing: isEligible
                                    ? ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  CreditClaimDetailScreen(
                                                activityId: id,
                                                activityName: name,
                                              ),
                                            ),
                                          );
                                        },
                                        child: const Text('Claim'),
                                      )
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
