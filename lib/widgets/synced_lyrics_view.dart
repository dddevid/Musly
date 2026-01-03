/*
  ATTENTION: The PC (Desktop) layout of this view is currently under development 
  and may not be graphically correct or centered as expected.
  
  If you wish to contribute to fixing it, you are welcome! 
  
  TO RE-ENABLE THE LYRICS BUTTON ON PC:
  1. Go to the file 'lib/widgets/desktop_player_bar.dart'
  2. Search for the commented code block related to the IconButton with the 'Icons.lyrics_rounded' icon
  3. Remove the /* ... */ comments to show the button again in the desktop player bar.
*/

import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
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

    final screenHeight = MediaQuery.of(context).size.height;
    double expectedOffset = 0.0;
    for (int i = 0; i < _currentLineIndex; i++) {
      expectedOffset += _estimateLineHeight(_lyrics!.lines[i].text);
    }

    final currentOffset = _scrollController.offset;
    final distance = (currentOffset - expectedOffset).abs();

    final threshold = screenHeight / 3;
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

    double expectedOffset = 0.0;
    for (int i = 0; i < _currentLineIndex; i++) {
      expectedOffset += _estimateLineHeight(_lyrics!.lines[i].text);
    }

    final currentOffset = _scrollController.offset;
    final distance = (currentOffset - expectedOffset).abs();

    final threshold = 150.0;
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
          // Only rebuild when the highlighted line changes.
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
    final fontSize = isActive ? 28.0 : 22.0;
    final verticalPadding = isActive ? 14.0 * 2 : 8.0 * 2;

    final screenWidth = MediaQuery.of(context).size.width;

    final availableWidth = _isDesktop
        ? (screenWidth * 0.6) - 100
        : screenWidth - 28 * 2 - 4 * 2;

    final charWidth = fontSize * 0.45;
    final charsPerLine = (availableWidth / charWidth).floor().clamp(10, 100);

    final numLines = (text.length / charsPerLine).ceil().clamp(1, 10);
    final textHeight = fontSize * 1.3 * numLines;
    return textHeight + verticalPadding;
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

  void _scrollToCurrentLine() {
    if (!_scrollController.hasClients ||
        _currentLineIndex < 0 ||
        _lyrics == null)
      return;

    if (_isUserScrolling) return;

    double targetOffset = 0;
    for (int i = 0; i < _currentLineIndex; i++) {
      targetOffset += _estimateLineHeight(_lyrics!.lines[i].text);
    }

    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
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
            _buildDesktopContent(context, imageUrl)
          else
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(context),
                  Expanded(child: _buildContent()),
                  _buildBottomControls(context),
                ],
              ),
            ),

          if (_isDesktop)
            Positioned(
              top: 24,
              right: 24,
              child: IconButton(
                onPressed: widget.onClose,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopContent(BuildContext context, String imageUrl) {
    return Padding(
      padding: const EdgeInsets.all(64.0),
      child: Row(
        children: [
          // Left Side: Artwork & Info
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'lyrics_artwork',
                  child: AspectRatio(
                    aspectRatio: 1,
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
                        color: Colors
                            .grey[900], // Background color to prevent flash
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          memCacheWidth: 600, // Optimized for desktop view
                          memCacheHeight: 600,
                          fadeInDuration: Duration.zero, // Prevent flash
                          fadeOutDuration: Duration.zero,
                          placeholder: (_, __) =>
                              Container(color: Colors.grey[900]),
                          errorWidget: (_, __, ___) =>
                              Container(color: Colors.grey[900]),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  widget.song.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                if (widget.song.artist != null)
                  Text(
                    widget.song.artist!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          const SizedBox(width: 64),

          // Right Side: Lyrics
          Expanded(flex: 6, child: _buildContent()),
        ],
      ),
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
        color: Colors.black, // Base color
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          memCacheWidth: 400,
          memCacheHeight: 400,
          fadeInDuration: Duration.zero, // Prevent flash
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
              _error ?? 'No lyrics available',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lyrics for this song couldn\'t be found',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 14,
              ),
            ),
          ],
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
    final screenHeight = MediaQuery.of(context).size.height;
    final hasSyncedTimestamps = _lyrics!.lines.any(
      (line) => line.timestamp != Duration.zero,
    );

    final showWaitingDots =
        hasSyncedTimestamps &&
        _lyrics!.lines.first.timestamp > Duration.zero &&
        _currentLineIndex < 0;

    final itemCount = _lyrics!.lines.length + (showWaitingDots ? 1 : 0);

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
          stops: const [0.0, 0.1, 0.9, 1.0],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(
          horizontal: 28,
          vertical: screenHeight / 3,
        ),
        itemCount: itemCount,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          if (showWaitingDots && index == 0) {
            return _buildWaitingDotsRow();
          }

          final lyricIndex = showWaitingDots ? index - 1 : index;
          final line = _lyrics!.lines[lyricIndex];
          final isActive = lyricIndex == _currentLineIndex;
          final isPast = lyricIndex < _currentLineIndex;

          return GestureDetector(
            onTap: hasSyncedTimestamps ? () => _seekToLine(lyricIndex) : null,
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: isActive ? 14 : 8,
                horizontal: 4,
              ),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                style: TextStyle(
                  fontSize: isActive ? 28 : 22,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: isActive
                      ? Colors.white
                      : isPast
                      ? Colors.white.withOpacity(0.25)
                      : Colors.white.withOpacity(0.4),
                  height: 1.3,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.left,
                child: Text(line.text),
              ),
            ),
          );
        },
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
