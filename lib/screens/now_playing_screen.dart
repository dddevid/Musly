import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter/cupertino.dart' hide RepeatMode;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:palette_generator/palette_generator.dart';
import '../l10n/app_localizations.dart';
import '../models/song.dart';
import '../models/radio_station.dart';
import '../providers/player_provider.dart';
import '../providers/library_provider.dart';
import '../services/subsonic_service.dart';
import '../services/player_ui_settings_service.dart';
import '../widgets/star_rating_widget.dart';
import '../theme/app_theme.dart';
import '../utils/navigation_helper.dart';
import '../utils/screen_helper.dart';
import '../widgets/synced_lyrics_view.dart';
import '../widgets/compact_lyrics_view.dart';
import 'album_screen.dart';
import '../widgets/multi_artist_widget.dart';
import '../widgets/album_artwork.dart' show isLocalFilePath;

const _kCarouselGap = 40.0;

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen>
    with TickerProviderStateMixin {
  String? _cachedImageUrl;
  String? _cachedThumbnailUrl;
  String? _cachedCoverArtId;
  bool _showLyrics = false;

  double _dragOffset = 0.0;
  bool _isDragging = false;
  static const double _dismissThreshold = 150.0;
  static const double _maxDragDistance = 400.0;

  double get _morphProgress => (_dragOffset / _maxDragDistance).clamp(0.0, 1.0);

  double get _scale => 1.0 - (_morphProgress * 0.15);
  double get _borderRadius => _morphProgress * 32.0;

  double _horizontalDragOffset = 0.0;
  bool _isHorizontalDragging = false;
  Song? _previewSong;
  bool _isSwipeAnimating = false;
  bool _hasTriggeredHaptic = false;
  double _currentArtworkSize = 0.0;
  late AnimationController _swipeAnimationController;
  static const double _swipeThreshold = 80.0;
  static const double _swipeVelocityThreshold = 600.0;

  double get _swipeProgress =>
      (_horizontalDragOffset.abs() / _swipeThreshold).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _swipeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _swipeAnimationController.dispose();
    super.dispose();
  }

  void _onVerticalDragStart(DragStartDetails details) {
    _isDragging = true;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dy).clamp(
        0.0,
        double.infinity,
      );
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;

    final velocity = details.primaryVelocity ?? 0;
    if (_dragOffset > _dismissThreshold || velocity > 800) {
      Navigator.pop(context);
    } else {
      setState(() {
        _dragOffset = 0.0;
      });
    }
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    if (_showLyrics || _isSwipeAnimating) return;
    _isHorizontalDragging = true;
    _hasTriggeredHaptic = false;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_isHorizontalDragging || _showLyrics) return;
    setState(() {
      _horizontalDragOffset += details.delta.dx;
      _updatePreviewSong();
    });
    if (_previewSong != null && _swipeProgress >= 1.0 && !_hasTriggeredHaptic) {
      _hasTriggeredHaptic = true;
      HapticFeedback.lightImpact();
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!_isHorizontalDragging) return;
    _isHorizontalDragging = false;

    final velocity = details.primaryVelocity ?? 0;
    final provider = context.read<PlayerProvider>();

    final shouldSkipNext = (_horizontalDragOffset < -_swipeThreshold ||
            velocity < -_swipeVelocityThreshold) &&
        provider.hasNext;
    final shouldSkipPrevious = (_horizontalDragOffset > _swipeThreshold ||
            velocity > _swipeVelocityThreshold) &&
        provider.hasPrevious;

    if (shouldSkipNext || shouldSkipPrevious) {
      final targetIndex = shouldSkipNext
          ? provider.currentIndex + 1
          : provider.currentIndex - 1;
      _animateSwipeCompletion(
        goNext: shouldSkipNext,
        targetIndex: targetIndex,
        provider: provider,
        flingVelocity: velocity.abs(),
      );
    } else {
      _animateSwipeSpringBack();
    }
  }

  void _animateSwipeCompletion({
    required bool goNext,
    required int targetIndex,
    required PlayerProvider provider,
    required double flingVelocity,
  }) {
    _isSwipeAnimating = true;
    final startOffset = _horizontalDragOffset;
    // Animate exactly so preview lands at center (size + gap)
    final targetDistance = _currentArtworkSize + _kCarouselGap;
    final endOffset = goNext ? -targetDistance : targetDistance;
    final distance = (endOffset - startOffset).abs();

    // Match fling velocity: duration = distance / velocity, clamped
    final speed = flingVelocity.clamp(600.0, 3000.0);
    final durationMs = (distance / speed * 1000).round().clamp(120, 350);

    _swipeAnimationController.duration = Duration(milliseconds: durationMs);
    _swipeAnimationController.reset();
    final animation = Tween<double>(begin: startOffset, end: endOffset).animate(
      CurvedAnimation(parent: _swipeAnimationController, curve: Curves.easeOut),
    );

    void listener() {
      if (!mounted) return;
      setState(() {
        _horizontalDragOffset = animation.value;
      });
    }

    animation.addListener(listener);

    _swipeAnimationController.forward().then((_) {
      animation.removeListener(listener);
      if (!mounted) return;
      setState(() {
        _horizontalDragOffset = 0.0;
        _previewSong = null;
        _isSwipeAnimating = false;
      });
      provider.skipToIndex(targetIndex);
    });
  }

  void _animateSwipeSpringBack() {
    _isSwipeAnimating = true;
    final startOffset = _horizontalDragOffset;
    final distance = startOffset.abs();

    // Proportional duration: short snap-back for small drags
    final durationMs = (distance / 400 * 250).round().clamp(120, 300);

    _swipeAnimationController.duration = Duration(milliseconds: durationMs);
    _swipeAnimationController.reset();
    final animation = Tween<double>(begin: startOffset, end: 0.0).animate(
      CurvedAnimation(
        parent: _swipeAnimationController,
        curve: Curves.easeOutQuad,
      ),
    );

    void listener() {
      if (!mounted) return;
      setState(() {
        _horizontalDragOffset = animation.value;
      });
    }

    animation.addListener(listener);

    _swipeAnimationController.forward().then((_) {
      animation.removeListener(listener);
      if (!mounted) return;
      setState(() {
        _previewSong = null;
        _isSwipeAnimating = false;
      });
    });
  }

  void _updatePreviewSong() {
    final provider = context.read<PlayerProvider>();
    final queue = provider.queue;
    final currentIndex = provider.currentIndex;

    if (_horizontalDragOffset > 0 && currentIndex > 0) {
      _previewSong = queue[currentIndex - 1];
    } else if (_horizontalDragOffset < 0 && currentIndex < queue.length - 1) {
      _previewSong = queue[currentIndex + 1];
    } else {
      _previewSong = null;
    }
  }

  String? _getPreviewArtworkUrl(Song? song) {
    if (song == null) return null;
    if (song.coverArt == null) return null;

    if (isLocalFilePath(song.coverArt)) {
      return song.coverArt;
    }

    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );
    return subsonicService.getCoverArtUrl(song.coverArt!, size: 600);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    Song song,
    double screenWidth,
    double screenHeight,
    Duration animDuration,
    Curve animCurve,
  ) {
    final artworkLandMin = screenHeight < 280 ? 80.0 : 120.0;
    final artworkLandMax = (screenWidth * 0.40).clamp(artworkLandMin, 500.0);
    final artworkSize = (screenHeight * 0.75).clamp(
      artworkLandMin,
      artworkLandMax,
    );
    _currentArtworkSize = artworkSize;

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Center(
            child: AnimatedContainer(
              duration: animDuration,
              curve: animCurve,
              transform: Matrix4.identity()
                ..setTranslationRaw(0.0, -_morphProgress * 10, 0.0)
                ..scaleByDouble(
                  1.0 + _morphProgress * 0.03,
                  1.0 + _morphProgress * 0.03,
                  1.0,
                  1.0,
                ),
              transformAlignment: Alignment.center,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showLyrics = true;
                  });
                },
                child: _SwipeableAlbumArtwork(
                  currentImageUrl: _cachedImageUrl ?? '',
                  currentThumbnailUrl: _cachedThumbnailUrl,
                  previewImageUrl: _getPreviewArtworkUrl(_previewSong),
                  hasPreviewSong: _previewSong != null,
                  size: artworkSize,
                  swipeProgress: _swipeProgress,
                  horizontalDragOffset: _horizontalDragOffset,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: _showLyrics
              ? Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: _PlayerHeader(
                        albumName: song.album ??
                            AppLocalizations.of(context)!.unknownAlbum,
                        albumId: song.albumId,
                        showLyricsButton: true,
                        isLyricsActive: _showLyrics,
                        onLyricsPressed: () {
                          setState(() {
                            _showLyrics = !_showLyrics;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: CompactLyricsView(
                        key: ValueKey(song.id),
                        song: song,
                        onClose: () {
                          setState(() {
                            _showLyrics = false;
                          });
                        },
                      ),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedOpacity(
                        duration: animDuration,
                        opacity: (1.0 - _morphProgress * 1.5).clamp(0.0, 1.0),
                        child: _PlayerHeader(
                          albumName: song.album ??
                              AppLocalizations.of(context)!.unknownAlbum,
                          albumId: song.albumId,
                          showLyricsButton: true,
                          isLyricsActive: _showLyrics,
                          onLyricsPressed: () {
                            setState(() {
                              _showLyrics = !_showLyrics;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      AnimatedOpacity(
                        duration: animDuration,
                        opacity: (1.0 - _morphProgress * 1.2).clamp(0.0, 1.0),
                        child: AnimatedContainer(
                          duration: animDuration,
                          curve: animCurve,
                          transform: Matrix4.identity()
                            ..setTranslationRaw(0, _morphProgress * 15, 0),
                          child: _PlayerControls(
                            formatDuration: _formatDuration,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Selector<PlayerProvider, (Song?, RadioStation?, bool)>(
      selector: (_, provider) => (
        provider.currentSong,
        provider.currentRadioStation,
        provider.isPlayingRadio,
      ),
      builder: (context, data, _) {
        final (song, radioStation, isPlayingRadio) = data;

        if (isPlayingRadio && radioStation != null) {
          return _buildRadioPlayer(context, radioStation);
        }

        if (song == null) {
          return Scaffold(
            body: Center(
              child: Text(AppLocalizations.of(context)!.noSongPlaying),
            ),
          );
        }

        if (_cachedCoverArtId != song.coverArt) {
          _cachedCoverArtId = song.coverArt;
          if (isLocalFilePath(song.coverArt)) {
            _cachedImageUrl = song.coverArt;
            _cachedThumbnailUrl = song.coverArt;
          } else {
            final subsonicService = Provider.of<SubsonicService>(
              context,
              listen: false,
            );
            _cachedImageUrl = subsonicService.getCoverArtUrl(
              song.coverArt,
              size: 1200,
            );
            _cachedThumbnailUrl = subsonicService.getCoverArtUrl(
              song.coverArt,
              size: 200,
            );
          }
        }

        final animDuration =
            _isDragging ? Duration.zero : const Duration(milliseconds: 300);
        final animCurve = Curves.easeOutCubic;

        return GestureDetector(
          onVerticalDragStart: _showLyrics ? null : _onVerticalDragStart,
          onVerticalDragUpdate: _showLyrics ? null : _onVerticalDragUpdate,
          onVerticalDragEnd: _showLyrics ? null : _onVerticalDragEnd,
          onHorizontalDragStart: _showLyrics ? null : _onHorizontalDragStart,
          onHorizontalDragUpdate: _showLyrics ? null : _onHorizontalDragUpdate,
          onHorizontalDragEnd: _showLyrics ? null : _onHorizontalDragEnd,
          child: Material(
            color: Colors.transparent,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedContainer(
                  duration: animDuration,
                  curve: animCurve,
                  transform: Matrix4.identity()
                    ..translateByDouble(0.0, _dragOffset, 0.0, 1.0)
                    ..scaleByDouble(_scale, _scale, 1.0, 1.0),
                  transformAlignment: Alignment.topCenter,
                  child: AnimatedContainer(
                    duration: animDuration,
                    curve: animCurve,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(_borderRadius),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Scaffold(
                      backgroundColor: Colors.transparent,
                      body: Stack(
                        fit: StackFit.expand,
                        children: [
                          _DynamicBackground(
                            imageUrl: _cachedImageUrl ?? '',
                          ),
                          IgnorePointer(
                            ignoring: _showLyrics,
                            child: AnimatedOpacity(
                              opacity: _showLyrics ? 0.12 : 1.0,
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOutCubic,
                              child: SafeArea(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final screenHeight = constraints.maxHeight;
                                    final screenWidth = constraints.maxWidth;

                                    final isLandscape =
                                        screenWidth > screenHeight;

                                    if (isLandscape) {
                                      return _buildLandscapeLayout(
                                        context,
                                        song,
                                        screenWidth,
                                        screenHeight,
                                        animDuration,
                                        animCurve,
                                      );
                                    }

                                    // Clamp artwork safely: ensure max >= min so
                                    // clamp() never throws on small screens
                                    // (e.g. Sony NW-A306 Walkman ~240x400 dp).
                                    final artworkMinSize =
                                        screenHeight < 400 ? 80.0 : 120.0;
                                    final artworkMaxSize = (screenHeight * 0.38)
                                        .clamp(artworkMinSize, 400.0);
                                    final artworkSize =
                                        (screenWidth * 0.80).clamp(
                                      artworkMinSize,
                                      artworkMaxSize,
                                    );
                                    _currentArtworkSize = artworkSize;

                                    final controlsHeight =
                                        screenHeight < 420 ? 180.0 : 250.0;
                                    final headerHeight =
                                        screenHeight < 420 ? 44.0 : 56.0;

                                    final availableSpace = screenHeight -
                                        headerHeight -
                                        artworkSize -
                                        controlsHeight;

                                    final topSpacing = (availableSpace * 0.35)
                                        .clamp(8.0, 60.0);
                                    final middleSpacing =
                                        (availableSpace * 0.45)
                                            .clamp(12.0, 50.0);
                                    final bottomSpacing =
                                        (availableSpace * 0.20)
                                            .clamp(4.0, 30.0);

                                    return SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minHeight: screenHeight,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            AnimatedOpacity(
                                              duration: animDuration,
                                              opacity:
                                                  (1.0 - _morphProgress * 1.5)
                                                      .clamp(0.0, 1.0),
                                              child: _PlayerHeader(
                                                albumName: song.album ??
                                                    AppLocalizations.of(
                                                            context)!
                                                        .unknownAlbum,
                                                albumId: song.albumId,
                                                showLyricsButton: true,
                                                isLyricsActive: _showLyrics,
                                                onLyricsPressed: () {
                                                  setState(() {
                                                    _showLyrics = !_showLyrics;
                                                  });
                                                },
                                              ),
                                            ),
                                            SizedBox(height: topSpacing),
                                            AnimatedContainer(
                                              duration: animDuration,
                                              curve: animCurve,
                                              transform: Matrix4.identity()
                                                ..translateByDouble(
                                                  0.0,
                                                  -_morphProgress * 20,
                                                  0.0,
                                                  1.0,
                                                )
                                                ..scaleByDouble(
                                                  1.0 + _morphProgress * 0.05,
                                                  1.0 + _morphProgress * 0.05,
                                                  1.0,
                                                  1.0,
                                                ),
                                              transformAlignment:
                                                  Alignment.center,
                                              child: GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    _showLyrics = true;
                                                  });
                                                },
                                                child: _SwipeableAlbumArtwork(
                                                  currentImageUrl:
                                                      _cachedImageUrl ?? '',
                                                  currentThumbnailUrl:
                                                      _cachedThumbnailUrl,
                                                  previewImageUrl:
                                                      _getPreviewArtworkUrl(
                                                    _previewSong,
                                                  ),
                                                  hasPreviewSong:
                                                      _previewSong != null,
                                                  size: artworkSize,
                                                  swipeProgress: _swipeProgress,
                                                  horizontalDragOffset:
                                                      _horizontalDragOffset,
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: middleSpacing),
                                            AnimatedOpacity(
                                              duration: animDuration,
                                              opacity:
                                                  (1.0 - _morphProgress * 1.2)
                                                      .clamp(0.0, 1.0),
                                              child: AnimatedContainer(
                                                duration: animDuration,
                                                curve: animCurve,
                                                transform: Matrix4.identity()
                                                  ..translateByDouble(
                                                    0.0,
                                                    _morphProgress * 30,
                                                    0.0,
                                                    1.0,
                                                  ),
                                                child: _PlayerControls(
                                                  formatDuration:
                                                      _formatDuration,
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: bottomSpacing),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 450),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, animation) {
                              final isEntering = animation.status ==
                                      AnimationStatus.forward ||
                                  animation.status == AnimationStatus.completed;
                              final slideAnimation = Tween<Offset>(
                                begin: const Offset(0, 0.18),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: isEntering
                                      ? Curves.easeOutCubic
                                      : Curves.easeInCubic,
                                ),
                              );
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: slideAnimation,
                                  child: child,
                                ),
                              );
                            },
                            child: _showLyrics
                                ? SizedBox.expand(
                                    key: const ValueKey('lyrics'),
                                    child: SyncedLyricsView(
                                      song: song,
                                      imageUrl: _cachedImageUrl,
                                      onClose: () {
                                        setState(() {
                                          _showLyrics = false;
                                        });
                                      },
                                    ),
                                  )
                                : const SizedBox.shrink(
                                    key: ValueKey('no-lyrics'),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRadioPlayer(BuildContext context, RadioStation station) {
    final animDuration =
        (_isDragging || _isHorizontalDragging || _isSwipeAnimating)
            ? Duration.zero
            : const Duration(milliseconds: 300);
    final animCurve = Curves.easeOutCubic;

    return GestureDetector(
      onVerticalDragStart: _onVerticalDragStart,
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: _onVerticalDragEnd,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedContainer(
              duration: animDuration,
              curve: animCurve,
              transform: Matrix4.identity()
                ..translateByDouble(0.0, _dragOffset, 0.0, 1.0)
                ..scaleByDouble(_scale, _scale, 1.0, 1.0),
              transformAlignment: Alignment.topCenter,
              child: AnimatedContainer(
                duration: animDuration,
                curve: animCurve,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_borderRadius),
                ),
                clipBehavior: Clip.antiAlias,
                child: Scaffold(
                  body: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF1a1a2e),
                          Color(0xFF16213e),
                          Color(0xFF0f0f23),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(
                                    CupertinoIcons.chevron_down,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.appleMusicRed,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        AppLocalizations.of(context)!.live,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      AppLocalizations.of(context)!
                                          .internetRadioUppercase,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 48),
                              ],
                            ),
                          ),
                          const Spacer(flex: 2),
                          Container(
                            width:
                                ScreenHelper.isSmallScreen(context) ? 160 : 200,
                            height:
                                ScreenHelper.isSmallScreen(context) ? 160 : 200,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFFF2D55), Color(0xFFFF6B35)],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFF2D55,
                                  ).withValues(alpha: 0.4),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.radio,
                              color: Colors.white,
                              size: ScreenHelper.radioIconSize(context),
                            ),
                          ),
                          const Spacer(),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  ScreenHelper.playerHorizontalPadding(context),
                            ),
                            child: Text(
                              station.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize:
                                    ScreenHelper.radioTitleFontSize(context),
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppTheme.appleMusicRed,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.appleMusicRed.withValues(
                                        alpha: 0.5,
                                      ),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(context)!.streamingLive,
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(flex: 2),
                          Selector<PlayerProvider, bool>(
                            selector: (_, p) => p.isPlaying,
                            builder: (context, isPlaying, _) {
                              final provider = context.read<PlayerProvider>();
                              return GestureDetector(
                                onTap: provider.togglePlayPause,
                                child: Container(
                                  width:
                                      ScreenHelper.radioPlayButtonSize(context),
                                  height:
                                      ScreenHelper.radioPlayButtonSize(context),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.black,
                                    size:
                                        ScreenHelper.radioPlayIconSize(context),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: () {
                              context.read<PlayerProvider>().stopRadio();
                              Navigator.pop(context);
                            },
                            icon: const Icon(
                              Icons.stop_rounded,
                              color: Colors.white60,
                            ),
                            label: Text(
                              AppLocalizations.of(context)!.stopRadio,
                              style: const TextStyle(color: Colors.white60),
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Palette cache: avoids re-extracting colors for the same cover every rebuild.
// ─────────────────────────────────────────────────────────────────────────────
final _paletteCache = <String, List<Color>>{};

// Default fallback colors (Apple Music deep-dark aesthetic).
const _kDefaultMeshColors = [
  Color(0xFF1A0A2E),
  Color(0xFF0D1B3E),
  Color(0xFF0A1628),
  Color(0xFF160A2A),
];

Future<List<Color>> _extractPaletteColors(String imageUrl) async {
  if (_paletteCache.containsKey(imageUrl)) {
    return _paletteCache[imageUrl]!;
  }

  try {
    ImageProvider provider;
    if (isLocalFilePath(imageUrl)) {
      provider = FileImage(File(imageUrl));
    } else {
      provider = NetworkImage(imageUrl);
    }

    final generator = await PaletteGenerator.fromImageProvider(
      provider,
      size: const Size(112, 112),
      maximumColorCount: 8,
    );

    final colors = <Color>[];

    // Prioritise vibrant then muted swatches for a rich mesh.
    final candidates = [
      generator.vibrantColor,
      generator.darkVibrantColor,
      generator.mutedColor,
      generator.darkMutedColor,
      generator.lightVibrantColor,
      generator.lightMutedColor,
    ].whereType<PaletteColor>().map((s) => s.color).toList();

    if (candidates.isEmpty) {
      final top = generator.colors.take(6).toList();
      colors.addAll(top);
    } else {
      colors.addAll(candidates);
    }

    // Always ensure 4 colors for AnimatedMeshGradient.
    while (colors.length < 4) {
      colors.add(colors.isNotEmpty ? colors.last : const Color(0xFF1A0A2E));
    }

    final result = [
      colors[0].withValues(alpha: 1.0),
      colors[1 % colors.length].withValues(alpha: 1.0),
      colors[2 % colors.length].withValues(alpha: 1.0),
      colors[3 % colors.length].withValues(alpha: 1.0),
    ];

    _paletteCache[imageUrl] = result;

    // Keep cache bounded.
    if (_paletteCache.length > 20) {
      _paletteCache.remove(_paletteCache.keys.first);
    }

    return result;
  } catch (_) {
    return _kDefaultMeshColors;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DynamicBackground: Animated Mesh Gradient background extracted from artwork.
// ─────────────────────────────────────────────────────────────────────────────

class _DynamicBackground extends StatefulWidget {
  final String imageUrl;

  const _DynamicBackground({required this.imageUrl});

  @override
  State<_DynamicBackground> createState() => _DynamicBackgroundState();
}

class _DynamicBackgroundState extends State<_DynamicBackground> {
  List<Color> _meshColors = _kDefaultMeshColors;
  List<Color> _prevColors = _kDefaultMeshColors;

  @override
  void initState() {
    super.initState();
    _loadColors(widget.imageUrl);
  }

  @override
  void didUpdateWidget(_DynamicBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadColors(widget.imageUrl);
    }
  }

  Future<void> _loadColors(String imageUrl) async {
    if (imageUrl.isEmpty) {
      if (mounted) {
        setState(() {
          _prevColors = _meshColors;
          _meshColors = _kDefaultMeshColors;
        });
      }
      return;
    }

    // Serve from cache immediately if available to avoid a flash.
    if (_paletteCache.containsKey(imageUrl)) {
      if (mounted) {
        setState(() {
          _prevColors = _meshColors;
          _meshColors = _paletteCache[imageUrl]!;
        });
      }
      return;
    }

    final colors = await _extractPaletteColors(imageUrl);
    if (mounted && imageUrl == widget.imageUrl) {
      setState(() {
        _prevColors = _meshColors;
        _meshColors = colors;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: TweenAnimationBuilder<List<Color>>(
        tween: _ColorListTween(begin: _prevColors, end: _meshColors),
        duration: const Duration(milliseconds: 900),
        builder: (context, colors, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Bottom solid fill — always visible.
              ColoredBox(color: colors[3]),
              // Blob 1 — top-left.
              _GradientBlob(
                color: colors[0],
                alignment: const Alignment(-0.8, -0.8),
                radius: 0.9,
              ),
              // Blob 2 — top-right.
              _GradientBlob(
                color: colors[1],
                alignment: const Alignment(0.8, -0.6),
                radius: 0.8,
              ),
              // Blob 3 — bottom-center.
              _GradientBlob(
                color: colors[2],
                alignment: const Alignment(0.0, 0.9),
                radius: 0.85,
              ),
              // Dark overlay for readability.
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.fromRGBO(0, 0, 0, 0.42),
                      Color.fromRGBO(0, 0, 0, 0.70),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Smoothly interpolates between two color lists.
class _ColorListTween extends Tween<List<Color>> {
  _ColorListTween({required List<Color> begin, required List<Color> end})
      : super(begin: begin, end: end);

  @override
  List<Color> lerp(double t) {
    final b = begin!;
    final e = end!;
    return List.generate(
      b.length,
      (i) => Color.lerp(b[i], e[i], t)!,
    );
  }
}

// A single radial gradient color blob.
class _GradientBlob extends StatelessWidget {
  final Color color;
  final Alignment alignment;
  final double radius;

  const _GradientBlob({
    required this.color,
    required this.alignment,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: FractionallySizedBox(
        widthFactor: radius * 1.4,
        heightFactor: radius * 1.4,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: 0.85),
                color.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerHeader extends StatelessWidget {
  final String albumName;
  final String? albumId;
  final bool showLyricsButton;
  final bool isLyricsActive;
  final VoidCallback? onLyricsPressed;

  const _PlayerHeader({
    required this.albumName,
    this.albumId,
    this.showLyricsButton = false,
    this.isLyricsActive = false,
    this.onLyricsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              CupertinoIcons.chevron_down,
              color: Colors.white,
              size: 28,
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: albumId != null
                  ? () {
                      Navigator.pop(context);
                      NavigationHelper.push(
                        context,
                        AlbumScreen(albumId: albumId!),
                      );
                    }
                  : null,
              child: Column(
                children: [
                  Text(
                    AppLocalizations.of(context)!.playingFrom,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    albumName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      decoration:
                          albumId != null ? TextDecoration.underline : null,
                      decorationColor: Colors.white.withValues(alpha: 0.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showLyricsButton)
                IconButton(
                  onPressed: onLyricsPressed,
                  padding: const EdgeInsets.all(6),
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                  icon: Icon(
                    CupertinoIcons.music_note_list,
                    color:
                        isLyricsActive ? AppTheme.appleMusicRed : Colors.white,
                    size: 22,
                  ),
                ),
              Selector<PlayerProvider, (double, double, bool)>(
                selector: (_, p) =>
                    (p.playbackSpeed, p.pitch, p.pitchCorrection),
                builder: (context, data, _) {
                  final (speed, pitch, correction) = data;
                  final speedStr = speed == 1.0 ? '1×' : '$speed×';
                  final tooltip = correction
                      ? AppLocalizations.of(context)!
                          .speedTooltipPitchPreserved(speedStr)
                      : AppLocalizations.of(context)!.speedTooltipWithPitch(
                          speedStr, pitch.toStringAsFixed(2));
                  return IconButton(
                    tooltip: tooltip,
                    onPressed: () => _showSpeedDialog(context),
                    padding: const EdgeInsets.all(6),
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                    icon: speed != 1.0
                        ? Text(
                            '$speed×',
                            style: const TextStyle(
                              color: AppTheme.appleMusicRed,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : const Icon(
                            CupertinoIcons.speedometer,
                            color: Colors.white,
                            size: 20,
                          ),
                  );
                },
              ),
              Selector<PlayerProvider, bool>(
                selector: (_, p) => p.hasSleepTimer,
                builder: (context, hasTimer, _) => IconButton(
                  tooltip: hasTimer
                      ? AppLocalizations.of(context)!.sleepTimerActive
                      : AppLocalizations.of(context)!.sleepTimer,
                  onPressed: () => _showSleepTimerDialog(context),
                  padding: const EdgeInsets.all(6),
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                  icon: Icon(
                    CupertinoIcons.moon_zzz,
                    color: hasTimer ? AppTheme.appleMusicRed : Colors.white,
                    size: 20,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _showQueue(context),
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: const Icon(
                  CupertinoIcons.list_bullet,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ],
      ),
    );
  }

  void _showSpeedDialog(BuildContext context) {
    final player = context.read<PlayerProvider>();
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSt) => Container(
          decoration: BoxDecoration(
            color: AppTheme.darkSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTheme.darkDivider,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(ctx)!.playbackSpeed,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...speeds.map(
                    (s) => ListTile(
                      dense: true,
                      title: Text(
                        s == 1.0
                            ? AppLocalizations.of(ctx)!.normalSpeed
                            : '$s×',
                        style: TextStyle(
                          color: player.playbackSpeed == s
                              ? AppTheme.appleMusicRed
                              : Colors.white,
                          fontWeight: player.playbackSpeed == s
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: player.playbackSpeed == s
                          ? const Icon(
                              CupertinoIcons.checkmark,
                              color: AppTheme.appleMusicRed,
                              size: 16,
                            )
                          : null,
                      onTap: () {
                        player.setPlaybackSpeed(s);
                        setSt(() {});
                      },
                    ),
                  ),
                  const Divider(
                      color: AppTheme.darkDivider, indent: 16, endIndent: 16),
                  SwitchListTile(
                    dense: true,
                    title: Text(
                      AppLocalizations.of(ctx)!.preservePitch,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    subtitle: Text(
                      AppLocalizations.of(ctx)!.preservePitchSubtitle,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    value: player.pitchCorrection,
                    activeTrackColor: AppTheme.appleMusicRed,
                    thumbColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppTheme.appleMusicRed;
                      }
                      return null;
                    }),
                    onChanged: (_) {
                      player.togglePitchCorrection();
                      setSt(() {});
                    },
                  ),
                  if (!player.pitchCorrection) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(ctx)!.pitch,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 15),
                          ),
                          Text(
                            '${player.pitch.toStringAsFixed(2)}×',
                            style: const TextStyle(
                              color: AppTheme.appleMusicRed,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Slider(
                      value: player.pitch,
                      min: 0.5,
                      max: 2.0,
                      divisions: 30,
                      activeColor: AppTheme.appleMusicRed,
                      inactiveColor: AppTheme.darkDivider,
                      label: '${player.pitch.toStringAsFixed(2)}×',
                      onChanged: (v) {
                        player.setPitch(v);
                        setSt(() {});
                      },
                    ),
                  ],
                  SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSleepTimerDialog(BuildContext context) {
    final player = context.read<PlayerProvider>();

    final l10n = AppLocalizations.of(context)!;
    final options = [
      (l10n.sleepTimerMinutes(15), const Duration(minutes: 15)),
      (l10n.sleepTimerMinutes(30), const Duration(minutes: 30)),
      (l10n.sleepTimerMinutes(45), const Duration(minutes: 45)),
      (l10n.sleepTimerHours(1), const Duration(hours: 1)),
      (l10n.sleepTimerHours(2), const Duration(hours: 2)),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        bool endCurrentSong = player.sleepTimerEndCurrentSong;
        bool fadeOut = player.sleepTimerFadeOut;
        int fadeOutSeconds = player.sleepTimerFadeDurationSeconds;
        return StatefulBuilder(
          builder: (ctx, setSt) {
            return Container(
              decoration: BoxDecoration(
                color: AppTheme.darkSurface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 36,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppTheme.darkDivider,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(ctx)!.sleepTimer,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Divider(color: Colors.white12, height: 24),
                    SwitchListTile(
                      value: fadeOut,
                      activeThumbColor: AppTheme.appleMusicRed,
                      title: Text(
                        AppLocalizations.of(ctx)!.fadeOut,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        AppLocalizations.of(ctx)!
                            .fadeOutSubtitle(fadeOutSeconds),
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12),
                      ),
                      onChanged: (v) => setSt(() => fadeOut = v),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      child: fadeOut
                          ? Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                              child: Row(
                                children: [
                                  const Icon(
                                    CupertinoIcons.moon_zzz,
                                    color: Colors.white54,
                                    size: 16,
                                  ),
                                  Expanded(
                                    child: Slider(
                                      value: fadeOutSeconds.toDouble(),
                                      min: 5,
                                      max: 120,
                                      divisions: 23,
                                      activeColor: AppTheme.appleMusicRed,
                                      label: '${fadeOutSeconds}s',
                                      onChanged: (v) => setSt(
                                          () => fadeOutSeconds = v.round()),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 40,
                                    child: Text(
                                      '${fadeOutSeconds}s',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    SwitchListTile(
                      value: endCurrentSong,
                      activeThumbColor: AppTheme.appleMusicRed,
                      title: Text(
                        AppLocalizations.of(ctx)!.finishCurrentSong,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        AppLocalizations.of(ctx)!.finishCurrentSongSubtitle,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12),
                      ),
                      onChanged: (v) => setSt(() => endCurrentSong = v),
                    ),
                    const Divider(color: Colors.white12, height: 8),
                    ...options.map(
                      (opt) => ListTile(
                        title: Text(
                          opt.$1,
                          style: const TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          Navigator.pop(sheetCtx);
                          player.setSleepTimer(
                            opt.$2,
                            endCurrentSong: endCurrentSong,
                            fadeOut: fadeOut,
                            fadeDurationSeconds: fadeOutSeconds,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(context)!
                                    .sleepTimerSetFor(opt.$1),
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ),
                    ListTile(
                      leading: const Icon(
                        CupertinoIcons.timer,
                        color: Colors.white70,
                      ),
                      title: Text(
                        AppLocalizations.of(ctx)!.customDuration,
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        _showCustomSleepTimerDialog(
                          context,
                          endCurrentSong: endCurrentSong,
                          fadeOut: fadeOut,
                          fadeOutSeconds: fadeOutSeconds,
                        );
                      },
                    ),
                    if (player.hasSleepTimer)
                      ListTile(
                        leading: const Icon(
                          CupertinoIcons.xmark_circle,
                          color: AppTheme.appleMusicRed,
                        ),
                        title: Text(
                          AppLocalizations.of(ctx)!.cancelTimer,
                          style: const TextStyle(color: AppTheme.appleMusicRed),
                        ),
                        onTap: () {
                          Navigator.pop(sheetCtx);
                          player.setSleepTimer(Duration.zero);
                        },
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCustomSleepTimerDialog(
    BuildContext context, {
    required bool endCurrentSong,
    required bool fadeOut,
    int fadeOutSeconds = 30,
  }) {
    final player = context.read<PlayerProvider>();
    int minutes = 30;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: AppTheme.darkSurface,
          title: Text(
            AppLocalizations.of(ctx)!.customSleepTimer,
            style: const TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(ctx)!.sleepTimerMinutes(minutes),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Slider(
                value: minutes.toDouble(),
                min: 1,
                max: 180,
                divisions: 179,
                activeColor: AppTheme.appleMusicRed,
                onChanged: (v) => setSt(() => minutes = v.round()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                AppLocalizations.of(ctx)!.cancel,
                style: const TextStyle(color: Colors.white54),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                player.setSleepTimer(
                  Duration(minutes: minutes),
                  endCurrentSong: endCurrentSong,
                  fadeOut: fadeOut,
                  fadeDurationSeconds: fadeOutSeconds,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.sleepTimerSetFor(
                        AppLocalizations.of(context)!
                            .sleepTimerMinutes(minutes),
                      ),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Text(
                AppLocalizations.of(ctx)!.set,
                style: const TextStyle(color: AppTheme.appleMusicRed),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQueue(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _QueueSheet(),
    );
  }
}

class _AlbumArtworkSection extends StatelessWidget {
  final String imageUrl;
  final String? thumbnailUrl;
  final double size;

  const _AlbumArtworkSection({
    required this.imageUrl,
    this.thumbnailUrl,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: SizedBox(
        width: size,
        height: size,
        child: RepaintBoundary(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl.isNotEmpty
                  ? isLocalFilePath(imageUrl)
                      ? Image.file(
                          File(imageUrl),
                          key: ValueKey(imageUrl),
                          fit: BoxFit.contain,
                          cacheWidth: 1200,
                          errorBuilder: (ctx, e, _) =>
                              _buildNoArtPlaceholder(ctx),
                        )
                      : CachedNetworkImage(
                          key: ValueKey(imageUrl),
                          imageUrl: imageUrl,
                          fit: BoxFit.contain,
                          memCacheWidth: 1200,
                          maxWidthDiskCache: 1200,
                          maxHeightDiskCache: 1200,
                          useOldImageOnUrlChange: true,
                          fadeInDuration: Duration.zero,
                          fadeOutDuration: Duration.zero,
                          placeholder: (ctx, url) =>
                              thumbnailUrl != null && thumbnailUrl!.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: thumbnailUrl!,
                                      fit: BoxFit.contain,
                                      memCacheWidth: 200,
                                      fadeInDuration: Duration.zero,
                                      errorWidget: (ctx, err, stack) =>
                                          _buildLoadingPlaceholder(),
                                    )
                                  : _buildLoadingPlaceholder(),
                          errorWidget: (ctx, e, _) =>
                              _buildNoArtPlaceholder(ctx),
                        )
                  : _buildNoArtPlaceholder(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF2A2A2A),
      highlightColor: const Color(0xFF3A3A3A),
      child: Container(
        width: size,
        height: size,
        color: const Color(0xFF2A2A2A),
      ),
    );
  }

  Widget _buildNoArtPlaceholder(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C2C2E), Color(0xFF1C1C1E)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note_rounded,
            size: (size * 0.28).clamp(40.0, 100.0),
            color: Colors.white.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.noArtwork,
            style: TextStyle(
              fontSize: (size * 0.045).clamp(11.0, 16.0),
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.18),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeableAlbumArtwork extends StatelessWidget {
  final String currentImageUrl;
  final String? currentThumbnailUrl;
  final String? previewImageUrl;
  final bool hasPreviewSong;
  final double size;
  final double swipeProgress;
  final double horizontalDragOffset;

  const _SwipeableAlbumArtwork({
    required this.currentImageUrl,
    this.currentThumbnailUrl,
    this.previewImageUrl,
    this.hasPreviewSong = false,
    required this.size,
    required this.swipeProgress,
    required this.horizontalDragOffset,
  });

  @override
  Widget build(BuildContext context) {
    final hasPreview = hasPreviewSong && horizontalDragOffset != 0;

    final isSwipingRight = horizontalDragOffset > 0;
    final previewStart =
        isSwipingRight ? -size - _kCarouselGap : size + _kCarouselGap;
    final previewOffset = previewStart + horizontalDragOffset;

    if (!hasPreview) {
      return _AlbumArtworkSection(
        imageUrl: currentImageUrl,
        thumbnailUrl: currentThumbnailUrl,
        size: size,
      );
    }

    // Fade based on distance from center
    final totalDistance = size + _kCarouselGap;
    final progress = (horizontalDragOffset.abs() / totalDistance).clamp(
      0.0,
      1.0,
    );
    final currentOpacity = (1.0 - progress * 0.5).clamp(0.5, 1.0);
    final previewOpacity = (progress * 0.5 + 0.5).clamp(0.5, 1.0);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Transform.translate(
          offset: Offset(previewOffset, 0),
          child: Opacity(
            opacity: previewOpacity,
            child: _buildPreviewArtwork(context),
          ),
        ),
        Transform.translate(
          offset: Offset(horizontalDragOffset, 0),
          child: Opacity(
            opacity: currentOpacity,
            child: _AlbumArtworkSection(
              imageUrl: currentImageUrl,
              thumbnailUrl: currentThumbnailUrl,
              size: size,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewArtwork(BuildContext context) {
    final hasArtwork = previewImageUrl != null && previewImageUrl!.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3 + swipeProgress * 0.2),
            blurRadius: 30 + swipeProgress * 20,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: !hasArtwork
            ? _buildNoArtPlaceholder(context)
            : isLocalFilePath(previewImageUrl)
                ? Image.file(
                    File(previewImageUrl!),
                    key: ValueKey(previewImageUrl),
                    fit: BoxFit.contain,
                    cacheWidth: 1200,
                    errorBuilder: (ctx, e, _) => _buildNoArtPlaceholder(ctx),
                  )
                : CachedNetworkImage(
                    key: ValueKey(previewImageUrl),
                    imageUrl: previewImageUrl!,
                    fit: BoxFit.contain,
                    memCacheWidth: 1200,
                    maxWidthDiskCache: 1200,
                    maxHeightDiskCache: 1200,
                    useOldImageOnUrlChange: true,
                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                    placeholder: (ctx, url) => _buildPlaceholder(),
                    errorWidget: (ctx, err, stack) =>
                        _buildNoArtPlaceholder(context),
                  ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF2A2A2A),
      highlightColor: const Color(0xFF3A3A3A),
      child: Container(
        width: size,
        height: size,
        color: const Color(0xFF2A2A2A),
      ),
    );
  }

  Widget _buildNoArtPlaceholder(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C2C2E), Color(0xFF1C1C1E)],
        ),
      ),
      child: Icon(
        Icons.music_note_rounded,
        size: (size * 0.28).clamp(40.0, 100.0),
        color: Colors.white.withValues(alpha: 0.15),
      ),
    );
  }
}

class _PlayerControls extends StatefulWidget {
  final String Function(Duration) formatDuration;

  const _PlayerControls({required this.formatDuration});

  @override
  State<_PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends State<_PlayerControls> {
  final _playerUiSettings = PlayerUiSettingsService();
  bool _showVolumeSlider = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _playerUiSettings.initialize();
    if (mounted) {
      setState(() {
        _showVolumeSlider = _playerUiSettings.getShowVolumeSlider();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ScreenHelper.playerHorizontalPadding(context),
      ),
      child: Column(
        children: [
          Selector<PlayerProvider, Song?>(
            selector: (_, p) => p.currentSong,
            builder: (context, song, _) => _SongInfo(song: song),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<bool>(
            valueListenable: _playerUiSettings.showStarRatingsNotifier,
            builder: (context, showRating, _) {
              if (!showRating) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Selector<PlayerProvider, Song?>(
                  selector: (_, p) => p.currentSong,
                  builder: (context, song, _) {
                    if (song == null) return const SizedBox.shrink();
                    return StarRatingWidget(
                      rating: song.userRating ?? 0,
                      onRatingChanged: (rating) {
                        context.read<PlayerProvider>().setRating(
                              song.id,
                              rating,
                            );
                      },
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 24,
                    );
                  },
                ),
              );
            },
          ),
          Selector<PlayerProvider, Duration>(
            selector: (_, p) => p.duration,
            builder: (context, duration, _) {
              final provider = context.read<PlayerProvider>();
              return StreamBuilder<Duration>(
                stream: provider.positionStream,
                initialData: provider.position,
                builder: (context, snapshot) {
                  final pos = snapshot.data ?? Duration.zero;
                  final progress = duration.inMilliseconds > 0
                      ? (pos.inMilliseconds / duration.inMilliseconds).clamp(
                          0.0,
                          1.0,
                        )
                      : 0.0;
                  return _ProgressBar(
                    progress: progress,
                    position: pos,
                    duration: duration,
                    formatDuration: widget.formatDuration,
                  );
                },
              );
            },
          ),
          const SizedBox(height: 8),
          const _PlaybackControls(),
          if (_showVolumeSlider) ...[
            const SizedBox(height: 12),
            const _VolumeSlider(),
          ],
        ],
      ),
    );
  }
}

class _SongInfo extends StatefulWidget {
  final Song? song;

  const _SongInfo({required this.song});

  @override
  State<_SongInfo> createState() => _SongInfoState();
}

class _SongInfoState extends State<_SongInfo> {
  bool _isStarred = false;

  @override
  void initState() {
    super.initState();
    _isStarred = widget.song?.starred ?? false;
  }

  @override
  void didUpdateWidget(_SongInfo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song?.id != widget.song?.id) {
      _isStarred = widget.song?.starred ?? false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.song == null) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.song!.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: ScreenHelper.titleFontSize(context),
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              MultiArtistWidget(
                artists: widget.song!.artistParticipants,
                artistFallback: widget.song!.artist,
                artistIdFallback: widget.song!.artistId,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: ScreenHelper.subtitleFontSize(context),
                ),
                onBeforeNavigate: () {
                  if (Navigator.canPop(context)) Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _showAddToPlaylistDialog(context),
          icon: const Icon(
            CupertinoIcons.plus_circle,
            color: Colors.white,
            size: 26,
          ),
        ),
        IconButton(
          onPressed: () => _toggleFavorite(context),
          icon: Icon(
            _isStarred ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
            color: _isStarred ? AppTheme.appleMusicRed : Colors.white,
            size: 26,
          ),
        ),
      ],
    );
  }

  Future<void> _toggleFavorite(BuildContext context) async {
    if (widget.song == null) return;
    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );
    try {
      if (_isStarred) {
        await subsonicService.unstar(id: widget.song!.id);
        setState(() => _isStarred = false);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.removedFromFavorites),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } else {
        await subsonicService.star(id: widget.song!.id);
        setState(() => _isStarred = true);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.addedToFavorites),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _showAddToPlaylistDialog(BuildContext context) async {
    if (widget.song == null) return;

    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );

    try {
      final playlists = await subsonicService.getPlaylists();

      if (!context.mounted) return;

      final outerContext = context;

      showModalBottomSheet(
        context: outerContext,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => Container(
          decoration: BoxDecoration(
            color: AppTheme.darkSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.darkDivider,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.addToPlaylistTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Material(
                  color: AppTheme.appleMusicRed,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _showCreatePlaylistDialog(outerContext);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            CupertinoIcons.add_circled_solid,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)!.createNewPlaylist,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  AppLocalizations.of(context)!.yourPlaylistsLabel,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    final coverArtUrl = playlist.coverArt != null
                        ? subsonicService.getCoverArtUrl(
                            playlist.coverArt!,
                            size: 100,
                          )
                        : null;

                    return ListTile(
                      leading: coverArtUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: CachedNetworkImage(
                                imageUrl: coverArtUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                placeholder: (ctx, url) => Container(
                                  width: 50,
                                  height: 50,
                                  color: AppTheme.darkCard,
                                  child: const Icon(
                                    CupertinoIcons.music_note_list,
                                    color: Colors.white30,
                                    size: 24,
                                  ),
                                ),
                                errorWidget: (ctx, e, _) => Container(
                                  width: 50,
                                  height: 50,
                                  color: AppTheme.darkCard,
                                  child: const Icon(
                                    CupertinoIcons.music_note_list,
                                    color: Colors.white30,
                                    size: 24,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppTheme.darkCard,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                CupertinoIcons.music_note_list,
                                color: Colors.white30,
                                size: 24,
                              ),
                            ),
                      title: Text(
                        playlist.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: playlist.songCount != null
                          ? Text(
                              AppLocalizations.of(context)!
                                  .songsCount(playlist.songCount!),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            )
                          : null,
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        await _addToPlaylist(
                          outerContext,
                          playlist.id,
                          playlist.name,
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorLoadingPlaylists(e),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _showCreatePlaylistDialog(BuildContext context) async {
    if (widget.song == null) return;

    final nameController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text(
          AppLocalizations.of(context)!.createPlaylistTitle,
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.playlistNameHint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.appleMusicRed),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(context, nameController.text.trim());
              }
            },
            child: Text(
              AppLocalizations.of(context)!.create,
              style: const TextStyle(
                color: AppTheme.appleMusicRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && context.mounted) {
      await _createPlaylistAndAddSong(context, result);
    }

    nameController.dispose();
  }

  Future<void> _createPlaylistAndAddSong(
    BuildContext context,
    String playlistName,
  ) async {
    if (widget.song == null) return;

    // Use LibraryProvider so the playlist list gets refreshed after creation
    final libraryProvider = Provider.of<LibraryProvider>(
      context,
      listen: false,
    );

    try {
      await libraryProvider.createPlaylist(
        playlistName,
        songIds: [widget.song!.id],
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!
                  .playlistCreatedWithSong(playlistName),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _addToPlaylist(
    BuildContext context,
    String playlistId,
    String playlistName,
  ) async {
    if (widget.song == null) return;

    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );

    try {
      await subsonicService.updatePlaylist(
        playlistId: playlistId,
        songIdsToAdd: [widget.song!.id],
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!
                  .addedToPlaylist(widget.song!.title, playlistName),
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

class _ProgressBar extends StatefulWidget {
  final double progress;
  final Duration position;
  final Duration duration;
  final String Function(Duration) formatDuration;

  const _ProgressBar({
    required this.progress,
    required this.position,
    required this.duration,
    required this.formatDuration,
  });

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar> {
  bool _isDragging = false;
  bool _waitingForSeek = false;
  double _dragValue = 0.0;

  @override
  void didUpdateWidget(_ProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.duration != widget.duration) {
      _isDragging = false;
      _waitingForSeek = false;
      _dragValue = 0.0;
      return;
    }

    if (_waitingForSeek && (widget.progress - _dragValue).abs() < 0.05) {
      setState(() => _waitingForSeek = false);
    }
  }

  void _updateProgressFromPosition(Offset localPosition, double width) {
    final newProgress = (localPosition.dx / width).clamp(0.0, 1.0);
    setState(() => _dragValue = newProgress);
  }

  @override
  Widget build(BuildContext context) {
    final showDragValue = _isDragging || _waitingForSeek;
    final displayProgress = showDragValue ? _dragValue : widget.progress;
    final displayPosition = showDragValue
        ? Duration(
            milliseconds: (_dragValue * widget.duration.inMilliseconds).round(),
          )
        : widget.position;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final trackWidth = constraints.maxWidth;

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: (details) {
                  setState(() {
                    _isDragging = true;
                    _waitingForSeek = false;
                    _dragValue = widget.progress;
                  });
                  _updateProgressFromPosition(
                    details.localPosition,
                    trackWidth,
                  );
                },
                onHorizontalDragUpdate: (details) {
                  _updateProgressFromPosition(
                    details.localPosition,
                    trackWidth,
                  );
                },
                onHorizontalDragEnd: (details) {
                  context.read<PlayerProvider>().seekToProgress(_dragValue);
                  setState(() {
                    _isDragging = false;
                    _waitingForSeek = true;
                  });
                },
                onTapDown: (details) {
                  final newProgress =
                      (details.localPosition.dx / trackWidth).clamp(0.0, 1.0);
                  setState(() {
                    _dragValue = newProgress;
                    _waitingForSeek = true;
                  });
                  context.read<PlayerProvider>().seekToProgress(newProgress);
                },
                child: SizedBox(
                  height: 40,
                  child: Center(
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: displayProgress.clamp(0.0, 1.0),
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Positioned(
                          left:
                              ((trackWidth * displayProgress.clamp(0.0, 1.0)) -
                                      6)
                                  .clamp(0.0, trackWidth - 12),
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.formatDuration(displayPosition),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
              Text(
                '-${widget.formatDuration(widget.duration - displayPosition)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlaybackControls extends StatelessWidget {
  const _PlaybackControls();

  @override
  Widget build(BuildContext context) {
    return Selector<PlayerProvider, (bool, bool, bool, RepeatMode, bool)>(
      selector: (_, p) => (
        p.isPlaying,
        p.shuffleEnabled,
        p.hasNext,
        p.repeatMode,
        p.hasPrevious,
      ),
      builder: (context, data, _) {
        final (isPlaying, shuffleEnabled, hasNext, repeatMode, _) = data;
        final provider = context.read<PlayerProvider>();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: provider.toggleShuffle,
              icon: Icon(
                CupertinoIcons.shuffle,
                color: shuffleEnabled
                    ? AppTheme.appleMusicRed
                    : Colors.white.withValues(alpha: 0.7),
                size: 22,
              ),
            ),
            IconButton(
              onPressed: provider.skipPrevious,
              icon: Icon(
                CupertinoIcons.backward_fill,
                color: Colors.white,
                size: ScreenHelper.skipButtonIconSize(context),
              ),
            ),
            Container(
              width: ScreenHelper.playButtonContainerSize(context),
              height: ScreenHelper.playButtonContainerSize(context),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: provider.togglePlayPause,
                icon: Icon(
                  isPlaying
                      ? CupertinoIcons.pause_fill
                      : CupertinoIcons.play_fill,
                  color: Colors.black,
                  size: ScreenHelper.playButtonIconSize(context),
                ),
              ),
            ),
            IconButton(
              onPressed: hasNext ? provider.skipNext : null,
              icon: Icon(
                CupertinoIcons.forward_fill,
                color: hasNext
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.3),
                size: ScreenHelper.skipButtonIconSize(context),
              ),
            ),
            IconButton(
              onPressed: provider.toggleRepeat,
              icon: Icon(
                repeatMode == RepeatMode.one
                    ? CupertinoIcons.repeat_1
                    : CupertinoIcons.repeat,
                color: repeatMode != RepeatMode.off
                    ? AppTheme.appleMusicRed
                    : Colors.white.withValues(alpha: 0.7),
                size: 22,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _VolumeSlider extends StatefulWidget {
  const _VolumeSlider();

  @override
  State<_VolumeSlider> createState() => _VolumeSliderState();
}

class _VolumeSliderState extends State<_VolumeSlider> {
  bool _isDragging = false;
  double _dragValue = 0.0;
  double _systemVolume = 0.5;
  StreamSubscription<double>? _volumeSubscription;

  // Serialise remote volume commits: store the latest desired value and run
  // one async write loop at a time so out-of-order responses can't snap the
  // renderer back to a stale level during a fast drag.
  double? _pendingRemoteVolume;
  bool _remoteCommitInProgress = false;

  @override
  void initState() {
    super.initState();
    _initVolumeController();
  }

  Future<void> _initVolumeController() async {
    VolumeController.instance.showSystemUI = false;

    _systemVolume = await VolumeController.instance.getVolume();
    if (mounted) setState(() {});

    _volumeSubscription = VolumeController.instance.addListener((volume) {
      if (mounted && !_isDragging) {
        setState(() {
          _systemVolume = volume;
        });
      }
    });
  }

  @override
  void dispose() {
    _volumeSubscription?.cancel();
    super.dispose();
  }

  void _applyVolume(double newVolume, PlayerProvider provider, bool isRemote) {
    setState(() {
      _dragValue = newVolume;
      if (!isRemote) _systemVolume = newVolume;
    });
    if (isRemote) {
      // Queue the value and let a single async loop drain the queue so rapid
      // drag ticks never result in out-of-order writes reaching the renderer.
      _pendingRemoteVolume = newVolume;
      _drainRemoteVolume(provider);
    } else {
      VolumeController.instance.setVolume(newVolume);
    }
  }

  Future<void> _drainRemoteVolume(PlayerProvider provider) async {
    if (_remoteCommitInProgress) return;
    _remoteCommitInProgress = true;
    try {
      while (_pendingRemoteVolume != null) {
        final value = _pendingRemoteVolume!;
        _pendingRemoteVolume = null;
        await provider.setVolume(value);
      }
    } finally {
      _remoteCommitInProgress = false;
    }
  }

  void _updateVolumeFromPosition(
    Offset localPosition,
    double width,
    PlayerProvider provider,
    bool isRemote,
  ) {
    final newVolume = (localPosition.dx / width).clamp(0.0, 1.0);
    _applyVolume(newVolume, provider, isRemote);
  }

  @override
  Widget build(BuildContext context) {
    // Consumer so the slider re-reads provider.volume on each UPnP poll tick.
    return Consumer<PlayerProvider>(
      builder: (context, provider, _) {
        final isRemote = provider.isRemotePlayback;
        final currentVolume = isRemote ? provider.volume : _systemVolume;
        final displayVolume = _isDragging ? _dragValue : currentVolume;

        return Row(
          children: [
            GestureDetector(
              onTap: () => _applyVolume(0.0, provider, isRemote),
              child: Icon(
                displayVolume <= 0.01
                    ? CupertinoIcons.speaker_slash_fill
                    : CupertinoIcons.speaker_1_fill,
                color: Colors.white.withValues(alpha: 0.7),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final trackWidth = constraints.maxWidth;

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragStart: (details) {
                      setState(() {
                        _isDragging = true;
                        _dragValue = currentVolume;
                      });
                      _updateVolumeFromPosition(
                        details.localPosition,
                        trackWidth,
                        provider,
                        isRemote,
                      );
                    },
                    onHorizontalDragUpdate: (details) {
                      _updateVolumeFromPosition(
                        details.localPosition,
                        trackWidth,
                        provider,
                        isRemote,
                      );
                    },
                    onHorizontalDragEnd: (details) {
                      setState(() => _isDragging = false);
                    },
                    onTapDown: (details) {
                      _updateVolumeFromPosition(
                        details.localPosition,
                        trackWidth,
                        provider,
                        isRemote,
                      );
                    },
                    child: SizedBox(
                      height: 40,
                      child: Center(
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              curve: Curves.easeOut,
                              height: _isDragging ? 6 : 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(
                                  _isDragging ? 3 : 2,
                                ),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: displayVolume.clamp(0.0, 1.0),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 120),
                                curve: Curves.easeOut,
                                height: _isDragging ? 6 : 4,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(
                                    _isDragging ? 3 : 2,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: ((trackWidth *
                                          displayVolume.clamp(0.0, 1.0)) -
                                      (_isDragging ? 10 : 6))
                                  .clamp(
                                0.0,
                                trackWidth - (_isDragging ? 20 : 12),
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 120),
                                curve: Curves.easeOut,
                                width: _isDragging ? 20 : 12,
                                height: _isDragging ? 20 : 12,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: _isDragging
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.4,
                                            ),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.2,
                                            ),
                                            blurRadius: 3,
                                          ),
                                        ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => _applyVolume(1.0, provider, isRemote),
              child: Icon(
                CupertinoIcons.speaker_3_fill,
                color: Colors.white.withValues(alpha: 0.7),
                size: 20,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QueueSheet extends StatelessWidget {
  const _QueueSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.darkSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppTheme.darkDivider,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.playingNext,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                              ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              Expanded(
                child: SafeArea(
                  top: false,
                  child: Selector<PlayerProvider, (List<Song>, int)>(
                    selector: (_, p) => (p.queue, p.currentIndex),
                    builder: (context, data, _) {
                      final (queue, currentIndex) = data;
                      final provider = context.read<PlayerProvider>();

                      return ReorderableListView.builder(
                        scrollController: scrollController,
                        itemCount: queue.length,
                        buildDefaultDragHandles: false,
                        onReorder: provider.reorderQueue,
                        proxyDecorator: (child, index, animation) =>
                            AnimatedBuilder(
                          animation: animation,
                          builder: (context, child) {
                            final elevationValue =
                                Tween<double>(begin: 0.0, end: 6.0)
                                    .animate(animation)
                                    .value;
                            return Material(
                              elevation: elevationValue,
                              color: Colors.transparent,
                              shadowColor: Colors.black.withValues(alpha: 0.3),
                              child: child,
                            );
                          },
                          child: child,
                        ),
                        itemBuilder: (context, index) {
                          final song = queue[index];
                          final isPlaying = index == currentIndex;

                          return ListTile(
                            key: ValueKey(song.id),
                            leading: isPlaying
                                ? const Icon(
                                    Icons.equalizer_rounded,
                                    color: AppTheme.appleMusicRed,
                                  )
                                : Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: AppTheme.lightSecondaryText,
                                    ),
                                  ),
                            title: Text(
                              song.title,
                              style: TextStyle(
                                color: isPlaying
                                    ? AppTheme.appleMusicRed
                                    : Colors.white,
                                fontWeight: isPlaying ? FontWeight.w600 : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              song.artist ?? '',
                              style: const TextStyle(
                                color: AppTheme.lightSecondaryText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.white70,
                                  ),
                                  onPressed: () =>
                                      provider.removeFromQueue(index),
                                ),
                                ReorderableDragStartListener(
                                  index: index,
                                  child: const Icon(
                                    Icons.drag_handle,
                                    color: Colors.white38,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () => provider.skipToIndex(index),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
