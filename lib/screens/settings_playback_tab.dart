import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../services/replay_gain_service.dart';
import '../services/auto_dj_service.dart';
import '../services/transcoding_service.dart';
import '../theme/app_theme.dart';

class SettingsPlaybackTab extends StatefulWidget {
  const SettingsPlaybackTab({super.key});

  @override
  State<SettingsPlaybackTab> createState() => _SettingsPlaybackTabState();
}

class _SettingsPlaybackTabState extends State<SettingsPlaybackTab> {
  final _replayGainService = ReplayGainService();

  ReplayGainMode _replayGainMode = ReplayGainMode.off;
  double _replayGainPreamp = 0.0;
  bool _replayGainPreventClipping = true;
  double _replayGainFallback = -6.0;
  AutoDjMode _autoDjMode = AutoDjMode.off;
  int _autoDjSongsToAdd = 5;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _replayGainService.initialize();
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);

    setState(() {
      _replayGainMode = _replayGainService.getMode();
      _replayGainPreamp = _replayGainService.getPreampGain();
      _replayGainPreventClipping = _replayGainService.getPreventClipping();
      _replayGainFallback = _replayGainService.getFallbackGain();
      _autoDjMode = playerProvider.autoDjService.mode;
      _autoDjSongsToAdd = playerProvider.autoDjService.songsToAdd;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        _buildSection(
          title: 'AUTO DJ',
          children: [
            _buildAutoDjModeSelector(),
            if (_autoDjMode != AutoDjMode.off) ...[
              _buildDivider(),
              _buildAutoDjSongsSlider(),
            ],
          ],
        ),
        const SizedBox(height: 24),
        _buildSection(
          title: 'VOLUME NORMALIZATION (REPLAYGAIN)',
          children: [
            _buildReplayGainModeSelector(),
            if (_replayGainMode != ReplayGainMode.off) ...[
              _buildDivider(),
              _buildReplayGainPreampSlider(),
              _buildDivider(),
              _buildReplayGainClippingToggle(),
              _buildDivider(),
              _buildReplayGainFallbackSlider(),
            ],
          ],
        ),
        const SizedBox(height: 24),
        _buildTranscodingSection(),
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

  Widget _buildAutoDjModeSelector() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
          CupertinoIcons.wand_stars,
          color: Colors.white,
          size: 18,
        ),
      ),
      title: const Text('Auto DJ Mode', style: TextStyle(fontSize: 16)),
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
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5856D6), Color(0xFF7B68EE)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          CupertinoIcons.music_note_list,
          color: Colors.white,
          size: 18,
        ),
      ),
      title: Text(
        'Songs to Add: $_autoDjSongsToAdd',
        style: const TextStyle(fontSize: 16),
      ),
      subtitle: Slider(
        value: _autoDjSongsToAdd.toDouble(),
        min: 1,
        max: 20,
        divisions: 19,
        activeColor: AppTheme.appleMusicRed,
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
          CupertinoIcons.speaker_2,
          color: Colors.white,
          size: 18,
        ),
      ),
      title: const Text('Mode', style: TextStyle(fontSize: 16)),
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
    switch (mode) {
      case ReplayGainMode.off:
        return 'Off';
      case ReplayGainMode.track:
        return 'Track';
      case ReplayGainMode.album:
        return 'Album';
    }
  }

  void _setReplayGainMode(ReplayGainMode mode) async {
    await _replayGainService.setMode(mode);
    setState(() => _replayGainMode = mode);
  }

  Widget _buildReplayGainPreampSlider() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text('Preamp: ${_replayGainPreamp.toStringAsFixed(1)} dB'),
      subtitle: Slider(
        value: _replayGainPreamp,
        min: -12,
        max: 12,
        divisions: 24,
        activeColor: AppTheme.appleMusicRed,
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
      title: const Text('Prevent Clipping'),
      trailing: CupertinoSwitch(
        value: _replayGainPreventClipping,
        activeTrackColor: AppTheme.appleMusicRed,
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
        'Fallback Gain: ${_replayGainFallback.toStringAsFixed(1)} dB',
      ),
      subtitle: Slider(
        value: _replayGainFallback,
        min: -12,
        max: 0,
        divisions: 12,
        activeColor: AppTheme.appleMusicRed,
        onChanged: (value) async {
          await _replayGainService.setFallbackGain(value);
          setState(() => _replayGainFallback = value);
        },
      ),
    );
  }

  Widget _buildTranscodingSection() {
    return Consumer<TranscodingService>(
      builder: (context, transcodingService, _) {
        return _buildSection(
          title: 'STREAMING QUALITY',
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9500), Color(0xFFFF3B30)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.waveform,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              title: const Text(
                'Enable Transcoding',
                style: TextStyle(fontSize: 16),
              ),
              subtitle: Text(
                'Reduce data usage with lower quality',
                style: TextStyle(
                  fontSize: 13,
                  color: _isDark
                      ? AppTheme.darkSecondaryText
                      : AppTheme.lightSecondaryText,
                ),
              ),
              trailing: CupertinoSwitch(
                value: transcodingService.enabled,
                activeTrackColor: AppTheme.appleMusicRed,
                onChanged: (value) => transcodingService.setEnabled(value),
              ),
            ),
            if (transcodingService.enabled) ...[
              _buildDivider(),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                title: const Text('WiFi Quality'),
                trailing: DropdownButton<int>(
                  value: transcodingService.wifiBitrate,
                  underline: const SizedBox(),
                  items: TranscodeBitrate.options.map((bitrate) {
                    return DropdownMenuItem(
                      value: bitrate,
                      child: Text(TranscodeBitrate.getLabel(bitrate)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) transcodingService.setWifiBitrate(value);
                  },
                ),
              ),
              _buildDivider(),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                title: const Text('Mobile Quality'),
                trailing: DropdownButton<int>(
                  value: transcodingService.mobileBitrate,
                  underline: const SizedBox(),
                  items: TranscodeBitrate.options.map((bitrate) {
                    return DropdownMenuItem(
                      value: bitrate,
                      child: Text(TranscodeBitrate.getLabel(bitrate)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null)
                      transcodingService.setMobileBitrate(value);
                  },
                ),
              ),
              _buildDivider(),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                title: const Text('Format'),
                trailing: DropdownButton<String>(
                  value: transcodingService.format,
                  underline: const SizedBox(),
                  items: TranscodeFormat.options.map((format) {
                    return DropdownMenuItem(
                      value: format,
                      child: Text(TranscodeFormat.getLabel(format)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) transcodingService.setFormat(value);
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
