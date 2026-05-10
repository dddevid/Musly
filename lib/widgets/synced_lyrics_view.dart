import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:window_manager/window_manager.dart';
import '../models/lyrics.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../services/subsonic_service.dart';
import '../services/offline_service.dart';
import '../services/lrclib_service.dart';
import '../services/storage_service.dart';
import 'album_artwork.dart' show isLocalFilePath;
import '../l10n/app_localizations.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Apple Music-like Lyrics Controller (inspired by AMLL)
// ─────────────────────────────────────────────────────────────────────────────

class AppleMusicLyricsController extends ChangeNotifier {
  List<LyricLine> _lines = [];
  int _activeIndex = -1;
  int _selectedIndex = -1;
  Duration _currentPosition = Duration.zero;

  /// ValueNotifier that ticks with line progress [0.0-1.0] for the active line.
  final ValueNotifier<double> progressNotifier = ValueNotifier<double>(0.0);

  /// ValueNotifier that ticks with the raw playback position for word-by-word lines.
  final ValueNotifier<Duration> positionNotifier =
      ValueNotifier<Duration>(Duration.zero);

  bool get isUserScrolling => _selectedIndex != -1;
  List<LyricLine> get lines => _lines;
  int get activeIndex => _activeIndex;
  int get selectedIndex => _selectedIndex;
  Duration get currentPosition => _currentPosition;

  void loadLines(List<LyricLine> lines) {
    _lines = lines;
    _activeIndex = -1;
    _selectedIndex = -1;
    _currentPosition = Duration.zero;
    progressNotifier.value = 0.0;
    positionNotifier.value = Duration.zero;
    notifyListeners();
  }

  void setPosition(Duration position) {
    _currentPosition = position;
    positionNotifier.value = position;
    final newIndex = _computeActiveIndex(position);
    final indexChanged = newIndex != _activeIndex;
    if (indexChanged) {
      _activeIndex = newIndex;
    }
    if (_selectedIndex != -1 && newIndex == _selectedIndex) {
      _selectedIndex = -1;
    }

    // Always update progress for the active line
    progressNotifier.value = _computeLineProgress();

    if (indexChanged) {
      notifyListeners();
    }
  }

  /// Progress within the current active line [0.0, 1.0]
  double _computeLineProgress() {
    if (_activeIndex < 0 || _activeIndex >= _lines.length) return 0.0;
    final line = _lines[_activeIndex];
    final start = line.timestamp.inMilliseconds;

    // Calculate end time from next line or use a default duration
    int end;
    if (_activeIndex + 1 < _lines.length) {
      end = _lines[_activeIndex + 1].timestamp.inMilliseconds;
    } else {
      end = start + 5000; // default 5s for last line
    }

    if (end <= start) return 1.0;
    final progress = (_currentPosition.inMilliseconds - start) / (end - start);
    return progress.clamp(0.0, 1.0);
  }

  double getLineProgress() => progressNotifier.value;

