import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../screens/student_page/StudentDashboard.dart';
import '../screens/registrar_page/RegistrarDashboard.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;
    final muted = isDark ? SAMsTheme.textMuted : SAMsTheme.textMuted;
    final brass = SAMsTheme.primary;

    return Scaffold(
      backgroundColor: t.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              // Brand/Identity
              Row(
                children: [
                  Container(width: 16, height: 2, color: brass),
                  const SizedBox(width: 8),
                  Text(
                    'UMPSA PORTAL',
                    style: TextStyle(fontFamily: 'Inter', 
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.5,
                      color: brass,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Select Your\nWorkspace Role.',
                style: TextStyle(fontFamily: 'Inter', 
                  fontSize: 40,
                  fontWeight: FontWeight.w400,
                  height: 1.15,
                  color: t.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a portal entry to manage course architectures or your student registration catalog.',
                style: TextStyle(fontFamily: 'Inter', 
                  fontSize: 14,
                  color: muted,
                  height: 1.5,
                ),
              ),
              const Spacer(),

              // Role Option: Student
              _buildRoleButton(
                context: context,
                title: 'Student Portal Entry',
                subtitle: 'Access catalogs, apply for electives, and review course credit status',
                icon: Iconsax.user_copy,
                brass: brass,
                muted: muted,
                theme: t,
                isDark: isDark,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StudentDashboard()),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Role Option: Registrar
              _buildRoleButton(
                context: context,
                title: 'Registrar Hub Entry',
                subtitle: 'Configure registration periods, monitor quotas, and edit course lists',
                icon: Iconsax.setting_5_copy,
                brass: brass,
                muted: muted,
                theme: t,
                isDark: isDark,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegistrarDashboard()),
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Role button builder helper
  Widget _buildRoleButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color brass,
    required Color muted,
    required ThemeData theme,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: brass.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: brass, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: muted)),
                ],
              ),
            ),
            Icon(Iconsax.arrow_right_1_copy, color: muted, size: 16),
          ],
        ),
      ),
    );
  }
}