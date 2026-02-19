import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import '../services/recommendation_service.dart';
import '../services/player_ui_settings_service.dart';
import '../services/locale_service.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class SettingsDisplayTab extends StatefulWidget {
  const SettingsDisplayTab({super.key});

  @override
  State<SettingsDisplayTab> createState() => _SettingsDisplayTabState();
}

class _SettingsDisplayTabState extends State<SettingsDisplayTab> {
  final _playerUiSettings = PlayerUiSettingsService();
  bool _showVolumeSlider = true;
  bool _showStarRatings = false;

  bool get _isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _playerUiSettings.initialize();

    setState(() {
      _showVolumeSlider = _playerUiSettings.getShowVolumeSlider();
      _showStarRatings = _playerUiSettings.getShowStarRatings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        _buildSection(
          title: AppLocalizations.of(context)!.language.toUpperCase(),
          children: [
            _buildLanguageSelector(),
            _buildDivider(),
            _buildTranslationCredit(),
          ],
        ),
        const SizedBox(height: 24),
        _buildSection(
          title: AppLocalizations.of(context)!.playerInterface.toUpperCase(),
          children: [
            _buildVolumeSliderToggle(),
            _buildDivider(),
            _buildStarRatingsToggle(),
            if (_isDesktop) ...[_buildDivider(), _buildDiscordRpcToggle()],
          ],
        ),
        const SizedBox(height: 24),
        _buildSection(
          title: AppLocalizations.of(
            context,
          )!.smartRecommendations.toUpperCase(),
          children: [
            _buildRecommendationsToggle(),
            _buildDivider(),
            _buildRecommendationsStats(),
            _buildDivider(),
            _buildClearRecommendationsButton(),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSection({
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
              color: _isDark
                  ? AppTheme.darkSecondaryText
                  : AppTheme.lightSecondaryText,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: _isDark ? AppTheme.darkSurface : Colors.white,
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

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 56),
      child: Container(
        height: 0.5,
        color: _isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
      ),
    );
  }

  Widget _buildVolumeSliderToggle() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF007AFF), Color(0xFF5AC8FA)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          CupertinoIcons.speaker_2,
          color: Colors.white,
          size: 18,
        ),
      ),
      title: Text(
        AppLocalizations.of(context)!.showVolumeSlider,
        style: const TextStyle(fontSize: 16),
      ),
      subtitle: Text(
        AppLocalizations.of(context)!.showVolumeSliderSubtitle,
        style: TextStyle(
          fontSize: 13,
          color: _isDark
              ? AppTheme.darkSecondaryText
              : AppTheme.lightSecondaryText,
        ),
      ),
      trailing: CupertinoSwitch(
        value: _showVolumeSlider,
        activeTrackColor: AppTheme.appleMusicRed,
        onChanged: (value) async {
          setState(() => _showVolumeSlider = value);
          await _playerUiSettings.setShowVolumeSlider(value);
        },
      ),
    );
  }

  Widget _buildStarRatingsToggle() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          CupertinoIcons.star_fill,
          color: Colors.white,
          size: 18,
        ),
      ),
      title: Text(
        AppLocalizations.of(context)!.showStarRatings,
        style: const TextStyle(fontSize: 16),
      ),
      subtitle: Text(
        AppLocalizations.of(context)!.showStarRatingsSubtitle,
        style: TextStyle(
          fontSize: 13,
          color: _isDark
              ? AppTheme.darkSecondaryText
              : AppTheme.lightSecondaryText,
        ),
      ),
      trailing: CupertinoSwitch(
        value: _showStarRatings,
        activeTrackColor: AppTheme.appleMusicRed,
        onChanged: (value) async {
          setState(() => _showStarRatings = value);
          await _playerUiSettings.setShowStarRatings(value);
        },
      ),
    );
  }

  Widget _buildRecommendationsToggle() {
    return Consumer<RecommendationService>(
      builder: (context, service, _) {
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF2D55), Color(0xFFFF6B6B)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              CupertinoIcons.sparkles,
              color: Colors.white,
              size: 18,
            ),
          ),
          title: Text(
            AppLocalizations.of(context)!.enableRecommendations,
            style: const TextStyle(fontSize: 16),
          ),
          subtitle: Text(
            AppLocalizations.of(context)!.enableRecommendationsSubtitle,
            style: TextStyle(
              fontSize: 13,
              color: _isDark
                  ? AppTheme.darkSecondaryText
                  : AppTheme.lightSecondaryText,
            ),
          ),
          trailing: CupertinoSwitch(
            value: service.enabled,
            activeTrackColor: AppTheme.appleMusicRed,
            onChanged: (value) => service.setEnabled(value),
          ),
        );
      },
    );
  }

  Widget _buildRecommendationsStats() {
    return Consumer<RecommendationService>(
      builder: (context, service, _) {
        final stats = service.getListeningStats();
        final uniqueSongs = stats['uniqueSongs'] ?? 0;
        final totalPlays = stats['totalPlays'] ?? 0;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          title: Text(
            AppLocalizations.of(context)!.listeningData,
            style: const TextStyle(fontSize: 16),
          ),
          subtitle: Text(
            AppLocalizations.of(context)!.totalPlays(totalPlays),
            style: TextStyle(
              fontSize: 13,
              color: _isDark
                  ? AppTheme.darkSecondaryText
                  : AppTheme.lightSecondaryText,
            ),
          ),
          trailing: Text(
            AppLocalizations.of(context)!.songsCount(uniqueSongs),
            style: TextStyle(
              fontSize: 14,
              color: _isDark
                  ? AppTheme.darkSecondaryText
                  : AppTheme.lightSecondaryText,
            ),
          ),
        );
      },
    );
  }

  Widget _buildClearRecommendationsButton() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        AppLocalizations.of(context)!.clearListeningHistory,
        style: const TextStyle(fontSize: 16, color: Color(0xFFFF3B30)),
      ),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.clearListeningHistory),
            content: Text(AppLocalizations.of(context)!.confirmClearHistory),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Provider.of<RecommendationService>(
                    context,
                    listen: false,
                  ).clearData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.historyCleared,
                      ),
                    ),
                  );
                },
                child: Text(
                  AppLocalizations.of(context)!.delete,
                  style: const TextStyle(color: Color(0xFFFF3B30)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDiscordRpcToggle() {
    return Consumer<PlayerProvider>(
      builder: (context, player, _) {
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF5865F2), // Discord Blurple
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              CupertinoIcons.game_controller,
              color: Colors.white,
              size: 18,
            ),
          ),
          title: Text(
            AppLocalizations.of(context)!.discordStatus,
            style: const TextStyle(fontSize: 16),
          ),
          subtitle: Text(
            AppLocalizations.of(context)!.discordStatusSubtitle,
            style: TextStyle(
              fontSize: 13,
              color: _isDark
                  ? AppTheme.darkSecondaryText
                  : AppTheme.lightSecondaryText,
            ),
          ),
          trailing: CupertinoSwitch(
            value: player.discordRpcEnabled,
            activeTrackColor: AppTheme.appleMusicRed,
            onChanged: (value) async {
              await player.setDiscordRpcEnabled(value);
              // Force rebuild to update switch state since provider might not notify
              setState(() {});
            },
          ),
        );
      },
    );
  }

  Widget _buildLanguageSelector() {
    return Consumer<LocaleService>(
      builder: (context, localeService, _) {
        final currentLocale = localeService.currentLocale;
        final currentLanguageCode = currentLocale?.languageCode ?? 'en';
        final currentLanguageName =
            LocaleService.supportedLanguages[currentLanguageCode] ?? 'English';

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF34C759), Color(0xFF30D158)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              CupertinoIcons.globe,
              color: Colors.white,
              size: 18,
            ),
          ),
          title: Text(
            AppLocalizations.of(context)!.language,
            style: const TextStyle(fontSize: 16),
          ),
          subtitle: Text(
            currentLanguageName,
            style: TextStyle(
              fontSize: 13,
              color: _isDark
                  ? AppTheme.darkSecondaryText
                  : AppTheme.lightSecondaryText,
            ),
          ),
          trailing: const Icon(Icons.chevron_right, size: 20),
          onTap: () => _showLanguagePicker(context, localeService),
        );
      },
    );
  }

  Widget _buildTranslationCredit() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF5AC8FA).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          CupertinoIcons.heart_fill,
          color: Color(0xFFFF3B30),
          size: 18,
        ),
      ),
      title: Text(
        AppLocalizations.of(context)!.communityTranslations,
        style: const TextStyle(fontSize: 16),
      ),
      subtitle: Text(
        AppLocalizations.of(context)!.communityTranslationsSubtitle,
        style: TextStyle(
          fontSize: 13,
          color: _isDark
              ? AppTheme.darkSecondaryText
              : AppTheme.lightSecondaryText,
        ),
      ),
      trailing: const Icon(Icons.open_in_new_rounded, size: 18),
      onTap: () => _launchUrl('https://crowdin.com/project/musly'),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showLanguagePicker(BuildContext context, LocaleService localeService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: _isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _isDark ? Colors.grey[600] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.globe, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.selectLanguage,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // System default option
            ListTile(
              leading: const Icon(CupertinoIcons.device_phone_portrait),
              title: Text(AppLocalizations.of(context)!.systemDefault),
              trailing: localeService.currentLocale == null
                  ? const Icon(Icons.check, color: AppTheme.appleMusicRed)
                  : null,
              onTap: () {
                localeService.setLocale(null);
                Navigator.pop(context);
              },
            ),
            const Divider(height: 1),
            // Language list
            Expanded(
              child: ListView(
                children: LocaleService.supportedLanguages.entries.map((entry) {
                  final isSelected =
                      localeService.currentLocale?.languageCode == entry.key;
                  return ListTile(
                    leading: Text(
                      _getFlagEmoji(entry.key),
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(entry.value),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: AppTheme.appleMusicRed)
                        : null,
                    onTap: () {
                      localeService.setLocale(Locale(entry.key));
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFlagEmoji(String languageCode) {
    const Map<String, String> flagMap = {
      'en': '🇬🇧',
      'sq': '🇦🇱',
      'it': '🇮🇹',
      'bn': '🇧🇩',
      'zh': '🇨🇳',
      'da': '🇩🇰',
      'fi': '🇫🇮',
      'fr': '🇫🇷',
      'de': '🇩🇪',
      'el': '🇬🇷',
      'hi': '🇮🇳',
      'id': '🇮🇩',
      'ga': '🇮🇪',
      'no': '🇳🇴',
      'pl': '🇵🇱',
      'pt': '🇵🇹',
      'ro': '🇷🇴',
      'ru': '🇷🇺',
      'es': '🇪🇸',
      'sv': '🇸🇪',
      'te': '🇮🇳',
      'tr': '🇹🇷',
      'uk': '🇺🇦',
      'vi': '🇻🇳',
    };
    return flagMap[languageCode] ?? '🌐';
  }
}
