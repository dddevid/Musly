import 'package:flutter/material.dart' hide RepeatMode;
import 'package:musly/widgets/common/blurred_gradient_background.dart';
import 'package:musly/widgets/now_playing/album_art_view.dart';
import 'package:musly/widgets/now_playing/marquee_text.dart';
import 'package:musly/widgets/now_playing/playback_controls.dart';
import 'package:musly/widgets/now_playing/playback_progress_slider.dart';
import 'package:musly/widgets/now_playing/volume_slider.dart';
import 'package:musly/widgets/now_playing/now_playing_bottom_actions.dart';
import 'lyrics_screen.dart';
import 'package:musly/models/lyric_line.dart';
import 'package:provider/provider.dart';
import 'package:musly/providers/player_provider.dart';
import 'package:musly/models/song.dart';
import 'package:musly/services/palette_service.dart';
import 'package:musly/services/subsonic_service.dart';
import 'package:musly/services/offline_service.dart';
import 'package:musly/services/lrc_ttml_parser.dart';
import 'package:musly/widgets/now_playing/queue_view.dart';
import 'package:musly/widgets/now_playing/now_playing_more_menu.dart';
import 'package:musly/widgets/now_playing/add_to_menu.dart';
import 'package:musly/widgets/common/multi_artist_widget.dart';
import 'package:musly/services/player_ui_settings_service.dart';
import 'package:musly/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';

class NowPlayingScreen extends StatefulWidget {
  final ImageProvider image;
  final String title;
  final String artist;
  final String heroTag;
  final List<LyricLine> lyrics;
  final Song? song;
  final double topPadding;

