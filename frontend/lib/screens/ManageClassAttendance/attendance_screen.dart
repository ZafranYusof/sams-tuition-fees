import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../widgets/glass_card.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  Map<String, dynamic>? _attendanceData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    try {
      final data = await ApiService.get('/attendance/my');
      setState(() {
        _attendanceData = Map<String, dynamic>.from(data);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanQR,
        backgroundColor: SAMsTheme.primary,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan QR'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: SAMsTheme.primary))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final stats = _attendanceData?['stats'] ?? {};
    final records = (_attendanceData?['records'] as List?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall stats
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [SAMsTheme.primary.withOpacity(0.2), SAMsTheme.surface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SAMsTheme.primary.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text('${stats['percentage'] ?? 0}%', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 48, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Overall Attendance', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _miniStat('Present', '${stats['present'] ?? 0}', SAMsTheme.success),
                    _miniStat('Total', '${stats['total'] ?? 0}', Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Recent Records', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          if (records.isEmpty)
            Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('No attendance records yet', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color))))
          else
            ...records.take(20).map((record) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                child: ListTile(
                  leading: Icon(
                    record['status'] == 'present' ? Icons.check_circle : record['status'] == 'late' ? Icons.access_time : Icons.cancel,
                    color: record['status'] == 'present' ? SAMsTheme.success : record['status'] == 'late' ? SAMsTheme.warning : SAMsTheme.error,
                  ),
                  title: Text(record['course']?['name'] ?? 'Course', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14)),
                  subtitle: Text(record['date']?.toString().substring(0, 10) ?? '', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(record['status']).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text((record['status'] ?? '').toUpperCase(), style: TextStyle(color: _statusColor(record['status']), fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            )),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w700)),
        Text(label, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12)),
      ],
    );
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'present': return SAMsTheme.success;
      case 'late': return SAMsTheme.warning;
      case 'absent': return SAMsTheme.error;
      default: return SAMsTheme.textMuted;
    }
  }

  void _scanQR() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text('Scan QR Code', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Text('QR scanner will open here.\nFor now, use manual check-in.', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}
