import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../services/bpm_analyzer_service.dart';
import '../services/cache_settings_service.dart';
import '../services/offline_service.dart';
import '../services/subsonic_service.dart';
import '../services/recommendation_service.dart';
import '../services/storage_service.dart';
import '../services/replay_gain_service.dart';
import '../services/auto_dj_service.dart';
import '../services/player_ui_settings_service.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/mini_player.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _bpmAnalyzer = BpmAnalyzerService();
  final _cacheSettings = CacheSettingsService();
  final _offlineService = OfflineService();
  final _replayGainService = ReplayGainService();
  final _playerUiSettings = PlayerUiSettingsService();
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
  bool _recommendationsEnabled = true;

  // ReplayGain settings
  ReplayGainMode _replayGainMode = ReplayGainMode.off;
  double _replayGainPreamp = 0.0;
  bool _replayGainPreventClipping = true;
  double _replayGainFallback = -6.0;

  // Auto DJ settings
  AutoDjMode _autoDjMode = AutoDjMode.off;
  int _autoDjSongsToAdd = 5;

  // Player UI settings
  bool _showVolumeSlider = true;

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
    await _replayGainService.initialize();
    await _playerUiSettings.initialize();
    await _loadOfflineInfo();

    final state = _offlineService.downloadState.value;
    final recommendationService = Provider.of<RecommendationService>(
      context,
      listen: false,
    );
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);

    setState(() {
      _imageCacheEnabled = _cacheSettings.getImageCacheEnabled();
      _musicCacheEnabled = _cacheSettings.getMusicCacheEnabled();
      _bpmCacheEnabled = _cacheSettings.getBpmCacheEnabled();
      _recommendationsEnabled = recommendationService.enabled;
      _isDownloading = state.isDownloading;
      _downloadProgress = state.currentProgress;
      _downloadTotal = state.totalCount;
      _downloadedCount = state.downloadedCount;
      // Load ReplayGain settings
      _replayGainMode = _replayGainService.getMode();
      _replayGainPreamp = _replayGainService.getPreampGain();
      _replayGainPreventClipping = _replayGainService.getPreventClipping();
      _replayGainFallback = _replayGainService.getFallbackGain();
      // Load Auto DJ settings
      _autoDjMode = playerProvider.autoDjService.mode;
      _autoDjSongsToAdd = playerProvider.autoDjService.songsToAdd;
      // Load Player UI settings
      _showVolumeSlider = _playerUiSettings.getShowVolumeSlider();
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
    final authProvider = Provider.of<AuthProvider>(context);
    final serverType = authProvider.config?.serverType;
    final serverVersion = authProvider.config?.serverVersion;

    String serverSubtitle = 'Subsonic API';
    if (serverType != null && serverType.isNotEmpty) {
      serverSubtitle = serverType;
      if (serverVersion != null && serverVersion.isNotEmpty) {
        serverSubtitle += ' $serverVersion';
      }
    }

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
          const SizedBox(height: 24),
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
            title: 'PLAYER INTERFACE',
            children: [_buildVolumeSliderToggle()],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'SMART RECOMMENDATIONS',
            children: [
              _buildRecommendationsToggle(),
              _buildDivider(),
              _buildRecommendationsStats(),
              _buildDivider(),
              _buildClearRecommendationsButton(),
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
          _buildSection(
            title: 'MUSIC FOLDERS',
            children: [_buildMusicFoldersButton()],
          ),
          const SizedBox(height: 24),
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
                subtitle: '1.0.3',
              ),
              _buildDivider(),
              _buildInfoTile(
                icon: CupertinoIcons.music_note_2,
                iconColor: AppTheme.appleMusicRed,
                title: 'Server Type',
                subtitle: serverSubtitle,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'DEVELOPER',
            children: [
              _buildDeveloperInfo(),
              _buildDivider(),
              _buildDonationButtons(),
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
            '$_currentProgress of $_totalSongs songs',
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

  Widget _buildDeveloperInfo() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5856D6), Color(0xFFAF52DE)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.code_rounded, color: Colors.white, size: 18),
      ),
      title: const Text('Made by dddevid', style: TextStyle(fontSize: 16)),
      subtitle: const Text(
        'github.com/dddevid',
        style: TextStyle(fontSize: 13),
      ),
      trailing: const Icon(Icons.open_in_new_rounded, size: 18),
      onTap: () => _openUrl('https://github.com/dddevid'),
    );
  }

  Widget _buildDonationButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Support Development',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildDonationButton(
                label: 'Buy Me a Coffee',
                icon: Icons.coffee_rounded,
                color: const Color(0xFFFFDD00),
                onTap: () => _openUrl('https://buymeacoffee.com/devidd'),
              ),
              _buildDonationButton(
                label: 'Bitcoin',
                icon: Icons.currency_bitcoin_rounded,
                color: const Color(0xFFF7931A),
                onTap: () => _showCryptoAddress(
                  'Bitcoin Address',
                  'bc1qrfv880kc8qamanalc5kcqs9q5wszh90e5eggyz',
                ),
              ),
              _buildDonationButton(
                label: 'Solana',
                icon: Icons.toll_rounded,
                color: const Color(0xFF14F195),
                onTap: () => _showCryptoAddress(
                  'Solana Address',
                  'E3JUcjyR6UCJtppU24iDrq82FyPeV9nhL1PKHx57iPXu',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDonationButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Cannot open URL');
      }
    } catch (e) {
      _showSnackBar('Error opening URL: $e');
    }
  }

  void _showCryptoAddress(String title, String address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              address,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: address));
                  Navigator.pop(context);
                  _showSnackBar('Address copied to clipboard');
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copy Address'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.appleMusicRed,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildMusicFoldersButton() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF9500), Color(0xFFFFCC00)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.folder_rounded, color: Colors.white, size: 18),
      ),
      title: const Text('Select Music Folders', style: TextStyle(fontSize: 16)),
      subtitle: Text(
        'Filter music by server folders',
        style: TextStyle(
          fontSize: 13,
          color: _isDark
              ? AppTheme.darkSecondaryText
              : AppTheme.lightSecondaryText,
        ),
      ),
      trailing: const Icon(CupertinoIcons.chevron_right, size: 18),
      onTap: _showMusicFoldersDialog,
    );
  }

  Future<void> _showMusicFoldersDialog() async {
    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );

    _showSnackBar('Loading music folders...');

    final folders = await subsonicService.getMusicFolders();

    if (!mounted) return;

    if (folders.isEmpty) {
      _showSnackBar('No music folders found');
      return;
    }

    final currentConfig = subsonicService.config;
    if (currentConfig == null) return;

    final selectedIds = List<String>.from(currentConfig.selectedMusicFolderIds);

    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) =>
          _MusicFoldersDialog(folders: folders, selectedIds: selectedIds),
    );

    if (result != null && mounted) {
      final storageService = Provider.of<StorageService>(
        context,
        listen: false,
      );

      final updatedConfig = currentConfig.copyWith(
        selectedMusicFolderIds: result,
      );

      subsonicService.configure(updatedConfig);
      await storageService.saveServerConfig(updatedConfig);

      final libraryProvider = Provider.of<LibraryProvider>(
        context,
        listen: false,
      );

      libraryProvider.refresh();

      _showSnackBar(
        result.isEmpty
            ? 'Showing all music folders'
            : 'Selected ${result.length} folder(s)',
      );
    }
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

  Widget _buildRecommendationsToggle() {
    return _buildCacheToggle(
      icon: CupertinoIcons.sparkles,
      iconGradient: const [Color(0xFFFF2D55), Color(0xFFFF375F)],
      title: 'Smart Recommendations',
      subtitle: 'AI-powered suggestions based on your listening',
      value: _recommendationsEnabled,
      onChanged: _toggleRecommendations,
    );
  }

  Widget _buildRecommendationsStats() {
    final recommendationService = Provider.of<RecommendationService>(
      context,
      listen: false,
    );
    final stats = recommendationService.getListeningStats();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5E5CE6), Color(0xFF7B68EE)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          CupertinoIcons.chart_bar,
          color: Colors.white,
          size: 18,
        ),
      ),
      title: const Text('Listening Statistics', style: TextStyle(fontSize: 16)),
      subtitle: Text(
        '${stats['totalPlays']} plays • ${stats['uniqueSongs']} songs • ${stats['uniqueArtists']} artists',
        style: TextStyle(
          fontSize: 13,
          color: _isDark
              ? AppTheme.darkSecondaryText
              : AppTheme.lightSecondaryText,
        ),
      ),
    );
  }

  Widget _buildClearRecommendationsButton() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF3B30), Color(0xFFFF453A)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(CupertinoIcons.trash, color: Colors.white, size: 18),
      ),
      title: const Text('Clear Learning Data', style: TextStyle(fontSize: 16)),
      subtitle: Text(
        'Reset all learning data and start fresh',
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
      onTap: _clearRecommendationsData,
    );
  }

  Future<void> _toggleRecommendations(bool value) async {
    final recommendationService = Provider.of<RecommendationService>(
      context,
      listen: false,
    );

    setState(() => _recommendationsEnabled = value);
    await recommendationService.setEnabled(value);

    _showSnackBar(
      value
          ? 'Smart recommendations enabled'
          : 'Smart recommendations disabled',
    );
  }

  // ReplayGain widgets
  Widget _buildReplayGainModeSelector() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          CupertinoIcons.speaker_2,
          color: Colors.white,
          size: 18,
        ),
      ),
      title: const Text('ReplayGain Mode', style: TextStyle(fontSize: 16)),
      subtitle: Text(
        _getReplayGainModeDescription(),
        style: TextStyle(
          fontSize: 13,
          color: _isDark
              ? AppTheme.darkSecondaryText
              : AppTheme.lightSecondaryText,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _isDark ? AppTheme.darkCard : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButton<ReplayGainMode>(
          value: _replayGainMode,
          underline: const SizedBox(),
          isDense: true,
          items: ReplayGainMode.values.map((mode) {
            return DropdownMenuItem(
              value: mode,
              child: Text(
                _getReplayGainModeName(mode),
                style: TextStyle(
                  fontSize: 14,
                  color: _isDark ? Colors.white : Colors.black,
                ),
              ),
            );
          }).toList(),
          onChanged: (mode) => _setReplayGainMode(mode!),
        ),
      ),
    );
  }

  String _getReplayGainModeName(ReplayGainMode mode) {
    switch (mode) {
      case ReplayGainMode.off:
        return 'Off';
      case ReplayGainMode.track:
        return 'Track';
      case ReplayGainMode.album:
        return 'Album';
    }
  }

  String _getReplayGainModeDescription() {
    switch (_replayGainMode) {
      case ReplayGainMode.off:
        return 'Volume normalization disabled';
      case ReplayGainMode.track:
        return 'Normalize each track individually';
      case ReplayGainMode.album:
        return 'Preserve album dynamics';
    }
  }

  Future<void> _setReplayGainMode(ReplayGainMode mode) async {
    setState(() => _replayGainMode = mode);
    await _replayGainService.setMode(mode);

    // Refresh the player's volume
    if (mounted) {
      final playerProvider = Provider.of<PlayerProvider>(
        context,
        listen: false,
      );
      await playerProvider.refreshReplayGain();
    }

    _showSnackBar('ReplayGain mode: ${_getReplayGainModeName(mode)}');
  }

  Widget _buildReplayGainPreampSlider() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF9500), Color(0xFFFF3B30)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          CupertinoIcons.slider_horizontal_3,
          color: Colors.white,
          size: 18,
        ),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Pre-amp Gain', style: TextStyle(fontSize: 16)),
          Text(
            '${_replayGainPreamp.toStringAsFixed(1)} dB',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.appleMusicRed,
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.appleMusicRed,
              inactiveTrackColor: _isDark ? Colors.white24 : Colors.black12,
              thumbColor: AppTheme.appleMusicRed,
              overlayColor: AppTheme.appleMusicRed.withOpacity(0.2),
            ),
            child: Slider(
              value: _replayGainPreamp,
              min: -15.0,
              max: 15.0,
              divisions: 30,
              onChanged: (value) {
                setState(() => _replayGainPreamp = value);
              },
              onChangeEnd: (value) => _setReplayGainPreamp(value),
            ),
          ),
          Text(
            'Additional volume adjustment (-15 to +15 dB)',
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

  Future<void> _setReplayGainPreamp(double value) async {
    await _replayGainService.setPreampGain(value);

    if (mounted) {
      final playerProvider = Provider.of<PlayerProvider>(
        context,
        listen: false,
      );
      await playerProvider.refreshReplayGain();
    }
  }

  Widget _buildReplayGainClippingToggle() {
    return _buildCacheToggle(
      icon: CupertinoIcons.waveform_path,
      iconGradient: const [Color(0xFF34C759), Color(0xFF30D158)],
      title: 'Prevent Clipping',
      subtitle: 'Limit volume to avoid distortion',
      value: _replayGainPreventClipping,
      onChanged: _setReplayGainPreventClipping,
    );
  }

  Future<void> _setReplayGainPreventClipping(bool value) async {
    setState(() => _replayGainPreventClipping = value);
    await _replayGainService.setPreventClipping(value);

    if (mounted) {
      final playerProvider = Provider.of<PlayerProvider>(
        context,
        listen: false,
      );
      await playerProvider.refreshReplayGain();
    }
  }

  Widget _buildReplayGainFallbackSlider() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5856D6), Color(0xFFAF52DE)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          CupertinoIcons.question_circle,
          color: Colors.white,
          size: 18,
        ),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Fallback Gain', style: TextStyle(fontSize: 16)),
          Text(
            '${_replayGainFallback.toStringAsFixed(1)} dB',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.appleMusicRed,
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.appleMusicRed,
              inactiveTrackColor: _isDark ? Colors.white24 : Colors.black12,
              thumbColor: AppTheme.appleMusicRed,
              overlayColor: AppTheme.appleMusicRed.withOpacity(0.2),
            ),
            child: Slider(
              value: _replayGainFallback,
              min: -15.0,
              max: 0.0,
              divisions: 15,
              onChanged: (value) {
                setState(() => _replayGainFallback = value);
              },
              onChangeEnd: (value) => _setReplayGainFallback(value),
            ),
          ),
          Text(
            'Used when tracks have no ReplayGain data',
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

  Future<void> _setReplayGainFallback(double value) async {
    await _replayGainService.setFallbackGain(value);

    if (mounted) {
      final playerProvider = Provider.of<PlayerProvider>(
        context,
        listen: false,
      );
      await playerProvider.refreshReplayGain();
    }
  }

  // Auto DJ widgets
  Widget _buildAutoDjModeSelector() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF2D55), Color(0xFFFF9500)],
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
      subtitle: Text(
        AutoDjService.getModeDescription(_autoDjMode),
        style: TextStyle(
          fontSize: 13,
          color: _isDark
              ? AppTheme.darkSecondaryText
              : AppTheme.lightSecondaryText,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _isDark ? AppTheme.darkCard : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButton<AutoDjMode>(
          value: _autoDjMode,
          underline: const SizedBox(),
          isDense: true,
          items: AutoDjMode.values.map((mode) {
            return DropdownMenuItem(
              value: mode,
              child: Text(
                AutoDjService.getModeDisplayName(mode),
                style: TextStyle(
                  fontSize: 14,
                  color: _isDark ? Colors.white : Colors.black,
                ),
              ),
            );
          }).toList(),
          onChanged: (mode) => _setAutoDjMode(mode!),
        ),
      ),
    );
  }

  Future<void> _setAutoDjMode(AutoDjMode mode) async {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    await playerProvider.autoDjService.setMode(mode);
    setState(() => _autoDjMode = mode);
  }

  Widget _buildAutoDjSongsSlider() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5856D6), Color(0xFFAF52DE)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          CupertinoIcons.music_note_list,
          color: Colors.white,
          size: 18,
        ),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Songs to Add', style: TextStyle(fontSize: 16)),
          Text(
            '$_autoDjSongsToAdd songs',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.appleMusicRed,
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.appleMusicRed,
              inactiveTrackColor: _isDark ? Colors.white24 : Colors.black12,
              thumbColor: AppTheme.appleMusicRed,
              overlayColor: AppTheme.appleMusicRed.withOpacity(0.2),
            ),
            child: Slider(
              value: _autoDjSongsToAdd.toDouble(),
              min: 1.0,
              max: 20.0,
              divisions: 19,
              onChanged: (value) {
                setState(() => _autoDjSongsToAdd = value.round());
              },
              onChangeEnd: (value) => _setAutoDjSongsToAdd(value.round()),
            ),
          ),
          Text(
            'Number of songs to add when queue is ending',
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

  Future<void> _setAutoDjSongsToAdd(int count) async {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    await playerProvider.autoDjService.setSongsToAdd(count);
  }

  Future<void> _clearRecommendationsData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Learning Data'),
        content: const Text(
          'Are you sure you want to clear all learning data? '
          'This will reset your personalized recommendations and the algorithm will start learning from scratch.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final recommendationService = Provider.of<RecommendationService>(
        context,
        listen: false,
      );

      try {
        await recommendationService.clearData();
        _showSnackBar('Learning data cleared successfully');
      } catch (e) {
        _showSnackBar('Error clearing data: $e');
      }
    }
  }

  // Player UI widgets
  Widget _buildVolumeSliderToggle() {
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
          CupertinoIcons.speaker_2,
          color: Colors.white,
          size: 18,
        ),
      ),
      title: const Text('Show Volume Slider', style: TextStyle(fontSize: 16)),
      subtitle: Text(
        'Display volume control in Now Playing screen',
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
}

class _MusicFoldersDialog extends StatefulWidget {
  final List<MusicFolder> folders;
  final List<String> selectedIds;

  const _MusicFoldersDialog({required this.folders, required this.selectedIds});

  @override
  State<_MusicFoldersDialog> createState() => _MusicFoldersDialogState();
}

class _MusicFoldersDialogState extends State<_MusicFoldersDialog> {
  late List<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Music Folders'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose which music folders to display. Leave all unchecked to show all folders.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.folders.length,
                itemBuilder: (context, index) {
                  final folder = widget.folders[index];
                  final isSelected = _selectedIds.contains(folder.id);

                  return CheckboxListTile(
                    title: Text(folder.name),
                    value: isSelected,
                    activeColor: AppTheme.appleMusicRed,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedIds.add(folder.id);
                        } else {
                          _selectedIds.remove(folder.id);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _selectedIds),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
