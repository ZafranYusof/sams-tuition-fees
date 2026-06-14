import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import 'student/student_fees_shell.dart';
import 'treasury/treasury_shell.dart';

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
    return StudentFeesShell(initialTab: initialTab);
  }
}
