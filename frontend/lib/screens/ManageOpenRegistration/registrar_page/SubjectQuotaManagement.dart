import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class SubjectQuotaManagement extends StatefulWidget {
  const SubjectQuotaManagement({super.key});

  @override
  State<SubjectQuotaManagement> createState() => _SubjectQuotaManagementState();
}

class _SubjectQuotaManagementState extends State<SubjectQuotaManagement> {
  // Mock data representing the course catalog
  final List<Map<String, dynamic>> _subjects = [
    {'code': 'CS101', 'name': 'Intro to Programming', 'quota': 50},
    {'code': 'CS202', 'name': 'Data Structures', 'quota': 30},
    {'code': 'MA101', 'name': 'Calculus I', 'quota': 40},
  ];

  void _updateQuota(int index) {
    // Logic to open dialog and update quota
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Quota'),
        content: TextField(
          decoration: const InputDecoration(labelText: 'New Quota'),
          keyboardType: TextInputType.number,
          onSubmitted: (val) {
            setState(() => _subjects[index]['quota'] = int.tryParse(val) ?? 0);
            Navigator.pop(ctx);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subject Quota Management')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _subjects.length,
        itemBuilder: (context, index) {
          final subject = _subjects[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(subject['name'], style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
              subtitle: Text('Current Quota: ${subject['quota']}'),
              trailing: IconButton(
                icon: const Icon(Iconsax.edit_copy, color: SAMsTheme.primary),
                onPressed: () => _updateQuota(index),
              ),
            ),
          );
        },
      ),
    );
  }
}