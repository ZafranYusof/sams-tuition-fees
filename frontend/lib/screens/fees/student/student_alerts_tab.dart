import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../services/api_service.dart';
import '../../../providers/auth_provider.dart';

class StudentAlertsTab extends ConsumerStatefulWidget {
  const StudentAlertsTab({super.key});

  @override
  ConsumerState<StudentAlertsTab> createState() => _StudentAlertsTabState();
}

class _StudentAlertsTabState extends ConsumerState<StudentAlertsTab> {
  List<dynamic> _alerts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = ref.read(authProvider).user;
      final sid = user?['studentId'] ?? user?['student_id'] ?? '';
      if (sid.isNotEmpty) {
        final data = await ApiService.get('/notifications/$sid');
        setState(() { _alerts = data['notifications'] ?? []; _loading = false; });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      final user = ref.read(authProvider).user;
      final sid = user?['studentId'] ?? user?['student_id'] ?? '';
      if (sid.isNotEmpty) {
        await ApiService.put('/notifications/read-all/$sid', {});
        await _load();
      }
    } catch (_) {}
  }

  Future<void> _markRead(String id) async {
    try {
      if (id.isEmpty) return;
      await ApiService.put('/notifications/$id/read', {});
      await _load();
    } catch (_) {}
  }

  int get _unreadCount => _alerts.where((a) => a['read'] == false).length;

  IconData _typeIcon(String type) {
    switch (type) {
      case 'payment': return Icons.check_circle_outline_rounded;
      case 'warning': return Icons.warning_amber_rounded;
      case 'reminder': return Icons.notifications_none_rounded;
      default: return Icons.info_outline_rounded;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'payment': return SAMsTheme.success;
      case 'warning': return SAMsTheme.warning;
      case 'reminder': return SAMsTheme.primary;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    if (_loading) {
      return Scaffold(
        backgroundColor: t.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: t.scaffoldBackgroundColor,
          elevation: 0,
          title: Text('Alerts', style: TextStyle(color: t.colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        body: const Center(child: CircularProgressIndicator(color: SAMsTheme.primary, strokeWidth: 2)),
      );
    }

    return Scaffold(
      backgroundColor: t.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: t.scaffoldBackgroundColor,
        elevation: 0,
        title: Text('Alerts', style: TextStyle(color: t.colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: RefreshIndicator(
        color: SAMsTheme.primary,
        onRefresh: _load,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$_unreadCount unread', style: TextStyle(color: t.textTheme.bodySmall?.color ?? Colors.grey, fontSize: 13)),
                  GestureDetector(
                    onTap: _unreadCount > 0 ? _markAllRead : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: t.cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: t.dividerColor),
                      ),
                      child: Text('Mark All Read', style: TextStyle(color: _unreadCount > 0 ? SAMsTheme.primary : (t.textTheme.bodySmall?.color ?? Colors.grey), fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _alerts.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.notifications_off_outlined, size: 40, color: t.textTheme.bodySmall?.color ?? Colors.grey),
                      const SizedBox(height: 12),
                      Text('No notifications yet', style: TextStyle(color: t.textTheme.bodySmall?.color ?? Colors.grey, fontSize: 13)),
                    ]))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      itemCount: _alerts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final a = _alerts[i];
                        final isRead = a['read'] == true;
                        final type = a['type'] ?? 'info';
                        final icon = _typeIcon(type);
                        final color = _typeColor(type);
                        return GestureDetector(
                          onTap: !isRead ? () => _markRead(a['_id']?.toString() ?? '') : null,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: t.cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isRead ? t.dividerColor : color.withOpacity(0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 34, height: 34,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(icon, color: color, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(a['title'] ?? '', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.colorScheme.onSurface)),
                                  const SizedBox(height: 4),
                                  Text(a['message'] ?? '', style: TextStyle(fontSize: 12, color: t.textTheme.bodyMedium?.color ?? Colors.grey, height: 1.4)),
                                  const SizedBox(height: 6),
                                  Text((a['createdAt'] ?? a['created_at'])?.toString().substring(0, 10) ?? '', style: TextStyle(fontSize: 11, color: t.textTheme.bodySmall?.color ?? Colors.grey)),
                                ])),
                                if (!isRead)
                                  Container(width: 7, height: 7, margin: const EdgeInsets.only(top: 4), decoration: const BoxDecoration(color: SAMsTheme.primary, shape: BoxShape.circle)),
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
