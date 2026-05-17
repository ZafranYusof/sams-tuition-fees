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
        await ApiService.put('/notifications/$sid/read-all', {});
        await _load();
      }
    } catch (_) {}
  }

  Future<void> _markRead(String id) async {
    try {
      await ApiService.put('/notifications/$id/read', {});
      await _load();
    } catch (_) {}
  }

  int get _unreadCount => _alerts.where((a) => a['read'] == false).length;

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(appBar: AppBar(title: const Text('Alerts')), body: const Center(child: CircularProgressIndicator(color: SAMsTheme.primary)));

    return Scaffold(
      appBar: AppBar(title: const Text('Alerts')),
      body: RefreshIndicator(
        color: SAMsTheme.primary,
        onRefresh: _load,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$_unreadCount unread', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 13)),
                  GestureDetector(
                    onTap: _unreadCount > 0 ? _markAllRead : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: Theme.of(context).dividerColor)),
                      child: const Text('Mark All Read', style: TextStyle(color: SAMsTheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _alerts.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.notifications_off_outlined, size: 48, color: Theme.of(context).textTheme.bodySmall?.color),
                      const SizedBox(height: 12),
                      Text('No notifications yet', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 14)),
                    ]))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      itemCount: _alerts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final a = _alerts[i];
                        final isRead = a['read'] == true;
                        final type = a['type'] ?? 'info';
                        final icon = type == 'payment' ? '✅' : (type == 'warning' ? '⚠️' : (type == 'reminder' ? '🔔' : 'ℹ️'));
                        return GestureDetector(
                          onTap: !isRead ? () => _markRead(a['id'] ?? a['_id'] ?? '') : null,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isRead ? Theme.of(context).cardColor : Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: isRead ? Theme.of(context).dividerColor : SAMsTheme.primary.withOpacity(0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(icon, style: const TextStyle(fontSize: 24)),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(a['title'] ?? '', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                                  const SizedBox(height: 4),
                                  Text(a['message'] ?? '', style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color, height: 1.4)),
                                  const SizedBox(height: 6),
                                  Text((a['createdAt'] ?? a['created_at'])?.toString().substring(0, 10) ?? '', style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
                                ])),
                                if (!isRead)
                                  Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 4), decoration: const BoxDecoration(color: SAMsTheme.primary, shape: BoxShape.circle)),
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
