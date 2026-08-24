import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:musly/l10n/app_localizations.dart';
import 'package:musly/providers/library_provider.dart';
import 'package:musly/services/subsonic_service.dart';
import 'package:musly/services/bpm_analyzer_service.dart';
import 'package:musly/services/cache_settings_service.dart';
import 'package:musly/services/local_music_service.dart';
import 'package:musly/services/offline_service.dart';
import 'package:musly/theme/app_theme.dart';
import 'package:musly/screens/media/download_playlist_status_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:musly/widgets/settings/settings_section_card.dart';
import 'package:musly/widgets/settings/settings_icon_badge.dart';
import 'package:musly/utils/context_extensions.dart';

class SettingsStorageTab extends StatefulWidget {
  const SettingsStorageTab({super.key});

  @override
  State<SettingsStorageTab> createState() => _SettingsStorageTabState();
}

class _SettingsStorageTabState extends State<SettingsStorageTab> {
  final _bpmAnalyzer = BpmAnalyzerService();
  final _cacheSettings = CacheSettingsService();
  final _offlineService = OfflineService();

  bool _imageCacheEnabled = true;
  bool _musicCacheEnabled = true;
  bool _bpmCacheEnabled = true;
  final bool _isCaching = false;
  final int _currentProgress = 0;
  final int _totalSongs = 0;
  int _downloadedCount = 0;
  String _downloadedSize = '0 B';
  String _audioCacheSize = '0 B';
  String _imageCacheSize = '0 B';
  String _totalCacheSize = '0 B';
  int _parallelDownloads = 3;
  bool _keepScreenOn = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _setupDownloadListener();
  }

  @override
  void dispose() {
    _offlineService.downloadState.removeListener(_onDownloadStateChanged);
    super.dispose();
  }

  void _setupDownloadListener() {
    _offlineService.downloadState.addListener(_onDownloadStateChanged);
  }

  void _onDownloadStateChanged() {
    if (!mounted) return;
    final state = _offlineService.downloadState.value;
    setState(() {
      _downloadedCount = state.downloadedCount;
    });
  }

  Future<void> _loadSettings() async {
    await _cacheSettings.initialize();
    await _offlineService.initialize();
    await _loadOfflineInfo();
    await _loadCacheInfo();

    setState(() {
      _imageCacheEnabled = _cacheSettings.getImageCacheEnabled();
      _musicCacheEnabled = _cacheSettings.getMusicCacheEnabled();
      _bpmCacheEnabled = _cacheSettings.getBpmCacheEnabled();
      _parallelDownloads = _offlineService.getParallelDownloadsCount();
      _keepScreenOn = _offlineService.getKeepScreenOn();
    });
  }

  Future<void> _loadCacheInfo() async {
    final audioBytes = await _cacheSettings.getAudioCacheSizeBytes();
    final imageBytes = await _cacheSettings.getImageCacheSizeBytes();
    final totalBytes = audioBytes + imageBytes;
    if (mounted) {
      setState(() {
        _audioCacheSize = _cacheSettings.formatBytes(audioBytes);
        _imageCacheSize = _cacheSettings.formatBytes(imageBytes);
        _totalCacheSize = _cacheSettings.formatBytes(totalBytes);
      });
    }
  }

  Future<void> _loadOfflineInfo() async {
    final count = _offlineService.getDownloadedCount();
    final size = await _offlineService.getDownloadedSize();
    if (mounted) {
      setState(() {
        _downloadedCount = count;
        _downloadedSize = _offlineService.formatSize(size);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isYoutube = Provider.of<SubsonicService>(context, listen: false).isYoutube;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        SettingsSectionCard(
          title: AppLocalizations.of(context)!.sectionCacheSettings,
          children: [
            _buildCacheToggle(
              icon: CupertinoIcons.photo,
              iconGradient: const [Color(0xFFFF3B30), Color(0xFFFF453A)],
              title: AppLocalizations.of(context)!.imageCacheTitle,
              subtitle: AppLocalizations.of(context)!.imageCacheSubtitle,
              value: _imageCacheEnabled,
              onChanged: _toggleImageCache,
            ),
            const SettingsDivider(),
            _buildCacheToggle(
              icon: CupertinoIcons.music_note,
              iconGradient: const [Color(0xFF34C759), Color(0xFF30D158)],
              title: AppLocalizations.of(context)!.musicCacheTitle,
              subtitle: AppLocalizations.of(context)!.musicCacheSubtitle,
              value: _musicCacheEnabled,
              onChanged: _toggleMusicCache,
            ),
            const SettingsDivider(),
            _buildCacheToggle(
              icon: CupertinoIcons.speedometer,
              iconGradient: const [Color(0xFF5856D6), Color(0xFF7B68EE)],
              title: AppLocalizations.of(context)!.bpmCacheTitle,
              subtitle: AppLocalizations.of(context)!.bpmCacheSubtitle,
              value: _bpmCacheEnabled,
              onChanged: _toggleBpmCache,
            ),
          ],
        ),
        const SizedBox(height: 24),
        SettingsSectionCard(
          title: AppLocalizations.of(context)!.sectionCacheCleanup,
          children: [
            _buildAudioCacheRow(),
            const SettingsDivider(),
            _buildImageCacheRow(),
            const SettingsDivider(),
            _buildClearAllCacheButton(),
          ],
        ),
        const SizedBox(height: 24),
        SettingsSectionCard(
          title: AppLocalizations.of(context)!.sectionOfflineDownloads,
          children: [
            _buildDownloadLocationTile(),
            const SettingsDivider(),
            _buildParallelDownloadsTile(),
            const SettingsDivider(),
            _buildKeepScreenOnTile(),
            const SettingsDivider(),
            _buildOfflineInfo(),
            const SettingsDivider(),
            _buildActiveDownloadsRow(),
            const SettingsDivider(),
            _buildPlaylistStatusRow(),
            if (!isYoutube) ...[
              const SettingsDivider(),
              _buildDownloadAllLibraryButton(),
            ],
            const SettingsDivider(),
            _buildDeleteDownloadsButton(),
          ],
        ),
        const SizedBox(height: 24),
        _buildLocalMusicSection(),
        const SizedBox(height: 24),
        SettingsSectionCard(
          title: AppLocalizations.of(context)!.sectionBpmAnalysis,
          children: [
            _buildBPMCacheInfo(),
            if (_isCaching) _buildCachingProgress(),
            if (!isYoutube) _buildCacheAllButton(),
            _buildClearCacheButton(),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildCacheToggle({
    required IconData icon,
    required List<Color> iconGradient,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: iconGradient),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: context.isDark
              ? AppTheme.darkSecondaryText
              : AppTheme.lightSecondaryText,
        ),
      ),
      trailing: CupertinoSwitch(
        value: value,
        activeTrackColor: Theme.of(context).colorScheme.primary,
        onChanged: onChanged,
      ),
    );
  }

  void _toggleImageCache(bool value) async {
    setState(() => _imageCacheEnabled = value);
    await _cacheSettings.setImageCacheEnabled(value);
    if (!value) await DefaultCacheManager().emptyCache();
  }

  void _toggleMusicCache(bool value) async {
    setState(() => _musicCacheEnabled = value);
    await _cacheSettings.setMusicCacheEnabled(value);
  }

  void _toggleBpmCache(bool value) async {
    setState(() => _bpmCacheEnabled = value);
    await _cacheSettings.setBpmCacheEnabled(value);
    if (!value) await _bpmAnalyzer.clearCache();
  }

  Widget _buildLocalMusicSection() {
    return Consumer<LocalMusicService>(
      builder: (context, localMusic, _) {
        final l10n = AppLocalizations.of(context)!;
        final customPaths = localMusic.customScanPaths;

        return SettingsSectionCard(
          title: l10n.localMusicLibrary,
          children: [
            // Merge toggle
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              secondary: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(CupertinoIcons.music_albums, color: Colors.white, size: 18),
              ),
              title: Text(l10n.mergeLocalLibrary, style: const TextStyle(fontSize: 16)),
              subtitle: Text(
                l10n.mergeLocalLibrarySubtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: context.isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
                ),
              ),
              value: context.watch<LibraryProvider>().mergeLocalLibrary,
              onChanged: (value) {
                final libraryProvider = context.read<LibraryProvider>();
                if (value) {
                  // Enable merge mode
                  libraryProvider.setLocalMusicService(localMusic, mergeWithServer: true);
                } else {
                  // Disable merge mode
                  libraryProvider.setMergeLocalLibrary(false);
                }
              },
            ),
            const SettingsDivider(),
            // Local music stats
            ListTile(
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
                child: const Icon(CupertinoIcons.music_note, color: Colors.white, size: 18),
              ),
              title: Text(l10n.localMusicStats, style: const TextStyle(fontSize: 16)),
              trailing: Text(
                '${localMusic.songCount} ${l10n.songs.toLowerCase()}',
                style: TextStyle(
                  fontSize: 14,
                  color: context.isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
                ),
              ),
              subtitle: localMusic.isScanning
                ? Text(localMusic.scanStatus, style: const TextStyle(fontSize: 12))
                : null,
            ),
            const SettingsDivider(),
            // Add folder button
            ListTile(
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
                child: const Icon(CupertinoIcons.plus, color: Colors.white, size: 18),
              ),
              title: Text(l10n.addMusicFolder, style: const TextStyle(fontSize: 16)),
              onTap: () => _addMusicFolder(context, localMusic),
            ),
            // Show custom paths
            if (customPaths.isNotEmpty) ...[
              const SettingsDivider(),
              ...customPaths.map((path) => ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9500), Color(0xFFFFB340)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(CupertinoIcons.folder_fill, color: Colors.white, size: 18),
                ),
                title: Text(
                  path.split('/').last,
                  style: const TextStyle(fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  path,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(CupertinoIcons.delete, color: Colors.red, size: 20),
                  onPressed: () => _removeMusicFolder(context, localMusic, path),
                ),
              )),
            ],
            const SettingsDivider(),
            // Rescan button
            ListTile(
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
                child: const Icon(CupertinoIcons.refresh, color: Colors.white, size: 18),
              ),
              title: Text(l10n.rescanLocalMusic, style: const TextStyle(fontSize: 16)),
              enabled: !localMusic.isScanning,
              onTap: () => _rescanLocalMusic(context, localMusic),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addMusicFolder(BuildContext context, LocalMusicService service) async {
    final path = await service.pickMusicDirectory();
    if (path == null) return;
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added folder: $path')),
    );
    // Trigger a rescan if merge mode is enabled
    final libraryProvider = context.read<LibraryProvider>();
    if (libraryProvider.mergeLocalLibrary) {
      service.scanForMusic();
    }
  }

  Future<void> _removeMusicFolder(BuildContext context, LocalMusicService service, String path) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Folder'),
        content: Text('Remove "$path" from scan paths?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await service.removeCustomScanPath(path);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Folder removed')),
    );
  }

  Widget _buildKeepScreenOnTile() {
    final l10n = AppLocalizations.of(context)!;
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
        child: const Icon(CupertinoIcons.bolt_fill, color: Colors.white, size: 18),
      ),
      title: Text(l10n.keepScreenOnDuringDownload, style: const TextStyle(fontSize: 16)),
      subtitle: Text(
        l10n.keepScreenOnDuringDownloadSubtitle,
        style: TextStyle(
          fontSize: 13,
          color: context.isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
        ),
      ),
      trailing: CupertinoSwitch(
        value: _keepScreenOn,
        activeTrackColor: Theme.of(context).colorScheme.primary,
        onChanged: (value) async {
          setState(() => _keepScreenOn = value);
          await _offlineService.setKeepScreenOn(value);
        },
      ),
    );
  }

  Widget _buildParallelDownloadsTile() {
    final l10n = AppLocalizations.of(context)!;
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
        child: const Icon(CupertinoIcons.arrow_down_to_line, color: Colors.white, size: 18),
      ),
      title: Text(l10n.parallelDownloads, style: const TextStyle(fontSize: 16)),
      subtitle: Text(
        l10n.parallelDownloadsSubtitle,
        style: TextStyle(
          fontSize: 13,
          color: context.isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$_parallelDownloads',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            CupertinoIcons.chevron_right,
            size: 16,
            color: context.isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
          ),
        ],
      ),
      onTap: _showParallelDownloadsDialog,
    );
  }

  Widget _buildDownloadLocationTile() {
    final customPath = _offlineService.getCustomDownloadPath();
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: const SettingsIconBadge(
        icon: CupertinoIcons.folder_badge_plus,
        gradientColors: [Color(0xFF007AFF), Color(0xFF00C6FF)],
      ),
      title: const Text('Cartella di Download', style: TextStyle(fontSize: 16)),
      subtitle: Text(
        customPath != null && customPath.isNotEmpty ? customPath : 'Predefinita (Memoria interna)',
        style: TextStyle(
          fontSize: 12,
          color: context.isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (customPath != null && customPath.isNotEmpty)
            IconButton(
              icon: const Icon(CupertinoIcons.clear_circled, size: 20),
              onPressed: () async {
                await _offlineService.setCustomDownloadPath(null);
                if (mounted) setState(() {});
              },
            ),
          Icon(
            CupertinoIcons.chevron_right,
            size: 16,
            color: context.isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
          ),
        ],
      ),
      onTap: _pickCustomDownloadDirectory,
    );
  }

  Future<void> _pickCustomDownloadDirectory() async {
    try {
      final selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory != null && selectedDirectory.isNotEmpty) {
        await _offlineService.setCustomDownloadPath(selectedDirectory);
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint('Error picking download folder: $e');
    }
  }

  Future<void> _showParallelDownloadsDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.parallelDownloads),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [1, 2, 3, 4, 5].map((count) {
            final isSelected = count == _parallelDownloads;
            return ListTile(
              title: Text('$count ${count == 1 ? l10n.downloadSingular : l10n.downloadPlural}'),
              subtitle: count == 1
                ? Text(l10n.slowerButStable)
                : count == 5
                  ? Text(l10n.fasterButMoreData)
                  : null,
              leading: Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? Theme.of(context).colorScheme.primary : null,
              ),
              onTap: () => Navigator.pop(context, count),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );

    if (selected != null && selected != _parallelDownloads) {
      await _offlineService.setParallelDownloadsCount(selected);
      setState(() {
        _parallelDownloads = selected;
      });
    }
  }

  Future<void> _rescanLocalMusic(BuildContext context, LocalMusicService service) async {
    if (service.isScanning) return;

    // Request permission first
    final hasPermission = await service.requestPermission();
    if (!hasPermission) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission required')),
        );
      }
      return;
    }

    await service.scanForMusic();
  }

  Widget _buildAudioCacheRow() {
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
          CupertinoIcons.music_note,
          color: Colors.white,
          size: 16,
        ),
      ),
      title: const Text('Cache Brani e Stream', style: TextStyle(fontSize: 16)),
      subtitle: Text(
        '$_audioCacheSize occupati su disco',
        style: TextStyle(
          fontSize: 13,
          color: context.isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(CupertinoIcons.trash, size: 20, color: Color(0xFFFF3B30)),
        tooltip: 'Svuota cache brani',
        onPressed: _clearAudioCache,
      ),
    );
  }

  Widget _buildImageCacheRow() {
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
          CupertinoIcons.photo,
          color: Colors.white,
          size: 16,
        ),
      ),
      title: const Text('Cache Copertine e Immagini', style: TextStyle(fontSize: 16)),
      subtitle: Text(
        '$_imageCacheSize occupati su disco',
        style: TextStyle(
          fontSize: 13,
          color: context.isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(CupertinoIcons.trash, size: 20, color: Color(0xFFFF3B30)),
        tooltip: 'Svuota cache immagini',
        onPressed: _clearImageCache,
      ),
    );
  }

  Widget _buildClearAllCacheButton() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF3B30), Color(0xFFFF453A)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          CupertinoIcons.trash_fill,
          color: Colors.white,
          size: 16,
        ),
      ),
      title: Text(
        AppLocalizations.of(context)!.clearAllCache,
        style: const TextStyle(fontSize: 16, color: Color(0xFFFF3B30)),
      ),
      subtitle: Text(
        'Totale cache: $_totalCacheSize',
        style: TextStyle(
          fontSize: 13,
          color: context.isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
        ),
      ),
      onTap: _clearAllCache,
    );
  }

  void _clearAudioCache() async {
    await _cacheSettings.clearAudioCache();
    await _loadCacheInfo();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cache brani svuotata')),
      );
    }
  }

  void _clearImageCache() async {
    await _cacheSettings.clearImageCache();
    await _loadCacheInfo();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cache copertine svuotata')),
      );
    }
  }

  void _clearAllCache() async {
    await _cacheSettings.clearAllCache();
    await _loadCacheInfo();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.allCacheCleared)),
      );
    }
  }

  Widget _buildOfflineInfo() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: SettingsIconBadge(
        gradientColors: const [Color(0xFF007AFF), Color(0xFF5AC8FA)],
        icon: CupertinoIcons.arrow_down_circle,
      ),
      title: Text(
        AppLocalizations.of(context)!.downloadedSongs,
        style: const TextStyle(fontSize: 16),
      ),
      trailing: Text(
        AppLocalizations.of(
          context,
        )!.downloadedStats(_downloadedCount, _downloadedSize),
        style: TextStyle(
          fontSize: 14,
          color: context.isDark
              ? AppTheme.darkSecondaryText
              : AppTheme.lightSecondaryText,
        ),
      ),
    );
  }

  Widget _buildActiveDownloadsRow() {
    return ValueListenableBuilder<DownloadState>(
      valueListenable: _offlineService.downloadState,
      builder: (context, state, _) {
        final subtitle = state.isDownloading && state.currentSong != null
            ? '${state.currentSong!.artist ?? ''} – ${state.currentSong!.title}  (${state.currentProgress}/${state.totalCount})'
            : state.isDownloading
                ? '${state.currentProgress}/${state.totalCount}'
                : 'No downloads in progress';
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: state.isDownloading
                    ? const [Color(0xFF34C759), Color(0xFF30D158)]
                    : const [Color(0xFF8E8E93), Color(0xFFAEAEB2)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              state.isDownloading
                  ? CupertinoIcons.arrow_down_circle_fill
                  : CupertinoIcons.arrow_down_circle,
              color: Colors.white,
              size: 18,
            ),
          ),
          title: const Text('Active Downloads', style: TextStyle(fontSize: 16)),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: context.isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(CupertinoIcons.chevron_right, size: 16),
          // Navigation wired up in feature/download-detail-screens
          onTap: null,
        );
      },
    );
  }

  Widget _buildPlaylistStatusRow() {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: _offlineService.downloadedSongIds,
      builder: (context, ids, _) {
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: SettingsIconBadge(
        gradientColors: const [Color(0xFF5856D6), Color(0xFF7B68EE)],
        icon: CupertinoIcons.music_note_list,
      ),
          title: const Text('Playlist Downloads', style: TextStyle(fontSize: 16)),
          subtitle: Text(
            '${ids.length} songs downloaded',
            style: TextStyle(
              fontSize: 12,
              color: context.isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
            ),
          ),
          trailing: const Icon(CupertinoIcons.chevron_right, size: 16),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const DownloadPlaylistStatusScreen(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDownloadAllLibraryButton() {
    return ValueListenableBuilder<DownloadState>(
      valueListenable: _offlineService.downloadState,
      builder: (context, downloadState, _) {
        final isDownloading = downloadState.isDownloading;
        final progress = downloadState.totalCount > 0
            ? downloadState.currentProgress / downloadState.totalCount
            : 0.0;

        if (isDownloading) {
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: SettingsIconBadge(
        gradientColors: const [Color(0xFF34C759), Color(0xFF30D158)],
        icon: CupertinoIcons.arrow_down_circle_fill,
      ),
                title: Text(
                  AppLocalizations.of(context)!.downloadingLibrary(
                    downloadState.currentProgress,
                    downloadState.totalCount,
                  ),
                  style: const TextStyle(fontSize: 16),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    _offlineService.cancelBackgroundDownload();
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: context.isDark
                      ? AppTheme.darkCard
                      : AppTheme.lightDivider,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF34C759),
                  ),
                ),
              ),
            ],
          );
        }

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: SettingsIconBadge(
        gradientColors: const [Color(0xFF34C759), Color(0xFF30D158)],
        icon: CupertinoIcons.cloud_download,
      ),
          title: Text(
            AppLocalizations.of(context)!.downloadAllLibrary,
            style: const TextStyle(fontSize: 16, color: Color(0xFF34C759)),
          ),
          onTap: _downloadAllLibrary,
        );
      },
    );
  }

  Future<void> _downloadAllLibrary() async {
    try {
      final libraryProvider = context.read<LibraryProvider>();
      final subsonicService = context.read<SubsonicService>();

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loading library...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      await libraryProvider.ensureLibraryLoaded();

      // If still empty, try to refresh from server with a small delay
      if (libraryProvider.cachedAllSongs.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 500));
        // Force refresh by calling refresh method
        await libraryProvider.refresh();
      }

      final allSongs = libraryProvider.cachedAllSongs;

      if (allSongs.isEmpty) {
        if (!mounted) return;
        final retry = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.noSongsAvailable),
            content: const Text(
              'Library appears to be empty or failed to load. Make sure your server supports full library scanning.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
        if (retry == true) {
          return await _downloadAllLibrary();
        }
        return;
      }

      if (!mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.downloadAllLibrary),
          content: Text(
            AppLocalizations.of(
              context,
            )!.downloadLibraryConfirm(allSongs.length),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppLocalizations.of(context)!.download),
            ),
          ],
        ),
      );

      if (confirm != true || !mounted) return;

      await _offlineService.startBackgroundDownload(allSongs, subsonicService);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.libraryDownloadStarted),
            duration: const Duration(seconds: 2),
          ),
        );
        await _loadOfflineInfo();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorStartingDownload(e),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildDeleteDownloadsButton() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF3B30), Color(0xFFFF453A)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          CupertinoIcons.trash_fill,
          color: Colors.white,
          size: 16,
        ),
      ),
      title: Text(
        AppLocalizations.of(context)!.deleteDownloads,
        style: const TextStyle(fontSize: 16, color: Color(0xFFFF3B30)),
      ),
      onTap: () async {
        await _offlineService.deleteAllDownloads();
        await _loadOfflineInfo();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.downloadsDeleted),
            ),
          );
        }
      },
    );
  }

  Widget _buildBPMCacheInfo() {
    final cachedCount = _bpmAnalyzer.getCachedCount();
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: SettingsIconBadge(
        gradientColors: const [Color(0xFF5856D6), Color(0xFF7B68EE)],
        icon: CupertinoIcons.speedometer,
      ),
      title: Text(
        AppLocalizations.of(context)!.cachedBpms,
        style: const TextStyle(fontSize: 16),
      ),
      trailing: Text(
        '$cachedCount',
        style: TextStyle(
          fontSize: 16,
          color: context.isDark
              ? AppTheme.darkSecondaryText
              : AppTheme.lightSecondaryText,
        ),
      ),
    );
  }

  Widget _buildCachingProgress() {
    final progress = _totalSongs > 0 ? _currentProgress / _totalSongs : 0.0;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: context.isDark ? AppTheme.darkCard : AppTheme.lightDivider,
        valueColor: AlwaysStoppedAnimation<Color>(
          Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildCacheAllButton() {
    return Column(
      children: [
        const SettingsDivider(),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          enabled: !_isCaching,
          title: Text(
            AppLocalizations.of(context)!.cacheAllBpms,
            style: TextStyle(
              fontSize: 16,
              color: _isCaching ? Colors.grey : null,
            ),
          ),
          trailing: _isCaching
              ? const CupertinoActivityIndicator()
              : const Icon(CupertinoIcons.chevron_right, size: 16),
          onTap: _isCaching ? null : () {},
        ),
      ],
    );
  }

  Widget _buildClearCacheButton() {
    return Column(
      children: [
        const SettingsDivider(),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          title: Text(
            AppLocalizations.of(context)!.clearBpmCache,
            style: const TextStyle(fontSize: 16, color: Color(0xFFFF3B30)),
          ),
          onTap: () async {
            await _bpmAnalyzer.clearCache();
            setState(() {});
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.bpmCacheCleared),
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
