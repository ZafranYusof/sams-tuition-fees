import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../auth/login_screen.dart';

class TreasuryProfileTab extends ConsumerWidget {
  const TreasuryProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(child: Container(
            width: 80, height: 80,
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [SAMsTheme.accent, SAMsTheme.primary]), shape: BoxShape.circle),
            child: const Center(child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 36)),
          )),
          const SizedBox(height: 16),
          Center(child: Text('Treasury Admin', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.w700))),
          Center(child: Text('admin@sams.edu.my', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 13))),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor)),
            child: Row(children: [
              const Icon(Icons.verified_user, color: SAMsTheme.success, size: 20),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Role', style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
                Text('Treasury Administrator', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600)),
              ]),
            ]),
          ),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, height: 48, child: ElevatedButton.icon(
            onPressed: () { ref.read(authProvider.notifier).logout(); Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false); },
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(backgroundColor: SAMsTheme.error, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          )),
        ],
      ),
    );
  }
}
