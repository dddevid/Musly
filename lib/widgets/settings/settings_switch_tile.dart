import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../theme/app_theme.dart';
import '../../utils/context_extensions.dart';
import 'settings_icon_badge.dart';

class SettingsSwitchTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? icon;
  final List<Color>? gradientColors;

  const SettingsSwitchTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.icon,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final hasLeading = icon != null && gradientColors != null;
    
    return InkWell(
      onTap: () => onChanged(!value),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (hasLeading) ...[
              SettingsIconBadge(gradientColors: gradientColors!, icon: icon!),
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
                      color: context.isDark ? Colors.white : Colors.black,
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
            const SizedBox(width: 16),
            CupertinoSwitch(
              value: value,
              activeTrackColor: Theme.of(context).colorScheme.primary,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