  void selectLine(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  void clearSelection() {
    _selectedIndex = -1;
    notifyListeners();
  }

  int _computeActiveIndex(Duration position) {
    if (_lines.isEmpty) return -1;
    int result = -1;
    for (int i = 0; i < _lines.length; i++) {
      if (position >= _lines[i].timestamp) {
        result = i;
      } else {
        break;
      }
    }
    return result;
  }

  @override
  void dispose() {
    progressNotifier.dispose();
    positionNotifier.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main SyncedLyricsView
// ─────────────────────────────────────────────────────────────────────────────

class SyncedLyricsView extends StatefulWidget {
  final Song song;
  final String? imageUrl;
  final VoidCallback? onClose;

  const SyncedLyricsView({
    super.key,
    required this.song,
    this.imageUrl,
    this.onClose,
  });

  @override
  State<SyncedLyricsView> createState() => _SyncedLyricsViewState();
}

class _SyncedLyricsViewState extends State<SyncedLyricsView>
    with TickerProviderStateMixin {
  SyncedLyrics? _lyrics;
  bool _isLoading = true;
  String? _error;
  late AnimationController _fadeController;
  late AnimationController _bgAnimationController;
  StreamSubscription<Duration>? _positionSubscription;

  late Song _song;
  bool _isPlaying = false;
  bool _isFullscreen = false;
  bool _showReturnButton = false;

  final AppleMusicLyricsController _lyricsController =
      AppleMusicLyricsController();

  bool get _isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat(reverse: true);

    _song = widget.song;
    _loadLyrics();
    _setupPositionListener();
    _maybeSetHighRefreshRate();

    _lyricsController.addListener(_onLyricsChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PlayerProvider>(
        context,
        listen: false,
      ).addListener(_onPlayerStateChanged);
    });
  }

  @override
  void dispose() {
    try {
      Provider.of<PlayerProvider>(
        context,
        listen: false,
      ).removeListener(_onPlayerStateChanged);
    } catch (_) {}
    _positionSubscription?.cancel();
    _fadeController.dispose();
    _bgAnimationController.dispose();
    _lyricsController.removeListener(_onLyricsChanged);
    _lyricsController.dispose();
    if (_isDesktop && _isFullscreen) _setWindowFullscreen(false);
    super.dispose();
  }

  void _onLyricsChanged() {
    if (!mounted) return;
    setState(() {
      _showReturnButton = _lyricsController.isUserScrolling;
    });
  }

  void _onPlayerStateChanged() {
    if (!mounted) return;
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final currentSong = playerProvider.currentSong;
    if (currentSong != null && currentSong.id != _song.id) {
      setState(() => _song = currentSong);
      _loadLyrics();
    }
  }

  Future<void> _maybeSetHighRefreshRate() async {
    try {
      if (!Platform.isAndroid) return;
      final battery = Battery();
      final level = await battery.batteryLevel;
      if (level > 15) await FlutterDisplayMode.setHighRefreshRate();
    } catch (e) {
      debugPrint('Display mode change failed: $e');
    }
  }

  Future<void> _setWindowFullscreen(bool enable) async {
    if (!_isDesktop) return;
    unawaited(() async {
      try {
        await windowManager.setFullScreen(enable);
        await windowManager.focus();
      } catch (e) {
        debugPrint('Failed to toggle fullscreen: $e');
      }
    }());
  }

  @override
  void didUpdateWidget(SyncedLyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.id != widget.song.id && widget.song.id != _song.id) {
      setState(() => _song = widget.song);
      _loadLyrics();
    }
  }

  void _setupPositionListener() {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    Duration lastUpdate = Duration.zero;
    _positionSubscription = playerProvider.positionStream.listen((position) {
      final diff = (position - lastUpdate).abs();
      final wentBackwards = position < lastUpdate;
      if (diff.inMilliseconds >= 16 || wentBackwards) {
        lastUpdate = position;
        _lyricsController.setPosition(position);
      }
      if (playerProvider.isPlaying != _isPlaying) {
        _isPlaying = playerProvider.isPlaying;
      }
    });
  }

  Future<void> _loadLyrics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final subsonicService = Provider.of<SubsonicService>(
        context,
        listen: false,
      );
      final offlineService = OfflineService();
      final cached = await offlineService.getLocalLyrics(_song.id);
      final syncedData = cached?['lyricsList'] as Map<String, dynamic>? ??
          await subsonicService.getLyricsBySongId(_song.id);

      if (!mounted) return;

      if (syncedData != null) {
        final structuredLyrics = syncedData['structuredLyrics'];
        if (structuredLyrics is List && structuredLyrics.isNotEmpty) {
          final syncedEntry =
              structuredLyrics.cast<Map<String, dynamic>>().firstWhere(
                    (l) => l['synced'] == true,
                    orElse: () => <String, dynamic>{},
                  );
          final lines = syncedEntry['line'] as List?;
          if (lines != null && lines.isNotEmpty) {
            final parsedLines = lines
                .map<LyricLine>((line) {
                  final start = line['start'] as int? ?? 0;
                  return LyricLine(
                    timestamp: Duration(milliseconds: start),
                    text: line['value']?.toString() ?? '',
                  );
                })
                .where((line) => line.text.isNotEmpty)
                .toList();
            if (parsedLines.isNotEmpty) {
              _applyLyrics(SyncedLyrics(lines: parsedLines));
              return;
            }
          }
        }
      }

      final plainData = cached?['lyrics'] as Map<String, dynamic>? ??
          await subsonicService.getLyrics(
            artist: _song.artist,
            title: _song.title,
            id: _song.id,
          );

      if (plainData != null) {
        final value = plainData['value']?.toString();
        if (value != null && value.isNotEmpty) {
          if (value.contains('[') && value.contains(':')) {
            _applyLyrics(SyncedLyrics.fromLrc(value));
          } else {
            _applyLyrics(SyncedLyrics.fromPlainText(value));
          }
          return;
        }
      }

