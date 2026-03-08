import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class SettingsAboutTab extends StatelessWidget {
  const SettingsAboutTab({super.key});

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        _buildSection(
          context,
          title: AppLocalizations.of(context)!.sectionAboutInformation,
          children: [
            _buildInfoTile(
              context,
              icon: CupertinoIcons.info,
              iconColor: Theme.of(context).colorScheme.primary,
              title: AppLocalizations.of(context)!.aboutVersion,
              subtitle: '1.0.8',
            ),
            _buildDivider(context),
            _buildInfoTile(
              context,
              icon: CupertinoIcons.device_phone_portrait,
              iconColor: const Color(0xFF007AFF),
              title: AppLocalizations.of(context)!.aboutPlatform,
              subtitle: Theme.of(context).platform.name.toUpperCase(),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSection(
          context,
          title: AppLocalizations.of(context)!.sectionAboutDeveloper,
          children: [_buildDeveloperInfo(context)],
        ),
        const SizedBox(height: 24),
        _buildSection(
          context,
          title: AppLocalizations.of(context)!.sectionAboutLinks,
          children: [
            _buildLinkTile(
              context,
              icon: Icons.code_rounded,
              title: AppLocalizations.of(context)!.aboutLinkGitHub,
              url: 'https://github.com/dddevid/Musly',
            ),
            _buildDivider(context),
            _buildLinkTile(
              context,
              icon: CupertinoIcons.doc_text,
              title: AppLocalizations.of(context)!.aboutLinkChangelog,
              url: 'https://github.com/dddevid/Musly/releases/tag/v1.0.8',
            ),
            _buildDivider(context),
            _buildLinkTile(
              context,
              icon: CupertinoIcons.exclamationmark_bubble,
              title: AppLocalizations.of(context)!.aboutLinkReportIssue,
              url: 'https://github.com/dddevid/Musly/issues/new',
            ),
            _buildDivider(context),
            _buildLinkTile(
              context,
              icon: Icons.chat_bubble_rounded,
              title: AppLocalizations.of(context)!.aboutLinkDiscord,
              url: 'https://discord.gg/k9FqpbT65M',
            ),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: _isDark(context)
                  ? AppTheme.darkSecondaryText
                  : AppTheme.lightSecondaryText,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: _isDark(context) ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 56),
      child: Container(
        height: 0.5,
        color: _isDark(context) ? AppTheme.darkDivider : AppTheme.lightDivider,
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: Text(
        subtitle,
        style: TextStyle(
          fontSize: 16,
          color: _isDark(context)
              ? AppTheme.darkSecondaryText
              : AppTheme.lightSecondaryText,
        ),
      ),
    );
  }

  Widget _buildDeveloperInfo(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5856D6), Color(0xFFAF52DE)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.code_rounded, color: Colors.white, size: 18),
      ),
      title: Text(AppLocalizations.of(context)!.aboutMadeBy, style: const TextStyle(fontSize: 16)),
      subtitle: Text(
        AppLocalizations.of(context)!.aboutGitHub,
        style: const TextStyle(fontSize: 13),
      ),
      trailing: const Icon(Icons.open_in_new_rounded, size: 18),
      onTap: () => _openUrl('https://github.com/dddevid'),
    );
  }

  Widget _buildLinkTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String url,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 18),
      ),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: Icon(
        Icons.open_in_new_rounded,
        size: 18,
        color: _isDark(context)
            ? AppTheme.darkSecondaryText
            : AppTheme.lightSecondaryText,
      ),
      onTap: () => _openUrl(url),
    );
  }

  void _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error opening URL: $e');
    }
  }
}
