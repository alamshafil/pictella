import 'package:flutter/material.dart';
import 'dart:ui';
import '../utils/app_settings.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final blurEffectsEnabled = AppSettings.instance.blurEffectsEnabled;

    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child:
            blurEffectsEnabled
                ? BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: _buildNavContainer(context),
                )
                : _buildNavContainer(context),
      ),
    );
  }

  Widget _buildNavContainer(BuildContext context) {
    // Define the item colors based on selection
    final selectedColor = const Color(0xFF64B5F6);
    final unselectedColor = Colors.white.withValues(alpha: 0.7);

    return Container(
      height: 72, // Slightly increased height
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            0,
            Icons.home_outlined,
            Icons.home,
            'Home',
            selectedColor,
            unselectedColor,
          ),
          _buildNavItem(
            1,
            Icons.search_outlined,
            Icons.search,
            'Search',
            selectedColor,
            unselectedColor,
          ),
          _buildNavItem(
            2,
            Icons.settings_outlined,
            Icons.settings,
            'Settings',
            selectedColor,
            unselectedColor,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
    Color selectedColor,
    Color unselectedColor,
  ) {
    final isSelected = index == currentIndex;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(index),
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? selectedColor : unselectedColor,
                  size: 28,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected ? selectedColor : unselectedColor,
                    fontWeight:
                        isSelected ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
