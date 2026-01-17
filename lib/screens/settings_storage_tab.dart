import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../providers/library_provider.dart';
import '../services/subsonic_service.dart';
import '../services/bpm_analyzer_service.dart';
import '../services/cache_settings_service.dart';
import '../services/offline_service.dart';
import '../theme/app_theme.dart';

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
  bool _isCaching = false;
  int _currentProgress = 0;
  int _totalSongs = 0;
  int _downloadedCount = 0;
  String _downloadedSize = '0 B';

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

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

    setState(() {
      _imageCacheEnabled = _cacheSettings.getImageCacheEnabled();
      _musicCacheEnabled = _cacheSettings.getMusicCacheEnabled();
      _bpmCacheEnabled = _cacheSettings.getBpmCacheEnabled();
    });
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
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        _buildSection(
          title: 'CACHE SETTINGS',
          children: [
            _buildCacheToggle(
              icon: CupertinoIcons.photo,
              iconGradient: const [Color(0xFFFF3B30), Color(0xFFFF453A)],
              title: 'Image Cache',
              subtitle: 'Save album covers locally',
              value: _imageCacheEnabled,
              onChanged: _toggleImageCache,
            ),
            _buildDivider(),
            _buildCacheToggle(
              icon: CupertinoIcons.music_note,
              iconGradient: const [Color(0xFF34C759), Color(0xFF30D158)],
              title: 'Music Cache',
              subtitle: 'Save song metadata locally',
              value: _musicCacheEnabled,
              onChanged: _toggleMusicCache,
            ),
            _buildDivider(),
            _buildCacheToggle(
              icon: CupertinoIcons.speedometer,
              iconGradient: const [Color(0xFF5856D6), Color(0xFF7B68EE)],
              title: 'BPM Cache',
              subtitle: 'Save BPM analysis locally',
              value: _bpmCacheEnabled,
              onChanged: _toggleBpmCache,
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSection(
          title: 'CACHE CLEANUP',
          children: [_buildClearAllCacheButton()],
        ),
        const SizedBox(height: 24),
        _buildSection(
          title: 'OFFLINE DOWNLOADS',
          children: [
            _buildOfflineInfo(),
            _buildDivider(),
            _buildDownloadAllLibraryButton(),
            _buildDivider(),
            _buildDeleteDownloadsButton(),
          ],
        ),
        const SizedBox(height: 24),
        _buildSection(
          title: 'BPM ANALYSIS',
          children: [
            _buildBPMCacheInfo(),
            if (_isCaching) _buildCachingProgress(),
            _buildCacheAllButton(),
            _buildClearCacheButton(),
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
          color: _isDark
              ? AppTheme.darkSecondaryText
              : AppTheme.lightSecondaryText,
        ),
      ),
      trailing: CupertinoSwitch(
        value: value,
        activeTrackColor: AppTheme.appleMusicRed,
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
      title: const Text(
        'Clear All Cache',
        style: TextStyle(fontSize: 16, color: Color(0xFFFF3B30)),
      ),
      onTap: _clearAllCache,
    );
  }

  void _clearAllCache() async {
    await DefaultCacheManager().emptyCache();
    await _bpmAnalyzer.clearCache();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('All cache cleared')));
      setState(() {});
    }
  }

  Widget _buildOfflineInfo() {
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
          CupertinoIcons.arrow_down_circle,
          color: Colors.white,
          size: 18,
        ),
      ),
      title: const Text('Downloaded Songs', style: TextStyle(fontSize: 16)),
      trailing: Text(
        '$_downloadedCount songs • $_downloadedSize',
        style: TextStyle(
          fontSize: 14,
          color: _isDark
              ? AppTheme.darkSecondaryText
              : AppTheme.lightSecondaryText,
        ),
      ),
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
                    CupertinoIcons.arrow_down_circle_fill,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                title: Text(
                  'Downloading Library... ${downloadState.currentProgress}/${downloadState.totalCount}',
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
                  backgroundColor: _isDark
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
              CupertinoIcons.cloud_download,
              color: Colors.white,
              size: 18,
            ),
          ),
          title: const Text(
            'Download All Library',
            style: TextStyle(fontSize: 16, color: Color(0xFF34C759)),
          ),
          onTap: _downloadAllLibrary,
        );
      },
    );
  }

  Future<void> _downloadAllLibrary() async {
    try {
      // Access providers
      final libraryProvider = context.read<LibraryProvider>();
      final subsonicService = context.read<SubsonicService>();

      // Get all songs from cache or load them
      final allSongs = libraryProvider.cachedAllSongs;

      if (allSongs.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No songs available. Please load your library first.',
            ),
          ),
        );
        return;
      }

      // Confirm action
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Download All Library'),
          content: Text(
            'This will download ${allSongs.length} songs to your device. '
            'This may take a while and use significant storage space.\n\n'
            'Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Download'),
            ),
          ],
        ),
      );

      if (confirm != true || !mounted) return;

      // Start background download
      await _offlineService.startBackgroundDownload(allSongs, subsonicService);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Library download started'),
            duration: Duration(seconds: 2),
          ),
        );
        await _loadOfflineInfo();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting download: $e'),
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
      title: const Text(
        'Delete All Downloads',
        style: TextStyle(fontSize: 16, color: Color(0xFFFF3B30)),
      ),
      onTap: () async {
        await _offlineService.deleteAllDownloads();
        await _loadOfflineInfo();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All downloads deleted')),
          );
        }
      },
    );
  }

  Widget _buildBPMCacheInfo() {
    final cachedCount = _bpmAnalyzer.getCachedCount();
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
          CupertinoIcons.speedometer,
          color: Colors.white,
          size: 18,
        ),
      ),
      title: const Text('Cached BPMs', style: TextStyle(fontSize: 16)),
      trailing: Text(
        '$cachedCount',
        style: TextStyle(
          fontSize: 16,
          color: _isDark
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
        backgroundColor: _isDark ? AppTheme.darkCard : AppTheme.lightDivider,
        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.appleMusicRed),
      ),
    );
  }

  Widget _buildCacheAllButton() {
    return Column(
      children: [
        _buildDivider(),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          enabled: !_isCaching,
          title: Text(
            'Cache All BPMs',
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
        _buildDivider(),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          title: const Text(
            'Clear BPM Cache',
            style: TextStyle(fontSize: 16, color: Color(0xFFFF3B30)),
          ),
          onTap: () async {
            await _bpmAnalyzer.clearCache();
            setState(() {});
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('BPM cache cleared')),
              );
            }
          },
        ),
      ],
    );
  }
}
