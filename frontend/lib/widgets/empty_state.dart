import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../config/theme.dart';

/// Reusable empty state widget with optional Lottie animation
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? lottieUrl;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.lottieUrl,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          // Lottie animation or icon fallback
          if (lottieUrl != null)
            SizedBox(
              width: 120, height: 120,
              child: Lottie.network(
                lottieUrl!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: t.dividerColor.withOpacity(0.3),
                  ),
                  child: Icon(icon, size: 32, color: t.textTheme.bodySmall?.color),
                ),
              ),
            )
          else
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: t.dividerColor.withOpacity(0.3),
              ),
              child: Icon(icon, size: 32, color: t.textTheme.bodySmall?.color),
            ),
          const SizedBox(height: 20),
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: t.colorScheme.onSurface), textAlign: TextAlign.center),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!, style: TextStyle(fontSize: 13, color: t.textTheme.bodySmall?.color, height: 1.4), textAlign: TextAlign.center),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: SAMsTheme.primary.withOpacity(0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text(actionLabel!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SAMsTheme.primary)),
            ),
          ],
        ]),
      ),
    );
  }

  // Preset factories with Lottie animations
  static Widget noFees({VoidCallback? onRefresh}) => EmptyState(
    icon: Icons.receipt_long_outlined,
    title: 'No fees assigned',
    subtitle: 'Your tuition fees will appear here once assigned by the treasury.',
    actionLabel: onRefresh != null ? 'Refresh' : null,
    onAction: onRefresh,
    lottieUrl: 'https://lottie.host/4db68bbd-31f6-4cd8-84eb-189571c43abc/7FkQaBciEE.json',
  );

  static Widget noPayments() => const EmptyState(
    icon: Icons.history_outlined,
    title: 'No payment history',
    subtitle: 'Your completed transactions will be listed here.',
    lottieUrl: 'https://lottie.host/e4bd0dab-7e5c-4612-a8fb-51a3e3076b78/mCBLkMQQFi.json',
  );

  static Widget noNotifications() => const EmptyState(
    icon: Icons.notifications_off_outlined,
    title: 'All caught up',
    subtitle: 'No notifications at the moment.',
    lottieUrl: 'https://lottie.host/b5e94a05-f8b0-4e3e-9f0e-cf3c1b96a420/VxJFNKEFfN.json',
  );

  static Widget noStudents() => const EmptyState(
    icon: Icons.people_outline,
    title: 'No students found',
    subtitle: 'Try adjusting your search or filter.',
  );

  static Widget error({VoidCallback? onRetry}) => EmptyState(
    icon: Icons.error_outline_rounded,
    title: 'Something went wrong',
    subtitle: 'Failed to load data. Check your connection.',
    actionLabel: onRetry != null ? 'Try again' : null,
    onAction: onRetry,
    lottieUrl: 'https://lottie.host/68c4e0e0-0623-4283-b60c-ec7c0354e3f4/cXNHlFYfND.json',
  );

  static Widget offline({VoidCallback? onRetry}) => EmptyState(
    icon: Icons.wifi_off_rounded,
    title: 'No connection',
    subtitle: 'Connect to the internet to view your data.',
    actionLabel: onRetry != null ? 'Retry' : null,
    onAction: onRetry,
    lottieUrl: 'https://lottie.host/68c4e0e0-0623-4283-b60c-ec7c0354e3f4/cXNHlFYfND.json',
  );
}
