import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/theme.dart';
import '../../../widgets/glass_card.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'RegistrationSession.dart';
import 'SubjectQuotaManagement.dart';

class RegistrarDashboard extends StatelessWidget {
  const RegistrarDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;
    final muted = isDark ? SAMsTheme.textMuted : const Color(0xFF6B7280);
    final brass = SAMsTheme.primary;
    
    return Scaffold(
      backgroundColor: t.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left_copy, color: t.colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'REGISTRAR HUB',
          style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: muted),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Administrative\nTools.', style: TextStyle(fontFamily: 'Inter', fontSize: 28, fontWeight: FontWeight.w400, height: 1.15, color: t.colorScheme.onSurface)),
              const SizedBox(height: 8),
              Text('Manage registration sessions, course quotas, and system configurations.', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: muted, height: 1.4)),
              const SizedBox(height: 32),
              
              // Registration Session
              GlassCard(
                padding: EdgeInsets.zero,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SetupRegistrationScreen()),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: brass.withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: brass.withAlpha(50)),
                          ),
                          child: Icon(Iconsax.clock_copy, color: brass, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Registration Session', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500, color: t.colorScheme.onSurface)),
                              const SizedBox(height: 2),
                              Text('Configure timelines and system status.', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: muted)),
                            ],
                          ),
                        ),
                        Icon(Iconsax.arrow_right_3_copy, color: muted, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              
              // Course Catalog & Quotas
              GlassCard(
                padding: EdgeInsets.zero,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SubjectQuotaManagement()),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: brass.withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: brass.withAlpha(50)),
                          ),
                          child: Icon(Iconsax.setting_5_copy, color: brass, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Course Catalog & Quotas', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500, color: t.colorScheme.onSurface)),
                              const SizedBox(height: 2),
                              Text('Update course lists and adjust enrollment caps.', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: muted)),
                            ],
                          ),
                        ),
                        Icon(Iconsax.arrow_right_3_copy, color: muted, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
