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
  late final AnimationController _cardFloatController;

  WrappedData? _data;
  bool _isLoading = true;
  int _currentSlide = 0;
  static const int _totalSlides = 8;
  Timer? _autoAdvanceTimer;
  Timer? _suspenseTimer;
  bool _isPaused = false;
  bool _isSuspenseLocked = false;
  int _suspenseCountdown = 3;
  bool _topSongRevealed = false;

  // Real-time slide progress animation
  double _currentSlideProgress = 0.0;
  Timer? _progressTicker;

  @override
  void initState() {
    super.initState();
    // Fullscreen immersive display like Spotify Wrapped stories
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _auraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _suspenseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _cardFloatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
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
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _autoAdvanceTimer?.cancel();
    _suspenseTimer?.cancel();
    _progressTicker?.cancel();
    _auraController.dispose();
    _suspenseController.dispose();
    _cardFloatController.dispose();
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
    _progressTicker?.cancel();
    if (_isPaused || _isSuspenseLocked) return;

    _currentSlideProgress = 0.0;
    const slideDurationMs = 8000;
    const intervalMs = 50;
    final increment = intervalMs / slideDurationMs;

    _progressTicker = Timer.periodic(const Duration(milliseconds: intervalMs), (timer) {
      if (!mounted || _isPaused || _isSuspenseLocked) return;

      setState(() {
        _currentSlideProgress += increment;
        if (_currentSlideProgress >= 1.0) {
          _currentSlideProgress = 1.0;
          timer.cancel();
          if (_currentSlide < _totalSlides - 1) {
            _nextSlide();
          }
        }
      });
    });
  }

  void _triggerTopSongSuspense() {
    if (_topSongRevealed) return;

    setState(() {
      _isSuspenseLocked = true;
      _suspenseCountdown = 3;
      _currentSlideProgress = 0.0;
    });

    _autoAdvanceTimer?.cancel();
    _progressTicker?.cancel();

    // 3-second suspense countdown with haptics
    _suspenseTimer?.cancel();
    _suspenseTimer = Timer.periodic(const Duration(milliseconds: 900), (timer) {
      if (!mounted) return;

      if (_suspenseCountdown > 1) {
        HapticFeedback.heavyImpact();
        setState(() {
          _suspenseCountdown--;
        });
      } else {
        timer.cancel();
        HapticFeedback.vibrate();
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
    if (_isSuspenseLocked) return;

    if (_currentSlide < _totalSlides - 1) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentSlide++;
        _currentSlideProgress = 0.0;
      });

      // Trigger suspense on Slide 4 (Top Songs Reveal)
      if (_currentSlide == 4 && !_topSongRevealed) {
        _triggerTopSongSuspense();
      } else {
        _startSlideTimer();
      }
    }
  }

  void _prevSlide() {
    if (_isSuspenseLocked) return;

    if (_currentSlide > 0) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentSlide--;
        _currentSlideProgress = 0.0;
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
        backgroundColor: const Color(0xFF090A0F),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFA243C), Color(0xFFFF512F)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFA243C).withValues(alpha: 0.4),
                      blurRadius: 28,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: CupertinoActivityIndicator(color: Colors.white, radius: 16),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Preparazione di Musly Playback ${WrappedService.getWrappedYear()}...',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Synthesizing your listening universe',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF07080C),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          if (!_isSuspenseLocked) {
            setState(() => _isPaused = true);
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
          }
        },
        child: Stack(
          children: [
            // Dynamic Ambient Aura Mesh Shader Background
            _buildAnimatedBackground(),

            // Floating Audio Visualizer Particles
            _buildFloatingAuraParticles(),

            // Active Story Slide Content
            SafeArea(
              child: Column(
                children: [
                  // Progress Bars & Header Controls
                  _buildHeaderProgress(),

                  // Slide Viewport
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: _isSuspenseLocked && _currentSlide == 4
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
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFA243C), Color(0xFFFF512F)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFA243C).withValues(alpha: 0.4),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: const Icon(CupertinoIcons.gift_fill, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 28),
              const Text(
                'Musly Playback è Stagionale',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Il tuo Year-in-Review annuale si sblocca automaticamente ogni anno tra fine novembre e metà gennaio.\n\nContinua ad ascoltare musica per espandere il tuo universo sonoro!',
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
                label: const Text('Anteprima Playback (Modalità Test)'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFA243C),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    final palettes = [
      [const Color(0xFFFA243C), const Color(0xFF7928CA), const Color(0xFF000000)], // 0. Intro
      [const Color(0xFF00C6FF), const Color(0xFF0072FF), const Color(0xFF050B14)], // 1. Minutes
      [const Color(0xFFFF512F), const Color(0xFFDD2476), const Color(0xFF14050E)], // 2. Chronotype
      [const Color(0xFF8E2DE2), const Color(0xFF4A00E0), const Color(0xFF0E0514)], // 3. Genres
      [const Color(0xFFFF0844), const Color(0xFFFFB199), const Color(0xFF140508)], // 4. Top Songs
      [const Color(0xFF11998E), const Color(0xFF38EF7D), const Color(0xFF05140C)], // 5. Top Artists
      [const Color(0xFFFF007A), const Color(0xFF7928CA), const Color(0xFF0A0514)], // 6. Personality
      [const Color(0xFFFA243C), const Color(0xFFFF8C00), const Color(0xFF050505)], // 7. Bento Card
    ];

    final currentColors = palettes[_currentSlide % palettes.length];

    return AnimatedBuilder(
      animation: _auraController,
      builder: (context, _) {
        final shiftX = 0.4 * (_auraController.value - 0.5);
        final shiftY = -0.3 + 0.4 * (_auraController.value - 0.5);

        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(shiftX, shiftY),
              radius: 1.5,
              colors: [
                currentColors[0].withValues(alpha: 0.45),
                currentColors[1].withValues(alpha: 0.22),
                currentColors[2],
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingAuraParticles() {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _cardFloatController,
        builder: (context, _) {
          return Opacity(
            opacity: 0.15 + (_cardFloatController.value * 0.1),
            child: CustomPaint(
              size: Size.infinite,
              painter: _ParticlePainter(_cardFloatController.value),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderProgress() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          Row(
            children: List.generate(_totalSlides, (index) {
              double fill = 0.0;
              if (index < _currentSlide) {
                fill = 1.0;
              } else if (index == _currentSlide) {
                fill = _currentSlideProgress;
              }

              return Expanded(
                child: Container(
                  height: 3.5,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: fill.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFA243C).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFA243C).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(CupertinoIcons.sparkles, color: Color(0xFFFA243C), size: 13),
                        const SizedBox(width: 5),
                        Text(
                          'PLAYBACK ${_data!.year}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.xmark_circle_fill, color: Colors.white60, size: 24),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuspenseCountdownSlide() {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: AnimatedBuilder(
          animation: _suspenseController,
          builder: (context, _) {
            final scale = 1.0 + (_suspenseController.value * 0.18);

            return Column(
              key: const ValueKey('suspense'),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF0844).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFF0844).withValues(alpha: 0.6)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.lock_fill, color: Color(0xFFFF0844), size: 14),
                      SizedBox(width: 7),
                      Text(
                        'RULLO DI TAMBURI...',
                        style: TextStyle(
                          color: Color(0xFFFF0844),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                const Text(
                  'Pronto a scoprire\nil tuo brano #1?',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.15,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Color(0xFFFF0844), Color(0xFFFFB199)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF0844).withValues(alpha: 0.6),
                          blurRadius: 40 * scale,
                          spreadRadius: 8 * scale,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$_suspenseCountdown',
                        style: const TextStyle(
                          fontSize: 58,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                const Text(
                  'Preparati al drop sonoro...',
                  style: TextStyle(fontSize: 14, color: Colors.white70, fontStyle: FontStyle.italic),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSlideContent(int index) {
    final Widget content = switch (index) {
      0 => _buildIntroSlide(),
      1 => _buildMinutesSlide(),
      2 => _buildChronotypeSlide(),
      3 => _buildGenreGalaxySlide(),
      4 => _buildTopSongsSlide(),
      5 => _buildTopArtistsSlide(),
      6 => _buildPersonalitySlide(),
      7 => _buildSummaryCardSlide(),
      _ => const SizedBox.shrink(),
    };

    if (index == 3 || index == 4 || index == 5) {
      return content;
    }

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: content,
      ),
    );
  }

  // ── Slide 0: Intro / Overture ─────────────────────────────────────────────
  Widget _buildIntroSlide() {
    return Column(
      key: const ValueKey('intro'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _cardFloatController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, -6 * _cardFloatController.value),
              child: child,
            );
          },
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFA243C), Color(0xFF7928CA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFA243C).withValues(alpha: 0.5),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(CupertinoIcons.music_albums_fill, color: Colors.white, size: 54),
          ),
        ),
        const SizedBox(height: 36),
        Text(
          'Your ${_data!.year}\nin Sound',
          style: const TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.1,
            letterSpacing: -0.8,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          'You explored sonic depths, relived moments, and built memories through music.',
          style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.45),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white24),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tocca per iniziare', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              SizedBox(width: 8),
              Icon(CupertinoIcons.arrow_right, color: Colors.white, size: 15),
            ],
          ),
        ),
      ],
    );
  }

  // ── Slide 1: Total Minutes & Percentile ────────────────────────────────────
  Widget _buildMinutesSlide() {
    final mins = _data!.totalMinutesListened;
    final hours = (mins / 60).toStringAsFixed(1);

    return Column(
      key: const ValueKey('minutes'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF00C6FF).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF00C6FF).withValues(alpha: 0.4)),
          ),
          child: Text(
            _data!.percentileText.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Color(0xFF00C6FF),
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 24),
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: mins),
          duration: const Duration(milliseconds: 1600),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return Text(
              '$value',
              style: const TextStyle(
                fontSize: 68,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -1.5,
              ),
            );
          },
        ),
        const Text(
          'MINUTI DI ASCOLTO',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white60, letterSpacing: 2.2),
        ),
        const SizedBox(height: 36),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetric('Ore totali', hours),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildMetric('Brani unici', '${_data!.totalUniqueTracks}'),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildMetric('Artisti', '${_data!.totalUniqueArtists}'),
            ],
          ),
        ),
      ],
    );
  }

  // ── Slide 2: Musical Chronotype ───────────────────────────────────────────
  Widget _buildChronotypeSlide() {
    return Column(
      key: const ValueKey('chronotype'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'IL TUO CRONOTIPO MUSICALE',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFFFF512F), letterSpacing: 1.5),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF512F), Color(0xFFDD2476)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF512F).withValues(alpha: 0.4),
                blurRadius: 36,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(CupertinoIcons.clock_fill, color: Colors.white, size: 48),
              const SizedBox(height: 18),
              Text(
                _data!.chronotypeName,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _data!.chronotypeDescription,
                style: const TextStyle(fontSize: 15, color: Colors.white, height: 1.45),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Slide 3: Genre Galaxy ─────────────────────────────────────────────────
  Widget _buildGenreGalaxySlide() {
    return Column(
      key: const ValueKey('genres'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'GALASSIA DEI GENERI',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF8E2DE2), letterSpacing: 1.5),
        ),
        const SizedBox(height: 6),
        const Text(
          'I Suoni che ti hanno guidato',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.separated(
            itemCount: _data!.topGenres.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, i) {
              final g = _data!.topGenres[i];
              final pct = (g.percentage * 100).round();

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(color: g.accentColor, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              g.name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                        Text(
                          '$pct%',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: g.accentColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: g.percentage,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(g.accentColor),
                        minHeight: 6,
                      ),
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

  // ── Slide 4: Top Songs & Reveal ───────────────────────────────────────────
  Widget _buildTopSongsSlide() {
    return Column(
      key: const ValueKey('songs'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TOP BRANI',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFFFF0844), letterSpacing: 1.5),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(CupertinoIcons.speaker_2_fill, color: Color(0xFF10B981), size: 12),
                  SizedBox(width: 5),
                  Text('IN RIPRODUZIONE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'I tuoi brani più ascoltati',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.separated(
            itemCount: _data!.topSongs.length.clamp(0, 5),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final rank = _data!.topSongs[i];
              final isTop = i == 0;

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isTop
                      ? const Color(0xFFFF0844).withValues(alpha: 0.22)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isTop ? const Color(0xFFFF0844).withValues(alpha: 0.6) : Colors.white10,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      '#${rank.rank}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: isTop ? const Color(0xFFFF0844) : Colors.white60,
                      ),
                    ),
                    const SizedBox(width: 14),
                    AlbumArtwork(coverArt: rank.song.coverArt, size: 48, borderRadius: 10),
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
                            rank.song.artist ?? 'Artista sconosciuto',
                            style: const TextStyle(fontSize: 12, color: Colors.white60),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${rank.playCount} ascolti',
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

  // ── Slide 5: Top Artists ──────────────────────────────────────────────────
  Widget _buildTopArtistsSlide() {
    return Column(
      key: const ValueKey('artists'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TOP ARTISTI',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF11998E), letterSpacing: 1.5),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF11998E).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF11998E).withValues(alpha: 0.4)),
              ),
              child: Text(
                _data!.topArtistSuperfanBadge,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF38EF7D)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Gli autori del tuo anno',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.separated(
            itemCount: _data!.topArtists.length.clamp(0, 5),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final rank = _data!.topArtists[i];
              final isTop = i == 0;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isTop
                      ? const Color(0xFF11998E).withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isTop ? const Color(0xFF38EF7D).withValues(alpha: 0.5) : Colors.white10,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      '#${rank.rank}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: isTop ? const Color(0xFF38EF7D) : Colors.white60,
                      ),
                    ),
                    const SizedBox(width: 14),
                    if (rank.coverArt != null && rank.coverArt!.isNotEmpty)
                      AlbumArtwork(coverArt: rank.coverArt, size: 44, borderRadius: 22)
                    else
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFF11998E).withValues(alpha: 0.3),
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
                      '${rank.playCount} ascolti',
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

  // ── Slide 6: Listening Personality Archetype ──────────────────────────────
  Widget _buildPersonalitySlide() {
    final arch = _data!.archetype;

    return Column(
      key: const ValueKey('personality'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'LA TUA PERSONALITÀ MUSICALE',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFFFF007A), letterSpacing: 1.5),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: arch.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: arch.gradientColors.first.withValues(alpha: 0.4),
                blurRadius: 40,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              Text(arch.emoji, style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  arch.badge,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                arch.title,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                arch.description,
                style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.45),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: arch.traits.map((t) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(t, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Slide 7: Bento Summary & Share Card ───────────────────────────────────
  Widget _buildSummaryCardSlide() {
    return Column(
      key: const ValueKey('summary'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'MUSLY PLAYBACK',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.8, color: Color(0xFFFA243C)),
                  ),
                  Text('${_data!.year}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70)),
                ],
              ),
              const SizedBox(height: 20),
              if (_data!.topSongs.isNotEmpty) ...[
                Row(
                  children: [
                    AlbumArtwork(coverArt: _data!.topSongs.first.song.coverArt, size: 58, borderRadius: 12),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Brano #1', style: TextStyle(fontSize: 11, color: Colors.white60, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
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
                const SizedBox(height: 18),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetric('Minuti', '${_data!.totalMinutesListened}'),
                  Container(width: 1, height: 32, color: Colors.white24),
                  _buildMetric('Top Artista', _data!.topArtists.isNotEmpty ? _data!.topArtists.first.name : 'N/A'),
                  Container(width: 1, height: 32, color: Colors.white24),
                  _buildMetric('Genere', _data!.topGenre),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _playTopSongs,
            icon: const Icon(CupertinoIcons.play_circle_fill, size: 22),
            label: const Text('Ascolta i tuoi Top Brani', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFA243C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white60, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double animationValue;

  _ParticlePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    const particleCount = 18;
    for (int i = 0; i < particleCount; i++) {
      final x = (size.width * (i * 0.13 + 0.1)) % size.width;
      final baseY = size.height * (i * 0.17 + 0.05) % size.height;
      final y = (baseY + animationValue * 20 * (i.isEven ? 1 : -1)) % size.height;
      final radius = (i % 3 + 1.5);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
