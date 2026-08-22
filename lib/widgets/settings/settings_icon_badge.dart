import 'package:flutter/material.dart';
import '../../theme/app_dimensions.dart';

class SettingsIconBadge extends StatelessWidget {
  final IconData icon;
  final List<Color> gradientColors;

  const SettingsIconBadge({
    super.key,
    required this.icon,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = gradientColors.first;
    return Container(
      width: AppDimensions.iconBadgeSize,
      height: AppDimensions.iconBadgeSize,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.iconBadgeRadius),
        boxShadow: [
          BoxShadow(
            color: baseColor.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: AppDimensions.iconSize,
      ),
    );
  }
}
