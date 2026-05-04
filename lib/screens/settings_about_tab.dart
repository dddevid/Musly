import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../services/analytics_service.dart';
import '../widgets/support_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsAboutTab extends StatefulWidget {
  const SettingsAboutTab({super.key});

  @override
  State<SettingsAboutTab> createState() => _SettingsAboutTabState();
}

class _SettingsAboutTabState extends State<SettingsAboutTab> {
  bool _analyticsEnabled = true;
  bool _hasRated = false;
  String? _deviceId;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final analytics = AnalyticsService();
    final prefs = await SharedPreferences.getInstance();
    final deviceId = await analytics.getDeviceId();
    setState(() {
      _analyticsEnabled = analytics.isEnabled;
      _hasRated = prefs.getBool('has_rated_app') ?? false;
      _deviceId = deviceId ?? 'not-available';
    });
  }

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
              subtitle: '1.0.10',
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
              url: 'https://github.com/dddevid/Musly/releases/tag/v1.0.10',
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
        const SizedBox(height: 24),
        _buildSection(
          context,
          title: 'Analytics & Privacy',
          children: [
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              secondary: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF34C759), Color(0xFF30D158)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.chart_bar,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              title: const Text(
                'Anonymous Analytics',
                style: TextStyle(fontSize: 16),
              ),
              subtitle: const Text(
                'Help improve Musly with anonymous crash reports and usage stats',
                style: TextStyle(fontSize: 12),
              ),
              value: _analyticsEnabled,
              onChanged: (value) async {
                await AnalyticsService().setEnabled(value);
                setState(() => _analyticsEnabled = value);
              },
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.device_phone_portrait,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              title: const Text('Device ID', style: TextStyle(fontSize: 16)),
              subtitle: Text(
                _analyticsEnabled
                    ? 'Anonymous ID: ${_deviceId ?? "Loading..."}'
                    : 'Enable analytics to see your anonymous device ID',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: _analyticsEnabled
                  ? IconButton(
                      icon: const Icon(CupertinoIcons.doc_on_doc, size: 18),
                      tooltip: 'Copy device ID',
                      onPressed: () {
                        if (_deviceId != null) {
                          Clipboard.setData(ClipboardData(text: _deviceId!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Device ID copied to clipboard'),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    )
                  : null,
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.info,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              title: const Text(
                'About Device ID',
                style: TextStyle(fontSize: 16),
              ),
              subtitle: const Text(
                'This is an anonymous identifier generated by the app. It cannot be linked to your personal identity and is used only for analytics.',
                style: TextStyle(fontSize: 12, height: 1.3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSection(
          context,
          title: 'Support',
          children: [
            _buildActionTile(
              context,
              icon: CupertinoIcons.star_fill,
              iconColor: const Color(0xFFFFCC00),
              title: _hasRated ? 'Thanks for Rating!' : 'Rate Musly',
              subtitle: _hasRated
                  ? 'You\'ve already rated the app'
                  : 'Share your feedback',
              onTap: _hasRated ? null : () => _showRatingDialog(context),
            ),
            _buildDivider(context),
            _buildActionTile(
              context,
              icon: CupertinoIcons.heart_fill,
              iconColor: const Color(0xFFFF2D55),
              title: 'Support Musly',
              subtitle: 'Join Discord or donate',
              onTap: () => _showSupportDialog(context),
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

  void _showSupportDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const SupportDialog());
  }

  void _showRatingDialog(BuildContext context) async {
    final ratingController = TextEditingController();
    int selectedRating = 5;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Rate Musly'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('How would you rate your experience?'),
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
                    decoration: const InputDecoration(
                      hintText: 'Optional feedback...',
                      border: OutlineInputBorder(),
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
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Submit'),
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
      if (mounted) {
        setState(() => _hasRated = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your feedback!')),
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
          color: _isDark(context)
              ? AppTheme.darkSecondaryText
              : AppTheme.lightSecondaryText,
        ),
      ),
      trailing: onTap != null
          ? Icon(
              CupertinoIcons.chevron_forward,
              size: 18,
              color: _isDark(context)
                  ? AppTheme.darkSecondaryText
                  : AppTheme.lightSecondaryText,
            )
          : null,
      onTap: onTap,
    );
  }
}