      // ── LRCLIB fallback ───────────────────────────────────────────────
      final storageService = StorageService();
      final lrcLibEnabled = await storageService.getLrcLibFallback();
      if (lrcLibEnabled && _song.artist != null) {
        final lrclib = LrcLibService();
        final fallbackLyrics = await lrclib.searchLyrics(
          artist: _song.artist!,
          title: _song.title,
          durationSeconds: _song.duration,
        );
        if (fallbackLyrics != null) {
          // Cache the result locally so we don't hit LRCLIB again
          final cacheMap = <String, dynamic>{};
          if (fallbackLyrics.containsKey('structuredLyrics')) {
            cacheMap['lyricsList'] = fallbackLyrics;
          } else {
            cacheMap['lyrics'] = fallbackLyrics;
          }
          await offlineService.saveLyrics(_song.id, cacheMap);

          if (fallbackLyrics.containsKey('structuredLyrics')) {
            final structured = fallbackLyrics['structuredLyrics'];
            if (structured is List && structured.isNotEmpty) {
              final entry = structured.cast<Map<String, dynamic>>().firstWhere(
                    (l) => l['synced'] == true,
                    orElse: () => <String, dynamic>{},
                  );
              final lines = entry['line'] as List?;
              if (lines != null && lines.isNotEmpty) {
                final parsedLines = lines
                    .map<LyricLine>((line) {
                      final start = line['start'] as int? ?? 0;
                      return LyricLine(
                        timestamp: Duration(milliseconds: start),
                        text: line['value']?.toString() ?? '',
                      );
                    })
                    .where((line) => line.text.isNotEmpty)
                    .toList();
                if (parsedLines.isNotEmpty) {
                  _applyLyrics(SyncedLyrics(lines: parsedLines));
                  return;
                }
              }
            }
          } else {
            final value = fallbackLyrics['value']?.toString();
            if (value != null && value.isNotEmpty) {
              if (value.contains('[') && value.contains(':')) {
                _applyLyrics(SyncedLyrics.fromLrc(value));
              } else {
                _applyLyrics(SyncedLyrics.fromPlainText(value));
              }
              return;
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _error = AppLocalizations.of(context)!.noLyricsAvailable;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = AppLocalizations.of(context)!.failedToLoadLyrics;
          _isLoading = false;
        });
      }
    }
  }

  void _applyLyrics(SyncedLyrics lyrics) {
    if (!mounted) return;
    setState(() {
      _lyrics = lyrics;
      _isLoading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _lyricsController.loadLines(lyrics.lines);
      final pos = Provider.of<PlayerProvider>(context, listen: false).position;
      _lyricsController.setPosition(pos);
    });
    _fadeController.forward(from: 0);
  }

  void _onLineTap(int index) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    playerProvider.seek(_lyricsController.lines[index].timestamp);
    _lyricsController.selectLine(index);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _lyricsController.clearSelection();
    });
  }

  void _returnToSyncedPosition() {
    _lyricsController.clearSelection();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );
    final String imageUrl;
    if (_song.id == widget.song.id && widget.imageUrl != null) {
      imageUrl = widget.imageUrl!;
    } else if (isLocalFilePath(_song.coverArt)) {
      imageUrl = _song.coverArt ?? '';
    } else {
      imageUrl = subsonicService.getCoverArtUrl(_song.coverArt, size: 1200);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(child: _buildAnimatedBackground(imageUrl)),
          RepaintBoundary(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(color: Colors.black.withValues(alpha: 0.6)),
            ),
          ),
          if (_isDesktop)
            _isFullscreen
                ? _buildFullscreenContent(context, imageUrl)
                : _buildDesktopContent(context, imageUrl)
          else
            _buildMobileContent(context),
          if (_isDesktop)
            Positioned(
              top: 24,
              right: 24,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildIconButton(
                    icon: _isFullscreen
                        ? Icons.fullscreen_exit_rounded
                        : Icons.fullscreen_rounded,
                    onTap: () {
                      final next = !_isFullscreen;
                      setState(() => _isFullscreen = next);
                      _setWindowFullscreen(next);
                    },
                    tooltip: _isFullscreen
                        ? AppLocalizations.of(context)!.exitFullscreen
                        : AppLocalizations.of(context)!.fullscreen,
                  ),
                  const SizedBox(width: 8),
                  _buildIconButton(
                    icon: Icons.close,
                    onTap: () {
                      _setWindowFullscreen(false);
                      widget.onClose?.call();
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildDesktopContent(BuildContext context, String imageUrl) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final artSize =
        math.min(screenWidth * 0.25, screenHeight * 0.45).clamp(200.0, 380.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 32.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: artSize + 40,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RepaintBoundary(
                  child: SizedBox(
                    height: artSize,
                    width: artSize,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                        ],
                        color: Colors.grey[900],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: isLocalFilePath(imageUrl)
                            ? Image.file(
                                File(imageUrl),
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) =>
                                    Container(color: Colors.grey[900]),
                              )
                            : CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                memCacheWidth: 1200,
                                memCacheHeight: 1200,
                                fadeInDuration: Duration.zero,
                                fadeOutDuration: Duration.zero,
                                useOldImageOnUrlChange: true,
                                placeholder: (ctx, url) =>
                                    Container(color: Colors.grey[900]),
                                errorWidget: (ctx, err, stack) =>
                                    Container(color: Colors.grey[900]),
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _song.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                if (_song.artist != null)
                  Text(
                    _song.artist!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 48),
          Expanded(child: _buildLyricsContent()),
        ],
      ),
    );
  }

  Widget _buildFullscreenContent(BuildContext context, String imageUrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 80.0, vertical: 48.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: _buildLyricsContent(isFullscreen: true),
        ),
      ),
    );
  }

  Widget _buildMobileContent(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildLyricsContent()),
          _buildBottomControls(context),
        ],
      ),
    );
  }

  Widget _buildLyricsContent({bool isFullscreen = false}) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
      );
    }

    if (_error != null || _lyrics == null || _lyrics!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.music_note_rounded,
                size: 80,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)!.noLyricsAvailable,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.lyricsNotFoundSubtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        FadeTransition(
          opacity: _fadeController,
          child: AMLLLyricsWidget(
            controller: _lyricsController,
            onLineTap: _onLineTap,
            onUserScroll: () {
              setState(() => _showReturnButton = true);
            },
            fontSize: isFullscreen ? 32.0 : (_isDesktop ? 26.0 : 24.0),
            lineGap: isFullscreen ? 32.0 : 24.0,
            enableBlur: true,
            alignPosition: isFullscreen ? 0.40 : 0.42,
          ),
        ),
        if (_showReturnButton)
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _returnToSyncedPosition,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.keyboard_arrow_up_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(context)!.backToCurrent,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAnimatedBackground(String imageUrl) {
    return AnimatedBuilder(
      animation: _bgAnimationController,
      builder: (context, child) {
        final scale = 1.2 + (_bgAnimationController.value * 0.2);
        final offsetX = (_bgAnimationController.value - 0.5) * 30;
        final offsetY = (_bgAnimationController.value - 0.5) * 20;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..translateByDouble(offsetX, offsetY, 0.0, 1.0)
            ..scaleByDouble(scale, scale, 1.0, 1.0),
          child: child,
        );
      },
      child: Container(
        color: Colors.black,
        child: isLocalFilePath(imageUrl)
            ? Image.file(
                File(imageUrl),
                key: ValueKey(imageUrl),
                fit: BoxFit.cover,
                cacheWidth: 300,
                cacheHeight: 300,
                errorBuilder: (ctx, err, stack) =>
                    Container(color: Colors.black),
              )
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                memCacheWidth: 1200,
                memCacheHeight: 1200,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
                useOldImageOnUrlChange: true,
                placeholder: (ctx, url) => Container(color: Colors.black),
                errorWidget: (ctx, err, stack) =>
                    Container(color: Colors.black),
              ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _song.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_song.artist != null)
                  Text(
                    _song.artist!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Column(
            children: [
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 14,
                  ),
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                  thumbColor: Colors.white,
                  overlayColor: Colors.white.withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: player.progress.clamp(0.0, 1.0),
                  onChanged: (value) {
                    final position = Duration(
                      milliseconds:
                          (value * player.duration.inMilliseconds).round(),
                    );
                    player.seek(position);
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: player.hasPrevious ? player.skipPrevious : null,
                    icon: Icon(
                      Icons.skip_previous_rounded,
                      color: player.hasPrevious
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.3),
                      size: 36,
                    ),
                  ),
                  GestureDetector(
                    onTap: player.isPlaying ? player.pause : player.play,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        player.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.black,
                        size: 32,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: player.hasNext ? player.skipNext : null,
                    icon: Icon(
                      Icons.skip_next_rounded,
                      color: player.hasNext
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.3),
                      size: 36,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main AMLL-style lyrics widget with spring scroll + gradient fill
// ─────────────────────────────────────────────────────────────────────────────

class AMLLLyricsWidget extends StatefulWidget {
  final AppleMusicLyricsController controller;
  final void Function(int index) onLineTap;
  final VoidCallback onUserScroll;
  final double fontSize;
  final double lineGap;
  final bool enableBlur;
  final double alignPosition; // 0.0-1.0, where active line sits vertically

  const AMLLLyricsWidget({
    super.key,
    required this.controller,
    required this.onLineTap,
    required this.onUserScroll,
    this.fontSize = 24.0,
    this.lineGap = 20.0,
    this.enableBlur = false,
    this.alignPosition = 0.5,
  });

  @override
  State<AMLLLyricsWidget> createState() => _AMLLLyricsWidgetState();
}

class _AMLLLyricsWidgetState extends State<AMLLLyricsWidget>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _lineKeys = {};

  int _lastActiveIndex = -1;
  bool _userScrolling = false;
  Timer? _scrollIdleTimer;

  // Spring-based scroll
  AnimationController? _springAnimController;

  // Cached viewport height from LayoutBuilder
  double _viewportHeight = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _scrollIdleTimer?.cancel();
    _springAnimController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    final idx = widget.controller.activeIndex;
    final indexChanged = idx != _lastActiveIndex;
    if (indexChanged && idx >= 0 && !_userScrolling) {
      _lastActiveIndex = idx;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _springScrollToLine(idx);
      });
    }
    if (indexChanged || widget.controller.isUserScrolling) {
      setState(() {});
    }
  }

  void _springScrollToLine(int index) {
    if (!_scrollController.hasClients) return;

    final key = _lineKeys[index];
    if (key == null || key.currentContext == null) {
      // ListView.builder hasn't rendered this item yet.
      // Estimate offset to force it into view, then retry on next frame.
      final estimatedItemHeight = widget.fontSize * 1.5 + widget.lineGap;
      final roughOffset = index * estimatedItemHeight -
          _scrollController.position.viewportDimension * widget.alignPosition +
          estimatedItemHeight / 2;
      final safeOffset = roughOffset.clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.jumpTo(safeOffset);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_userScrolling) _springScrollToLine(index);
      });
      return;
    }

    final box = key.currentContext!.findRenderObject() as RenderBox?;
    if (box == null) return;

    // Get position relative to scroll viewport
    final scrollBox = _scrollController.position.context.storageContext
        .findRenderObject() as RenderBox?;
    if (scrollBox == null) return;

    final linePos = box.localToGlobal(Offset.zero, ancestor: scrollBox);
    final viewportH = _scrollController.position.viewportDimension;
    final currentOffset = _scrollController.offset;

    // Target: line CENTER at alignPosition% from top of the viewport
    final absoluteLineCenter =
        currentOffset + linePos.dy + (box.size.height / 2);
    final targetViewportPos = viewportH * widget.alignPosition;

    final targetOffset = (absoluteLineCenter - targetViewportPos).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    // Spring animation — high damping avoids oscillation/over-scroll.
    _springAnimController?.dispose();
    _springAnimController = AnimationController.unbounded(vsync: this);
    _springAnimController!.value = currentOffset;

    final spring = SpringDescription(mass: 1.0, stiffness: 120, damping: 22);
    final simulation = SpringSimulation(spring, currentOffset, targetOffset, 0);

    _springAnimController!.addListener(() {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          _springAnimController!.value.clamp(
            0.0,
            _scrollController.position.maxScrollExtent,
          ),
        );
      }
    });

    _springAnimController!.animateWith(simulation);
  }

  void _onUserScrollStart() {
    if (!_userScrolling) {
      _userScrolling = true;
      widget.onUserScroll();
    }
    _scrollIdleTimer?.cancel();
    _scrollIdleTimer = Timer(const Duration(seconds: 5), () {
      _userScrolling = false;
      if (mounted) widget.controller.clearSelection();
    });
  }

  double _calculateBlur(int itemIndex, int activeIndex) {
    if (activeIndex < 0) return 0.0;
    final distance = (itemIndex - activeIndex).abs();
    if (distance == 0) return 0.0;
    if (distance == 1) return 1.2;
    if (distance == 2) return 2.8;
    if (distance == 3) return 4.5;
    return 6.0;
  }

  double _calculateScale(int itemIndex, int activeIndex) {
    if (activeIndex < 0) return 0.97;
    if (itemIndex == activeIndex) return 1.0;
    final distance = (itemIndex - activeIndex).abs();
    if (distance == 1) return 0.97;
    if (distance == 2) return 0.95;
    return 0.93;
  }

  double _calculateOpacity(int itemIndex, int activeIndex) {
    if (activeIndex < 0) return 0.55;
    if (itemIndex == activeIndex) return 1.0;
    // Past lines (already read)
    if (itemIndex < activeIndex) {
      final distance = activeIndex - itemIndex;
      if (distance == 1) return 0.38;
      if (distance <= 3) return 0.22;
      return 0.12;
    }
    // Future lines (not yet read) — Apple Music dims these aggressively
    final distance = itemIndex - activeIndex;
    if (distance == 1) return 0.28;
    if (distance <= 3) return 0.16;
    return 0.08;
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.controller.lines;
    final activeIndex = widget.controller.activeIndex;

    // Ensure keys exist
    for (int i = 0; i < lines.length; i++) {
      _lineKeys.putIfAbsent(i, () => GlobalKey());
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n is UserScrollNotification || n is ScrollUpdateNotification) {
          if (n is ScrollUpdateNotification && n.dragDetails != null) {
            _onUserScrollStart();
          }
        }
        return false;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          _viewportHeight = constraints.maxHeight;

          return ShaderMask(
            shaderCallback: (rect) => LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.white,
                Colors.white,
                Colors.transparent,
              ],
              stops: const [0.0, 0.10, 0.90, 1.0],
            ).createShader(rect),
            blendMode: BlendMode.dstIn,
            child: ListView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(
                left: 28,
                right: 28,
                // Use the actual widget height, not the full screen height
                top: _viewportHeight * widget.alignPosition,
                bottom: _viewportHeight * (1 - widget.alignPosition),
              ),
              itemCount: lines.length,
              itemBuilder: (context, index) {
                final isActive = index == activeIndex;
                final isSelected = index == widget.controller.selectedIndex;
                final opacity = _calculateOpacity(index, activeIndex);
                final scale = _calculateScale(index, activeIndex);
                final blur = _calculateBlur(index, activeIndex);

                return _AMLLLineWidget(
                  key: _lineKeys[index],
                  line: lines[index],
                  isActive: isActive,
                  isSelected: isSelected,
                  progressNotifier:
                      isActive ? widget.controller.progressNotifier : null,
                  positionNotifier:
                      isActive ? widget.controller.positionNotifier : null,
                  staticProgress: index < activeIndex ? 1.0 : 0.0,
                  targetOpacity: isActive || isSelected ? 1.0 : opacity,
                  targetScale: scale,
                  blurAmount: blur,
                  fontSize: widget.fontSize,
                  lineGap: widget.lineGap,
                  onTap: () => widget.onLineTap(index),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual lyric line with AMLL effects:
//  - spring scale/opacity animations
//  - gradient fill (played ← bright | dim → unplayed)
//  - blur for distant lines
//  - subtle float up when active
//  - improved multi-line gradient progress
// ─────────────────────────────────────────────────────────────────────────────

class _AMLLLineWidget extends StatefulWidget {
  final LyricLine line;
  final bool isActive;
  final bool isSelected;

  /// Only non-null for the active line — line progress [0.0-1.0] for fade-in.
  final ValueNotifier<double>? progressNotifier;

  /// Only non-null for the active line — raw position for word-by-word timing.
  final ValueNotifier<Duration>? positionNotifier;

  /// Static progress for non-active lines (0.0 or 1.0).
  final double staticProgress;
  final double targetOpacity;
  final double targetScale;
  final double blurAmount;
  final double fontSize;
  final double lineGap;
  final VoidCallback onTap;

  const _AMLLLineWidget({
    super.key,
    required this.line,
    required this.isActive,
    required this.isSelected,
    required this.progressNotifier,
    required this.positionNotifier,
    required this.staticProgress,
    required this.targetOpacity,
    required this.targetScale,
    required this.blurAmount,
    required this.fontSize,
    required this.lineGap,
    required this.onTap,
  });

  @override
  State<_AMLLLineWidget> createState() => _AMLLLineWidgetState();
}

class _AMLLLineWidgetState extends State<_AMLLLineWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  // Starting values for current transition
  double _startScale = 1.0;
  double _startOpacity = 1.0;
  double _startTranslateY = 0.0;
  double _startBlur = 0.0;

  // Target values when transition started
  double _targetScale = 1.0;
  double _targetOpacity = 1.0;
  double _targetTranslateY = 0.0;
  double _targetBlur = 0.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController.unbounded(vsync: this);

    _startScale = _targetScale = widget.targetScale;
    _startOpacity =
        _targetOpacity = widget.isActive ? 1.0 : widget.targetOpacity;
    _startTranslateY = _targetTranslateY = 0.0;
    _startBlur = _targetBlur = widget.blurAmount;

    // Set to 1.0 so the builder uses _target* values directly if no animation runs
    _animController.value = 1.0;
  }

  void _runSpring() {
    final t = _animController.value;

    // Calculate what the CURRENT visible values are, as the new starting point
    _startScale = _startScale + (_targetScale - _startScale) * t;
    _startOpacity =
        (_startOpacity + (_targetOpacity - _startOpacity) * t).clamp(0.0, 1.0);
    _startTranslateY =
        _startTranslateY + (_targetTranslateY - _startTranslateY) * t;
    _startBlur = math.max(0.0, _startBlur + (_targetBlur - _startBlur) * t);

    // Update targets
    _targetScale = widget.targetScale;
    _targetOpacity = widget.isActive ? 1.0 : widget.targetOpacity;
    _targetTranslateY = 0.0;
    _targetBlur = widget.blurAmount;

    // Match scroll spring so opacity/scale transitions feel in sync.
    final spring = const SpringDescription(
      mass: 1.0,
      stiffness: 120,
      damping: 22,
    );
    _animController.animateWith(SpringSimulation(spring, 0, 1, 0));
  }

  @override
  void didUpdateWidget(_AMLLLineWidget old) {
    super.didUpdateWidget(old);

    final targetOpacity = widget.isActive ? 1.0 : widget.targetOpacity;
    final oldTargetOpacity = old.isActive ? 1.0 : old.targetOpacity;

    if (widget.targetScale != old.targetScale ||
        targetOpacity != oldTargetOpacity ||
        widget.blurAmount != old.blurAmount) {
      _runSpring();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPlain = widget.line.timestamp == Duration.zero &&
        widget.staticProgress == 0.0 &&
        !widget.isActive;

    // For plain (unsynced) lyrics
    if (isPlain) {
      return Padding(
        padding: EdgeInsets.only(bottom: widget.lineGap),
        child: Text(
          widget.line.text,
          textAlign: TextAlign.left,
          style: TextStyle(
            fontSize: widget.fontSize,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.7),
            height: 1.35,
            letterSpacing: -0.3,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          final t = _animController.value;

          final scale = _startScale + (_targetScale - _startScale) * t;
          final opacity = (_startOpacity + (_targetOpacity - _startOpacity) * t)
              .clamp(0.0, 1.0);
          final translateY =
              _startTranslateY + (_targetTranslateY - _startTranslateY) * t;
          final blur = math.max(
            0.0,
            _startBlur + (_targetBlur - _startBlur) * t,
          );

          Widget lineWidget = Padding(
            padding: EdgeInsets.only(bottom: widget.lineGap),
            child: Transform.translate(
              offset: Offset(0, translateY),
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.centerLeft,
                child: child,
              ),
            ),
          );

          if (opacity < 1.0) {
            lineWidget = Opacity(opacity: opacity, child: lineWidget);
          }

          if (blur > 0.5) {
            lineWidget = ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: lineWidget,
            );
          }

          return lineWidget;
        },
        child: _buildGradientChild(),
      ),
    );
  }

  Widget _buildGradientChild() {
    final textStyle = TextStyle(
      fontSize: widget.fontSize,
      fontWeight: (widget.isActive || widget.isSelected)
          ? FontWeight.w800
          : FontWeight.w700,
      color: Colors.white,
      height: 1.35,
      letterSpacing: -0.5,
    );

    // ── Active word-by-word line ──────────────────────────────────────────────
    if (widget.isActive && widget.line.hasWordTimestamps) {
      return ValueListenableBuilder<Duration>(
        valueListenable:
            widget.positionNotifier ?? ValueNotifier(Duration.zero),
        builder: (context, position, _) {
          final words = widget.line.words!;
          int activeWordIdx = -1;
          for (int i = 0; i < words.length; i++) {
            if (position >= words[i].timestamp) {
              activeWordIdx = i;
            } else {
              break;
            }
          }

          if (activeWordIdx >= words.length - 1 && activeWordIdx >= 0) {
            return Text(
              widget.line.text,
              textAlign: TextAlign.left,
              style: textStyle.copyWith(
                shadows: [
                  Shadow(
                      color: Colors.white.withValues(alpha: 0.55),
                      blurRadius: 28),
                  Shadow(
                      color: Colors.white.withValues(alpha: 0.25),
                      blurRadius: 48),
                ],
              ),
            );
          }

          final spans = <TextSpan>[];
          for (int i = 0; i < words.length; i++) {
            if (i > 0) {
              final spaceAlpha = i <= activeWordIdx ? 0.85 : 0.28;
              spans.add(TextSpan(
                text: ' ',
                style: textStyle.copyWith(
                    color: Colors.white.withValues(alpha: spaceAlpha)),
              ));
            }
            final isPast = i < activeWordIdx;
            final isCurrent = i == activeWordIdx;
            spans.add(TextSpan(
              text: words[i].text,
              style: textStyle.copyWith(
                color: Colors.white.withValues(
                    alpha: isPast
                        ? 0.85
                        : isCurrent
                            ? 1.0
                            : 0.28),
                shadows: isCurrent
                    ? [
                        Shadow(
                            color: Colors.white.withValues(alpha: 0.6),
                            blurRadius: 28),
                        Shadow(
                            color: Colors.white.withValues(alpha: 0.25),
                            blurRadius: 48),
                      ]
                    : null,
              ),
            ));
          }
          return Text.rich(TextSpan(children: spans),
              textAlign: TextAlign.left);
        },
      );
    }

    // ── Active regular synced line — fade-in whole line ───────────────────────
    if (widget.isActive && widget.line.timestamp != Duration.zero) {
      return ValueListenableBuilder<double>(
        valueListenable: widget.progressNotifier ?? ValueNotifier(0.0),
        builder: (context, progress, _) {
          if (progress >= 1.0) {
            return Text(
              widget.line.text,
              textAlign: TextAlign.left,
              style: textStyle.copyWith(
                shadows: [
                  Shadow(
                      color: Colors.white.withValues(alpha: 0.4),
                      blurRadius: 16)
                ],
              ),
            );
          }
          final fadeProgress = (progress / 0.15).clamp(0.0, 1.0);
          final alpha = 0.28 + (0.72 * fadeProgress);
          return Text(
            widget.line.text,
            textAlign: TextAlign.left,
            style: textStyle.copyWith(
              color: Colors.white.withValues(alpha: alpha),
              shadows: fadeProgress > 0.5
                  ? [
                      Shadow(
                          color: Colors.white.withValues(
                              alpha: 0.55 * (fadeProgress - 0.5) * 2),
                          blurRadius: 28),
                      Shadow(
                          color: Colors.white.withValues(
                              alpha: 0.25 * (fadeProgress - 0.5) * 2),
                          blurRadius: 48),
                    ]
                  : null,
            ),
          );
        },
      );
    }

    // ── Selected / past / active-unsynced ─────────────────────────────────────
    if (widget.isActive || widget.isSelected || widget.staticProgress >= 1.0) {
      return Text(
        widget.line.text,
        textAlign: TextAlign.left,
        style: textStyle.copyWith(
          shadows: (widget.isActive || widget.isSelected)
              ? [
                  Shadow(
                      color: Colors.white.withValues(alpha: 0.55),
                      blurRadius: 28),
                  Shadow(
                      color: Colors.white.withValues(alpha: 0.25),
                      blurRadius: 48),
                ]
              : null,
        ),
      );
    }

    // ── Dim future line ───────────────────────────────────────────────────────
    return Text(
      widget.line.text,
      textAlign: TextAlign.left,
      style: textStyle.copyWith(color: Colors.white.withValues(alpha: 0.28)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LyricsButton
// ─────────────────────────────────────────────────────────────────────────────

class LyricsButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isActive;

  const LyricsButton({super.key, this.onPressed, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lyrics_rounded,
              size: 18,
              color:
                  isActive ? Colors.white : Colors.white.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 4),
            Builder(
              builder: (context) => Text(
                AppLocalizations.of(context)!.lyrics,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isActive
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
