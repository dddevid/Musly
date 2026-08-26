import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:musly/l10n/app_localizations.dart';
import 'package:musly/providers/player_provider.dart';
import 'package:musly/services/replay_gain_service.dart';
import 'package:musly/services/auto_dj_service.dart';
import 'package:musly/services/transcoding_service.dart';
import 'package:musly/services/storage_service.dart';
import 'package:musly/services/fade_settings_service.dart';
import 'package:musly/services/subsonic_service.dart';
import 'package:musly/theme/app_theme.dart';
import 'package:musly/widgets/settings/settings_section_card.dart';
import 'package:musly/widgets/settings/settings_icon_badge.dart';
import 'package:musly/utils/context_extensions.dart';

import 'package:musly/services/crossfade_service.dart';

class SettingsPlaybackTab extends StatefulWidget {
  const SettingsPlaybackTab({super.key});

  @override
  State<SettingsPlaybackTab> createState() => _SettingsPlaybackTabState();
}

class _SettingsPlaybackTabState extends State<SettingsPlaybackTab> {
  final _replayGainService = ReplayGainService();
  final _fadeSettingsService = FadeSettingsService();
  final _crossfadeService = CrossfadeService();

  ReplayGainMode _replayGainMode = ReplayGainMode.off;
  double _replayGainPreamp = 0.0;
  bool _replayGainPreventClipping = true;
  double _replayGainFallback = -6.0;
  bool _lrcLibFallback = true;
  AutoDjMode _autoDjMode = AutoDjMode.off;
  int _autoDjSongsToAdd = 5;
  bool _fadeEnabled = false;
  int _fadeDurationMs = 300;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    await _replayGainService.initialize();
    await _fadeSettingsService.initialize();
    await _crossfadeService.initialize();

    final storageService = StorageService();
    final lrcLibFallback = await storageService.getLrcLibFallback();
    setState(() {
      _replayGainMode = _replayGainService.getMode();
      _replayGainPreamp = _replayGainService.getPreampGain();
      _replayGainPreventClipping = _replayGainService.getPreventClipping();
      _replayGainFallback = _replayGainService.getFallbackGain();
      _lrcLibFallback = lrcLibFallback;
      _autoDjMode = playerProvider.autoDjService.mode;
      _autoDjSongsToAdd = playerProvider.autoDjService.songsToAdd;
      _fadeEnabled = _fadeSettingsService.getFadeEnabled();
      _fadeDurationMs = _fadeSettingsService.getFadeDurationMs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isYoutube =
        Provider.of<SubsonicService>(context, listen: false).isYoutube;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        SettingsSectionCard(
          title: AppLocalizations.of(context)!.sectionAutoDj,
          children: [
            _buildAutoDjModeSelector(),
            if (_autoDjMode != AutoDjMode.off) ...[
              const SettingsDivider(),
              _buildAutoDjSongsSlider(),
            ],
          ],
        ),
        const SizedBox(height: 24),
        _buildCrossfadeSection(),
        const SizedBox(height: 24),
        _buildGaplessSection(),
        const SizedBox(height: 24),
        _buildFadeSection(),
        const SizedBox(height: 24),
        _buildLrcLibSection(),
        const SizedBox(height: 24),
        SettingsSectionCard(
          title: AppLocalizations.of(context)!.sectionVolumeNormalization,
          children: [
            _buildReplayGainModeSelector(),
            if (_replayGainMode != ReplayGainMode.off) ...[
              const SettingsDivider(),
              _buildReplayGainPreampSlider(),
              const SettingsDivider(),
              _buildReplayGainClippingToggle(),
              const SettingsDivider(),
              _buildReplayGainFallbackSlider(),
            ],
          ],
        ),
        if (!isYoutube) ...[
          const SizedBox(height: 24),
          _buildTranscodingSection(),
        ],
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildAutoDjModeSelector() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: SettingsIconBadge(
        gradientColors: const [Color(0xFFFF2D55), Color(0xFFFF6B6B)],
        icon: CupertinoIcons.wand_stars,
      ),
      title: Text(
        AppLocalizations.of(context)!.autoDjMode,
        style: const TextStyle(fontSize: 16),
      ),
      trailing: DropdownButton<AutoDjMode>(
        value: _autoDjMode,
        underline: const SizedBox(),
        items: AutoDjMode.values.map((mode) {
          return DropdownMenuItem(
            value: mode,
            child: Text(_getAutoDjModeLabel(mode)),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) _setAutoDjMode(value);
        },
      ),
    );
  }

  String _getAutoDjModeLabel(AutoDjMode mode) {
    return AutoDjService.getModeDisplayName(mode);
  }

  void _setAutoDjMode(AutoDjMode mode) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    playerProvider.autoDjService.setMode(mode);
    setState(() => _autoDjMode = mode);
  }

