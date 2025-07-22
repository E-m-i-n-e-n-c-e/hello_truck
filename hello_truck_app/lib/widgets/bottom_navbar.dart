import 'package:flutter/material.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const CustomBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 350),
        // Shut up i want grey
        color: Colors.grey.shade200,
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(
              icon: Icons.home,
              index: 0,
              colorScheme: colorScheme,
            ),
            _buildNavItem(
              icon: Icons.map,
              index: 1,
              colorScheme: colorScheme,
            ),
            _buildNavItem(
              icon: Icons.person,
              index: 2,
              colorScheme: colorScheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required int index,
    required ColorScheme colorScheme,
  }) {
    bool isSelected = selectedIndex == index;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.all(0),
      ),
      onPressed: () => onItemSelected(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 26,
            color: isSelected ? colorScheme.primary : colorScheme.onSurface,
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 2,
            width: isSelected ? 20 : 0,
            color: isSelected ? colorScheme.primary : Colors.transparent,
          ),
        ],
      ),
    );
  }
}