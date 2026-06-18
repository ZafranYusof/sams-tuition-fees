import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../config/theme.dart';
import '../../../widgets/glass_card.dart';
import 'manage_activity.dart';
import 'review_claim.dart';

class PusatAdabCurriculumScreen extends StatelessWidget {
  const PusatAdabCurriculumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Curriculum Management'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GlassCard(
              child: ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: SAMsTheme.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Iconsax.calendar_1, color: SAMsTheme.accent),
                ),
                title: Text('Manage Activities',
                  style: TextStyle(fontWeight: FontWeight.w600, color: t.colorScheme.onSurface)),
                subtitle: Text('Add, edit and delete activities',
                  style: TextStyle(color: t.textTheme.bodySmall?.color)),
                trailing: Icon(Iconsax.arrow_right_3, color: t.textTheme.bodySmall?.color, size: 18),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ManageActivityScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: SAMsTheme.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Iconsax.clipboard_tick, color: SAMsTheme.success),
                ),
                title: Text('Review Claims',
                  style: TextStyle(fontWeight: FontWeight.w600, color: t.colorScheme.onSurface)),
                subtitle: Text('Approve or reject claims',
                  style: TextStyle(color: t.textTheme.bodySmall?.color)),
                trailing: Icon(Iconsax.arrow_right_3, color: t.textTheme.bodySmall?.color, size: 18),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ReviewClaimScreen(),
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
