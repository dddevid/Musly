import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/library_provider.dart';
import '../../services/recommendation_service.dart';
import '../../services/wrapped_service.dart';
import '../../widgets/common/album_artwork.dart';

class WrappedScreen extends StatefulWidget {
  final bool devPreview;

  const WrappedScreen({super.key, this.devPreview = false});

  @override
  State<WrappedScreen> createState() => _WrappedScreenState();
}

class _WrappedScreenState extends State<WrappedScreen>
    with TickerProviderStateMixin {
  late final AnimationController _auraController;
  late final AnimationController _suspenseController;
  WrappedData? _data;
  bool _isLoading = true;
  int _currentSlide = 0;
  static const int _totalSlides = 6;
  Timer? _autoAdvanceTimer;
  Timer? _suspenseTimer;
  bool _isPaused = false;
  bool _isSuspenseLocked = false;
  int _suspenseCountdown = 3;
  bool _topSongRevealed = false;

  @override
  void initState() {
    super.initState();
    // Enable Fullscreen immersive mode like Spotify Wrapped
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _auraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _suspenseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    // Pause active playback when entering Wrapped
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final player = Provider.of<PlayerProvider>(context, listen: false);
      if (player.isPlaying) {
        player.pause();
      }
    });

    _loadData();
  }

  @override
  void dispose() {
    // Restore normal system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _autoAdvanceTimer?.cancel();
    _suspenseTimer?.cancel();
    _auraController.dispose();
    _suspenseController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final recService = Provider.of<RecommendationService>(context, listen: false);
    final libProvider = Provider.of<LibraryProvider>(context, listen: false);

    final allSongs = libProvider.cachedAllSongs.isNotEmpty
        ? libProvider.cachedAllSongs
        : libProvider.randomSongs;

    final wrappedData = await WrappedService().computeWrappedData(
      recommendationService: recService,
      allLibrarySongs: allSongs,
    );

    if (mounted) {
      setState(() {
        _data = wrappedData;
        _isLoading = false;
      });
      _startSlideTimer();
    }
  }

  void _startSlideTimer() {
    _autoAdvanceTimer?.cancel();
    if (_isPaused || _isSuspenseLocked) return;

    _autoAdvanceTimer = Timer(const Duration(seconds: 7), () {
      if (mounted && !_isPaused && !_isSuspenseLocked) {
        if (_currentSlide < _totalSlides - 1) {
          _nextSlide();
        }
      }
    });
  }

  void _triggerTopSongSuspense() {
    if (_topSongRevealed) return;

    setState(() {
      _isSuspenseLocked = true;
      _suspenseCountdown = 3;
    });

    _autoAdvanceTimer?.cancel();

    // 3-second suspense countdown (unskippable)
    _suspenseTimer?.cancel();
    _suspenseTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (!mounted) return;

      if (_suspenseCountdown > 1) {
        HapticFeedback.mediumImpact();
        setState(() {
          _suspenseCountdown--;
        });
      } else {
        timer.cancel();
        HapticFeedback.heavyImpact();
        setState(() {
          _isSuspenseLocked = false;
          _topSongRevealed = true;
        });

        // Automatically start playing the #1 top song in background!
        if (_data != null && _data!.topSongs.isNotEmpty) {
          final topSong = _data!.topSongs.first.song;
          final player = Provider.of<PlayerProvider>(context, listen: false);
          player.playSong(topSong);
        }

        _startSlideTimer();
      }
    });
  }

  void _nextSlide() {
    if (_isSuspenseLocked) return; // Cannot skip during suspense

    if (_currentSlide < _totalSlides - 1) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentSlide++;
      });

      if (_currentSlide == 2 && !_topSongRevealed) {
        _triggerTopSongSuspense();
      } else {
        _startSlideTimer();
      }
    }
  }

  void _prevSlide() {
    if (_isSuspenseLocked) return; // Cannot skip during suspense

    if (_currentSlide > 0) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentSlide--;
      });
      _startSlideTimer();
    }
  }

  void _playTopSongs() {
    if (_data == null || _data!.topSongs.isEmpty) return;
    final songs = _data!.topSongs.map((s) => s.song).toList();
    final player = Provider.of<PlayerProvider>(context, listen: false);
    player.playSong(songs.first, playlist: songs, startIndex: 0);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isSeason = WrappedService.isWrappedSeason(devPreview: widget.devPreview);

    if (!isSeason) {
      return _buildOutOfSeasonScreen();
    }

    if (_isLoading || _data == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0B10),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFFFA243C)),
              const SizedBox(height: 20),
              Text(
                'Unwrapping your ${WrappedService.getWrappedYear()}...',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF090A0F),
      body: GestureDetector(
        onTapDown: (_) {
          if (!_isSuspenseLocked) {
            setState(() => _isPaused = true);
            _autoAdvanceTimer?.cancel();
          }
        },
        onTapUp: (details) {
          if (!_isSuspenseLocked) {
            setState(() => _isPaused = false);
            final width = MediaQuery.of(context).size.width;
            if (details.globalPosition.dx < width * 0.3) {
              _prevSlide();
            } else {
              _nextSlide();
            }
          }
        },
        onTapCancel: () {
          if (!_isSuspenseLocked) {
            setState(() => _isPaused = false);
            _startSlideTimer();
          }
        },
        child: Stack(
          children: [
            // Dynamic Ambient Aura Background
            _buildAnimatedBackground(),

            // Slide Content
            SafeArea(
              child: Column(
                children: [
                  // Progress Bars & Header Controls
                  _buildHeaderProgress(),

                  // Active Slide
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: _isSuspenseLocked && _currentSlide == 2
                            ? _buildSuspenseCountdownSlide()
                            : _buildSlideContent(_currentSlide),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutOfSeasonScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF090A0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.xmark, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFA243C).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.gift_fill, color: Color(0xFFFA243C), size: 40),
              ),
              const SizedBox(height: 24),
              const Text(
                'Musly Wrapped is Seasonal',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Your annual Year-in-Review unlocks automatically every year between late November and mid-January.\n\nKeep listening to build up your music story!',
                style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const WrappedScreen(devPreview: true),
                    ),
                  );
                },
                icon: const Icon(CupertinoIcons.sparkles),
                label: const Text('Preview Wrapped (Test Mode)'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFA243C),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    final gradients = [
      [const Color(0xFFFA243C), const Color(0xFF6B11FF)],
      [const Color(0xFF00C6FF), const Color(0xFF0072FF)],
      [const Color(0xFFFF512F), const Color(0xFFDD2476)],
      [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)],
      [const Color(0xFF11998E), const Color(0xFF38EF7D)],
      [const Color(0xFFFA243C), const Color(0xFFFF8C00)],
    ];

    final currentColors = gradients[_currentSlide % gradients.length];

    return AnimatedBuilder(
      animation: _auraController,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(
                0.3 * (_auraController.value - 0.5),
                -0.4 + 0.3 * (_auraController.value - 0.5),
              ),
              radius: 1.4,
              colors: [
                currentColors[0].withValues(alpha: 0.35),
                currentColors[1].withValues(alpha: 0.18),
                const Color(0xFF090A0F),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderProgress() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: List.generate(_totalSlides, (index) {
              final isPassed = index < _currentSlide;
              final isCurrent = index == _currentSlide;
              return Expanded(
                child: Container(
                  height: 3.5,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isPassed || isCurrent
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(CupertinoIcons.sparkles, color: Color(0xFFFA243C), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'MUSLY WRAPPED ${_data!.year}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.xmark, color: Colors.white70, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuspenseCountdownSlide() {
    return AnimatedBuilder(
      animation: _suspenseController,
      builder: (context, _) {
        final scale = 1.0 + (_suspenseController.value * 0.15);

        return Column(
          key: const ValueKey('suspense'),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF512F).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFF512F).withValues(alpha: 0.5)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.lock_fill, color: Color(0xFFFF512F), size: 14),
                  SizedBox(width: 6),
                  Text(
                    'RULLO DI TAMBURI...',
                    style: TextStyle(
                      color: Color(0xFFFF512F),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Pronto a scoprire\nil tuo brano #1?',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            Transform.scale(
              scale: scale,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFFFA243C), Color(0xFFFF512F)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFA243C).withValues(alpha: 0.5),
                      blurRadius: 36 * scale,
                      spreadRadius: 6 * scale,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$_suspenseCountdown',
                    style: const TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
            const Text(
              'Un attimo di suspense...',
              style: TextStyle(fontSize: 14, color: Colors.white60, fontStyle: FontStyle.italic),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSlideContent(int index) {
    switch (index) {
      case 0:
        return _buildIntroSlide();
      case 1:
        return _buildMinutesSlide();
      case 2:
        return _buildTopSongsSlide();
      case 3:
        return _buildTopArtistsSlide();
      case 4:
        return _buildPersonalitySlide();
      case 5:
        return _buildSummaryCardSlide();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildIntroSlide() {
    return Column(
      key: const ValueKey('intro'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFA243C), Color(0xFFFF5E3A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFA243C).withValues(alpha: 0.45),
                blurRadius: 36,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(CupertinoIcons.music_albums_fill, color: Colors.white, size: 54),
        ),
        const SizedBox(height: 36),
        Text(
          'Your ${_data!.year}\nin Music',
          style: const TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.15,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          'You explored new horizons, revisited favorites, and made memories with sound.',
          style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.4),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 36),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tap to begin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              SizedBox(width: 6),
              Icon(CupertinoIcons.chevron_right, color: Colors.white, size: 14),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMinutesSlide() {
    final mins = _data!.totalMinutesListened;
    final hours = (mins / 60).toStringAsFixed(1);

    return Column(
      key: const ValueKey('minutes'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Total Listening Time',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF00C6FF), letterSpacing: 1.0),
        ),
        const SizedBox(height: 16),
        Text(
          '$mins',
          style: const TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -1,
          ),
        ),
        const Text(
          'MINUTES',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white60, letterSpacing: 2),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetric('Hours', hours),
              Container(width: 1, height: 36, color: Colors.white24),
              _buildMetric('Tracks', '${_data!.totalUniqueTracks}'),
              Container(width: 1, height: 36, color: Colors.white24),
              _buildMetric('Artists', '${_data!.totalUniqueArtists}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white60)),
      ],
    );
  }

  Widget _buildTopSongsSlide() {
    return Column(
      key: const ValueKey('songs'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TOP SONGS',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFFF512F), letterSpacing: 1.2),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(CupertinoIcons.speaker_2_fill, color: Color(0xFF10B981), size: 12),
                  SizedBox(width: 4),
                  Text('AUDIO PREVIEW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Your Most Played Tracks',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.separated(
            itemCount: _data!.topSongs.length.clamp(0, 5),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final rank = _data!.topSongs[i];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: i == 0
                      ? const Color(0xFFFA243C).withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: i == 0
                        ? const Color(0xFFFA243C).withValues(alpha: 0.5)
                        : Colors.white10,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      '#${rank.rank}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: i == 0 ? const Color(0xFFFA243C) : Colors.white60,
                      ),
                    ),
                    const SizedBox(width: 14),
                    AlbumArtwork(coverArt: rank.song.coverArt, size: 46, borderRadius: 8),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rank.song.title,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            rank.song.artist ?? 'Unknown Artist',
                            style: const TextStyle(fontSize: 12, color: Colors.white60),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${rank.playCount} plays',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTopArtistsSlide() {
    return Column(
      key: const ValueKey('artists'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TOP ARTISTS',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF8E2DE2), letterSpacing: 1.2),
        ),
        const SizedBox(height: 4),
        const Text(
          'The Creators You Loved',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.separated(
            itemCount: _data!.topArtists.length.clamp(0, 5),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final rank = _data!.topArtists[i];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: i == 0
                      ? const Color(0xFF8E2DE2).withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: i == 0
                        ? const Color(0xFF8E2DE2).withValues(alpha: 0.5)
                        : Colors.white10,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      '#${rank.rank}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: i == 0 ? const Color(0xFF8E2DE2) : Colors.white60,
                      ),
                    ),
                    if (rank.coverArt != null && rank.coverArt!.isNotEmpty)
                      AlbumArtwork(
                        coverArt: rank.coverArt,
                        size: 42,
                        borderRadius: 21,
                      )
                    else
                      CircleAvatar(
                        radius: 21,
                        backgroundColor: const Color(0xFF8E2DE2).withValues(alpha: 0.3),
                        child: Text(
                          rank.name.isNotEmpty ? rank.name[0].toUpperCase() : '?',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        rank.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${rank.playCount} plays',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalitySlide() {
    return Column(
      key: const ValueKey('personality'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'YOUR LISTENING PERSONALITY',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF38EF7D), letterSpacing: 1.2),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF38EF7D).withValues(alpha: 0.35),
                blurRadius: 32,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(CupertinoIcons.sparkles, color: Colors.white, size: 48),
              const SizedBox(height: 16),
              Text(
                _data!.listeningPersonality,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _data!.personalityDescription,
                style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        if (_data!.topGenre.isNotEmpty) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Top Genre: ${_data!.topGenre}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryCardSlide() {
    return Column(
      key: const ValueKey('summary'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('MUSLY WRAPPED', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Color(0xFFFA243C))),
                  Text('${_data!.year}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70)),
                ],
              ),
              const SizedBox(height: 18),
              if (_data!.topSongs.isNotEmpty) ...[
                Row(
                  children: [
                    AlbumArtwork(coverArt: _data!.topSongs.first.song.coverArt, size: 54, borderRadius: 10),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Top Song', style: TextStyle(fontSize: 11, color: Colors.white60)),
                          Text(
                            _data!.topSongs.first.song.title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _data!.topSongs.first.song.artist ?? '',
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetric('Minutes', '${_data!.totalMinutesListened}'),
                  Container(width: 1, height: 30, color: Colors.white24),
                  _buildMetric('Top Artist', _data!.topArtists.isNotEmpty ? _data!.topArtists.first.name : 'N/A'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _playTopSongs,
            icon: const Icon(CupertinoIcons.play_circle_fill, size: 20),
            label: const Text('Play Your Top Songs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFA243C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }
}
