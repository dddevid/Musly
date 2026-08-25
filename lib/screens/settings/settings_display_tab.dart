import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:musly/services/recommendation_service.dart';
import 'package:musly/services/player_ui_settings_service.dart';
import 'package:musly/services/theme_service.dart';
import 'package:musly/services/locale_service.dart';
import 'package:musly/providers/player_provider.dart';
import 'package:musly/theme/app_theme.dart';
import 'package:musly/l10n/app_localizations.dart';
import 'package:musly/services/subsonic_service.dart';
import 'package:musly/widgets/settings/settings_section_card.dart';
import 'package:musly/widgets/settings/settings_icon_badge.dart';
import 'package:musly/utils/context_extensions.dart';
import 'package:musly/services/storage_service.dart';
import 'package:window_manager/window_manager.dart';

class SettingsDisplayTab extends StatefulWidget {
  const SettingsDisplayTab({super.key});

  @override
  State<SettingsDisplayTab> createState() => _SettingsDisplayTabState();
}

class _SettingsDisplayTabState extends State<SettingsDisplayTab> {
  final _playerUiSettings = PlayerUiSettingsService();
  bool _showVolumeSlider = true;
  bool _showStarRatings = false;
  bool _showMiniPlayerHeart = false;
  bool _showMiniPlayerRepeat = false;
  bool _showMiniPlayerShuffle = false;
  bool _showLiveLyricUnderArtwork = false;
  bool _liveSearch = true;
  bool _lyricsBlurUnfocused = false;
  String _lyricsAlignment = 'left';
  bool _lyricsGlowEffect = true;
  bool _hideWindowTitlebar = false;

  ThemeMode _themeMode = ThemeMode.system;
  AccentColor _accentColor = AccentColor.red;
  bool _liquidGlass = false;

  bool get _isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _playerUiSettings.initialize();

    if (!mounted) return;
    final themeService = Provider.of<ThemeService>(context, listen: false);

    setState(() {
      _showVolumeSlider = _playerUiSettings.getShowVolumeSlider();
      _showStarRatings = _playerUiSettings.getShowStarRatings();
      _showMiniPlayerHeart = _playerUiSettings.getShowMiniPlayerHeart();
      _showMiniPlayerRepeat = _playerUiSettings.getShowMiniPlayerRepeat();
      _showMiniPlayerShuffle = _playerUiSettings.getShowMiniPlayerShuffle();
      _showLiveLyricUnderArtwork = _playerUiSettings.getShowLiveLyricUnderArtwork();
      _liveSearch = _playerUiSettings.getLiveSearch();
      _lyricsBlurUnfocused = _playerUiSettings.getLyricsBlurUnfocused();
      _lyricsAlignment = _playerUiSettings.getLyricsAlignment();
      _lyricsGlowEffect = _playerUiSettings.getLyricsGlowEffect();
      _themeMode = themeService.themeMode;
      _accentColor = themeService.accentColor;
      _liquidGlass = themeService.liquidGlass;
    });

