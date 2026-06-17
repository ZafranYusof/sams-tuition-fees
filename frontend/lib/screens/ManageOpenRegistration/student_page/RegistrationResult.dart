import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/theme.dart';
import '../../../services/api_service.dart';
import '../../../widgets/glass_card.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'RegistrationConfirmation.dart';

class RegistrationResult extends StatefulWidget {
  final List<String> selectedCodes;

  const RegistrationResult({super.key, required this.selectedCodes});

  @override
  State<RegistrationResult> createState() => _RegistrationResultState();
}

class _RegistrationResultState extends State<RegistrationResult> {
  bool _submitting = false;

  Future<void> _confirmRegistration() async {
    setState(() => _submitting = true);
    try {
      // Register each course via API
      for (final code in widget.selectedCodes) {
        await ApiService.post('/registration/register', {
          'courseId': code,
          'semester': 1,
          'academicYear': '2025/2026',
        });
      }
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RegistrationConfirmation(codes: widget.selectedCodes)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed. Please try again.', style: TextStyle(fontFamily: 'Inter')), backgroundColor: SAMsTheme.error),
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
          'REVIEW REGISTRATION',
          style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: muted),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Confirm Your\nSubjects.', style: TextStyle(fontFamily: 'Inter', fontSize: 28, fontWeight: FontWeight.w400, height: 1.15, color: t.colorScheme.onSurface)),
                const SizedBox(height: 8),
                Text('${widget.selectedCodes.length} subject(s) selected for registration.', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: muted)),
              ],
            ),
          ),

          // Subject List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: widget.selectedCodes.length,
              itemBuilder: (ctx, i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: brass.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text('${i + 1}', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: brass)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(widget.selectedCodes[i], style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w500, color: t.colorScheme.onSurface)),
                      ),
                      Icon(Iconsax.tick_circle_copy, color: SAMsTheme.success, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            decoration: BoxDecoration(
              color: isDark ? SAMsTheme.cardDark : Colors.white,
              border: Border(top: BorderSide(color: SAMsTheme.border)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: SAMsTheme.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text('Back', style: TextStyle(fontFamily: 'Inter', color: t.colorScheme.onSurface, fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 48,
                      child: Material(
                        color: _submitting ? muted.withAlpha(100) : brass,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _submitting ? null : _confirmRegistration,
                          child: Center(
                            child: _submitting
                              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Confirm', style: TextStyle(fontFamily: 'Inter', color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                                    const SizedBox(width: 6),
                                    Icon(Iconsax.arrow_right_3_copy, color: Colors.white, size: 16),
                                  ],
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
