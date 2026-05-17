import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import 'student_home_tab.dart';
import 'student_payment_tab.dart';
import 'student_history_tab.dart';
import 'student_alerts_tab.dart';

class StudentFeesShell extends StatefulWidget {
  const StudentFeesShell({super.key});

  @override
  State<StudentFeesShell> createState() => _StudentFeesShellState();
}

class _StudentFeesShellState extends State<StudentFeesShell> {
  int _currentIndex = 0;

  final _screens = const [
    StudentHomeTab(),
    StudentPaymentTab(),
    StudentHistoryTab(),
    StudentAlertsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Theme.of(context).cardColor,
          selectedItemColor: SAMsTheme.primary,
          unselectedItemColor: Theme.of(context).textTheme.bodySmall?.color,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.payment_outlined), activeIcon: Icon(Icons.payment), label: 'Payment'),
            BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'History'),
            BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), activeIcon: Icon(Icons.notifications), label: 'Alerts'),
          ],
        ),
      ),
    );
  }
}
