import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

import 'student/student_fees_shell.dart';
import 'treasury/treasury_shell.dart';
import '../ManageDashboard/registrar_dashboard.dart';

class FeesScreen extends ConsumerWidget {
  const FeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final role = user?['role'] ?? 'student';
    final args = ModalRoute.of(context)?.settings.arguments;
    final initialTab = (args is Map) ? (args['initialTab'] as int? ?? 0) : 0;

    if (role == 'admin') {
      return const TreasuryShell();
    }
    if (role == 'registrar') {
      return const RegistrarDashboard();
    }
    // For non-student roles (lecturer, faculty, staff), show a message
    if (role != 'student') {
      return Scaffold(
        appBar: AppBar(title: const Text('Fees')),
        body: const Center(child: Text('Fees module is for students only')),
      );
    }
    return StudentFeesShell(initialTab: initialTab);
  }
}
