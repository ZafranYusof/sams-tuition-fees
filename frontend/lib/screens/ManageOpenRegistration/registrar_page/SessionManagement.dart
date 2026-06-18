import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/theme.dart';
import '../../../services/api_service.dart';
import '../../../widgets/app_toast.dart';
import '../../../widgets/glass_card.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

class SessionManagement extends StatefulWidget {
  const SessionManagement({super.key});

  @override
  State<SessionManagement> createState() => _SessionManagementState();
}

class _SessionManagementState extends State<SessionManagement> {
  DateTime? startDate;
  DateTime? endDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  bool _saving = false;

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart 
          ? (startTime ?? const TimeOfDay(hour: 8, minute: 0))
          : (endTime ?? const TimeOfDay(hour: 23, minute: 59)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) startTime = picked;
        else endTime = picked;
      });
    }
  }

  Future<void> _confirmTimeline() async {
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);
    try {
      await ApiService.post('/registrar/session', {
        'sessionName': 'Registration Session',
        'startDate': startDate!.toIso8601String(),
        'endDate': endDate!.toIso8601String(),
      });
      if (mounted) {
        AppToast.success(context, 'Session created');
      }
    } catch (e) {
      if (mounted) AppToast.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;
    final muted = isDark ? SAMsTheme.textMuted : const Color(0xFF6B7280);
    final brass = SAMsTheme.primary;
    final bool isTimelineInvalid = startDate == null || endDate == null || startTime == null || endTime == null;

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
          'SESSION MANAGEMENT',
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
              Text('Configure\nTimeline.', style: TextStyle(fontFamily: 'Inter', fontSize: 28, fontWeight: FontWeight.w400, height: 1.15, color: t.colorScheme.onSurface)),
              const SizedBox(height: 8),
              Text('Set the registration period dates and times.', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: muted, height: 1.4)),
              const SizedBox(height: 32),

              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildSettingRow(
                      icon: Iconsax.calendar_1_copy,
                      label: 'Registration Dates',
                      value: startDate != null ? '${DateFormat('dd MMM').format(startDate!)} - ${DateFormat('dd MMM').format(endDate!)}' : 'Not Configured',
                      onTap: () => _selectDateRange(context),
                      brass: brass, muted: muted, t: t,
                    ),
                    Divider(color: t.dividerColor, height: 24),
                    _buildSettingRow(
                      icon: Iconsax.clock_copy,
                      label: 'Start Time',
                      value: startTime?.format(context) ?? 'Not Set',
                      onTap: () => _selectTime(context, true),
                      brass: brass, muted: muted, t: t,
                    ),
                    Divider(color: t.dividerColor, height: 24),
                    _buildSettingRow(
                      icon: Iconsax.clock_copy,
                      label: 'End Time',
                      value: endTime?.format(context) ?? 'Not Set',
                      onTap: () => _selectTime(context, false),
                      brass: brass, muted: muted, t: t,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: Material(
                  color: isTimelineInvalid ? SAMsTheme.textMuted.withAlpha(51) : brass,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: (isTimelineInvalid || _saving) ? null : _confirmTimeline,
                    child: Center(
                      child: _saving
                        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Confirm Active Timeline', style: TextStyle(fontFamily: 'Inter', color: isTimelineInvalid ? muted : Colors.white, fontWeight: FontWeight.w600)),
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

  Widget _buildSettingRow({required IconData icon, required String label, required String value, required VoidCallback onTap, required Color brass, required Color muted, required ThemeData t}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: brass, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: t.colorScheme.onSurface)),
                  Text(value, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: muted)),
                ],
              ),
            ),
            Icon(Iconsax.arrow_right_3_copy, color: muted, size: 14),
          ],
        ),
      ),
    );
  }
}
