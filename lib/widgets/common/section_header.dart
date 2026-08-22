import 'package:flutter/material.dart';
import 'package:musly/l10n/app_localizations.dart';

class HorizontalScrollSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final VoidCallback? onSeeAllTap;
  final double itemSpacing;
  final EdgeInsets padding;
  final double? cardSize;

  const HorizontalScrollSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    this.onSeeAllTap,
    this.itemSpacing = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.cardSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final listHeight = (cardSize ?? 150) + 84; 

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: padding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.headlineLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (onSeeAllTap != null)
                TextButton(
                  onPressed: onSeeAllTap,
                  child: Text(
                    AppLocalizations.of(context)!.seeAll,
                    style: theme.textTheme.labelLarge,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: listHeight,
          child: ListView.separated(
            padding: padding,
            scrollDirection: Axis.horizontal,
            itemCount: children.length,
            separatorBuilder: (context, index) => SizedBox(width: itemSpacing),
            itemBuilder: (context, index) => children[index],
          ),
        ),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onActionTap;
  final IconData? icon;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onActionTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 24, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.headlineLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (actionText != null && onActionTap != null)
            TextButton(
              onPressed: onActionTap,
              child: Text(actionText!, style: theme.textTheme.labelLarge),
            ),
        ],
      ),
    );
  }
}
