import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_lyric/flutter_lyric.dart';
import '../models/lyrics.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../services/subsonic_service.dart';

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

  // Track song internally to handle updates independent of parent
  late Song _song;

  bool _isPlaying = false;

  bool _isFullscreen = false;
  bool _showReturnButton = false;

  // flutter_lyric controller
  LyricController? _lyricController;

  // Throttle position updates for performance
  Duration _lastUpdatePosition = Duration.zero;

  bool get _isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30), // Slower animation = less GPU work
    )..repeat(reverse: true);

    _song = widget.song;
    _loadLyrics();
    _setupPositionListener();
    _maybeSetHighRefreshRate();

    // Listen to Song changes from provider directly (since this is a pushed route)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PlayerProvider>(
        context,
        listen: false,
      ).addListener(_onPlayerStateChanged);
    });
  }

  @override
  void dispose() {
    // Try/catch in case provider is already disposed
    try {
      Provider.of<PlayerProvider>(
        context,
        listen: false,
      ).removeListener(_onPlayerStateChanged);
    } catch (_) {}

    _positionSubscription?.cancel();
    _fadeController.dispose();
    _bgAnimationController.dispose();
    _lyricController?.dispose();
    if (_isDesktop && _isFullscreen) {
      _setWindowFullscreen(false);
    }
    super.dispose();
  }

  void _onPlayerStateChanged() {
    if (!mounted) return;
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final currentSong = playerProvider.currentSong;

    if (currentSong != null && currentSong.id != _song.id) {
      setState(() {
        _song = currentSong;
      });
      _loadLyrics();
    }
  }

  Future<void> _maybeSetHighRefreshRate() async {
    try {
      if (!Platform.isAndroid) return;
      final battery = Battery();
      final level = await battery.batteryLevel;
      if (level > 15) {
        await FlutterDisplayMode.setHighRefreshRate();
      }
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
    if (oldWidget.song.id != widget.song.id) {
      // If parent triggers update, sync internal state
      if (widget.song.id != _song.id) {
        setState(() {
          _song = widget.song;
        });
        _loadLyrics();
      }
    }
  }

  void _setupPositionListener() {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    _positionSubscription = playerProvider.positionStream.listen((position) {
      // Throttle updates - update more frequently (approx 30fps) to catch fast lyrics
      final diff = (position - _lastUpdatePosition).abs();
      final wentBackwards = position < _lastUpdatePosition;

      if (diff.inMilliseconds >= 32 || wentBackwards) {
        _lastUpdatePosition = position;
        _lyricController?.setProgress(position);
      }

      if (playerProvider.isPlaying != _isPlaying) {
        _isPlaying = playerProvider.isPlaying;
      }
    });
  }

  bool _canShowReturnButton = false;

  void _initializeLyricController() {
    _lyricController?.dispose();
    _lyricController = LyricController();

    // Ignore updates during initial layout
    _canShowReturnButton = false;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _canShowReturnButton = true;
    });

    // Set up tap callback to seek
    _lyricController!.setOnTapLineCallback((Duration position) {
      final playerProvider = Provider.of<PlayerProvider>(
        context,
        listen: false,
      );
      playerProvider.seek(position);

      if (mounted) {
        setState(() => _showReturnButton = true);
      }
    });

    // Listen for selection events to show/hide return button
    _lyricController!.registerEvent(LyricEvent.stopSelection, (_) {
      if (mounted && _canShowReturnButton) {
        setState(() => _showReturnButton = true);
      }
    });

    _lyricController!.registerEvent(LyricEvent.resumeActiveLine, (_) {
      if (mounted) {
        setState(() => _showReturnButton = false);
      }
    });
  }

  String _convertToLrc(SyncedLyrics lyrics) {
    final buffer = StringBuffer();
    for (final line in lyrics.lines) {
      final minutes = line.timestamp.inMinutes;
      final seconds = line.timestamp.inSeconds % 60;
      final milliseconds = line.timestamp.inMilliseconds % 1000;
      final centiseconds = (milliseconds / 10).floor();
      buffer.writeln(
        '[${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${centiseconds.toString().padLeft(2, '0')}]${line.text}',
      );
    }
    return buffer.toString();
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

      final syncedData = await subsonicService.getLyricsBySongId(_song.id);

      if (syncedData != null) {
        final structuredLyrics = syncedData['structuredLyrics'];
        if (structuredLyrics is List && structuredLyrics.isNotEmpty) {
          final lyrics = structuredLyrics.first;
          final lines = lyrics['line'] as List?;
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
              setState(() {
                _lyrics = SyncedLyrics(lines: parsedLines);
                _isLoading = false;
              });
              _initializeLyricController();
              _lyricController!.loadLyric(_convertToLrc(_lyrics!));
              _fadeController.forward();
              return;
            }
          }
        }
      }

      final plainData = await subsonicService.getLyrics(
        artist: _song.artist,
        title: _song.title,
      );

      if (plainData != null) {
        final value = plainData['value']?.toString();
        if (value != null && value.isNotEmpty) {
          if (value.contains('[') && value.contains(':')) {
            setState(() {
              _lyrics = SyncedLyrics.fromLrc(value);
              _isLoading = false;
            });
            _initializeLyricController();
            _lyricController!.loadLyric(value);
          } else {
            setState(() {
              _lyrics = SyncedLyrics.fromPlainText(value);
              _isLoading = false;
            });
            _initializeLyricController();
            _lyricController!.loadLyric(_convertToLrc(_lyrics!));
          }
          _fadeController.forward();
          return;
        }
      }

      setState(() {
        _error = 'No lyrics available';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load lyrics';
        _isLoading = false;
      });
    }
  }

  void _returnToSyncedPosition() {
    // Simply hide the button - the LyricStyle auto-resume will handle scrolling
    setState(() {
      _showReturnButton = false;
    });
  }

  LyricStyle _buildLyricStyle({bool isFullscreen = false}) {
    final baseFontSize = isFullscreen ? 32.0 : (_isDesktop ? 24.0 : 24.0);

    return LyricStyle(
      textStyle: TextStyle(
        fontSize: baseFontSize,
        fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: 0.4),
        height: 1.35,
        letterSpacing: -0.5,
      ),
      activeStyle: TextStyle(
        fontSize: baseFontSize,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        height: 1.35,
        letterSpacing: -0.5,
        shadows: [
          Shadow(color: Colors.white.withValues(alpha: 0.3), blurRadius: 8),
        ],
      ),
      translationStyle: TextStyle(
        fontSize: baseFontSize * 0.75,
        fontWeight: FontWeight.w500,
        color: Colors.white.withValues(alpha: 0.5),
        height: 1.3,
      ),
      lineGap: isFullscreen ? 32.0 : 24.0,
      translationLineGap: 8.0,
      lineTextAlign: TextAlign.center,
      contentAlignment: CrossAxisAlignment.center,
      fadeRange: FadeRange(top: 80.0, bottom: 80.0),
      scrollDuration: const Duration(milliseconds: 400),
      scrollCurve: Curves.easeOutCubic,
      activeHighlightColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(
        horizontal: isFullscreen ? 24 : 28,
        vertical: 100,
      ),
      selectionAnchorPosition: 0.5,
      selectionAlignment: MainAxisAlignment.center,
      selectedColor: Colors.white.withValues(alpha: 0.8),
      selectedTranslationColor: Colors.white.withValues(alpha: 0.6),
      selectionAutoResumeDuration: const Duration(milliseconds: 500),
      activeAutoResumeDuration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );
    final imageUrl = (_song.id == widget.song.id && widget.imageUrl != null)
        ? widget.imageUrl!
        : subsonicService.getCoverArtUrl(_song.coverArt, size: 600);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(child: _buildAnimatedBackground(imageUrl)),

          RepaintBoundary(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 40,
                sigmaY: 40,
              ), // Reduced blur for better performance
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
                  IconButton(
                    onPressed: () {
                      final next = !_isFullscreen;
                      setState(() => _isFullscreen = next);
                      _setWindowFullscreen(next);
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isFullscreen
                            ? Icons.fullscreen_exit_rounded
                            : Icons.fullscreen_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    tooltip: _isFullscreen ? 'Exit Fullscreen' : 'Fullscreen',
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      _setWindowFullscreen(false);
                      widget.onClose?.call();
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopContent(BuildContext context, String imageUrl) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final artSize = math
        .min(screenWidth * 0.25, screenHeight * 0.45)
        .clamp(200.0, 380.0);

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
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                        ],
                        color: Colors.grey[900],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          memCacheWidth: 600,
                          memCacheHeight: 600,
                          fadeInDuration: Duration.zero,
                          fadeOutDuration: Duration.zero,
                          useOldImageOnUrlChange: true,
                          placeholder: (_, __) =>
                              Container(color: Colors.grey[900]),
                          errorWidget: (_, __, ___) =>
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
                      color: Colors.white.withOpacity(0.7),
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
                color: Colors.white.withOpacity(0.2),
              ),
              const SizedBox(height: 24),
              Text(
                'No lyrics available',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Lyrics for this song couldn\'t be found',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
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
          child: LyricView(
            controller: _lyricController!,
            style: _buildLyricStyle(isFullscreen: isFullscreen),
            width: double.infinity,
            height: double.infinity,
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
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.keyboard_arrow_up_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Back to current',
                        style: TextStyle(
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
        final scale =
            1.2 + (_bgAnimationController.value * 0.2); // Reduced scale range
        final offsetX =
            (_bgAnimationController.value - 0.5) * 30; // Reduced offset
        final offsetY = (_bgAnimationController.value - 0.5) * 20;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..translate(offsetX, offsetY)
            ..scale(scale),
          child: child,
        );
      },
      child: Container(
        color: Colors.black,
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          memCacheWidth: 300, // Reduced cache size
          memCacheHeight: 300,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          useOldImageOnUrlChange: true,
          placeholder: (_, __) => Container(color: Colors.black),
          errorWidget: (_, __, ___) => Container(color: Colors.black),
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
                color: Colors.white.withOpacity(0.15),
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
                      color: Colors.white.withOpacity(0.7),
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
                  inactiveTrackColor: Colors.white.withOpacity(0.3),
                  thumbColor: Colors.white,
                  overlayColor: Colors.white.withOpacity(0.2),
                ),
                child: Slider(
                  value: player.progress.clamp(0.0, 1.0),
                  onChanged: (value) {
                    final position = Duration(
                      milliseconds: (value * player.duration.inMilliseconds)
                          .round(),
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
                          : Colors.white.withOpacity(0.3),
                      size: 36,
                    ),
                  ),
                  GestureDetector(
                    onTap: player.isPlaying ? player.pause : player.play,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
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
                          : Colors.white.withOpacity(0.3),
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
              ? Colors.white.withOpacity(0.2)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lyrics_rounded,
              size: 18,
              color: isActive ? Colors.white : Colors.white.withOpacity(0.7),
            ),
            const SizedBox(width: 4),
            Text(
              'Lyrics',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isActive ? Colors.white : Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
