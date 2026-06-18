import 'package:flutter/material.dart';

import 'manage_activity.dart';
import 'review_claim.dart';

class PusatAdabCurriculumScreen extends StatelessWidget {
  const PusatAdabCurriculumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Curriculum Management',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.event,
                ),
                title: const Text(
                  'Manage Activities',
                ),
                subtitle: const Text(
                  'Add, edit and delete activities',
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const ManageActivityScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.assignment,
                ),
                title: const Text(
                  'Review Claims',
                ),
                subtitle: const Text(
                  'Approve or reject claims',
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const ReviewClaimScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}