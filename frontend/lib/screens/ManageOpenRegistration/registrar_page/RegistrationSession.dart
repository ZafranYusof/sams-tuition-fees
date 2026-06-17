import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

class SetupRegistrationScreen extends StatefulWidget {
  const SetupRegistrationScreen({super.key});

  @override
  State<SetupRegistrationScreen> createState() => _SetupRegistrationScreenState();
}

class _SetupRegistrationScreenState extends State<SetupRegistrationScreen> {
  DateTime? startDate;
  DateTime? endDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: isDark 
            ? ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: SAMsTheme.primary, onPrimary: SAMsTheme.textPrimary, surface: SAMsTheme.cardDark))
            : ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: SAMsTheme.primary)),
          child: child!,
        );
      },
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
      helpText: isStart ? 'SET REGISTRATION OPEN TIME' : 'SET REGISTRATION CLOSING TIME',
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startTime = picked;
        } else {
          endTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;
    final muted = isDark ? SAMsTheme.textMuted : SAMsTheme.textMuted;
    final brass = SAMsTheme.primary;

    // Configuration is only valid if dates and times are set
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
          'SYSTEM CONFIGURATION',
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
              Text('Registration Planner', style: TextStyle(fontFamily: 'Inter', fontSize: 32, color: t.colorScheme.onSurface)),
              const SizedBox(height: 6),
              Text('Establish live system calendar intervals and coordinate course catalog operational parameters.', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: muted, height: 1.4)),
              const SizedBox(height: 40),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? SAMsTheme.cardDark : SAMsTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? SAMsTheme.border : SAMsTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Iconsax.calendar_1_copy, color: brass, size: 22),
                        const SizedBox(width: 12),
                        Text('Operational Timeframe', style: TextStyle(fontFamily: 'Inter', fontSize: 18, color: t.colorScheme.onSurface)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Date Visualizers
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMetricColumn('START DATE', startDate != null ? DateFormat('dd MMM yyyy').format(startDate!) : 'Not Configured', muted, t.colorScheme.onSurface),
                        Container(height: 30, width: 1, color: isDark ? SAMsTheme.border : SAMsTheme.border),
                        _buildMetricColumn('END DATE', endDate != null ? DateFormat('dd MMM yyyy').format(endDate!) : 'Not Configured', muted, t.colorScheme.onSurface),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Time Visualizers
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMetricColumn('START TIME', startTime != null ? startTime!.format(context) : 'Not Configured', muted, t.colorScheme.onSurface),
                        Container(height: 30, width: 1, color: isDark ? SAMsTheme.border : SAMsTheme.border),
                        _buildMetricColumn('END TIME', endTime != null ? endTime!.format(context) : 'Not Configured', muted, t.colorScheme.onSurface),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Action Trigger Controls Row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: brass),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              _selectDateRange(context);
                            },
                            icon: Icon(Iconsax.calendar_copy, size: 16, color: brass),
                            label: Text('Set Dates', style: TextStyle(fontFamily: 'Inter', color: brass, fontWeight: FontWeight.w600, fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: brass),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              _selectTime(context, true);
                            },
                            icon: Icon(Iconsax.clock_copy, size: 16, color: brass),
                            label: Text('Start Time', style: TextStyle(fontFamily: 'Inter', color: brass, fontWeight: FontWeight.w600, fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: brass),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              _selectTime(context, false);
                            },
                            icon: Icon(Iconsax.clock_copy, size: 16, color: brass),
                            label: Text('End Time', style: TextStyle(fontFamily: 'Inter', color: brass, fontWeight: FontWeight.w600, fontSize: 13)),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              const Spacer(),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: Material(
                  color: isTimelineInvalid ? SAMsTheme.textMuted.withAlpha(51) : t.colorScheme.onSurface,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: isTimelineInvalid ? null : () {
                      HapticFeedback.mediumImpact();
                      
                      // Synthesize Dates & Times into singular structures for transport
                      final finalStartDateTime = DateTime(startDate!.year, startDate!.month, startDate!.day, startTime!.hour, startTime!.minute);
                      final finalEndDateTime = DateTime(endDate!.year, endDate!.month, endDate!.day, endTime!.hour, endTime!.minute);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: SAMsTheme.success,
                          content: Text('Open Registration timeline sequence confirmed successfully.', style: TextStyle(fontFamily: 'Inter', color: SAMsTheme.textPrimary)),
                        ),
                      );

                      // Returns data back to DashboardScreen context safely
                      Navigator.pop(context, {
                        'start': finalStartDateTime,
                        'end': finalEndDateTime,
                      });
                    },
                    child: Container(
                      alignment: Alignment.center,
                      child: Text(
                        'Confirm Active Timeline',
                        style: TextStyle(fontFamily: 'Inter', 
                          color: isTimelineInvalid ? muted : t.colorScheme.surface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value, Color muted, Color textCol) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label, 
            style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: muted),
          ),
          const SizedBox(height: 4),
          Text(
            value, 
            style: TextStyle(fontFamily: 'Inter', 
              fontSize: 14, 
              fontWeight: FontWeight.w500, 
              color: textCol,
            ).copyWith(
              overflow: TextOverflow.ellipsis, // 🌟 Safe injection via copyWith
            ), 
            textAlign: TextAlign.center, 
            maxLines: 1, 
          ),
        ],
      ),
    );
  }
}