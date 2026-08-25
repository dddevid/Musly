import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:musly/l10n/app_localizations.dart';
import 'package:musly/theme/app_theme.dart';
import 'package:musly/services/analytics_service.dart';
import 'package:musly/widgets/dialogs/support_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:musly/widgets/settings/settings_section_card.dart';
import 'package:musly/utils/context_extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:musly/screens/onboarding/onboarding_screen.dart';
import 'package:musly/screens/wrapped/wrapped_screen.dart';
import 'package:musly/services/wrapped_service.dart';

class SettingsAboutTab extends StatefulWidget {
  const SettingsAboutTab({super.key});

  @override
  State<SettingsAboutTab> createState() => _SettingsAboutTabState();
}

class _SettingsAboutTabState extends State<SettingsAboutTab> {
  bool _hasRated = false;
  int _versionTapCount = 0;
  bool _devWrappedUnlocked = false;

  bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hasRated = prefs.getBool('has_rated_app') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        SettingsSectionCard(
          title: AppLocalizations.of(context)!.sectionAboutInformation,
          children: [
            _buildInfoTile(
              context,
              icon: CupertinoIcons.info,
              iconColor: Theme.of(context).colorScheme.primary,
              title: AppLocalizations.of(context)!.aboutVersion,
              subtitle: '2.0.1',
              onTap: _onVersionTapped,
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
        SettingsSectionCard(
          title: AppLocalizations.of(context)!.sectionAboutDeveloper,
          children: [_buildDeveloperInfo(context)],
        ),
        const SizedBox(height: 24),
        SettingsSectionCard(
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
              url: 'https://github.com/dddevid/Musly/releases/tag/v2.0.1',
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
            _buildDivider(context),
            _buildActionTile(
              context,
              icon: CupertinoIcons.sparkles,
              iconColor: const Color(0xFF6366F1),
              title: AppLocalizations.of(context)!.welcomeTourTitle,
              subtitle: AppLocalizations.of(context)!.welcomeTourSubtitle,
              onTap: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) => const OnboardingScreen(),
                  ),
                );
              },
            ),
            if (!_isDesktop && (WrappedService.isWrappedSeason() || (kDebugMode && _devWrappedUnlocked))) ...[
              _buildDivider(context),
              _buildActionTile(
                context,
                icon: CupertinoIcons.gift_fill,
                iconColor: const Color(0xFFFA243C),
                title: kDebugMode && !WrappedService.isWrappedSeason()
                    ? AppLocalizations.of(context)!.muslyPlaybackDev
                    : AppLocalizations.of(context)!.muslyPlaybackAnnual,
                subtitle: kDebugMode && !WrappedService.isWrappedSeason()
                    ? AppLocalizations.of(context)!.muslyPlaybackDevSubtitle
                    : AppLocalizations.of(context)!.muslyPlaybackAnnualSubtitle,
                onTap: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) => WrappedScreen(
                        devPreview: kDebugMode && _devWrappedUnlocked,
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),
        SettingsSectionCard(
          title: AppLocalizations.of(context)!.sectionAboutSupport,
          children: [
            _buildActionTile(
              context,
              icon: CupertinoIcons.star_fill,
              iconColor: const Color(0xFFFFCC00),
              title: _hasRated
                  ? AppLocalizations.of(context)!.thanksForRating
                  : AppLocalizations.of(context)!.rateMusly,
              subtitle: _hasRated
                  ? AppLocalizations.of(context)!.alreadyRatedSubtitle
                  : AppLocalizations.of(context)!.shareFeedbackSubtitle,
              onTap: _hasRated ? null : () => _showRatingDialog(context),
            ),
            _buildDivider(context),
            _buildActionTile(
              context,
              icon: CupertinoIcons.heart_fill,
              iconColor: const Color(0xFFFF2D55),
              title: AppLocalizations.of(context)!.supportMuslyTitle,
              subtitle: AppLocalizations.of(context)!.supportMuslySubtitle,
              onTap: () => _showSupportDialog(context),
            ),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }


  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 56),
      child: Container(
        height: 0.5,
        color: context.isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
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
          color: context.isDark
              ? AppTheme.darkSecondaryText
              : AppTheme.lightSecondaryText,
        ),
      ),
      onTap: onTap,
    );
  }

  void _onVersionTapped() {
    if (!kDebugMode || _isDesktop) return;

    setState(() {
      _versionTapCount++;
      if (_versionTapCount >= 8) {
        _devWrappedUnlocked = true;
      }
    });

    HapticFeedback.lightImpact();

    if (_versionTapCount < 8 && _versionTapCount >= 4) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.devPlaybackTapsAway(8 - _versionTapCount)),
          duration: const Duration(milliseconds: 700),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (_versionTapCount == 8) {
      final l10n = AppLocalizations.of(context)!;
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(CupertinoIcons.sparkles, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(l10n.devPlaybackUnlocked),
            ],
          ),
          backgroundColor: const Color(0xFFFA243C),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
      title: Text(
        AppLocalizations.of(context)!.aboutMadeBy,
        style: const TextStyle(fontSize: 16),
      ),
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
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 18,
        ),
      ),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: Icon(
        Icons.open_in_new_rounded,
        size: 18,
        color: context.isDark
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

  void _showSupportDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const SupportDialog());
  }

  void _showRatingDialog(BuildContext context) async {
    final ratingController = TextEditingController();
    int selectedRating = 5;
    final l10n = AppLocalizations.of(context)!;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.rateMuslyDialogTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.rateMuslyDialogQuestion),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starIndex = index + 1;
                    return IconButton(
                      icon: Icon(
                        starIndex <= selectedRating
                            ? CupertinoIcons.star_fill
                            : CupertinoIcons.star,
                        color: const Color(0xFFFFCC00),
                      ),
                      onPressed: () {
                        setDialogState(() => selectedRating = starIndex);
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 100),
                  child: TextField(
                    controller: ratingController,
                    decoration: InputDecoration(
                      hintText: l10n.optionalFeedbackHint,
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.submit),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      await AnalyticsService().recordRating(
        selectedRating,
        ratingController.text,
      );
      await AnalyticsService().markAppAsRated();
      if (context.mounted) {
        setState(() => _hasRated = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.thankYouFeedback)),
        );
      }
    }
    ratingController.dispose();
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [iconColor, iconColor.withValues(alpha: 0.7)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: context.isDark
              ? AppTheme.darkSecondaryText
              : AppTheme.lightSecondaryText,
        ),
      ),
      trailing: onTap != null
          ? Icon(
              CupertinoIcons.chevron_forward,
              size: 18,
              color: context.isDark
                  ? AppTheme.darkSecondaryText
                  : AppTheme.lightSecondaryText,
            )
          : null,
      onTap: onTap,
    );
  }
}
