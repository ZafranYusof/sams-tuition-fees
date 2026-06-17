import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard_screen.dart';
import '../ManageTuitionFees/fees_screen.dart';
import 'profile_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  final String role;
  
  const MainShell({super.key, required this.role});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;
  late final List<Widget> _pages;
  late final List<BottomNavigationBarItem> _navItems;

  @override
  void initState() {
    super.initState();
    _buildNavigation();
  }

  void _buildNavigation() {
    switch (widget.role) {
      case 'admin':
        _pages = [
          const DashboardScreen(),
          const FeesScreen(),
          const ProfileScreen(),
        ];
        _navItems = [
          const BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          const BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Students'),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ];
        break;
      case 'lecturer':
        _pages = [
          const DashboardScreen(),
          const ProfileScreen(),
        ];
        _navItems = [
          const BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ];
        break;
      case 'faculty':
      case 'registrar':
        _pages = [
          const DashboardScreen(),
          const ProfileScreen(),
        ];
        _navItems = [
          const BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ];
        break;
      case 'staff':
        _pages = [
          const DashboardScreen(),
          const ProfileScreen(),
        ];
        _navItems = [
          const BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ];
        break;
      default: // student
        _pages = [
          const DashboardScreen(),
          const ProfileScreen(),
        ];
        _navItems = [
          const BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: _navItems,
      ),
    );
  }
}
