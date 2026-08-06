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
    return Container(
      width: AppDimensions.iconBadgeSize,
      height: AppDimensions.iconBadgeSize,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.iconBadgeRadius),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: AppDimensions.iconSize,
      ),
    );
  }
}
