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
    if (provider.currentSong != null && _lastSong?.id != provider.currentSong?.id) {
      _lastSong = provider.currentSong;
      _updateImageProviderAndColors();
      _fetchLyrics();
    }
  }

  Future<void> _updateImageProviderAndColors() async {
    if (_lastSong == null) return;
    final subsonic = Provider.of<SubsonicService>(context, listen: false);
    final coverUrl = _lastSong!.coverArt != null ? subsonic.getCoverArtUrl(_lastSong!.coverArt, size: 600) : null;
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
      
      if (offlineService.isOfflineMode || _lastSong!.isLocal || offlineService.isSongDownloaded(_lastSong!.id)) {
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
      
      // Fallback se nessun testo è stato trovato o parsato
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
    final colors = await PaletteService.extractColors(_currentImageProvider!, imageId);
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

  void _onVerticalDragUpdate(DragUpdateDetails details) {
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _bgColors.isNotEmpty ? _bgColors.first : Colors.white;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Theme(
      data: ThemeData.dark(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onVerticalDragUpdate: isLandscape ? null : _onVerticalDragUpdate,
          onVerticalDragEnd: isLandscape ? null : _onVerticalDragEnd,
          child: Stack(
            children: [
              // 1. Shared Animated Background
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
                        // Page 0: Main Cover Art View
                        _buildMainView(accentColor, isLandscape: isLandscape),
                        
                        // Page 1: Lyrics View
                        _fetchedLyrics.isNotEmpty
                            ? StreamBuilder<Duration>(
                                stream: Provider.of<PlayerProvider>(context, listen: false).positionStream,
                                initialData: Provider.of<PlayerProvider>(context, listen: false).position,
                                builder: (context, snapshot) {
                                  return LyricsScreen(
                                    lyrics: _fetchedLyrics,
                                    currentTime: snapshot.data ?? Duration.zero,
                                    onSeek: (duration) {
                                      Provider.of<PlayerProvider>(context, listen: false).seek(duration);
                                    },
                                  );
                                },
                              )
                            : Center(
                                child: _isLoadingLyrics 
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : Text(
                                        AppLocalizations.of(context)?.noLyricsFound ?? "No lyrics available",
                                        style: const TextStyle(color: Colors.white70, fontSize: 18),
                                      ),
                              ),
                        
                        // Page 2: Queue View
                        const QueueView(),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Drag Handle (Top) - Portrait only
              if (!isLandscape)
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: 36,
                    height: 5,
                    margin: EdgeInsets.only(top: widget.topPadding > 0 ? widget.topPadding + 8 : 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),

              // 3. Header (Persistent across pages)
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: isLandscape ? 8.0 : (widget.topPadding > 0 ? widget.topPadding + 16 : 24), 
                    left: isLandscape ? 16.0 : 8.0, 
                    right: isLandscape ? 16.0 : 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          _currentPage == 0 ? Icons.keyboard_arrow_down_rounded : Icons.close_rounded, 
                          color: Colors.white, 
                          size: 32,
                        ),
                        onPressed: () {
                          if (_currentPage != 0) {
                            _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                          } else {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_horiz_rounded, color: Colors.white, size: 28),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveLyricPill(PlayerProvider provider, Color accentColor, {required bool isSmall, bool isLandscape = false}) {
    return ValueListenableBuilder<bool>(
      valueListenable: PlayerUiSettingsService().showLiveLyricUnderArtworkNotifier,
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
              final next = (i + 1 < _fetchedLyrics.length) ? _fetchedLyrics[i + 1] : null;
              if (currentTime >= line.startTime && (next == null || currentTime < next.startTime)) {
                activeLine = line;
                break;
              }
            }
            if (activeLine == null || activeLine.text.trim().isEmpty) {
              return const SizedBox.shrink();
            }
            return GestureDetector(
              onTap: () {
                _pageController.animateToPage(
                  1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Container(
                margin: EdgeInsets.fromLTRB(
                  isLandscape ? 8.0 : 32.0,
                  0,
                  isLandscape ? 8.0 : 32.0,
                  isLandscape ? 2.0 : (isSmall ? 2.0 : 4.0),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isSmall || isLandscape ? 12.0 : 16.0,
                  vertical: isSmall || isLandscape ? 4.0 : 8.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.music_note_rounded,
                      size: isSmall || isLandscape ? 13 : 16,
                      color: accentColor.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        activeLine.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isSmall || isLandscape ? 12 : 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.95),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
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
    Song? currentSong,
    String title,
    String artist,
    bool isStarred, {
    required bool isSmall,
    bool isLandscape = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isLandscape ? 16.0 : 32.0,
        vertical: isLandscape ? 2.0 : (isSmall ? 8.0 : 24.0),
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
            icon: Icon(
              isStarred ? Icons.favorite_rounded : Icons.add_circle_outline_rounded,
              color: isStarred ? Theme.of(context).colorScheme.primary : Colors.white,
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

  Widget _buildMainView(Color accentColor, {bool isLandscape = false}) {
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
  ) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 44.0, 20.0, 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Column: Album Artwork & Live Lyric
            Expanded(
              flex: 5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
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
                  _buildLiveLyricPill(provider, accentColor, isSmall: true, isLandscape: true),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Right Column: Details & Controls
            Expanded(
              flex: 6,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTitleArtistRow(
                    context,
                    currentSong,
                    title,
                    artist,
                    isStarred,
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
                      isRepeatEnabled: provider.repeatMode != RepeatMode.off,
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
                    valueListenable: PlayerUiSettingsService().showVolumeSliderNotifier,
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
                        _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                      } else {
                        _pageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                      }
                    },
                    onQueueTap: () {
                      if (_currentPage == 2) {
                        _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                      } else {
                        _pageController.animateToPage(2, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                      }
                    },
                  ),
                ],
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
  ) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmall = screenHeight < 720;
    final isVerySmall = screenHeight < 620;

    return SafeArea(
      child: Column(
        children: [
          SizedBox(height: isSmall ? 40 : 56), // Space for header
          
          // Album Art with horizontal swipe navigation (Issue #201)
          Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmall ? 40.0 : 36.0,
                  vertical: isVerySmall ? 2.0 : (isSmall ? 6.0 : 12.0),
                ),
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

          _buildLiveLyricPill(provider, accentColor, isSmall: isSmall),
      
          _buildTitleArtistRow(context, currentSong, title, artist, isStarred, isSmall: isSmall),

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

          SizedBox(height: isSmall ? 8 : 16),

          // Controls
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

          SizedBox(height: isVerySmall ? 4 : (isSmall ? 8 : 24)),

          // Volume Slider (Issue #200)
          ValueListenableBuilder<bool>(
            valueListenable: PlayerUiSettingsService().showVolumeSliderNotifier,
            builder: (context, showVolume, _) {
              if (!showVolume) return const SizedBox.shrink();
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.0),
                child: VolumeSlider(),
              );
            },
          ),

          // Bottom Actions
          NowPlayingBottomActions(
            isLyricsActive: _currentPage == 1,
            isQueueActive: _currentPage == 2,
            accentColor: accentColor,
            onLyricsTap: () {
              if (_currentPage == 1) {
                _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
              } else {
                _pageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
              }
            },
            onQueueTap: () {
               if (_currentPage == 2) {
                _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
              } else {
                _pageController.animateToPage(2, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
              }
            },
          ),
          
          SizedBox(height: isSmall ? 6 : 16),
        ],
      ),
    );
  }
}
