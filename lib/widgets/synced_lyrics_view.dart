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
import '../models/lyrics.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../services/subsonic_service.dart';
import '../services/bpm_analyzer_service.dart';

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
  int _currentLineIndex = -1;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _fadeController;
  late AnimationController _bgAnimationController;
  late AnimationController _dotsController;
  StreamSubscription<Duration>? _positionSubscription;

  Duration _timeUntilFirstLyric = Duration.zero;
  bool _isPlaying = false;

  final _bpmAnalyzer = BpmAnalyzerService();
  bool _bpmInitialized = false;

  bool _isUserScrolling = false;
  bool _showReturnButton = false;
  Timer? _userScrollTimer;
  bool _isFullscreen = false;

  // GlobalKeys for each lyric line for precise scrolling
  final Map<int, GlobalKey> _itemKeys = {};

  // Cache for line heights to avoid expensive TextPainter calculations
  final Map<String, double> _heightCache = {};
  final Map<String, double> _activeHeightCache = {};

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
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();

    _loadLyrics();
    _setupPositionListener();
    _initializeBPM();
    _setupScrollListener();
    _maybeSetHighRefreshRate();
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

  void _setupScrollListener() {
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.position.isScrollingNotifier.value) return;

    _isUserScrolling = true;
    _userScrollTimer?.cancel();

    _checkScrollDistance();

    _userScrollTimer = Timer(const Duration(milliseconds: 500), () {
      _checkAutoResync();
    });
  }

  void _checkScrollDistance() {
    if (_lyrics == null || _currentLineIndex < 0) return;

    // Check if waiting dots are being shown
    final hasSyncedTimestamps = _lyrics!.lines.any(
      (line) => line.timestamp != Duration.zero,
    );
    final showWaitingDots =
        hasSyncedTimestamps &&
        _lyrics!.lines.first.timestamp > Duration.zero &&
        _timeUntilFirstLyric.inMilliseconds > 0;

    double expectedOffset = 0.0;

    // Account for waiting dots row if present
    if (showWaitingDots) {
      expectedOffset += 50.0;
    }

    for (int i = 0; i < _currentLineIndex; i++) {
      expectedOffset += _estimateLineHeight(_lyrics!.lines[i].text);
    }

    if (_scrollController.hasClients) {
      expectedOffset = expectedOffset.clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
    }

    final currentOffset = _scrollController.offset;
    final distance = (currentOffset - expectedOffset).abs();

    final threshold = _isDesktop
        ? 250.0
        : MediaQuery.of(context).size.height / 3;
    if (distance > threshold && !_showReturnButton) {
      setState(() {
        _showReturnButton = true;
      });
    } else if (distance <= threshold && _showReturnButton) {
      setState(() {
        _showReturnButton = false;
      });
    }
  }

  void _checkAutoResync() {
    if (_lyrics == null || _currentLineIndex < 0) return;

    // Check if waiting dots are being shown
    final hasSyncedTimestamps = _lyrics!.lines.any(
      (line) => line.timestamp != Duration.zero,
    );
    final showWaitingDots =
        hasSyncedTimestamps &&
        _lyrics!.lines.first.timestamp > Duration.zero &&
        _timeUntilFirstLyric.inMilliseconds > 0;

    double expectedOffset = 0.0;

    // Account for waiting dots row if present
    if (showWaitingDots) {
      expectedOffset += 50.0;
    }

    for (int i = 0; i < _currentLineIndex; i++) {
      expectedOffset += _estimateLineHeight(_lyrics!.lines[i].text);
    }

    if (_scrollController.hasClients) {
      expectedOffset = expectedOffset.clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
    }

    final currentOffset = _scrollController.offset;
    final distance = (currentOffset - expectedOffset).abs();

    final threshold = _isDesktop ? 220.0 : 150.0;
    if (distance <= threshold) {
      _isUserScrolling = false;
      setState(() {
        _showReturnButton = false;
      });

      _scrollToCurrentLine();
    }
  }

  void _returnToSyncedPosition() {
    _isUserScrolling = false;
    setState(() {
      _showReturnButton = false;
    });
    _scrollToCurrentLine();
  }

  Future<void> _initializeBPM() async {
    if (_bpmInitialized) return;

    try {
      final subsonicService = Provider.of<SubsonicService>(
        context,
        listen: false,
      );
      final audioUrl = subsonicService.getStreamUrl(widget.song.id);

      final bpm = await _bpmAnalyzer.getBPM(widget.song, audioUrl);

      if (mounted) {
        final beatDuration = (60000 / bpm).round();
        _dotsController.duration = Duration(milliseconds: beatDuration);
        _bpmInitialized = true;
      }
    } catch (e) {
      debugPrint('Error initializing BPM: $e');
    }
  }

  @override
  void didUpdateWidget(SyncedLyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.id != widget.song.id) {
      _bpmInitialized = false;
      _loadLyrics();
      _initializeBPM();
    }
  }

  void _setupPositionListener() {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    _positionSubscription = playerProvider.positionStream.listen((position) {
      if (_lyrics != null && _lyrics!.isNotEmpty) {
        final firstTimestamp = _lyrics!.lines.first.timestamp;
        _timeUntilFirstLyric = firstTimestamp - position;

        final isNowPlaying = playerProvider.isPlaying;
        if (isNowPlaying != _isPlaying) {
          _isPlaying = isNowPlaying;
          if (_isPlaying) {
            _dotsController.repeat();
          } else {
            _dotsController.stop();
          }
        }

        final newIndex = _lyrics!.getCurrentLineIndex(position);
        if (newIndex != _currentLineIndex) {
          setState(() {
            _currentLineIndex = newIndex;
          });
          _scrollToCurrentLine();
        }
      }
    });
  }

  Future<void> _loadLyrics() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentLineIndex = -1;
    });

    try {
      final subsonicService = Provider.of<SubsonicService>(
        context,
        listen: false,
      );

      final syncedData = await subsonicService.getLyricsBySongId(
        widget.song.id,
      );

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
              _fadeController.forward();

              WidgetsBinding.instance.addPostFrameCallback((_) {
                _updateCurrentLineAndScroll();
              });
              return;
            }
          }
        }
      }

      final plainData = await subsonicService.getLyrics(
        artist: widget.song.artist,
        title: widget.song.title,
      );

      if (plainData != null) {
        final value = plainData['value']?.toString();
        if (value != null && value.isNotEmpty) {
          if (value.contains('[') && value.contains(':')) {
            setState(() {
              _lyrics = SyncedLyrics.fromLrc(value);
              _isLoading = false;
            });
          } else {
            setState(() {
              _lyrics = SyncedLyrics.fromPlainText(value);
              _isLoading = false;
            });
          }
          _fadeController.forward();

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateCurrentLineAndScroll();
          });
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

  double _estimateLineHeight(String text, {bool isActive = false}) {
    // Use cached value if available
    final cacheKey = '$text-$isActive';
    final cache = isActive ? _activeHeightCache : _heightCache;

    if (cache.containsKey(cacheKey)) {
      return cache[cacheKey]!;
    }

    final fontSize = isActive ? 28.0 : 22.0;
    final verticalPadding = isActive ? 14.0 * 2 : 8.0 * 2;

    final screenWidth = MediaQuery.of(context).size.width;

    final availableWidth = _isDesktop
        ? (screenWidth * 0.6) - 100
        : screenWidth - 28 * 2 - 4 * 2;

    // Use TextPainter for precise measurements
    final textStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
      height: 1.3,
    );

    final textSpan = TextSpan(text: text, style: textStyle);

    final textPainter = TextPainter(
      text: textSpan,
      maxLines: null,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(maxWidth: availableWidth);

    // Cache the result for future use
    final height = textPainter.height + verticalPadding;
    cache[cacheKey] = height;

    return height;
  }

  void _updateCurrentLineAndScroll() {
    if (_lyrics == null || _lyrics!.lines.isEmpty) return;

    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final position = playerProvider.position;
    final newIndex = _lyrics!.getCurrentLineIndex(position);

    if (newIndex != _currentLineIndex) {
      setState(() {
        _currentLineIndex = newIndex;
      });
    }

    if (_currentLineIndex >= 0) {
      _scrollToCurrentLine();
    }
  }

  void _scrollToCurrentLine({bool isRetry = false}) {
    if (_currentLineIndex < 0) return;
    if (_lyrics == null) return;
    if (_isUserScrolling) return;

    // Get or create the GlobalKey for the current line
    final key = _itemKeys[_currentLineIndex];
    if (key == null) {
      if (!isRetry) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _scrollToCurrentLine(isRetry: true);
          }
        });
      }
      return;
    }

    final currentContext = key.currentContext;
    if (currentContext == null) {
      if (!isRetry) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _scrollToCurrentLine(isRetry: true);
          }
        });
      }
      return;
    }

    // Schedule scroll after frame to let AnimatedPadding settle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_isUserScrolling) return;

      final ctx = key.currentContext;
      if (ctx == null) return;

      // Use Scrollable.ensureVisible for precise scrolling
      // alignment 0.5 = exact center
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.linear,
        alignment: 0.5,
      );
    });
  }

  void _seekToLine(int index) {
    if (_lyrics == null || index >= _lyrics!.lines.length) return;

    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final position = _lyrics!.lines[index].timestamp;
    playerProvider.seek(position);
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _userScrollTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _fadeController.dispose();
    _bgAnimationController.dispose();
    _dotsController.dispose();
    if (_isDesktop && _isFullscreen) {
      _setWindowFullscreen(false);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );
    final imageUrl =
        widget.imageUrl ??
        subsonicService.getCoverArtUrl(widget.song.coverArt, size: 600);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildAnimatedBackground(imageUrl),

          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(color: Colors.black.withOpacity(0.6)),
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
                  widget.song.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                if (widget.song.artist != null)
                  Text(
                    widget.song.artist!,
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

          Expanded(child: _buildDesktopLyricsContent()),
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
          child: _buildFullscreenLyricsContent(),
        ),
      ),
    );
  }

  Widget _buildFullscreenLyricsContent() {
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
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        FadeTransition(
          opacity: _fadeController,
          child: _buildFullscreenLyricsList(),
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

  Widget _buildFullscreenLyricsList() {
    final hasSyncedTimestamps = _lyrics!.lines.any(
      (line) => line.timestamp != Duration.zero,
    );

    final showWaitingDots =
        hasSyncedTimestamps &&
        _lyrics!.lines.first.timestamp > Duration.zero &&
        _timeUntilFirstLyric.inMilliseconds > 0;

    final itemCount = _lyrics!.lines.length + (showWaitingDots ? 1 : 0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final avgLineHeight = 60.0;
        final verticalPadding = (constraints.maxHeight - avgLineHeight) / 2;

        return ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.white,
                Colors.white,
                Colors.transparent,
              ],
              stops: const [0.0, 0.15, 0.85, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(scrollbars: false),
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(
                horizontal: 24,
                vertical: verticalPadding,
              ),
              itemCount: itemCount,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                if (showWaitingDots && index == 0) {
                  return SizedBox(
                    width: double.infinity,
                    child: Center(child: _buildWaitingDotsRow()),
                  );
                }

                final lyricIndex = showWaitingDots ? index - 1 : index;
                final line = _lyrics!.lines[lyricIndex];
                final isActive = lyricIndex == _currentLineIndex;
                final isPast = lyricIndex < _currentLineIndex;

                // Get or create GlobalKey for this lyric line
                _itemKeys[lyricIndex] ??= GlobalKey();

                return GestureDetector(
                  key: _itemKeys[lyricIndex],
                  onTap: hasSyncedTimestamps
                      ? () => _seekToLine(lyricIndex)
                      : null,
                  child: AnimatedPadding(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    padding: EdgeInsets.symmetric(
                      vertical: isActive ? 18 : 12,
                      horizontal: 4,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        style: TextStyle(
                          fontSize: isActive ? 38 : 30,
                          fontWeight: isActive
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: isActive
                              ? Colors.white
                              : isPast
                              ? Colors.white.withOpacity(0.25)
                              : Colors.white.withOpacity(0.4),
                          height: 1.3,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                        child: Text(line.text, textAlign: TextAlign.center),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileContent(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildContent()),
          _buildBottomControls(context),
        ],
      ),
    );
  }

  Widget _buildDesktopLyricsContent() {
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
          child: _buildDesktopLyricsList(),
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

  Widget _buildDesktopLyricsList() {
    final hasSyncedTimestamps = _lyrics!.lines.any(
      (line) => line.timestamp != Duration.zero,
    );

    final showWaitingDots =
        hasSyncedTimestamps &&
        _lyrics!.lines.first.timestamp > Duration.zero &&
        _currentLineIndex < 0;

    final itemCount = _lyrics!.lines.length + (showWaitingDots ? 1 : 0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final avgLineHeight = 50.0;
        final verticalPadding = (constraints.maxHeight - avgLineHeight) / 2;

        return ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.white,
                Colors.white,
                Colors.transparent,
              ],
              stops: const [0.0, 0.12, 0.88, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(scrollbars: false),
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(
                horizontal: 24,
                vertical: verticalPadding,
              ),
              itemCount: itemCount,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                if (showWaitingDots && index == 0) {
                  return SizedBox(
                    width: double.infinity,
                    child: Center(child: _buildWaitingDotsRow()),
                  );
                }

                final lyricIndex = showWaitingDots ? index - 1 : index;
                final line = _lyrics!.lines[lyricIndex];
                final isActive = lyricIndex == _currentLineIndex;
                final isPast = lyricIndex < _currentLineIndex;

                // Get or create GlobalKey for this lyric line
                _itemKeys[lyricIndex] ??= GlobalKey();

                return GestureDetector(
                  key: _itemKeys[lyricIndex],
                  onTap: hasSyncedTimestamps
                      ? () => _seekToLine(lyricIndex)
                      : null,
                  child: AnimatedPadding(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    padding: EdgeInsets.symmetric(
                      vertical: isActive ? 14 : 8,
                      horizontal: 4,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        style: TextStyle(
                          fontSize: isActive ? 28 : 22,
                          fontWeight: isActive
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: isActive
                              ? Colors.white
                              : isPast
                              ? Colors.white.withOpacity(0.25)
                              : Colors.white.withOpacity(0.4),
                          height: 1.3,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                        child: Text(line.text, textAlign: TextAlign.center),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedBackground(String imageUrl) {
    return AnimatedBuilder(
      animation: _bgAnimationController,
      builder: (context, child) {
        final scale = 1.3 + (_bgAnimationController.value * 0.3);
        final offsetX = (_bgAnimationController.value - 0.5) * 50;
        final offsetY = (_bgAnimationController.value - 0.5) * 30;

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
          memCacheWidth: 400,
          memCacheHeight: 400,
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
                  widget.song.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.song.artist != null)
                  Text(
                    widget.song.artist!,
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

  Widget _buildContent() {
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
        FadeTransition(opacity: _fadeController, child: _buildLyricsList()),

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

  Widget _buildWaitingDotsRow() {
    double opacity = 1.0;
    if (_timeUntilFirstLyric.inMilliseconds <= 500 &&
        _timeUntilFirstLyric.inMilliseconds > 0) {
      opacity = _timeUntilFirstLyric.inMilliseconds / 500.0;
    } else if (_timeUntilFirstLyric.inMilliseconds <= 0) {
      opacity = 0.0;
    }

    return AnimatedOpacity(
      opacity: opacity,
      duration: const Duration(milliseconds: 100),
      child: AnimatedBuilder(
        animation: _dotsController,
        builder: (context, child) {
          final beatIndex = (_dotsController.value * 3).floor() % 3;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              mainAxisAlignment: _isDesktop
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                final isActive = index == beatIndex && _isPlaying;

                final progress = (_dotsController.value * 3) % 1.0;
                double scale = 1.0;
                double dotOpacity = 0.4;

                if (isActive) {
                  scale = 1.0 + (0.8 * (1.0 - (progress * 2 - 1).abs()));
                  dotOpacity = 0.8 + (0.2 * (1.0 - (progress * 2 - 1).abs()));
                } else if (!_isPlaying) {
                  scale = 1.0;
                  dotOpacity = 0.5;
                }

                return Container(
                  margin: const EdgeInsets.only(right: 10),
                  width: 10,
                  height: 10,
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(dotOpacity),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLyricsList() {
    final hasSyncedTimestamps = _lyrics!.lines.any(
      (line) => line.timestamp != Duration.zero,
    );

    final showWaitingDots =
        hasSyncedTimestamps &&
        _lyrics!.lines.first.timestamp > Duration.zero &&
        _timeUntilFirstLyric.inMilliseconds > 0;

    final itemCount = _lyrics!.lines.length + (showWaitingDots ? 1 : 0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final avgLineHeight = 45.0;
        final verticalPadding = (constraints.maxHeight - avgLineHeight) / 2;

        return ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.white,
                Colors.white,
                Colors.transparent,
              ],
              stops: const [0.0, 0.12, 0.88, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.symmetric(
              horizontal: 28,
              vertical: verticalPadding,
            ),
            itemCount: itemCount,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              if (showWaitingDots && index == 0) {
                return SizedBox(
                  width: double.infinity,
                  child: Center(child: _buildWaitingDotsRow()),
                );
              }

              final lyricIndex = showWaitingDots ? index - 1 : index;
              final line = _lyrics!.lines[lyricIndex];
              final isActive = lyricIndex == _currentLineIndex;
              final isPast = lyricIndex < _currentLineIndex;

              // Get or create GlobalKey for this lyric line
              _itemKeys[lyricIndex] ??= GlobalKey();

              return GestureDetector(
                key: _itemKeys[lyricIndex],
                onTap: hasSyncedTimestamps
                    ? () => _seekToLine(lyricIndex)
                    : null,
                child: AnimatedPadding(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.symmetric(
                    vertical: isActive ? 14 : 8,
                    horizontal: 4,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      style: TextStyle(
                        fontSize: isActive ? 28 : 22,
                        fontWeight: isActive
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: isActive
                            ? Colors.white
                            : isPast
                            ? Colors.white.withOpacity(0.25)
                            : Colors.white.withOpacity(0.4),
                        height: 1.3,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                      child: Text(line.text, textAlign: TextAlign.center),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
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
