import 'package:flutter/material.dart';
import '../../config/theme.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Session Management')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            ListTile(
              title: const Text('Registration Dates'),
              subtitle: Text(startDate != null ? '${DateFormat('dd MMM').format(startDate!)} - ${DateFormat('dd MMM').format(endDate!)}' : 'Not Configured'),
              trailing: const Icon(Iconsax.calendar_1_copy),
              onTap: () => _selectDateRange(context),
            ),
            ListTile(
              title: const Text('Start Time'),
              subtitle: Text(startTime?.format(context) ?? 'Not Set'),
              trailing: const Icon(Iconsax.clock_copy),
              onTap: () => _selectTime(context, true),
            ),
            ListTile(
              title: const Text('End Time'),
              subtitle: Text(endTime?.format(context) ?? 'Not Set'),
              trailing: const Icon(Iconsax.clock_copy),
              onTap: () => _selectTime(context, false),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                // Logic to finalize timeline per original design
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Timeline confirmed')));
              },
              child: const Text('Confirm Active Timeline'),
            ),
          ],
        ),
      ),
    );
  }
}