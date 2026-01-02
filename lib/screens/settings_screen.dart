import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../providers/library_provider.dart';
import '../services/bpm_analyzer_service.dart';
import '../services/cache_settings_service.dart';
import '../services/offline_service.dart';
import '../services/subsonic_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _bpmAnalyzer = BpmAnalyzerService();
  final _cacheSettings = CacheSettingsService();
  final _offlineService = OfflineService();
  bool _isCaching = false;
  int _currentProgress = 0;
  int _totalSongs = 0;

  bool _isDownloading = false;
  int _downloadProgress = 0;
  int _downloadTotal = 0;
  int _downloadedCount = 0;
  String _downloadedSize = '0 B';

  bool _imageCacheEnabled = true;
  bool _musicCacheEnabled = true;
  bool _bpmCacheEnabled = true;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _loadCacheSettings();
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
      _isDownloading = state.isDownloading;
      _downloadProgress = state.currentProgress;
      _downloadTotal = state.totalCount;
      _downloadedCount = state.downloadedCount;
    });

    if (!state.isDownloading &&
        state.currentProgress == state.totalCount &&
        state.totalCount > 0) {
      _loadOfflineInfo();
      _showSnackBar('Download completato: ${state.downloadedCount} brani');
    }
  }

  Future<void> _loadCacheSettings() async {
    await _cacheSettings.initialize();
    await _offlineService.initialize();
    await _loadOfflineInfo();

    final state = _offlineService.downloadState.value;
    setState(() {
      _imageCacheEnabled = _cacheSettings.getImageCacheEnabled();
      _musicCacheEnabled = _cacheSettings.getMusicCacheEnabled();
      _bpmCacheEnabled = _cacheSettings.getBpmCacheEnabled();
      _isDownloading = state.isDownloading;
      _downloadProgress = state.currentProgress;
      _downloadTotal = state.totalCount;
      _downloadedCount = state.downloadedCount;
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
    return Scaffold(
      backgroundColor: _isDark
          ? AppTheme.darkBackground
          : AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: false,
        backgroundColor: _isDark
            ? AppTheme.darkBackground
            : AppTheme.lightBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (_isDownloading && _downloadTotal > 0)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF007AFF).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const CupertinoActivityIndicator(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Download in background',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF007AFF),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Continua anche se esci da questa schermata',
                          style: TextStyle(
                            fontSize: 12,
                            color: _isDark
                                ? AppTheme.darkSecondaryText
                                : AppTheme.lightSecondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          _buildSection(
            title: 'GESTIONE CACHE',
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
            title: 'OFFLINE DOWNLOAD',
            children: [
              _buildOfflineInfo(),
              if (_isDownloading) _buildDownloadProgress(),
              _buildDivider(),
              _buildDownloadAllButton(),
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
          const SizedBox(height: 24),
          _buildSection(
            title: 'INFORMATION',
            children: [
              _buildInfoTile(
                icon: CupertinoIcons.info,
                iconColor: AppTheme.appleMusicRed,
                title: 'Version',
                subtitle: '1.0.1',
              ),
              _buildDivider(),
              _buildInfoTile(
                icon: CupertinoIcons.music_note_2,
                iconColor: AppTheme.appleMusicRed,
                title: 'Server',
                subtitle: 'Subsonic API',
              ),
            ],
          ),
          const SizedBox(height: 40),
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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

  Widget _buildBPMCacheInfo() {
    final cachedCount = _bpmAnalyzer.getCachedCount();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$cachedCount',
            style: TextStyle(
              fontSize: 16,
              color: _isDark
                  ? AppTheme.darkSecondaryText
                  : AppTheme.lightSecondaryText,
            ),
          ),
          if (cachedCount > 0) ...[
            const SizedBox(width: 8),
            const Icon(
              CupertinoIcons.checkmark_circle_fill,
              color: Color(0xFF34C759),
              size: 20,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCachingProgress() {
    final progress = _totalSongs > 0 ? _currentProgress / _totalSongs : 0.0;
    final percentage = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Analisi in corso...',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.appleMusicRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: _isDark
                  ? AppTheme.darkCard
                  : AppTheme.lightDivider,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.appleMusicRed,
              ),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$_currentProgress di $_totalSongs canzoni',
            style: TextStyle(
              fontSize: 12,
              color: _isDark
                  ? AppTheme.darkSecondaryText
                  : AppTheme.lightSecondaryText,
            ),
          ),
        ],
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
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isCaching
                    ? [Colors.grey, Colors.grey.shade600]
                    : [const Color(0xFF34C759), const Color(0xFF30D158)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              CupertinoIcons.arrow_down_circle_fill,
              color: Colors.white,
              size: 18,
            ),
          ),
          title: Text(
            'Cache all BPMs',
            style: TextStyle(
              fontSize: 16,
              color: _isCaching
                  ? (_isDark
                        ? AppTheme.darkSecondaryText
                        : AppTheme.lightSecondaryText)
                  : null,
            ),
          ),
          trailing: _isCaching
              ? const CupertinoActivityIndicator()
              : Icon(
                  CupertinoIcons.chevron_right,
                  size: 16,
                  color: _isDark
                      ? AppTheme.darkSecondaryText
                      : AppTheme.lightSecondaryText,
                ),
          onTap: _isCaching ? null : _startCachingAll,
        ),
      ],
    );
  }

  Widget _buildClearCacheButton() {
    final cachedCount = _bpmAnalyzer.getCachedCount();
    final isDisabled = _isCaching || cachedCount == 0;

    return Column(
      children: [
        _buildDivider(),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          enabled: !isDisabled,
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDisabled
                    ? [Colors.grey, Colors.grey.shade600]
                    : [const Color(0xFFFF3B30), const Color(0xFFFF453A)],
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
            'Clear cache',
            style: TextStyle(
              fontSize: 16,
              color: isDisabled
                  ? (_isDark
                        ? AppTheme.darkSecondaryText
                        : AppTheme.lightSecondaryText)
                  : const Color(0xFFFF3B30),
            ),
          ),
          trailing: Icon(
            CupertinoIcons.chevron_right,
            size: 16,
            color: _isDark
                ? AppTheme.darkSecondaryText
                : AppTheme.lightSecondaryText,
          ),
          onTap: isDisabled ? null : _clearCache,
        ),
      ],
    );
  }

  Widget _buildInfoTile({
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
          color: _isDark
              ? AppTheme.darkSecondaryText
              : AppTheme.lightSecondaryText,
        ),
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: iconGradient,
          ),
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
        activeColor: AppTheme.appleMusicRed,
        onChanged: onChanged,
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF9500), Color(0xFFFFB340)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          CupertinoIcons.clear_circled_solid,
          color: Colors.white,
          size: 18,
        ),
      ),
      title: const Text('Clear all cache', style: TextStyle(fontSize: 16)),
      subtitle: Text(
        'Remove all cache (images, music, BPM)',
        style: TextStyle(
          fontSize: 13,
          color: _isDark
              ? AppTheme.darkSecondaryText
              : AppTheme.lightSecondaryText,
        ),
      ),
      trailing: Icon(
        CupertinoIcons.chevron_right,
        size: 16,
        color: _isDark
            ? AppTheme.darkSecondaryText
            : AppTheme.lightSecondaryText,
      ),
      onTap: _clearAllCache,
    );
  }

  Future<void> _toggleImageCache(bool value) async {
    setState(() => _imageCacheEnabled = value);
    await _cacheSettings.setImageCacheEnabled(value);

    if (!value) {
      await DefaultCacheManager().emptyCache();
      _showSnackBar('Cache images disabled and cleared');
    } else {
      _showSnackBar('Cache images enabled');
    }
  }

  Future<void> _toggleMusicCache(bool value) async {
    setState(() => _musicCacheEnabled = value);
    await _cacheSettings.setMusicCacheEnabled(value);
    _showSnackBar(value ? 'Cache music enabled' : 'Cache music disabled');
  }

  Future<void> _toggleBpmCache(bool value) async {
    setState(() => _bpmCacheEnabled = value);
    await _cacheSettings.setBpmCacheEnabled(value);

    if (!value) {
      await _bpmAnalyzer.clearCache();
      _showSnackBar('Cache BPM disabled and cleared');
    } else {
      _showSnackBar('Cache BPM enabled');
    }
  }

  Future<void> _clearAllCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all cache'),
        content: const Text(
          'Are you sure you want to clear all cache? '
          'This action will remove images, music, and BPM saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abort'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Future.wait([
          DefaultCacheManager().emptyCache(),
          _bpmAnalyzer.clearCache(),
        ]);

        setState(() {});
        _showSnackBar('All cache has been cleared');
      } catch (e) {
        _showSnackBar('Error during cache cleanup: $e');
      }
    }
  }

  Future<void> _startCachingAll() async {
    final libraryProvider = Provider.of<LibraryProvider>(
      context,
      listen: false,
    );

    setState(() {
      _isCaching = true;
      _currentProgress = 0;
      _totalSongs = 0;
    });

    try {
      _showSnackBar('Loading songs...');
      final songs = await libraryProvider.getAllSongs();

      if (songs.isEmpty) {
        setState(() {
          _isCaching = false;
        });
        _showSnackBar('No songs available');
        return;
      }

      setState(() {
        _totalSongs = songs.length;
      });

      await _bpmAnalyzer.cacheAllBPM(
        songs,
        onProgress: (current, total) {
          if (mounted) {
            setState(() {
              _currentProgress = current;
              _totalSongs = total;
            });
          }
        },
        onSongCached: (song, bpm) {
          debugPrint('Cached BPM for ${song.title}: $bpm');
        },
        onCompleted: () {
          if (mounted) {
            setState(() {
              _isCaching = false;
            });
            _showSnackBar('Cache completed: $_totalSongs songs');
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCaching = false;
        });
        _showSnackBar('Error during caching: $e');
      }
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear cache'),
        content: const Text('Are you sure you want to delete all saved BPMs?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _bpmAnalyzer.clearCache();
      setState(() {});
      _showSnackBar('Cache BPM cleared');
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF007AFF), Color(0xFF5AC8FA)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          CupertinoIcons.arrow_down_circle_fill,
          color: Colors.white,
          size: 18,
        ),
      ),
      title: const Text('Downloaded songs', style: TextStyle(fontSize: 16)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$_downloadedCount songs • $_downloadedSize',
            style: TextStyle(
              fontSize: 14,
              color: _isDark
                  ? AppTheme.darkSecondaryText
                  : AppTheme.lightSecondaryText,
            ),
          ),
          if (_downloadedCount > 0) ...[
            const SizedBox(width: 8),
            const Icon(
              CupertinoIcons.checkmark_circle_fill,
              color: Color(0xFF34C759),
              size: 20,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDownloadProgress() {
    final progress = _downloadTotal > 0
        ? _downloadProgress / _downloadTotal
        : 0.0;
    final percentage = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Downloading...',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF007AFF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: _isDark
                  ? AppTheme.darkCard
                  : AppTheme.lightDivider,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF007AFF),
              ),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$_downloadProgress of $_downloadTotal songs',
            style: TextStyle(
              fontSize: 12,
              color: _isDark
                  ? AppTheme.darkSecondaryText
                  : AppTheme.lightSecondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadAllButton() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      enabled: !_isDownloading,
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isDownloading
                ? [Colors.grey, Colors.grey.shade600]
                : [const Color(0xFF34C759), const Color(0xFF30D158)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          CupertinoIcons.cloud_download_fill,
          color: Colors.white,
          size: 18,
        ),
      ),
      title: Text(
        'Download all catalog',
        style: TextStyle(
          fontSize: 16,
          color: _isDownloading
              ? (_isDark
                    ? AppTheme.darkSecondaryText
                    : AppTheme.lightSecondaryText)
              : null,
        ),
      ),
      subtitle: _isDownloading
          ? Text(
              'Downloading... ${_downloadProgress} of ${_downloadTotal} songs',
              style: TextStyle(
                fontSize: 13,
                color: _isDark
                    ? AppTheme.darkSecondaryText
                    : AppTheme.lightSecondaryText,
              ),
            )
          : Text(
              'Download all songs for offline listening',
              style: TextStyle(
                fontSize: 13,
                color: _isDark
                    ? AppTheme.darkSecondaryText
                    : AppTheme.lightSecondaryText,
              ),
            ),
      trailing: _isDownloading
          ? const CupertinoActivityIndicator()
          : Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: _isDark
                  ? AppTheme.darkSecondaryText
                  : AppTheme.lightSecondaryText,
            ),
      onTap: _isDownloading ? null : _startDownloadAll,
    );
  }

  Widget _buildDeleteDownloadsButton() {
    final isDisabled = _isDownloading || _downloadedCount == 0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      enabled: !isDisabled,
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDisabled
                ? [Colors.grey, Colors.grey.shade600]
                : [const Color(0xFFFF3B30), const Color(0xFFFF453A)],
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
        'Delete downloads',
        style: TextStyle(
          fontSize: 16,
          color: isDisabled
              ? (_isDark
                    ? AppTheme.darkSecondaryText
                    : AppTheme.lightSecondaryText)
              : const Color(0xFFFF3B30),
        ),
      ),
      trailing: Icon(
        CupertinoIcons.chevron_right,
        size: 16,
        color: _isDark
            ? AppTheme.darkSecondaryText
            : AppTheme.lightSecondaryText,
      ),
      onTap: isDisabled ? null : _deleteAllDownloads,
    );
  }

  Future<void> _startDownloadAll() async {
    final libraryProvider = Provider.of<LibraryProvider>(
      context,
      listen: false,
    );
    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );

    try {
      _showSnackBar('Loading catalog...');
      final songs = await libraryProvider.getAllSongs();

      if (songs.isEmpty) {
        _showSnackBar('No songs to download');
        return;
      }

      _showSnackBar(
        'Starting download of ${songs.length} songs in background...',
      );

      _offlineService.startBackgroundDownload(songs, subsonicService);
    } catch (e) {
      _showSnackBar('Error during download: $e');
    }
  }

  Future<void> _deleteAllDownloads() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete downloads'),
        content: Text(
          'Are you sure you want to delete all $_downloadedCount downloaded songs? '
          'This will free up $_downloadedSize of space.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete all'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _offlineService.deleteAllDownloads();
        await _loadOfflineInfo();
        _showSnackBar('Downloads deleted');
      } catch (e) {
        _showSnackBar('Error during deletion: $e');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _isDark ? AppTheme.darkCard : Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
