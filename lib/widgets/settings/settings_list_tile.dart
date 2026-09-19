import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/context_extensions.dart';
import 'settings_icon_badge.dart';

class SettingsListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leading;
  final VoidCallback? onTap;
  final IconData? icon;
  final List<Color>? gradientColors;
  final Color? titleColor;

  const SettingsListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.leading,
    this.onTap,
    this.icon,
    this.gradientColors,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasLeading = leading != null || (icon != null && gradientColors != null);
    
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (hasLeading) ...[
              leading ?? SettingsIconBadge(gradientColors: gradientColors!, icon: icon!),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: titleColor ?? (context.isDark ? Colors.white : Colors.black),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.isDark
                            ? AppTheme.darkSecondaryText
                            : AppTheme.lightSecondaryText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 16),
              Flexible(
                child: DefaultTextStyle(
                  style: TextStyle(
                    fontSize: 16,
                    color: context.isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
                  ),
                  child: trailing!,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
