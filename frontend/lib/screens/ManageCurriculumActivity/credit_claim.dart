import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../widgets/glass_card.dart';
import 'credit_claim_detail.dart';

class CreditClaimScreen extends ConsumerStatefulWidget {
  const CreditClaimScreen({super.key});

  @override
  ConsumerState<CreditClaimScreen> createState() => _CreditClaimScreenState();
}

class _CreditClaimScreenState extends ConsumerState<CreditClaimScreen> {
  // Dummy data — nampak ada activity, student boleh tekan Claim
  // Status 'completed' = eligible to claim
  final List<Map<String, dynamic>> activities = [
    {
      '_id': 'dummy_1',
      'name': 'Football Tournament',
      'status': 'completed',
      'points': 3,
    },
    {
      '_id': 'dummy_2',
      'name': 'Coding Workshop',
      'status': 'ongoing',
      'points': 2,
    },
    {
      '_id': 'dummy_3',
      'name': 'Photography Workshop',
      'status': 'upcoming',
      'points': 2,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Credit Claims'),
      ),
      body: ListView.builder(
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
            icon = Icons.assignment;
          } else if (status == 'ongoing') {
            color = SAMsTheme.warning;
            icon = Icons.pending_actions;
          } else {
            color = SAMsTheme.primary;
            icon = Icons.event;
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
                      : status[0].toUpperCase() + status.substring(1),
                ),
                trailing: isEligible
                    ? ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreditClaimDetailScreen(
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
    );
  }
}