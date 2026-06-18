import 'package:flutter/material.dart';
import '../../screens/registrar_page/SessionManagement.dart';
import '../../screens/registrar_page/SubjectQuotaManagement.dart';

class RegistrationSession extends StatelessWidget {
  const RegistrationSession({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registration Session Control', style: TextStyle(fontFamily: 'Inter', fontSize: 20)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          _buildHubTile(
            context,
            title: 'Manage Timelines',
            subtitle: 'Configure open/close dates and system status',
            icon: Icons.timer,
            destination: const SessionManagement(),
          ),
          const SizedBox(height: 16),
          _buildHubTile(
            context,
            title: 'Manage Course Quotas',
            subtitle: 'Adjust seat availability and course capacity',
            icon: Icons.school,
            destination: const SubjectQuotaManagement(),
          ),
        ],
      ),
    );
  }

  Widget _buildHubTile(BuildContext context, {
    required String title, 
    required String subtitle, 
    required IconData icon, 
    required Widget destination
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFC5A880)),
        title: Text(title, style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => destination)),
      ),
    );
  }
}