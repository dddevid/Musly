import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_dimensions.dart';
import '../../utils/context_extensions.dart';

class SettingsSectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsSectionCard({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: AppDimensions.sectionHeaderPadding,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}

class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppDimensions.dividerIndent),
      child: Container(
        height: AppDimensions.dividerHeight,
        color: context.isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
      ),
    );
  }
}
