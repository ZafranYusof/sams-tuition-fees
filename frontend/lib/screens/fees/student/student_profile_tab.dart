import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../auth/login_screen.dart';

class StudentProfileTab extends ConsumerWidget {
  const StudentProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar
          Center(child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [SAMsTheme.primary, SAMsTheme.primaryLight]), shape: BoxShape.circle),
            child: Center(child: Text((user?['name'] ?? 'S')[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700))),
          )),
          const SizedBox(height: 16),
          Center(child: Text(user?['name'] ?? 'Student', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.w700))),
          Center(child: Text(user?['studentId'] ?? '', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 13))),
          Center(child: Text(user?['email'] ?? '', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 12))),
          const SizedBox(height: 32),
          _profileItem(Icons.school_outlined, 'Faculty', user?['faculty'] ?? 'FKOM'),
          _profileItem(Icons.menu_book_outlined, 'Program', user?['program'] ?? 'Software Engineering'),
          _profileItem(Icons.calendar_today_outlined, 'Semester', '2'),
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

  Widget _profileItem(IconData icon, String label, String value) => Builder(
    builder: (context) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor)),
      child: Row(children: [
        Icon(icon, color: SAMsTheme.primary, size: 20),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
          Text(value, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600)),
        ]),
      ]),
    ),
  );
}
