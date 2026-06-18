import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/glass_card.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class ActivityDetailScreen extends ConsumerStatefulWidget {
  final String activityId;
  final String title;
  final String category;
  final String location;
  final int creditHours;
  final int slots;

  const ActivityDetailScreen({
    super.key,
    required this.activityId,
    required this.title,
    required this.category,
    required this.location,
    required this.creditHours,
    required this.slots,
  });

  @override
  ConsumerState<ActivityDetailScreen> createState() =>
      _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends ConsumerState<ActivityDetailScreen> {
  bool isRegistering = false;
  bool alreadyJoined = false;
  bool isCheckingStatus = true;

  @override
  void initState() {
    super.initState();
    _checkAlreadyJoined();
  }

  Future<void> _checkAlreadyJoined() async {
    try {
      final data = await ApiService.get('/curriculum/${widget.activityId}');
      final List<dynamic> participants =
          data is Map ? (data['participants'] ?? []) : [];
      final currentUser = ref.read(authProvider).user;
      final currentUserId = currentUser?['_id'] ?? currentUser?['id'] ?? '';

      final found = participants.any((p) {
        if (p is Map) return p['_id'] == currentUserId;
        return p.toString() == currentUserId;
      });

      if (mounted) setState(() => alreadyJoined = found);
    } catch (_) {
      // ignore — user can still try to register
    } finally {
      if (mounted) setState(() => isCheckingStatus = false);
    }
  }

  Future<void> _register() async {
    setState(() => isRegistering = true);
    try {
      await ApiService.post('/curriculum/${widget.activityId}/join', {});

      if (mounted) {
        setState(() => alreadyJoined = true);
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Success'),
            content: Text('${widget.title} registered successfully.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // back to activity list
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isRegistering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _infoRow(Iconsax.category, 'Category', widget.category),
                    const SizedBox(height: 12),
                    _infoRow(Iconsax.location, 'Location', widget.location),
                    const SizedBox(height: 12),
                    _infoRow(Iconsax.medal_star, 'Credit Hours',
                        widget.creditHours.toString()),
                    const SizedBox(height: 12),
                    _infoRow(
                        Iconsax.people, 'Available Slots', widget.slots.toString()),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(
                    alreadyJoined ? Iconsax.tick_circle : Iconsax.tick_circle),
                label: Text(
                    alreadyJoined ? 'Registered' : 'Register Activity'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      alreadyJoined ? t.colorScheme.outline : t.colorScheme.primary,
                  foregroundColor: t.colorScheme.onSurface,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: alreadyJoined || isRegistering || isCheckingStatus
                    ? null
                    : _register,
              ),
            ),
            if (isRegistering || isCheckingStatus) ...[
              const SizedBox(height: 12),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Text('$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value)),
      ],
    );
  }
}