  const NowPlayingScreen({
    super.key,
    required this.image,
    required this.title,
    required this.artist,
    required this.heroTag,
    this.lyrics = const [],
    this.song,
    this.topPadding = 0.0,
  });

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  List<Color> _bgColors = [];
  List<LyricLine> _fetchedLyrics = [];
  bool _isLoadingLyrics = true;
  Song? _lastSong;
  ImageProvider? _currentImageProvider;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _fetchedLyrics = widget.lyrics;
    _currentImageProvider = widget.image;
    _lastSong = widget.song;
    _extractColors();
    _fetchLyrics();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<PlayerProvider>(context);
    if (provider.currentSong != null &&
        _lastSong?.id != provider.currentSong?.id) {
      _lastSong = provider.currentSong;
      _updateImageProviderAndColors();
      _fetchLyrics();
    }
  }

  Future<void> _updateImageProviderAndColors() async {
    if (_lastSong == null) return;
    final subsonic = Provider.of<SubsonicService>(context, listen: false);
    final coverUrl = _lastSong!.coverArt != null
        ? subsonic.getCoverArtUrl(_lastSong!.coverArt, size: 600)
        : null;
    if (coverUrl != null && coverUrl.isNotEmpty) {
      _currentImageProvider = CachedNetworkImageProvider(coverUrl);
    } else {
      _currentImageProvider = const AssetImage('assets/logo.png');
    }
    _extractColors();
  }

  Future<void> _fetchLyrics() async {
    if (_lastSong == null) return;

    setState(() => _isLoadingLyrics = true);
    try {
      final subsonic = Provider.of<SubsonicService>(context, listen: false);
      final offlineService = OfflineService();

      Map<String, dynamic>? rawLyrics;

      if (offlineService.isOfflineMode ||
          _lastSong!.isLocal ||
          offlineService.isSongDownloaded(_lastSong!.id)) {
        rawLyrics = await offlineService.getLocalLyrics(_lastSong!.id);
      }

      if (rawLyrics == null && !offlineService.isOfflineMode) {
        rawLyrics = await subsonic.getLyricsBySongId(_lastSong!.id) ??
            await subsonic.getLyrics(
              artist: _lastSong!.artist,
              title: _lastSong!.title,
              duration: _lastSong!.duration,
            );
      }

      if (rawLyrics != null) {
        if (rawLyrics['value'] != null) {
          final lrcText = rawLyrics['value'] as String;
          if (mounted) {
            setState(() {
              _fetchedLyrics = LrcParser.parseLrc(lrcText);
              _isLoadingLyrics = false;
            });
          }
          return;
        } else if (rawLyrics['structuredLyrics'] != null) {
          final structured = rawLyrics['structuredLyrics'] as List?;
          if (structured != null && structured.isNotEmpty) {
            final lines = structured.first['line'] as List?;
            if (lines != null) {
              final parsedLines = lines.map((l) {
                return LyricLine(
                  startTime: Duration(milliseconds: l['start'] as int),
                  text: l['value'] as String,
                );
              }).toList();
              if (mounted) {
                setState(() {
                  _fetchedLyrics = parsedLines;
                  _isLoadingLyrics = false;
                });
              }
              return;
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _fetchedLyrics = [];
          _isLoadingLyrics = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching lyrics: $e');
    }

    if (mounted) {
      setState(() => _isLoadingLyrics = false);
    }
  }

  Future<void> _extractColors() async {
    if (_currentImageProvider == null || _lastSong == null) return;
    final imageId = _lastSong!.id;
    final colors =
        await PaletteService.extractColors(_currentImageProvider!, imageId);
    if (mounted) {
      setState(() {
        _bgColors = colors;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {}

  void _onVerticalDragEnd(DragEndDetails details) {
    if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _bgColors.isNotEmpty ? _bgColors.first : Colors.white;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final view = View.of(context);
    final viewPadding = MediaQueryData.fromView(view).padding;
    final mediaQueryPadding = MediaQuery.of(context).padding;

    final effectiveTopPadding = widget.topPadding > 0
        ? widget.topPadding
        : (viewPadding.top > 0 ? viewPadding.top : mediaQueryPadding.top);

    final effectiveBottomPadding =
        viewPadding.bottom > 0 ? viewPadding.bottom : mediaQueryPadding.bottom;
    final effectiveLeftPadding =
        viewPadding.left > 0 ? viewPadding.left : mediaQueryPadding.left;
    final effectiveRightPadding =
        viewPadding.right > 0 ? viewPadding.right : mediaQueryPadding.right;

    return Theme(
      data: ThemeData.dark(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onVerticalDragUpdate: isLandscape ? null : _onVerticalDragUpdate,
          onVerticalDragEnd: isLandscape ? null : _onVerticalDragEnd,
          child: Stack(
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: BlurredGradientBackground(
                    colors: _bgColors,
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      children: [
                        _buildMainView(
                          accentColor,
                          isLandscape: isLandscape,
                          effectiveTopPadding: effectiveTopPadding,
                          effectiveBottomPadding: effectiveBottomPadding,
                          effectiveLeftPadding: effectiveLeftPadding,
                          effectiveRightPadding: effectiveRightPadding,
                        ),
                        _fetchedLyrics.isNotEmpty
                            ? StreamBuilder<Duration>(
                                stream: Provider.of<PlayerProvider>(context,
                                        listen: false)
                                    .positionStream,
                                initialData: Provider.of<PlayerProvider>(
                                        context,
                                        listen: false)
                                    .position,
                                builder: (context, snapshot) {
                                  return LyricsScreen(
                                    lyrics: _fetchedLyrics,
                                    currentTime: snapshot.data ?? Duration.zero,
                                    onSeek: (duration) {
                                      Provider.of<PlayerProvider>(context,
                                              listen: false)
                                          .seek(duration);
                                    },
                                  );
                                },
                              )
                            : Center(
                                child: _isLoadingLyrics
                                    ? const CircularProgressIndicator(
                                        color: Colors.white)
                                    : Text(
                                        AppLocalizations.of(context)
                                                ?.noLyricsFound ??
                                            "No lyrics available",
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 18),
                                      ),
                              ),
                        const QueueView(),
                      ],
                    ),
                  ),
                ),
              ),
              if (!isLandscape)
                Positioned(
                  top: effectiveTopPadding > 0
                      ? effectiveTopPadding + 8.0
                      : 16.0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: isLandscape
                    ? (effectiveTopPadding > 0
                        ? effectiveTopPadding + 4.0
                        : 8.0)
                    : (effectiveTopPadding > 0
                        ? effectiveTopPadding + 14.0
                        : 22.0),
                left: isLandscape ? effectiveLeftPadding + 12.0 : 8.0,
                right: isLandscape ? effectiveRightPadding + 12.0 : 8.0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        _currentPage == 0
                            ? Icons.keyboard_arrow_down_rounded
                            : Icons.close_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                      onPressed: () {
                        if (_currentPage != 0) {
                          _pageController.animateToPage(0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut);
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_horiz_rounded,
                          color: Colors.white, size: 28),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          useRootNavigator: true,
                          builder: (context) => const NowPlayingMoreMenu(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveLyricPill(PlayerProvider provider, Color accentColor,
      {required bool isSmall, bool isLandscape = false}) {
    return ValueListenableBuilder<bool>(
      valueListenable:
          PlayerUiSettingsService().showLiveLyricUnderArtworkNotifier,
      builder: (context, showLyric, _) {
        if (!showLyric || _fetchedLyrics.isEmpty) {
          return const SizedBox.shrink();
        }
        return StreamBuilder<Duration>(
          stream: provider.positionStream,
          initialData: provider.position,
          builder: (context, snapshot) {
            final currentTime = snapshot.data ?? Duration.zero;
            LyricLine? activeLine;
            for (int i = 0; i < _fetchedLyrics.length; i++) {
              final line = _fetchedLyrics[i];
              final next = (i + 1 < _fetchedLyrics.length)
                  ? _fetchedLyrics[i + 1]
                  : null;
              if (currentTime >= line.startTime &&
                  (next == null || currentTime < next.startTime)) {
                activeLine = line;
                break;
              }
            }
            final hasLine =
                activeLine != null && activeLine.text.trim().isNotEmpty;
            final text = hasLine ? activeLine.text.trim() : '';

            if (!hasLine) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isLandscape ? 12.0 : 28.0,
                vertical: isLandscape ? 2.0 : (isSmall ? 2.0 : 4.0),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    _pageController.animateToPage(
                      1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Ink(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmall || isLandscape ? 12.0 : 14.0,
                        vertical: isSmall || isLandscape ? 5.0 : 7.0,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lyrics_rounded,
                              size: isSmall || isLandscape ? 13 : 15,
                              color: accentColor.withValues(alpha: 0.95),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.2),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              ),
                              child: Text(
                                text,
                                key: ValueKey<String>(text),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize:
                                      isSmall || isLandscape ? 12.5 : 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.1,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: isSmall || isLandscape ? 14 : 16,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTitleArtistRow(
    BuildContext context,
    PlayerProvider provider,
    Song? currentSong,
    String title,
    String artist,
    bool isStarred, {
    required bool isSmall,
    bool isLandscape = false,
    double? verticalPadding,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isLandscape ? 16.0 : 32.0,
        vertical:
            isLandscape ? 2.0 : (verticalPadding ?? (isSmall ? 6.0 : 12.0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                MarqueeText(
                  text: title,
                  style: TextStyle(
                    fontSize: isLandscape ? 19 : (isSmall ? 20 : 24),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: isLandscape ? 2 : (isSmall ? 2 : 4)),
                MultiArtistWidget(
                  artists: currentSong?.artistParticipants,
                  artistFallback: artist,
                  artistIdFallback: currentSong?.artistId,
                  onBeforeNavigate: () => Navigator.pop(context),
                  style: TextStyle(
                    fontSize: isLandscape ? 14 : (isSmall ? 15 : 18),
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: isStarred ? 'Remove from favorites' : 'Add to favorites',
            icon: Icon(
              isStarred
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: isStarred
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white,
              size: isLandscape ? 22 : 24,
            ),
            onPressed: () {
              if (currentSong == null) return;
              provider.toggleFavorite();
            },
          ),
          IconButton(
            tooltip: 'Add to playlist',
            icon: Icon(
              Icons.add_circle_outline_rounded,
              color: Colors.white70,
              size: isLandscape ? 22 : 24,
            ),
            onPressed: () {
              if (currentSong == null) return;
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                useRootNavigator: true,
                builder: (context) => AddToMenu(
                  song: currentSong,
                  coverProvider: _currentImageProvider ?? widget.image,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStarRatingRow(
    PlayerProvider provider,
    Song? currentSong, {
    required bool isSmall,
    bool isLandscape = false,
  }) {
    return ValueListenableBuilder<bool>(
      valueListenable: PlayerUiSettingsService().showStarRatingsNotifier,
      builder: (context, showStarRatings, _) {
        if (!showStarRatings || currentSong == null) {
          return const SizedBox.shrink();
        }
        final currentRating = currentSong.userRating ?? 0;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isLandscape ? 16.0 : 32.0,
            vertical: isLandscape ? 0.0 : (isSmall ? 0.0 : 2.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) {
              final starValue = index + 1;
              final isFilled = starValue <= currentRating;
              return IconButton(
                iconSize: isLandscape || isSmall ? 20 : 24,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                constraints: BoxConstraints(
                  minWidth: isLandscape || isSmall ? 28 : 34,
                  minHeight: isLandscape || isSmall ? 28 : 34,
                ),
                icon: Icon(
                  isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: isFilled ? const Color(0xFFFFB800) : Colors.white38,
                ),
                onPressed: () async {
                  final newRating =
                      isFilled && starValue == currentRating ? 0 : starValue;
                  try {
                    await provider.setRating(currentSong.id, newRating);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to set rating: $e'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildMainView(
    Color accentColor, {
    bool isLandscape = false,
    required double effectiveTopPadding,
    required double effectiveBottomPadding,
    required double effectiveLeftPadding,
    required double effectiveRightPadding,
  }) {
    return Consumer<PlayerProvider>(
      builder: (context, provider, child) {
        final currentSong = provider.currentSong ?? widget.song;
        final title = currentSong?.title ?? widget.title;
        final artist = currentSong?.artist ?? widget.artist;
        final isStarred = currentSong?.starred ?? false;

        if (isLandscape) {
          return _buildLandscapeLayout(
            context,
            provider,
            currentSong,
            title,
            artist,
            isStarred,
            accentColor,
            effectiveTopPadding,
            effectiveLeftPadding,
            effectiveRightPadding,
          );
        }

        return _buildPortraitLayout(
          context,
          provider,
          currentSong,
          title,
          artist,
          isStarred,
          accentColor,
          effectiveTopPadding,
          effectiveBottomPadding,
        );
      },
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    PlayerProvider provider,
    Song? currentSong,
    String title,
    String artist,
    bool isStarred,
    Color accentColor,
    double effectiveTopPadding,
    double effectiveLeftPadding,
    double effectiveRightPadding,
  ) {
    final topPadding =
        effectiveTopPadding > 0 ? effectiveTopPadding + 44.0 : 48.0;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          effectiveLeftPadding > 0 ? effectiveLeftPadding + 16.0 : 20.0,
          topPadding,
          effectiveRightPadding > 0 ? effectiveRightPadding + 16.0 : 20.0,
          4.0,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 4.0),
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onHorizontalDragEnd: (details) {
                              final vel = details.primaryVelocity;
                              if (vel != null) {
                                if (vel < -250) {
                                  provider.skipNext();
                                } else if (vel > 250) {
                                  provider.skipPrevious();
                                }
                              }
                            },
                            child: AlbumArtView(
                              image: _currentImageProvider ?? widget.image,
                              tag: currentSong?.id ?? widget.heroTag,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  _buildLiveLyricPill(provider, accentColor,
                      isSmall: true, isLandscape: true),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 6,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(minWidth: 320, maxWidth: 500),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTitleArtistRow(
                          context,
                          provider,
                          currentSong,
                          title,
                          artist,
                          isStarred,
                          isSmall: true,
                          isLandscape: true,
                        ),
                        _buildStarRatingRow(
                          provider,
                          currentSong,
                          isSmall: true,
                          isLandscape: true,
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: StreamBuilder<Duration>(
                            stream: provider.positionStream,
                            initialData: provider.position,
                            builder: (context, snapshot) {
                              return PlaybackProgressSlider(
                                position: snapshot.data ?? Duration.zero,
                                duration: provider.duration,
                                accentColor: Colors.white,
                                onChanged: (val) {
                                  provider.seek(val);
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: PlaybackControls(
                            isPlaying: provider.isPlaying,
                            isShuffleEnabled: provider.shuffleEnabled,
                            isRepeatEnabled:
                                provider.repeatMode != RepeatMode.off,
                            accentColor: accentColor,
                            onPlayPause: () => provider.togglePlayPause(),
                            onNext: () => provider.skipNext(),
                            onPrevious: () => provider.skipPrevious(),
                            onShuffleToggle: () => provider.toggleShuffle(),
                            onRepeatToggle: () => provider.toggleRepeat(),
                          ),
                        ),
                        const SizedBox(height: 2),
                        ValueListenableBuilder<bool>(
                          valueListenable: PlayerUiSettingsService()
                              .showVolumeSliderNotifier,
                          builder: (context, showVolume, _) {
                            if (!showVolume) return const SizedBox.shrink();
                            return const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                              child: VolumeSlider(),
                            );
                          },
                        ),
                        const SizedBox(height: 2),
                        NowPlayingBottomActions(
                          isLyricsActive: _currentPage == 1,
                          isQueueActive: _currentPage == 2,
                          accentColor: accentColor,
                          onLyricsTap: () {
                            if (_currentPage == 1) {
                              _pageController.animateToPage(0,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut);
                            } else {
                              _pageController.animateToPage(1,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut);
                            }
                          },
                          onQueueTap: () {
                            if (_currentPage == 2) {
                              _pageController.animateToPage(0,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut);
                            } else {
                              _pageController.animateToPage(2,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut);
                            }
                          },
                        ),
                      ],
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

  Widget _buildPortraitLayout(
    BuildContext context,
    PlayerProvider provider,
    Song? currentSong,
    String title,
    String artist,
    bool isStarred,
    Color accentColor,
    double effectiveTopPadding,
    double effectiveBottomPadding,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = constraints.maxHeight;
        final screenWidth = constraints.maxWidth;
        final isSmall = screenHeight < 720;
        final isVerySmall = screenHeight < 620;

        final spacingScale = ((screenHeight - 620.0) / 280.0).clamp(0.0, 1.0);

        final headerClearance = effectiveTopPadding > 0
            ? effectiveTopPadding + (isSmall ? 46.0 : 52.0)
            : (isSmall ? 48.0 : 56.0);

        final horizontalArtPadding = screenWidth > 480
            ? ((screenWidth - 380.0) / 2.0).clamp(32.0, 120.0)
            : (screenWidth < 360 ? 24.0 : 32.0);

        final titleVerticalPadding = 4.0 + (6.0 * spacingScale);
        final sliderBottomSpacing = isSmall ? 4.0 : (6.0 + 8.0 * spacingScale);
        final controlsBottomSpacing =
            isVerySmall ? 4.0 : (isSmall ? 6.0 : (8.0 + 10.0 * spacingScale));
        final bottomActionsSpacing = effectiveBottomPadding > 0
            ? effectiveBottomPadding + 4.0
            : (isSmall ? 6.0 : (10.0 + 6.0 * spacingScale));

        return SafeArea(
          top: false,
          bottom: false,
          child: Column(
            children: [
              SizedBox(height: headerClearance),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalArtPadding,
                      vertical: isVerySmall ? 2.0 : (isSmall ? 4.0 : 8.0),
                    ),
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragEnd: (details) {
                          final vel = details.primaryVelocity;
                          if (vel != null) {
                            if (vel < -250) {
                              provider.skipNext();
                            } else if (vel > 250) {
                              provider.skipPrevious();
                            }
                          }
                        },
                        child: AlbumArtView(
                          image: _currentImageProvider ?? widget.image,
                          tag: currentSong?.id ?? widget.heroTag,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _buildLiveLyricPill(provider, accentColor, isSmall: isSmall),
              _buildTitleArtistRow(
                context,
                provider,
                currentSong,
                title,
                artist,
                isStarred,
                isSmall: isSmall,
                verticalPadding: titleVerticalPadding,
              ),
              _buildStarRatingRow(provider, currentSong, isSmall: isSmall),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: StreamBuilder<Duration>(
                  stream: provider.positionStream,
                  initialData: provider.position,
                  builder: (context, snapshot) {
                    return PlaybackProgressSlider(
                      position: snapshot.data ?? Duration.zero,
                      duration: provider.duration,
                      accentColor: Colors.white,
                      onChanged: (val) {
                        provider.seek(val);
                      },
                    );
                  },
                ),
              ),
              SizedBox(height: sliderBottomSpacing),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: PlaybackControls(
                  isPlaying: provider.isPlaying,
                  isShuffleEnabled: provider.shuffleEnabled,
                  isRepeatEnabled: provider.repeatMode != RepeatMode.off,
                  accentColor: accentColor,
                  onPlayPause: () => provider.togglePlayPause(),
                  onNext: () => provider.skipNext(),
                  onPrevious: () => provider.skipPrevious(),
                  onShuffleToggle: () => provider.toggleShuffle(),
                  onRepeatToggle: () => provider.toggleRepeat(),
                ),
              ),
              SizedBox(height: controlsBottomSpacing),
              ValueListenableBuilder<bool>(
                valueListenable:
                    PlayerUiSettingsService().showVolumeSliderNotifier,
                builder: (context, showVolume, _) {
                  if (!showVolume) return const SizedBox.shrink();
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.0),
                    child: VolumeSlider(),
                  );
                },
              ),
              NowPlayingBottomActions(
                isLyricsActive: _currentPage == 1,
                isQueueActive: _currentPage == 2,
                accentColor: accentColor,
                onLyricsTap: () {
                  if (_currentPage == 1) {
                    _pageController.animateToPage(0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut);
                  } else {
                    _pageController.animateToPage(1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut);
                  }
                },
                onQueueTap: () {
                  if (_currentPage == 2) {
                    _pageController.animateToPage(0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut);
                  } else {
                    _pageController.animateToPage(2,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut);
                  }
                },
              ),
              SizedBox(height: bottomActionsSpacing),
            ],
          ),
        );
      },
    );
  }
}