  Widget _buildAutoDjSongsSlider() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: SettingsIconBadge(
        gradientColors: const [Color(0xFF5856D6), Color(0xFF7B68EE)],
        icon: CupertinoIcons.music_note_list,
      ),
      title: Text(
        AppLocalizations.of(context)!.autoDjSongsToAdd(_autoDjSongsToAdd),
        style: const TextStyle(fontSize: 16),
      ),
      subtitle: Slider(
        value: _autoDjSongsToAdd.toDouble(),
        min: 1,
        max: 20,
        divisions: 19,
        activeColor: Theme.of(context).colorScheme.primary,
        onChanged: (value) {
          final count = value.round();
          final playerProvider = Provider.of<PlayerProvider>(
            context,
            listen: false,
          );
          playerProvider.autoDjService.setSongsToAdd(count);
          setState(() => _autoDjSongsToAdd = count);
        },
      ),
    );
  }

  Widget _buildReplayGainModeSelector() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: SettingsIconBadge(
        gradientColors: const [Color(0xFF34C759), Color(0xFF30D158)],
        icon: CupertinoIcons.speaker_2,
      ),
      title: Text(AppLocalizations.of(context)!.replayGainMode,
          style: const TextStyle(fontSize: 16)),
      trailing: DropdownButton<ReplayGainMode>(
        value: _replayGainMode,
        underline: const SizedBox(),
        items: ReplayGainMode.values.map((mode) {
          return DropdownMenuItem(
            value: mode,
            child: Text(_getReplayGainModeLabel(mode)),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) _setReplayGainMode(value);
        },
      ),
    );
  }

  String _getReplayGainModeLabel(ReplayGainMode mode) {
    final l10n = AppLocalizations.of(context)!;
    switch (mode) {
      case ReplayGainMode.off:
        return l10n.replayGainModeOff;
      case ReplayGainMode.track:
        return l10n.replayGainModeTrack;
      case ReplayGainMode.album:
        return l10n.replayGainModeAlbum;
    }
  }

  void _setReplayGainMode(ReplayGainMode mode) async {
    await _replayGainService.setMode(mode);
    setState(() => _replayGainMode = mode);
  }

  Widget _buildReplayGainPreampSlider() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(AppLocalizations.of(context)!
          .replayGainPreamp(_replayGainPreamp.toStringAsFixed(1))),
      subtitle: Slider(
        value: _replayGainPreamp,
        min: -12,
        max: 12,
        divisions: 24,
        activeColor: Theme.of(context).colorScheme.primary,
        onChanged: (value) async {
          await _replayGainService.setPreampGain(value);
          setState(() => _replayGainPreamp = value);
        },
      ),
    );
  }

  Widget _buildReplayGainClippingToggle() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(AppLocalizations.of(context)!.replayGainPreventClipping),
      trailing: CupertinoSwitch(
        value: _replayGainPreventClipping,
        activeTrackColor: Theme.of(context).colorScheme.primary,
        onChanged: (value) async {
          await _replayGainService.setPreventClipping(value);
          setState(() => _replayGainPreventClipping = value);
        },
      ),
    );
  }

  Widget _buildReplayGainFallbackSlider() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        AppLocalizations.of(context)!
            .replayGainFallbackGain(_replayGainFallback.toStringAsFixed(1)),
      ),
      subtitle: Slider(
        value: _replayGainFallback,
        min: -12,
        max: 0,
        divisions: 12,
        activeColor: Theme.of(context).colorScheme.primary,
        onChanged: (value) async {
          await _replayGainService.setFallbackGain(value);
          setState(() => _replayGainFallback = value);
        },
      ),
    );
  }

  Widget _buildLrcLibSection() {
    final accent = Theme.of(context).colorScheme.primary;
    final l10n = AppLocalizations.of(context)!;
    return SettingsSectionCard(
      title: l10n.sectionLyrics,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent, accent.withValues(alpha: 0.6)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              CupertinoIcons.text_quote,
              color: Colors.white,
              size: 18,
            ),
          ),
          title: Text(
            AppLocalizations.of(context)!.enableLrcLibFallback,
            style: const TextStyle(fontSize: 16),
          ),
          subtitle: Text(
            AppLocalizations.of(context)!.lrcLibFallbackSubtitle,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.5)
                  : Colors.black.withValues(alpha: 0.5),
            ),
          ),
          trailing: CupertinoSwitch(
            value: _lrcLibFallback,
            activeTrackColor: accent,
            onChanged: (v) async {
              final storage = StorageService();
              await storage.saveLrcLibFallback(v);
              setState(() => _lrcLibFallback = v);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCrossfadeSection() {
    final accent = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final crossfadeSec = _crossfadeService.getCrossfadeSeconds();

    return SettingsSectionCard(
      title: l10n.sectionSmartCrossfade,
      children: [
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [accent, accent.withValues(alpha: 0.6)]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(CupertinoIcons.slider_horizontal_below_rectangle,
                color: Colors.white, size: 18),
          ),
          title:
              Text(l10n.trackCrossfade, style: const TextStyle(fontSize: 16)),
          subtitle: Text(
            crossfadeSec == 0
                ? l10n.crossfadeOffSubtitle
                : l10n.crossfadeDurationSubtitle(crossfadeSec),
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.5)
                  : Colors.black.withValues(alpha: 0.5),
            ),
          ),
          trailing: Text(
            crossfadeSec == 0
                ? l10n.replayGainModeOff
                : l10n.crossfadeDurationBadge(crossfadeSec),
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: accent),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Slider(
                value: crossfadeSec.toDouble(),
                min: 0,
                max: 12,
                divisions: 12,
                activeColor: accent,
                onChanged: (value) async {
                  final sec = value.round();
                  await _crossfadeService.setCrossfadeSeconds(sec);
                  setState(() {});
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.replayGainModeOff,
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.black38)),
                  Text(l10n.crossfadeDurationBadge(6),
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.black38)),
                  Text(l10n.crossfadeDurationBadge(12),
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.black38)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGaplessSection() {
    return Consumer<PlayerProvider>(
      builder: (context, player, _) {
        final accent = Theme.of(context).colorScheme.primary;
        final l10n = AppLocalizations.of(context)!;
        return SettingsSectionCard(
          title: l10n.sectionGaplessPlayback,
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent, accent.withValues(alpha: 0.6)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.link,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              title: Text(
                l10n.gaplessPlayback,
                style: const TextStyle(fontSize: 16),
              ),
              subtitle: Text(
                l10n.gaplessPlaybackSubtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.5),
                ),
              ),
              trailing: CupertinoSwitch(
                value: player.gaplessEnabled,
                activeTrackColor: accent,
                onChanged: (_) => player.toggleGaplessPlayback(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFadeSection() {
    final l10n = AppLocalizations.of(context)!;
    return SettingsSectionCard(
      title: l10n.sectionFadeInOut,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              CupertinoIcons.waveform,
              color: Colors.white,
              size: 18,
            ),
          ),
          title: Text(
            l10n.fadeInOutEnable,
            style: const TextStyle(fontSize: 16),
          ),
          subtitle: Text(
            l10n.fadeInOutSubtitle,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.5)
                  : Colors.black.withValues(alpha: 0.5),
            ),
          ),
          trailing: CupertinoSwitch(
            value: _fadeEnabled,
            activeTrackColor: Theme.of(context).colorScheme.primary,
            onChanged: (v) async {
              await _fadeSettingsService.setFadeEnabled(v);
              setState(() => _fadeEnabled = v);
            },
          ),
        ),
        if (_fadeEnabled) ...[
          const SettingsDivider(),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            title: Text(
              l10n.fadeDuration(_fadeDurationMs),
              style: const TextStyle(fontSize: 16),
            ),
            subtitle: Slider(
              value: _fadeDurationMs.toDouble(),
              min: 100,
              max: 1000,
              divisions: 18,
              activeColor: Theme.of(context).colorScheme.primary,
              onChanged: (value) async {
                final duration = value.round();
                await _fadeSettingsService.setFadeDurationMs(duration);
                setState(() => _fadeDurationMs = duration);
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTranscodingSection() {
    return Consumer<TranscodingService>(
      builder: (context, ts, _) {
        final accent = Theme.of(context).colorScheme.primary;
        final secondaryText = context.isDark
            ? AppTheme.darkSecondaryText
            : AppTheme.lightSecondaryText;

        Widget connectionBadge() {
          final isWifi = ts.currentConnectionType == ConnectionType.wifi;
          final l10n = AppLocalizations.of(context)!;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (isWifi ? Colors.green : Colors.orange)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isWifi ? Icons.wifi_rounded : Icons.signal_cellular_alt,
                  size: 12,
                  color: isWifi ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  isWifi ? l10n.networkWifi : l10n.networkMobile,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isWifi ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
          );
        }

        return SettingsSectionCard(
          title: AppLocalizations.of(context)!.sectionStreamingQuality,
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              leading: SettingsIconBadge(
                gradientColors: const [Color(0xFFFF9500), Color(0xFFFF3B30)],
                icon: CupertinoIcons.waveform,
              ),
              title: Text(
                AppLocalizations.of(context)!.transcodingEnable,
                style: const TextStyle(fontSize: 16),
              ),
              subtitle: Text(
                AppLocalizations.of(context)!.transcodingEnableSubtitle,
                style: TextStyle(fontSize: 13, color: secondaryText),
              ),
              trailing: CupertinoSwitch(
                value: ts.enabled,
                activeTrackColor: accent,
                onChanged: (v) => ts.setEnabled(v),
              ),
            ),
            if (ts.enabled) ...[
              const SettingsDivider(),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent, accent.withValues(alpha: 0.6)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_fix_high_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                title: Text(
                  AppLocalizations.of(context)!.smartTranscoding,
                  style: const TextStyle(fontSize: 16),
                ),
                subtitle: Text(
                  AppLocalizations.of(context)!.smartTranscodingSubtitle,
                  style: TextStyle(fontSize: 13, color: secondaryText),
                ),
                trailing: CupertinoSwitch(
                  value: ts.smartEnabled,
                  activeTrackColor: accent,
                  onChanged: (v) => ts.setSmartEnabled(v),
                ),
              ),
              if (ts.smartEnabled)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          AppLocalizations.of(context)!
                              .smartTranscodingDetectedNetwork,
                          style: TextStyle(fontSize: 12, color: secondaryText),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      connectionBadge(),
                      const Spacer(),
                      Flexible(
                        child: Text(
                          AppLocalizations.of(context)!
                              .smartTranscodingActiveBitrate(
                            ts.getCurrentBitrate() != null
                                ? '${ts.getCurrentBitrate()} kbps'
                                : AppLocalizations.of(context)!
                                    .transcodingFormatOriginal,
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: secondaryText,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ),
              const SettingsDivider(),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: const Icon(Icons.wifi_rounded, size: 20),
                title:
                    Text(AppLocalizations.of(context)!.transcodingWifiQuality),
                subtitle: Text(
                  ts.smartEnabled
                      ? AppLocalizations.of(context)!
                          .transcodingWifiQualitySubtitleSmart
                      : AppLocalizations.of(context)!
                          .transcodingWifiQualitySubtitle,
                  style: TextStyle(fontSize: 12, color: secondaryText),
                ),
                trailing: DropdownButton<int>(
                  value: ts.wifiBitrate,
                  underline: const SizedBox(),
                  items: TranscodeBitrate.options.map((bitrate) {
                    final label = bitrate == TranscodeBitrate.original
                        ? AppLocalizations.of(context)!
                            .transcodingBitrateOriginal
                        : '$bitrate kbps';
                    return DropdownMenuItem(value: bitrate, child: Text(label));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) ts.setWifiBitrate(v);
                  },
                ),
              ),
              const SettingsDivider(),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: const Icon(
                  Icons.signal_cellular_alt_rounded,
                  size: 20,
                ),
                title: Text(
                    AppLocalizations.of(context)!.transcodingMobileQuality),
                subtitle: Text(
                  ts.smartEnabled
                      ? AppLocalizations.of(context)!
                          .transcodingMobileQualitySubtitleSmart
                      : AppLocalizations.of(context)!
                          .transcodingMobileQualitySubtitle,
                  style: TextStyle(fontSize: 12, color: secondaryText),
                ),
                trailing: DropdownButton<int>(
                  value: ts.mobileBitrate,
                  underline: const SizedBox(),
                  items: TranscodeBitrate.options.map((bitrate) {
                    final label = bitrate == TranscodeBitrate.original
                        ? AppLocalizations.of(context)!
                            .transcodingBitrateOriginal
                        : '$bitrate kbps';
                    return DropdownMenuItem(value: bitrate, child: Text(label));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) ts.setMobileBitrate(v);
                  },
                ),
              ),
              const SettingsDivider(),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: const Icon(Icons.audio_file_rounded, size: 20),
                title: Text(AppLocalizations.of(context)!.transcodingFormat),
                subtitle: Text(
                  AppLocalizations.of(context)!.transcodingFormatSubtitle,
                  style: TextStyle(fontSize: 12, color: secondaryText),
                ),
                trailing: DropdownButton<String>(
                  value: ts.format,
                  underline: const SizedBox(),
                  items: TranscodeFormat.options.map((format) {
                    final label = format == TranscodeFormat.original
                        ? AppLocalizations.of(context)!
                            .transcodingFormatOriginal
                        : format.toUpperCase();
                    return DropdownMenuItem(value: format, child: Text(label));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) ts.setFormat(v);
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