    if (_isDesktop) {
      final hide = await StorageService().getHideWindowTitlebar();
      if (mounted) setState(() => _hideWindowTitlebar = hide);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isYoutube =
        Provider.of<SubsonicService>(context, listen: false).isYoutube;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        SettingsSectionCard(
          title: AppLocalizations.of(context)!.appearanceSection.toUpperCase(),
          children: [_buildAppearanceEditor()],
        ),
        const SizedBox(height: 24),
        SettingsSectionCard(
          title: AppLocalizations.of(context)!.language.toUpperCase(),
          children: [
            _buildLanguageSelector(),
            const SettingsDivider(),
            _buildOtaSyncTile(),
            const SettingsDivider(),
            _buildTranslationCredit(),
          ],
        ),
        const SizedBox(height: 24),
        SettingsSectionCard(
          title: AppLocalizations.of(context)!.playerInterface.toUpperCase(),
          children: [
            _buildVolumeSliderToggle(),
            if (!isYoutube) ...[
              const SettingsDivider(),
              _buildStarRatingsToggle(),
            ],
            const SettingsDivider(),
            _buildLiveLyricUnderArtworkToggle(),
            const SettingsDivider(),
            _buildMiniPlayerHeartToggle(),
            const SettingsDivider(),
            _buildMiniPlayerRepeatToggle(),
            const SettingsDivider(),
            _buildMiniPlayerShuffleToggle(),
            if (_isDesktop) ...[
              const SettingsDivider(),
              _buildDiscordRpcToggle(),
              const SettingsDivider(),
              _buildDiscordRpcStateStyleSelector(),
              const SettingsDivider(),
              _buildWindowTitlebarToggle(),
            ],
          ],
        ),

        const SizedBox(height: 24),
        SettingsSectionCard(
          title: AppLocalizations.of(context)!.liveSearchSection.toUpperCase(),
          children: [
            _buildLiveSearchToggle(),
          ],
        ),
        const SizedBox(height: 24),
        SettingsSectionCard(
          title: AppLocalizations.of(context)!.lyricsDisplaySection.toUpperCase(),
          children: [
            _buildLyricsBlurToggle(),
            const SettingsDivider(),
            _buildLyricsAlignmentSelector(),
            const SettingsDivider(),
            _buildLyricsGlowToggle(),
          ],
        ),
        const SizedBox(height: 24),
        SettingsSectionCard(
          title: AppLocalizations.of(
            context,
          )!.smartRecommendations.toUpperCase(),
          children: [
            _buildRecommendationsToggle(),
            const SettingsDivider(),
            _buildRecommendationsStats(),
            const SettingsDivider(),
            _buildClearRecommendationsButton(),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildAppearanceEditor() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = context.isDark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          _buildEditorRow(
            icon: CupertinoIcons.moon_stars_fill,
            iconColor: const Color(0xFF5856D6),
            label: AppLocalizations.of(context)!.themeLabel,
            child: _ThemeModeSelector(
              value: _themeMode,
              isDark: isDark,
              onChanged: (mode) async {
                setState(() => _themeMode = mode);
                await themeService.setThemeMode(mode);
              },
            ),
          ),

          const SizedBox(height: 20),

          _buildEditorRow(
            icon: Icons.palette_rounded,
            iconColor: const Color(0xFFFF9500),
            label: AppLocalizations.of(context)!.accentColorLabel,
            child: _AccentColorPicker(
              selected: _accentColor,
              onChanged: (color) async {
                setState(() => _accentColor = color);
                await themeService.setAccentColor(color);
              },
            ),
          ),

          if (!_isDesktop) ...[
            const SizedBox(height: 20),
            _buildEditorRow(
              icon: CupertinoIcons.sparkles,
              iconColor: const Color(0xFF64D2FF),
              label: AppLocalizations.of(context)!.circularDesignLabel,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.circularDesignSubtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppTheme.darkSecondaryText
                          : AppTheme.lightSecondaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Spacer(),
                      CupertinoSwitch(
                        value: _liquidGlass,
                        activeTrackColor: const Color(0xFF64D2FF),
                        onChanged: (value) async {
                          setState(() => _liquidGlass = value);
                          await themeService.setLiquidGlass(value);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVolumeSliderToggle() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: SettingsIconBadge(
        gradientColors: const [Color(0xFF007AFF), Color(0xFF5AC8FA)],
        icon: CupertinoIcons.speaker_2,
      ),
      title: Text(
        AppLocalizations.of(context)!.showVolumeSlider,
        style: const TextStyle(fontSize: 16),
      ),
      subtitle: Text(
        AppLocalizations.of(context)!.showVolumeSliderSubtitle,
        style: TextStyle(
          fontSize: 13,
          color: context.isDark
              ? AppTheme.darkSecondaryText
              : AppTheme.lightSecondaryText,
        ),
      ),
      trailing: CupertinoSwitch(
        value: _showVolumeSlider,
        activeTrackColor: Theme.of(context).colorScheme.primary,
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
      leading: SettingsIconBadge(
        gradientColors: const [Color(0xFFFFD700), Color(0xFFFFA500)],
        icon: CupertinoIcons.star_fill,
      ),
      title: Text(
        AppLocalizations.of(context)!.showStarRatings,
        style: const TextStyle(fontSize: 16),
      ),
      subtitle: Text(
        AppLocalizations.of(context)!.showStarRatingsSubtitle,
        style: TextStyle(
          fontSize: 13,
          color: context.isDark
              ? AppTheme.darkSecondaryText
              : AppTheme.lightSecondaryText,
        ),
      ),
      trailing: CupertinoSwitch(
        value: _showStarRatings,
        activeTrackColor: Theme.of(context).colorScheme.primary,
        onChanged: (value) async {
          setState(() => _showStarRatings = value);
          await _playerUiSettings.setShowStarRatings(value);
        },
      ),
    );
  }

  Widget _buildMiniPlayerHeartToggle() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: SettingsIconBadge(
        gradientColors: const [Color(0xFFFF2D55), Color(0xFFFF6B6B)],
        icon: CupertinoIcons.heart_fill,
      ),
      title: Text(
        AppLocalizations.of(context)!.showMiniPlayerHeart,
        style: const TextStyle(fontSize: 16),
      ),
      subtitle: Text(
        AppLocalizations.of(context)!.showMiniPlayerHeartSubtitle,
        style: TextStyle(
          fontSize: 13,
          color: context.isDark
              ? AppTheme.darkSecondaryText
              : AppTheme.lightSecondaryText,
        ),
      ),
      trailing: CupertinoSwitch(
        value: _showMiniPlayerHeart,
        activeTrackColor: Theme.of(context).colorScheme.primary,
        onChanged: (value) async {
          setState(() => _showMiniPlayerHeart = value);
          await _playerUiSettings.setShowMiniPlayerHeart(value);
        },
      ),
    );
  }

  Widget _buildMiniPlayerRepeatToggle() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: SettingsIconBadge(
        gradientColors: const [Color(0xFF34C759), Color(0xFF30D158)],
        icon: CupertinoIcons.repeat,
      ),
      title: Text(
        AppLocalizations.of(context)!.showMiniPlayerRepeat,
        style: const TextStyle(fontSize: 16),
      ),
      subtitle: Text(
        AppLocalizations.of(context)!.showMiniPlayerRepeatSubtitle,
        style: TextStyle(
          fontSize: 13,
          color: context.isDark
              ? AppTheme.darkSecondaryText
              : AppTheme.lightSecondaryText,
        ),
      ),
      trailing: CupertinoSwitch(
        value: _showMiniPlayerRepeat,
        activeTrackColor: Theme.of(context).colorScheme.primary,
        onChanged: (value) async {
          setState(() => _showMiniPlayerRepeat = value);
          await _playerUiSettings.setShowMiniPlayerRepeat(value);
        },
      ),
    );
  }

  Widget _buildMiniPlayerShuffleToggle() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: SettingsIconBadge(
        gradientColors: const [Color(0xFF5856D6), Color(0xFF7B68EE)],
        icon: CupertinoIcons.shuffle,
      ),
      title: Text(
        AppLocalizations.of(context)!.showMiniPlayerShuffle,
        style: const TextStyle(fontSize: 16),
      ),
      subtitle: Text(
        AppLocalizations.of(context)!.showMiniPlayerShuffleSubtitle,
        style: TextStyle(
          fontSize: 13,
          color: context.isDark
              ? AppTheme.darkSecondaryText
              : AppTheme.lightSecondaryText,
        ),
      ),
      trailing: CupertinoSwitch(
        value: _showMiniPlayerShuffle,
        activeTrackColor: Theme.of(context).colorScheme.primary,
        onChanged: (value) async {
          setState(() => _showMiniPlayerShuffle = value);
          await _playerUiSettings.setShowMiniPlayerShuffle(value);
        },
      ),
    );
  }



