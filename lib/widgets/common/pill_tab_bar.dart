import 'package:flutter/material.dart';

class PillTabBar extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final EdgeInsetsGeometry padding;
  final double height;

  const PillTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.height = 42,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: padding,
      child: Container(
        height: height,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: List.generate(tabs.length, (index) {
            final isSelected = selectedIndex == index;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected && !isDark
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onTabSelected(index),
                    borderRadius: BorderRadius.circular(8),
                    child: Center(
                      child: Text(
                        tabs[index],
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? (isDark ? Colors.white : Colors.black)
                              : (isDark ? Colors.white70 : Colors.black54),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
