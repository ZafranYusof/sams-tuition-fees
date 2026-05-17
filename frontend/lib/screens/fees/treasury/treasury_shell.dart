import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import 'treasury_dashboard_tab.dart';
import 'treasury_students_tab.dart';

class TreasuryShell extends StatefulWidget {
  const TreasuryShell({super.key});

  @override
  State<TreasuryShell> createState() => _TreasuryShellState();
}

class _TreasuryShellState extends State<TreasuryShell> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      TreasuryDashboardTab(onViewStudents: () => setState(() => _currentIndex = 1)),
      const TreasuryStudentsTab(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
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
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined, size: 22), activeIcon: Icon(Icons.dashboard_rounded, size: 22), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.people_outline_rounded, size: 22), activeIcon: Icon(Icons.people_rounded, size: 22), label: 'Students'),
          ],
        ),
      ),
    );
  }
}