  Widget _buildLiveLyricUnderArtworkToggle() {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: SettingsIconBadge(
        gradientColors: const [Color(0xFF5856D6), Color(0xFFAF52DE)],
        icon: CupertinoIcons.quote_bubble_fill,
      ),
      title: Text(
        l10n.lyricsUnderArtwork,
        style: const TextStyle(fontSize: 16),
      ),
      subtitle: Text(
        l10n.lyricsUnderArtworkSubtitle,
        style: TextStyle(
          fontSize: 13,
          color: context.isDark
              ? AppTheme.darkSecondaryText
              : AppTheme.lightSecondaryText,
        ),
      ),
      trailing: CupertinoSwitch(
        value: _showLiveLyricUnderArtwork,
        activeTrackColor: Theme.of(context).colorScheme.primary,
        onChanged: (value) async {
          setState(() => _showLiveLyricUnderArtwork = value);
          await _playerUiSettings.setShowLiveLyricUnderArtwork(value);
        },
      ),
    );
  }

  Widget _buildLiveSearchToggle() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: SettingsIconBadge(
        gradientColors: const [Color(0xFFFF9500), Color(0xFFFFCC00)],
        icon: CupertinoIcons.search,
      ),
      title: Text(
        AppLocalizations.of(context)!.liveSearch,
        style: const TextStyle(fontSize: 16),
      ),
      subtitle: Text(
        AppLocalizations.of(context)!.liveSearchSubtitle,
        style: TextStyle(
          fontSize: 13,
          color: context.isDark
              ? AppTheme.darkSecondaryText
              : AppTheme.lightSecondaryText,
        ),
      ),
      trailing: CupertinoSwitch(
        value: _liveSearch,
        activeTrackColor: Theme.of(context).colorScheme.primary,
        onChanged: (value) async {
          setState(() => _liveSearch = value);
          await _playerUiSettings.setLiveSearch(value);
        },
      ),
    );
  }

  Widget _buildEditorRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Widget child,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trailing != null) ...[const Spacer(), trailing],
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
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
          leading: SettingsIconBadge(
        gradientColors: const [Color(0xFFFF2D55), Color(0xFFFF6B6B)],
        icon: CupertinoIcons.sparkles,
      ),
          title: Text(
            AppLocalizations.of(context)!.enableRecommendations,
            style: const TextStyle(fontSize: 16),
          ),
          subtitle: Text(
            AppLocalizations.of(context)!.enableRecommendationsSubtitle,
            style: TextStyle(
              fontSize: 13,
              color: context.isDark
                  ? AppTheme.darkSecondaryText
                  : AppTheme.lightSecondaryText,
            ),
          ),
          trailing: CupertinoSwitch(
            value: service.enabled,
            activeTrackColor: Theme.of(context).colorScheme.primary,
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
              color: context.isDark
                  ? AppTheme.darkSecondaryText
                  : AppTheme.lightSecondaryText,
            ),
          ),
          trailing: Text(
            AppLocalizations.of(context)!.songsCount(uniqueSongs),
            style: TextStyle(
              fontSize: 14,
              color: context.isDark
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
              color: const Color(0xFF5865F2), 
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
              color: context.isDark
                  ? AppTheme.darkSecondaryText
                  : AppTheme.lightSecondaryText,
            ),
          ),
          trailing: CupertinoSwitch(
            value: player.discordRpcEnabled,
            activeTrackColor: Theme.of(context).colorScheme.primary,
            onChanged: (value) async {
              await player.setDiscordRpcEnabled(value);
              
              setState(() {});
            },
          ),
        );
      },
    );
  }

  Widget _buildDiscordRpcStateStyleSelector() {
    final l10n = AppLocalizations.of(context)!;
    final styles = [
      ('artist', l10n.discordRpcStyleArtist),
      ('song_title', l10n.discordRpcStyleSong),
      ('app_name', l10n.discordRpcStyleApp),
    ];
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
              color: const Color(0xFF5865F2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              CupertinoIcons.text_bubble,
              color: Colors.white,
              size: 18,
            ),
          ),
          title: Text(l10n.discordStatusText, style: const TextStyle(fontSize: 16)),
          subtitle: Text(
            l10n.discordStatusTextSubtitle,
            style: TextStyle(
              fontSize: 13,
              color: context.isDark
                  ? AppTheme.darkSecondaryText
                  : AppTheme.lightSecondaryText,
            ),
          ),
          trailing: DropdownButton<String>(
            value: player.discordRpcStateStyle,
            underline: const SizedBox.shrink(),
            items: styles
                .map(
                  (s) => DropdownMenuItem(
                    value: s.$1,
                    child: Text(s.$2, style: const TextStyle(fontSize: 14)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) player.setDiscordRpcStateStyle(value);
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
          leading: SettingsIconBadge(
        gradientColors: const [Color(0xFF34C759), Color(0xFF30D158)],
        icon: CupertinoIcons.globe,
      ),
          title: Text(
            AppLocalizations.of(context)!.language,
            style: const TextStyle(fontSize: 16),
          ),
          subtitle: Text(
            currentLanguageName,
            style: TextStyle(
              fontSize: 13,
              color: context.isDark
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

  Widget _buildOtaSyncTile() {
    final localeService = Provider.of<LocaleService>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF34C759).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          CupertinoIcons.cloud_download,
          color: Color(0xFF34C759),
          size: 18,
        ),
      ),
      title: Text(
        l10n.checkTranslationUpdates,
        style: const TextStyle(fontSize: 16),
      ),
      subtitle: Text(
        l10n.checkTranslationUpdatesSubtitle,
        style: TextStyle(
          fontSize: 13,
          color: context.isDark
              ? AppTheme.darkSecondaryText
              : AppTheme.lightSecondaryText,
        ),
      ),
      trailing: const Icon(Icons.refresh_rounded, size: 20),
      onTap: () async {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.checkingTranslationUpdates),
            duration: const Duration(seconds: 1),
          ),
        );
        final updated = await localeService.syncOtaTranslations(force: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                updated
                    ? l10n.translationsUpdated
                    : l10n.translationsUpToDate,
              ),
              backgroundColor: updated ? const Color(0xFF34C759) : null,
            ),
          );
        }
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
          color: context.isDark
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
          color: context.isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.isDark ? Colors.grey[600] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
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
            
            ListTile(
              leading: const Icon(CupertinoIcons.device_phone_portrait),
              title: Text(AppLocalizations.of(context)!.systemDefault),
              trailing: localeService.currentLocale == null
                  ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () {
                localeService.setLocale(null);
                Navigator.pop(context);
              },
            ),
            const Divider(height: 1),
            
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
                        ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
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
    return LocaleService.getFlagEmoji(languageCode);
  }

  Widget _buildLyricsBlurToggle() {
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile.adaptive(
      title: Text(l10n.lyricsBlurUnfocused),
      subtitle: Text(l10n.lyricsBlurUnfocusedSubtitle),
      value: _lyricsBlurUnfocused,
      onChanged: (val) async {
        await _playerUiSettings.setLyricsBlurUnfocused(val);
        setState(() => _lyricsBlurUnfocused = val);
      },
    );
  }

  Widget _buildLyricsAlignmentSelector() {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      title: Text(l10n.lyricsAlignment),
      subtitle: Text(_lyricsAlignment == 'center' ? l10n.lyricsAlignmentCentered : l10n.lyricsAlignmentLeft),
      trailing: SegmentedButton<String>(
        segments: [
          ButtonSegment(value: 'left', label: Text(l10n.alignLeft), icon: const Icon(Icons.format_align_left, size: 16)),
          ButtonSegment(value: 'center', label: Text(l10n.alignCenter), icon: const Icon(Icons.format_align_center, size: 16)),
        ],
        selected: {_lyricsAlignment},
        onSelectionChanged: (val) async {
          final chosen = val.first;
          await _playerUiSettings.setLyricsAlignment(chosen);
          setState(() => _lyricsAlignment = chosen);
        },
      ),
    );
  }

  Widget _buildLyricsGlowToggle() {
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile.adaptive(
      title: Text(l10n.lyricsGlowEffect),
      subtitle: Text(l10n.lyricsGlowEffectSubtitle),
      value: _lyricsGlowEffect,
      onChanged: (val) async {
        await _playerUiSettings.setLyricsGlowEffect(val);
        setState(() => _lyricsGlowEffect = val);
      },
    );
  }

  Widget _buildWindowTitlebarToggle() {
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile.adaptive(
      title: Text(l10n.hideWindowTitlebar),
      subtitle: Text(l10n.hideWindowTitlebarSubtitle),
      value: _hideWindowTitlebar,
      onChanged: (val) async {
        await StorageService().saveHideWindowTitlebar(val);
        setState(() => _hideWindowTitlebar = val);
        if (_isDesktop) {
          try {
            await windowManager.setTitleBarStyle(val ? TitleBarStyle.hidden : TitleBarStyle.normal);
          } catch (_) {}
        }
      },
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector({
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  final ThemeMode value;
  final bool isDark;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = [
      (mode: ThemeMode.system, label: AppLocalizations.of(context)!.themeModeSystem, icon: CupertinoIcons.device_phone_portrait),
      (mode: ThemeMode.light, label: AppLocalizations.of(context)!.themeModeLight, icon: CupertinoIcons.sun_max_fill),
      (mode: ThemeMode.dark, label: AppLocalizations.of(context)!.themeModeDark, icon: CupertinoIcons.moon_fill),
    ];

    final accent = Theme.of(context).colorScheme.primary;

    return Row(
      children: options.map((opt) {
        final selected = value == opt.mode;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(opt.mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? accent
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    opt.icon,
                    size: 18,
                    color: selected
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    opt.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AccentColorPicker extends StatelessWidget {
  const _AccentColorPicker({
    required this.selected,
    required this.onChanged,
  });

  final AccentColor selected;
  final ValueChanged<AccentColor> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: AccentColor.values.map((color) {
        final isSelected = selected == color;
        return GestureDetector(
          onTap: () => onChanged(color),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.color.withValues(alpha: 0.6),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
