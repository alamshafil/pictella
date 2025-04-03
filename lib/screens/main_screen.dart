import 'package:flutter/material.dart';
import 'package:image_app/components/bottom_nav_bar.dart';
import 'dashboard_screen.dart';
import 'settings_screen.dart';
import 'search_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _screens = [
      const DashboardScreen(isInTabView: true),
      const SearchScreen(isInTabView: true),
      const SettingsScreen(isInTabView: true),
    ];
  }

  void _onIndexChanged(int index) {
    if (_currentIndex == index) return;

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Add a Theme override to customize NavigationBar appearance
    return Theme(
      data: Theme.of(context).copyWith(
        // Customize NavigationBar appearance
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.transparent,
          elevation: 0,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return TextStyle(
                fontSize: 13,
                color: const Color(0xFF64B5F6),
                fontWeight: FontWeight.w500,
              );
            }
            return TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.7),
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            return IconThemeData(
              size: 26,
              color:
                  states.contains(WidgetState.selected)
                      ? const Color(0xFF64B5F6)
                      : Colors.white.withValues(alpha: 0.7),
            );
          }),
        ),
      ),
      child: Scaffold(
        // Use IndexedStack to maintain state and prevent rebuilds
        body: IndexedStack(index: _currentIndex, children: _screens),
        extendBody: true,
        // Use the CustomBottomNavBar with material components
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onIndexChanged,
        ),
      ),
    );
  }
}
