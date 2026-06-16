import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../config/theme.dart';
import '../../../services/api_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/language_provider.dart';
import '../../../widgets/shimmer_loading.dart';
import '../../../widgets/empty_state.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

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

  /// Alerts visible after applying user's Notification preference toggles.
  /// Runs BEFORE the tab filter (_AlertFilter).
  List<dynamic> get _prefVisibleAlerts {
    final notifPrefs = ref.read(notificationPrefsProvider);
    return _alerts
        .where((a) => notifPrefs.isTypeEnabled(a['type']?.toString()))
        .toList();
  }

  int get _unreadCount =>
      _prefVisibleAlerts.where((a) => a['read'] == false).length;

  List<dynamic> get _filteredAlerts {
    final visible = _prefVisibleAlerts;
    if (_activeFilter == _AlertFilter.all) return visible;
    final typeStr = switch (_activeFilter) {
      _AlertFilter.payments => 'payment',
      _AlertFilter.reminders => 'reminder',
      _AlertFilter.warnings => 'warning',
      _ => '',
    };
    return visible.where((a) => a['type'] == typeStr).toList();
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



  // --- Date section grouping ---
  /// Returns a section KEY ('today' | 'yesterday' | 'earlier').
  /// Translation happens at render time so locale switches re-render correctly.
  String _dateSectionKey(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'earlier';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return 'earlier';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final alertDay = DateTime(date.year, date.month, date.day);

    if (alertDay == today) return 'today';
    if (alertDay == today.subtract(const Duration(days: 1))) return 'yesterday';
    return 'earlier';
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
    final theme = Theme.of(context);
    final locale = ref.watch(languageProvider).locale;
    // Watch so toggles in Profile > Notifications instantly re-filter the list.
    ref.watch(notificationPrefsProvider);

    if (_loading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          title: Text(t('alerts', locale),
              style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
        ),
        body: const ShimmerFeeList(count: 5),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(t('alerts', locale),
            style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        actions: [
          if (_unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _markAllRead,
                icon: const Icon(Icons.done_all_rounded, size: 18, color: SAMsTheme.primary),
                label: Text(t('mark_all', locale),
                    style: const TextStyle(
                        color: SAMsTheme.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: SAMsTheme.primary,
        onRefresh: _load,
        child: Column(
          children: [
            // Filter chips row
            _buildFilterChips(theme),
            Expanded(
              child: _prefVisibleAlerts.isEmpty
                  ? EmptyState.noNotifications()
                  : AnimatedBuilder(
                      animation: _staggerController,
                      builder: (context, _) => _buildGroupedList(theme, locale),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme) {
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
                    ? SAMsTheme.primary.withValues(alpha: 0.1)
                    : theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? SAMsTheme.primary.withValues(alpha: 0.4)
                      : theme.dividerColor,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon,
                      size: 14,
                      color: isActive
                          ? SAMsTheme.primary
                          : (theme.textTheme.bodySmall?.color ?? Colors.grey)),
                  const SizedBox(width: 5),
                  Text(label,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w500,
                          color: isActive
                              ? SAMsTheme.primary
                              : (theme.textTheme.bodySmall?.color ?? Colors.grey))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildGroupedList(ThemeData theme, String locale) {
    final filtered = _filteredAlerts;
    if (filtered.isEmpty) {
      return Center(
        child: Text(t('no_alerts_category', locale),
            style: TextStyle(
                fontSize: 13,
                color: theme.textTheme.bodySmall?.color ?? Colors.grey)),
      );
    }

    // Build grouped structure: list of (sectionHeader | alertItem)
    final List<dynamic> items = [];

    // Insert "All caught up" banner only when truly empty after filter
    if (filtered.isEmpty && _prefVisibleAlerts.isNotEmpty) {
      items.add({'_caughtUp': true});
    }

    String? lastSection;
    int animIndex = 0;

    for (final alert in filtered) {
      final dateStr = alert['createdAt']?.toString() ??
          alert['created_at']?.toString();
      final sectionKey = _dateSectionKey(dateStr);
      if (sectionKey != lastSection) {
        items.add({'_section': sectionKey});
        lastSection = sectionKey;
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
          return _buildAllCaughtUpBanner(theme, locale);
        }
        if (item.containsKey('_section')) {
          return _buildSectionHeader(
              t(item['_section'] as String, locale), theme);
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildAlertItem(
              item['_alert'], item['_animIndex'] as int, theme),
        );
      },
    );
  }

  Widget _buildAllCaughtUpBanner(ThemeData theme, String locale) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: SAMsTheme.success.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: SAMsTheme.success.withValues(alpha: 0.15)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: SAMsTheme.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: SAMsTheme.success, size: 26),
            ),
            const SizedBox(height: 10),
            Text(t('all_caught_up', locale),
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface)),
            const SizedBox(height: 4),
            Text(t('no_unread', locale),
                style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color ?? Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF5C33CF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(title,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF5C33CF),
                    letterSpacing: 0.5)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Divider(color: theme.dividerColor, height: 1)),
        ],
      ),
    );
  }

  Widget _buildAlertItem(dynamic a, int i, ThemeData theme) {
    final isRead = a['read'] == true;
    final type = a['type'] ?? 'info';
    final icon = _typeIcon(type);
    final color = _typeColor(type);
    final anim = _itemAnimation(i);
    final alertId = a['_id']?.toString() ?? '';

    final card = GestureDetector(
      onTap: !isRead
          ? () {
              HapticFeedback.selectionClick();
              _markRead(alertId);
            }
          : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: ShapeDecoration(
          color: theme.cardColor,
          shape: SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius(cornerRadius: 14, cornerSmoothing: 0.8),
            side: BorderSide(color: isRead ? theme.dividerColor : color.withValues(alpha: 0.3)),
          ),
        ),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
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
                            color: theme.colorScheme.onSurface)),
                    const SizedBox(height: 4),
                    Text(a['message'] ?? '',
                        style: TextStyle(
                            fontSize: 12,
                            color:
                                theme.textTheme.bodyMedium?.color ?? Colors.grey,
                            height: 1.4)),
                    const SizedBox(height: 4),
                    Text(_formatTimestamp(a['createdAt']?.toString() ?? ''),
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.withValues(alpha: 0.7))),
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
      );

    final Widget itemWidget = isRead
        ? card
        : Slidable(
            key: ValueKey(alertId.isEmpty ? 'alert_$i' : alertId),
            endActionPane: ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.28,
              children: [
                CustomSlidableAction(
                  onPressed: (_) {
                    HapticFeedback.mediumImpact();
                    _markRead(alertId);
                  },
                  backgroundColor: const Color(0xFF5C33CF),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  child: Container(
                    margin: const EdgeInsets.only(left: 6),
                    decoration: ShapeDecoration(
                      color: const Color(0xFF5C33CF),
                      shape: SmoothRectangleBorder(
                        borderRadius: SmoothBorderRadius(
                            cornerRadius: 14, cornerSmoothing: 0.8),
                      ),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_rounded,
                            color: Colors.white, size: 22),
                        SizedBox(height: 4),
                        Text('Read',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            child: card,
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
