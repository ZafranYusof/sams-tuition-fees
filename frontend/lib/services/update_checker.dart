import 'package:flutter/material.dart';

class UpdateChecker {
  static const String currentVersion = '1.0.0';
  static const String latestVersion = '1.0.0'; // In production, fetch from API

  static bool get hasUpdate => currentVersion != latestVersion;

  static void checkAndShow(BuildContext context) {
    if (!hasUpdate) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(Icons.system_update, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Text('Update Available', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18)),
        ]),
        content: Text(
          'A new version ($latestVersion) is available. Please update for the best experience.',
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Later', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
