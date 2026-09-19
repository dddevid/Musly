import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:musly/services/android_auto_settings_service.dart';
import 'package:musly/services/storage_service.dart';
import 'package:musly/models/server_config.dart';
import 'package:musly/widgets/settings/settings_section_card.dart';
import 'package:musly/widgets/settings/settings_switch_tile.dart';
import 'package:musly/widgets/settings/settings_list_tile.dart';
import 'package:musly/l10n/app_localizations.dart';

class SettingsAndroidAutoTab extends StatefulWidget {
  const SettingsAndroidAutoTab({super.key});

  @override
  State<SettingsAndroidAutoTab> createState() => _SettingsAndroidAutoTabState();
}

class _SettingsAndroidAutoTabState extends State<SettingsAndroidAutoTab> {
  final _settings = AndroidAutoSettingsService();
  final _storage = StorageService();

  bool _showRecent = true;
  bool _showFavorites = true;
  bool _showAlbums = true;
  bool _showArtists = true;
  bool _showPlaylists = true;
  bool _showGenres = true;
  bool _showRadio = true;
  bool _showDownloads = true;
  int _maxItems = 100;
  String? _selectedServerId;
  List<ServerConfig> _profiles = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _settings.initialize();
    final profiles = await _storage.getSavedProfiles();
    if (mounted) {
      setState(() {
        _showRecent = _settings.getShowRecent();
        _showFavorites = _settings.getShowFavorites();
        _showAlbums = _settings.getShowAlbums();
        _showArtists = _settings.getShowArtists();
        _showPlaylists = _settings.getShowPlaylists();
        _showGenres = _settings.getShowGenres();
        _showRadio = _settings.getShowRadio();
        _showDownloads = _settings.getShowDownloads();
        _maxItems = _settings.getMaxItems();
        _selectedServerId = _settings.getServerId();
        _profiles = profiles;
      });
    }
  }

  String _getServerId(ServerConfig config) {
    return '${config.serverFamily}_${config.serverUrl}_${config.username}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return Center(
        child: Text(l10n.androidAutoNotSupported),
      );
    }
    
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        SettingsSectionCard(
          title: 'Server',
          children: [
            SettingsListTile(
              title: l10n.androidAutoDefaultServer,
              subtitle: l10n.androidAutoDefaultServerDesc,
              icon: CupertinoIcons.cloud,
              gradientColors: const [Color(0xFF34C759), Color(0xFF30D158)],
              trailing: Container(
                constraints: const BoxConstraints(maxWidth: 180),
                child: DropdownButton<String?>(
                  isExpanded: true,
                  value: _profiles.any((p) => _getServerId(p) == _selectedServerId) ? _selectedServerId : null,
                  underline: const SizedBox(),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(
                        l10n.androidAutoUseActiveServer,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ..._profiles.map((p) {
                      return DropdownMenuItem<String?>(
                        value: _getServerId(p),
                        child: Text(
                          p.displayServerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: (String? newValue) async {
                    await _settings.setServerId(newValue);
                    setState(() => _selectedServerId = newValue);
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SettingsSectionCard(
          title: l10n.androidAutoCategories,
          children: [
            SettingsSwitchTile(
              title: l10n.androidAutoShowRecent,
              icon: CupertinoIcons.clock,
              gradientColors: const [Color(0xFF007AFF), Color(0xFF5AC8FA)],
              value: _showRecent,
              onChanged: (val) async {
                await _settings.setShowRecent(val);
                setState(() => _showRecent = val);
              },
            ),
            const SettingsDivider(),
            SettingsSwitchTile(
              title: l10n.androidAutoShowFavorites,
              icon: CupertinoIcons.heart_fill,
              gradientColors: const [Color(0xFFFF2D55), Color(0xFFFF375F)],
              value: _showFavorites,
              onChanged: (val) async {
                await _settings.setShowFavorites(val);
                setState(() => _showFavorites = val);
              },
            ),
            const SettingsDivider(),
            SettingsSwitchTile(
              title: l10n.androidAutoShowAlbums,
              icon: CupertinoIcons.square_stack_3d_up,
              gradientColors: const [Color(0xFFAF52DE), Color(0xFFBF5AF2)],
              value: _showAlbums,
              onChanged: (val) async {
                await _settings.setShowAlbums(val);
                setState(() => _showAlbums = val);
              },
            ),
            const SettingsDivider(),
            SettingsSwitchTile(
              title: l10n.androidAutoShowArtists,
              icon: CupertinoIcons.person_2_fill,
              gradientColors: const [Color(0xFFFF9500), Color(0xFFFF9F0A)],
              value: _showArtists,
              onChanged: (val) async {
                await _settings.setShowArtists(val);
                setState(() => _showArtists = val);
              },
            ),
            const SettingsDivider(),
            SettingsSwitchTile(
              title: l10n.androidAutoShowPlaylists,
              icon: CupertinoIcons.music_note_list,
              gradientColors: const [Color(0xFF34C759), Color(0xFF30D158)],
              value: _showPlaylists,
              onChanged: (val) async {
                await _settings.setShowPlaylists(val);
                setState(() => _showPlaylists = val);
              },
            ),
            const SettingsDivider(),
            SettingsSwitchTile(
              title: l10n.androidAutoShowGenres,
              icon: CupertinoIcons.guitars,
              gradientColors: const [Color(0xFFFFCC00), Color(0xFFFFD60A)],
              value: _showGenres,
              onChanged: (val) async {
                await _settings.setShowGenres(val);
                setState(() => _showGenres = val);
              },
            ),
            const SettingsDivider(),
            SettingsSwitchTile(
              title: l10n.androidAutoShowRadio,
              icon: CupertinoIcons.radiowaves_right,
              gradientColors: const [Color(0xFF5856D6), Color(0xFF5E5CE6)],
              value: _showRadio,
              onChanged: (val) async {
                await _settings.setShowRadio(val);
                setState(() => _showRadio = val);
              },
            ),
            const SettingsDivider(),
            SettingsSwitchTile(
              title: l10n.androidAutoShowDownloads,
              icon: CupertinoIcons.cloud_download,
              gradientColors: const [Color(0xFF32ADE6), Color(0xFF64D2FF)],
              value: _showDownloads,
              onChanged: (val) async {
                await _settings.setShowDownloads(val);
                setState(() => _showDownloads = val);
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        SettingsSectionCard(
          title: l10n.androidAutoPerformance,
          children: [
            SettingsListTile(
              title: l10n.androidAutoMaxItems,
              subtitle: l10n.androidAutoMaxItemsDesc,
              icon: CupertinoIcons.speedometer,
              gradientColors: const [Color(0xFFFF3B30), Color(0xFFFF453A)],
              trailing: DropdownButton<int>(
                value: _maxItems,
                underline: const SizedBox(),
                items: [20, 50, 100, 200, 500].map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text(value.toString()),
                  );
                }).toList(),
                onChanged: (int? newValue) async {
                  if (newValue != null) {
                    await _settings.setMaxItems(newValue);
                    setState(() => _maxItems = newValue);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
