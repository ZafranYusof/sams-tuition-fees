import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/theme.dart';
import '../../../services/api_service.dart';
import '../../../widgets/glass_card.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'RegistrationConfirmation.dart';

class RegistrationResult extends StatefulWidget {
  final List<Map<String, dynamic>> selectedCourses;

  const RegistrationResult({super.key, required this.selectedCourses});

  @override
  State<RegistrationResult> createState() => _RegistrationResultState();
}

class _RegistrationResultState extends State<RegistrationResult> {
  bool _submitting = false;

  Future<void> _confirmRegistration() async {
      setState(() => _submitting = true);
      final List<String> succeeded = [];
      final List<String> skipped = [];
      final List<String> failed = [];
      try {
        for (final course in widget.selectedCourses) {
          try {
            await ApiService.post('/registration/enroll', {
              'courseId': course['_id'],
              'semester': 1,
              'academicYear': '2025/2026',
            });
            succeeded.add(course['code'] as String);
          } catch (e) {
            final msg = e.toString().replaceAll('Exception: ', '');
            if (msg.toLowerCase().contains('already enrolled')) {
              skipped.add(course['code'] as String);
            } else {
              failed.add(course['code'] as String);
            }
          }
        }
        if (mounted) {
          if (failed.isEmpty) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RegistrationConfirmation(
                codes: [...succeeded, ...skipped],
                skipped: skipped,
              )),
            );
            // If RegistrationConfirmation popped with true, pass it back to SubjectRegistration
            if (result == true && mounted) {
              Navigator.of(context).pop(true);
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed: ${failed.join(", ")}', style: TextStyle(fontFamily: 'Inter')), backgroundColor: SAMsTheme.error),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          final msg = e.toString().replaceAll('Exception: ', '');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Registration failed: $msg', style: TextStyle(fontFamily: 'Inter')), backgroundColor: SAMsTheme.error, duration: const Duration(seconds: 5)),
          );
        }
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
    }

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
          'CONFIRM REGISTRATION',
          style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: muted),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Review Selected Subjects', style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w500, color: t.colorScheme.onSurface)),
              const SizedBox(height: 8),
              Text('Please confirm the following course registration:', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: muted)),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: widget.selectedCourses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final course = widget.selectedCourses[index];
                    return GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: brass.withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(course['code'] ?? '', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: brass)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(course['name'] ?? 'Unknown Course', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: t.colorScheme.onSurface)),
                                  const SizedBox(height: 3),
                                  Text('${course['credits'] ?? 0} Credit Hours', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: muted)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: Material(
                  color: _submitting ? muted : brass,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _submitting ? null : _confirmRegistration,
                    child: Center(
                      child: _submitting
                          ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('Confirm Registration', style: TextStyle(fontFamily: 'Inter', color: Colors.white, fontWeight: FontWeight.w600)),
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
