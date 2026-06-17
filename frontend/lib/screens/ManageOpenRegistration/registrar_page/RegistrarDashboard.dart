import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../registrar_page/RegistrationSession.dart';
import '../registrar_page/SubjectQuotaManagement.dart';

class RegistrarDashboard extends StatelessWidget {
  const RegistrarDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    
    return Scaffold(
      backgroundColor: t.colorScheme.surface,
      appBar: AppBar(
        title: Text('Registrar Hub', style: TextStyle(fontFamily: 'Inter', fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Administrative Tools', style: TextStyle(fontFamily: 'Inter', fontSize: 28)),
            const SizedBox(height: 24),
            
            // Navigate to Registration Session (SessionManagement + SubjectQuotaManagement)
            _buildAdminCard(
              context,
              title: 'Registration Session',
              subtitle: 'Configure timelines and system status.',
              icon: Iconsax.clock_copy,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SetupRegistrationScreen()),
              ),
            ),
            const SizedBox(height: 16),
            
            // Navigate to Quota/Catalog Management
            _buildAdminCard(
              context,
              title: 'Course Catalog & Quotas',
              subtitle: 'Update course lists and adjust enrollment caps.',
              icon: Iconsax.setting_5_copy,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubjectQuotaManagement()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    final t = Theme.of(context);
    return Card(
      child: ListTile(
        leading: Icon(icon, color: SAMsTheme.primary),
        title: Text(title, style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Iconsax.arrow_right_3_copy),
        onTap: onTap,
      ),
    );
  }
}