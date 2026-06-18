import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/theme.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class RegistrationConfirmation extends StatelessWidget {
  final List<String> codes;
  const RegistrationConfirmation({super.key, required this.codes});

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
          'PROCESSING',
          style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: muted),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: SAMsTheme.success.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Iconsax.tick_circle_copy, color: SAMsTheme.success, size: 36),
                ),
                const SizedBox(height: 24),
                Text('Registration Successful', style: TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w500, color: t.colorScheme.onSurface)),
                const SizedBox(height: 8),
                Text('You have been registered for the following subjects:', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: muted)),
                const SizedBox(height: 24),
                ...codes.map((code) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: t.colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: t.dividerColor),
                    ),
                    child: Text(code, style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: t.colorScheme.onSurface)),
                  ),
                )),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: Material(
                    color: brass,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      child: Center(
                        child: Text('Return to Dashboard', style: TextStyle(fontFamily: 'Inter', color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
