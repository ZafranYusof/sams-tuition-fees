import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../config/theme.dart';
import '../../../services/api_service.dart';
import '../../../services/cache_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/shimmer_loading.dart';
import '../../../widgets/empty_state.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:figma_squircle/figma_squircle.dart';

class StudentAlertsTab extends ConsumerStatefulWidget {
  const StudentAlertsTab({super.key});

  @override
  ConsumerState<StudentAlertsTab> createState() => _StudentAlertsTabState();
}

enum _AlertFilter { all, payments, reminders, warnings }

class _StudentAlertsTabState extends ConsumerState<StudentAlertsTab>
    with TickerProviderStateMixin {
  List<dynamic> _alerts = [];
  bool _loading = true;
  _AlertFilter _activeFilter = _AlertFilter.all;
  late AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _load();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final user = ref.read(authProvider).user;
      final sid = user?['studentId'] ?? user?['student_id'] ?? '';
      if (sid.isNotEmpty) {
        final data = await ApiService.get('/notifications/$sid');
        setState(() {
          _alerts = data['notifications'] ?? [];
          _loading = false;
        });
        _staggerController.forward(from: 0);
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    HapticFeedback.mediumImpact();
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
    HapticFeedback.lightImpact();
    try {
      if (id.isEmpty) return;
      await ApiService.put('/notifications/$id/read', {});
      await _load();
    } catch (_) {}
  }

  int get _unreadCount => _alerts.where((a) => a['read'] == false).length;

  List<dynamic> get _filteredAlerts {
    if (_activeFilter == _AlertFilter.all) return _alerts;
    final typeStr = switch (_activeFilter) {
      _AlertFilter.payments => 'payment',
      _AlertFilter.reminders => 'reminder',
      _AlertFilter.warnings => 'warning',
      _ => '',
    };
    return _alerts.where((a) => a['type'] == typeStr).toList();
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'payment':
        return Iconsax.tick_circle;
      case 'warning':
        return Iconsax.danger;
      case 'reminder':
        return Iconsax.notification;
      default:
        return Iconsax.info_circle;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'payment':
        return SAMsTheme.success;
      case 'warning':
        return SAMsTheme.warning;
      case 'reminder':
        return SAMsTheme.primary;
      default:
        return Colors.grey;
    }
  }

  // --- Relative time formatting ---
  String _relativeTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr.length >= 10 ? dateStr.substring(0, 10) : dateStr;

    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24 && now.day == date.day) return '${diff.inHours}h ago';
    if (diff.inDays == 0 && now.day != date.day) return 'Yesterday';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  // --- Date section grouping ---
  String _dateSection(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Earlier';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return 'Earlier';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final alertDay = DateTime(date.year, date.month, date.day);

    if (alertDay == today) return 'Today';
    if (alertDay == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return 'Earlier';
  }

  /// Staggered interval for item at index i
  Animation<double> _itemAnimation(int index) {
    final count = _filteredAlerts.length.clamp(1, 20);
    final start = (index * 0.6 / count).clamp(0.0, 1.0);
    final end = (start + 0.4).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _staggerController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
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
          title: Text('Alerts',
              style: TextStyle(
                  color: t.colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
        ),
        body: const ShimmerFeeList(count: 5),
      );
    }

    return Scaffold(
      backgroundColor: t.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: t.scaffoldBackgroundColor,
        elevation: 0,
        title: Text('Alerts',
            style: TextStyle(
                color: t.colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
      ),
      body: RefreshIndicator(
        color: SAMsTheme.primary,
        onRefresh: _load,
        child: Column(
          children: [
            // Unread count + Mark All Read
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$_unreadCount unread',
                      style: TextStyle(
                          color: t.textTheme.bodySmall?.color ?? Colors.grey,
                          fontSize: 13)),
                  GestureDetector(
                    onTap: _unreadCount > 0 ? _markAllRead : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: t.cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: t.dividerColor),
                      ),
                      child: Text('Mark All Read',
                          style: TextStyle(
                              color: _unreadCount > 0
                                  ? SAMsTheme.primary
                                  : (t.textTheme.bodySmall?.color ??
                                      Colors.grey),
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
            // Filter chips row
            _buildFilterChips(t),
            Expanded(
              child: _alerts.isEmpty
                  ? EmptyState.noNotifications()
                  : AnimatedBuilder(
                      animation: _staggerController,
                      builder: (context, _) => _buildGroupedList(t),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(ThemeData t) {
    final filters = [
      (_AlertFilter.all, 'All', Iconsax.sms),
      (_AlertFilter.payments, 'Payments', Iconsax.tick_circle),
      (_AlertFilter.reminders, 'Reminders', Iconsax.notification),
      (_AlertFilter.warnings, 'Warnings', Iconsax.danger),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (filter, label, icon) = filters[i];
          final isActive = _activeFilter == filter;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _activeFilter = filter);
              _staggerController.forward(from: 0);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? SAMsTheme.primary.withOpacity(0.1)
                    : t.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? SAMsTheme.primary.withOpacity(0.4)
                      : t.dividerColor,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon,
                      size: 14,
                      color: isActive
                          ? SAMsTheme.primary
                          : (t.textTheme.bodySmall?.color ?? Colors.grey)),
                  const SizedBox(width: 5),
                  Text(label,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w500,
                          color: isActive
                              ? SAMsTheme.primary
                              : (t.textTheme.bodySmall?.color ?? Colors.grey))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildGroupedList(ThemeData t) {
    final filtered = _filteredAlerts;
    if (filtered.isEmpty) {
      return Center(
        child: Text('No alerts in this category',
            style: TextStyle(
                fontSize: 13,
                color: t.textTheme.bodySmall?.color ?? Colors.grey)),
      );
    }

    // Build grouped structure: list of (sectionHeader | alertItem)
    final List<dynamic> items = [];

    // Insert "All caught up" banner only when truly empty after filter
    if (filtered.isEmpty && _alerts.isNotEmpty) {
      items.add({'_caughtUp': true});
    }

    String? lastSection;
    int animIndex = 0;

    for (final alert in filtered) {
      final dateStr = alert['createdAt']?.toString() ??
          alert['created_at']?.toString();
      final section = _dateSection(dateStr);
      if (section != lastSection) {
        items.add({'_section': section});
        lastSection = section;
      }
      items.add({'_alert': alert, '_animIndex': animIndex});
      animIndex++;
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        if (item.containsKey('_caughtUp')) {
          return _buildAllCaughtUpBanner(t);
        }
        if (item.containsKey('_section')) {
          return _buildSectionHeader(item['_section'], t);
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildAlertItem(
              item['_alert'], item['_animIndex'] as int, t),
        );
      },
    );
  }

  Widget _buildAllCaughtUpBanner(ThemeData t) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: SAMsTheme.success.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: SAMsTheme.success.withOpacity(0.15)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: SAMsTheme.success.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: SAMsTheme.success, size: 26),
            ),
            const SizedBox(height: 10),
            Text('All caught up!',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: t.colorScheme.onSurface)),
            const SizedBox(height: 4),
            Text('No unread alerts remaining',
                style: TextStyle(
                    fontSize: 12,
                    color: t.textTheme.bodySmall?.color ?? Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData t) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFC9A961).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(title,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFC9A961),
                    letterSpacing: 0.5)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Divider(color: t.dividerColor, height: 1)),
        ],
      ),
    );
  }

  Widget _buildAlertItem(dynamic a, int i, ThemeData t) {
    final isRead = a['read'] == true;
    final type = a['type'] ?? 'info';
    final icon = _typeIcon(type);
    final color = _typeColor(type);
    final anim = _itemAnimation(i);
    final dateStr =
        a['createdAt']?.toString() ?? a['created_at']?.toString();

    final itemWidget = Dismissible(
      key: Key(a['_id']?.toString() ?? 'alert_$i'),
      direction:
          isRead ? DismissDirection.none : DismissDirection.endToStart,
      confirmDismiss: (_) async {
        HapticFeedback.mediumImpact();
        return true;
      },
      onDismissed: (_) {
        _markRead(a['_id']?.toString() ?? '');
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFC9A961),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 24),
      ),
      child: GestureDetector(
        onTap: !isRead
            ? () => _markRead(a['_id']?.toString() ?? '')
            : null,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: ShapeDecoration(
            color: t.cardColor,
            shape: SmoothRectangleBorder(
              borderRadius: SmoothBorderRadius(cornerRadius: 14, cornerSmoothing: 0.8),
              side: BorderSide(color: isRead ? t.dividerColor : color.withOpacity(0.3)),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(a['title'] ?? '',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: t.colorScheme.onSurface)),
                    const SizedBox(height: 4),
                    Text(a['message'] ?? '',
                        style: TextStyle(
                            fontSize: 12,
                            color:
                                t.textTheme.bodyMedium?.color ?? Colors.grey,
                            height: 1.4)),
                  ])),
              if (!isRead)
                Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: const BoxDecoration(
                        color: SAMsTheme.primary, shape: BoxShape.circle)),
            ],
          ),
        ),
      ),
    );

    // Stagger entrance: fade + slide up
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(anim),
        child: itemWidget,
      ),
    );
  }
}
