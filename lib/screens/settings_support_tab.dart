import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class SettingsSupportTab extends StatelessWidget {
  const SettingsSupportTab({super.key});

  Future<void> _launchDiscord() async {
    final uri = Uri.parse('https://discord.gg/RrcFvFPdRU');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchDonation() async {
    final uri = Uri.parse('https://revolut.me/ddevid_1');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      children: [
        // Heart icon at top
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFA2D48), Color(0xFFFF6B6B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              CupertinoIcons.heart_fill,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
        const SizedBox(height: 24),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.supportGreeting,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.supportParagraph1,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.supportParagraph2,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.supportParagraph3,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.supportParagraph4,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    fontStyle: FontStyle.italic,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Donation button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _buildActionCard(
            context: context,
            icon: CupertinoIcons.heart_fill,
            title: l10n.supportDonationTitle,
            subtitle: l10n.supportDonationSubtitle,
            color: const Color(0xFFFA2D48),
            onTap: _launchDonation,
          ),
        ),
        const SizedBox(height: 16),

        // Discord button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _buildActionCard(
            context: context,
            icon: CupertinoIcons.chat_bubble_fill,
            title: l10n.supportDiscordTitle,
            subtitle: l10n.supportDiscordSubtitle,
            color: const Color(0xFF5865F2),
            onTap: _launchDiscord,
          ),
        ),
        const SizedBox(height: 24),

        // Ways to support without money
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.supportWaysTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSupportItem(
                  context: context,
                  icon: CupertinoIcons.share,
                  text: l10n.supportWayShare,
                ),
                const SizedBox(height: 12),
                _buildSupportItem(
                  context: context,
                  icon: CupertinoIcons.exclamationmark_circle,
                  text: l10n.supportWayBugs,
                ),
                const SizedBox(height: 12),
                _buildSupportItem(
                  context: context,
                  icon: CupertinoIcons.heart_fill,
                  text: l10n.supportWayEnjoy,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Made with love
        Center(
          child: Text(
            l10n.supportMadeWithLove,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_forward,
                color: color,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportItem({
    required BuildContext context,
    required IconData icon,
    required String text,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText;

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: secondaryTextColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }
}
