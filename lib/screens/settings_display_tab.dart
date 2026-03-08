import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import '../services/recommendation_service.dart';
import '../services/player_ui_settings_service.dart';
import '../services/theme_service.dart';
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
  double _albumArtCornerRadius = 8.0;
  String _artworkShape = 'rounded';
  String _artworkShadow = 'soft';
  String _artworkShadowColor = 'black';
  bool _liveSearch = true;

  ThemeMode _themeMode = ThemeMode.system;
  AccentColor _accentColor = AccentColor.red;
  bool _liquidGlass = false;

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

    if (!mounted) return;
    final themeService = Provider.of<ThemeService>(context, listen: false);

    setState(() {
      _showVolumeSlider = _playerUiSettings.getShowVolumeSlider();
      _showStarRatings = _playerUiSettings.getShowStarRatings();
      _albumArtCornerRadius = _playerUiSettings.getAlbumArtCornerRadius();
      _artworkShape = _playerUiSettings.getArtworkShape();
      _artworkShadow = _playerUiSettings.getArtworkShadow();
      _artworkShadowColor = _playerUiSettings.getArtworkShadowColor();
      _liveSearch = _playerUiSettings.getLiveSearch();
      _themeMode = themeService.themeMode;
      _accentColor = themeService.accentColor;
      _liquidGlass = themeService.liquidGlass;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        _buildSection(
          title: AppLocalizations.of(context)!.appearanceSection.toUpperCase(),
          children: [_buildAppearanceEditor()],
        ),
        const SizedBox(height: 24),
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
            if (_isDesktop) ...[
              _buildDivider(),
              _buildDiscordRpcToggle(),
              _buildDivider(),
              _buildDiscordRpcStateStyleSelector(),
            ],
          ],
        ),
        const SizedBox(height: 24),
        _buildSection(
          title: AppLocalizations.of(context)!.liveSearchSection.toUpperCase(),
          children: [
            _buildLiveSearchToggle(),
          ],
        ),
        const SizedBox(height: 24),
        _buildSection(
          title: AppLocalizations.of(
            context,
          )!.artworkStyleSection.toUpperCase(),
          children: [_buildArtworkStyleEditor()],
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

  Widget _buildAppearanceEditor() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = _isDark;

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

          ...[
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
        activeTrackColor: Theme.of(context).colorScheme.primary,
        onChanged: (value) async {
          setState(() => _showStarRatings = value);
          await _playerUiSettings.setShowStarRatings(value);
        },
      ),
    );
  }

  Widget _buildLiveSearchToggle() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF9500), Color(0xFFFFCC00)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          CupertinoIcons.search,
          color: Colors.white,
          size: 18,
        ),
      ),
      title: Text(
        AppLocalizations.of(context)!.liveSearch,
        style: const TextStyle(fontSize: 16),
      ),
      subtitle: Text(
        AppLocalizations.of(context)!.liveSearchSubtitle,
        style: TextStyle(
          fontSize: 13,
          color: _isDark
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

  double _artworkPreviewRadius() {
    if (_artworkShape == 'circle') return 9999.0;
    if (_artworkShape == 'square') return 0.0;
    return _albumArtCornerRadius;
  }

  List<BoxShadow>? _artworkPreviewShadow() {
    if (_artworkShadow == 'none') return null;
    const previewSize = 108.0;
    final Color color = _artworkShadowColor == 'accent'
        ? Theme.of(context).colorScheme.primary
        : Colors.black;
    double opacity;
    double blur;
    Offset offset;
    switch (_artworkShadow) {
      case 'medium':
        opacity = _isDark ? 0.35 : 0.25;
        blur = previewSize / 6;
        offset = Offset(0, previewSize / 20);
        break;
      case 'strong':
        opacity = _isDark ? 0.55 : 0.40;
        blur = previewSize / 4;
        offset = Offset(0, previewSize / 12);
        break;
      default: 
        opacity = _isDark ? 0.22 : 0.14;
        blur = previewSize / 10;
        offset = Offset(0, previewSize / 30);
    }
    return [
      BoxShadow(
        color: color.withValues(alpha: opacity),
        blurRadius: blur,
        offset: offset,
      ),
    ];
  }

  Widget _buildArtworkStyleEditor() {
    final l10n = AppLocalizations.of(context)!;
    const previewSize = 108.0;
    final radius = _artworkPreviewRadius();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Center(
            child: Column(
              children: [
                Text(
                  l10n.artworkPreview,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _isDark
                        ? AppTheme.darkSecondaryText
                        : AppTheme.lightSecondaryText,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 14),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  width: previewSize,
                  height: previewSize,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withAlpha(180),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(
                      radius.clamp(0.0, previewSize / 2),
                    ),
                    boxShadow: _artworkPreviewShadow(),
                  ),
                  child: const Icon(
                    Icons.music_note_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          _buildEditorRow(
            icon: Icons.crop_square_rounded,
            iconColor: const Color(0xFF5856D6),
            label: l10n.artworkShape,
            child: _buildChips(
              options: [
                (value: 'rounded', label: l10n.artworkShapeRounded),
                (value: 'circle', label: l10n.artworkShapeCircle),
                (value: 'square', label: l10n.artworkShapeSquare),
              ],
              selected: _artworkShape,
              onSelected: (v) {
                setState(() => _artworkShape = v);
                _playerUiSettings.setArtworkShape(v);
              },
            ),
          ),

          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: _artworkShape == 'rounded'
                ? Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildEditorRow(
                        icon: Icons.rounded_corner,
                        iconColor: const Color(0xFFFF9500),
                        label: l10n.artworkCornerRadius,
                        trailing: Text(
                          _albumArtCornerRadius.round() == 0
                              ? l10n.artworkCornerRadiusNone
                              : '${_albumArtCornerRadius.round()}px',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Theme.of(context).colorScheme.primary,
                            inactiveTrackColor: _isDark
                                ? AppTheme.darkDivider
                                : AppTheme.lightDivider,
                            thumbColor: Theme.of(context).colorScheme.primary,
                            overlayColor: Theme.of(context).colorScheme.primary.withValues(
                              alpha: 0.12,
                            ),
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 7,
                            ),
                          ),
                          child: Slider(
                            value: _albumArtCornerRadius,
                            min: 0,
                            max: 24,
                            divisions: 24,
                            onChanged: (v) {
                              setState(() => _albumArtCornerRadius = v);
                              _playerUiSettings.setAlbumArtCornerRadius(v);
                            },
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 16),

          _buildEditorRow(
            icon: Icons.blur_on_rounded,
            iconColor: const Color(0xFF34AADC),
            label: l10n.artworkShadow,
            child: _buildChips(
              options: [
                (value: 'none', label: l10n.artworkShadowNone),
                (value: 'soft', label: l10n.artworkShadowSoft),
                (value: 'medium', label: l10n.artworkShadowMedium),
                (value: 'strong', label: l10n.artworkShadowStrong),
              ],
              selected: _artworkShadow,
              onSelected: (v) {
                setState(() => _artworkShadow = v);
                _playerUiSettings.setArtworkShadow(v);
              },
            ),
          ),

          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: _artworkShadow != 'none'
                ? Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildEditorRow(
                        icon: Icons.palette_outlined,
                        iconColor: const Color(0xFFFF2D55),
                        label: l10n.artworkShadowColor,
                        child: _buildChips(
                          options: [
                            (
                              value: 'black',
                              label: l10n.artworkShadowColorBlack,
                            ),
                            (
                              value: 'accent',
                              label: l10n.artworkShadowColorAccent,
                            ),
                          ],
                          selected: _artworkShadowColor,
                          onSelected: (v) {
                            setState(() => _artworkShadowColor = v);
                            _playerUiSettings.setArtworkShadowColor(v);
                          },
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
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
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            if (trailing != null) ...[const Spacer(), trailing],
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildChips({
    required List<({String value, String label})> options,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = opt.value == selected;
        return GestureDetector(
          onTap: () => onSelected(opt.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : (_isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06)),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
              ),
            ),
            child: Text(
              opt.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (_isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ),
        );
      }).toList(),
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
              color: _isDark
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
              color: _isDark
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
            
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _isDark ? Colors.grey[600] : Colors.grey[300],
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
