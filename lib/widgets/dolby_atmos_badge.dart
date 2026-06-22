import 'package:flutter/material.dart';

/// A compact Dolby Atmos badge shown next to songs that support it.
class DolbyAtmosBadge extends StatelessWidget {
  final double fontSize;
  final EdgeInsets padding;

  const DolbyAtmosBadge({
    super.key,
    this.fontSize = 9,
    this.padding = const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Dolby Atmos',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: isDark ? Colors.white.withValues(alpha: 0.85) : Colors.black.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
