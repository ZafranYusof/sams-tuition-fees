import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/theme.dart';
import '../../../widgets/glass_card.dart';
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
    final controller = TextEditingController(text: _subjects[index]['quota'].toString());
    showDialog(
      context: context,
      builder: (ctx) {
        final t = Theme.of(context);
        return AlertDialog(
          backgroundColor: t.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Update Quota', style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w500, color: t.colorScheme.onSurface)),
          content: TextField(
            controller: controller,
            style: TextStyle(fontFamily: 'Inter', color: t.colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: 'New Quota',
              labelStyle: TextStyle(fontFamily: 'Inter', color: SAMsTheme.textMuted),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: SAMsTheme.border), borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: SAMsTheme.primary), borderRadius: BorderRadius.circular(8)),
            ),
            keyboardType: TextInputType.number,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(fontFamily: 'Inter', color: SAMsTheme.textMuted)),
            ),
            TextButton(
              onPressed: () {
                setState(() => _subjects[index]['quota'] = int.tryParse(controller.text) ?? 0);
                Navigator.pop(ctx);
              },
              child: Text('Update', style: TextStyle(fontFamily: 'Inter', color: SAMsTheme.primary, fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final muted = SAMsTheme.textMuted;
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
          'COURSE QUOTAS',
          style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: muted),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Manage\nEnrollment Caps.', style: TextStyle(fontFamily: 'Inter', fontSize: 28, fontWeight: FontWeight.w400, height: 1.15, color: t.colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  Text('${_subjects.length} courses in catalog.', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: muted)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _subjects.length,
                itemBuilder: (context, index) {
                  final subject = _subjects[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: brass.withAlpha(25),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: brass.withAlpha(50)),
                            ),
                            child: Center(
                              child: Text(subject['code'].toString().substring(0, 3), style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.bold, color: brass)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(subject['name'], style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: t.colorScheme.onSurface)),
                                const SizedBox(height: 2),
                                Text('${subject['code']}  •  Quota: ${subject['quota']}', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: muted)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Iconsax.edit_copy, color: brass, size: 18),
                            onPressed: () => _updateQuota(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
