import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/library_provider.dart';
import '../../services/recommendation_service.dart';
import '../../services/wrapped_service.dart';
import '../../widgets/common/album_artwork.dart';
import '../../l10n/app_localizations.dart';

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

  String _getChronotypeName(AppLocalizations? l10n, String id, String fallback) {
    if (l10n == null) return fallback;
    return switch (id) {
      'midnight_wanderer' => l10n.chronotypeMidnightWanderer,
      'sunrise_harmonizer' => l10n.chronotypeSunriseHarmonizer,
      'afternoon_flow' => l10n.chronotypeAfternoonFlow,
      'twilight_lounger' => l10n.chronotypeTwilightLounger,
      _ => fallback,
    };
  }

  String _getChronotypeDesc(AppLocalizations? l10n, String id, String fallback) {
    if (l10n == null) return fallback;
    return switch (id) {
      'midnight_wanderer' => l10n.chronotypeMidnightWandererDesc,
      'sunrise_harmonizer' => l10n.chronotypeSunriseHarmonizerDesc,
      'afternoon_flow' => l10n.chronotypeAfternoonFlowDesc,
      'twilight_lounger' => l10n.chronotypeTwilightLoungerDesc,
      _ => fallback,
    };
  }

  String _getArchetypeTitle(AppLocalizations? l10n, PersonalityArchetype arch) {
    if (l10n == null) return arch.title;
    return switch (arch.id) {
      'luminary' => l10n.archetypeLuminary,
      'devotee' => l10n.archetypeDevotee,
      'night_owl' => l10n.archetypeNightOwl,
      'sunrise_harmonizer' => l10n.archetypeSunrise,
      'alchemist' => l10n.archetypeAlchemist,
      _ => arch.title,
    };
  }

  String _getArchetypeBadge(AppLocalizations? l10n, PersonalityArchetype arch) {
    if (l10n == null) return arch.badge;
    return switch (arch.id) {
      'luminary' => l10n.archetypeLuminaryBadge,
      'devotee' => l10n.archetypeDevoteeBadge,
      'night_owl' => l10n.archetypeNightOwlBadge,
      'sunrise_harmonizer' => l10n.archetypeSunriseBadge,
      'alchemist' => l10n.archetypeAlchemistBadge,
      _ => arch.badge,
    };
  }

  String _getArchetypeDesc(AppLocalizations? l10n, PersonalityArchetype arch) {
    if (l10n == null) return arch.description;
    return switch (arch.id) {
      'luminary' => l10n.archetypeLuminaryDesc,
      'devotee' => l10n.archetypeDevoteeDesc,
      'night_owl' => l10n.archetypeNightOwlDesc,
      'sunrise_harmonizer' => l10n.archetypeSunriseDesc,
      'alchemist' => l10n.archetypeAlchemistDesc,
      _ => arch.description,
    };
  }

  List<String> _getArchetypeTraits(AppLocalizations? l10n, PersonalityArchetype arch) {
    if (l10n == null) return arch.traits;
    return switch (arch.id) {
      'luminary' => [l10n.archetypeLuminaryTrait1, l10n.archetypeLuminaryTrait2, l10n.archetypeLuminaryTrait3],
      'devotee' => [l10n.archetypeDevoteeTrait1, l10n.archetypeDevoteeTrait2, l10n.archetypeDevoteeTrait3],
      'night_owl' => [l10n.archetypeNightOwlTrait1, l10n.archetypeNightOwlTrait2, l10n.archetypeNightOwlTrait3],
      'sunrise_harmonizer' => [l10n.archetypeSunriseTrait1, l10n.archetypeSunriseTrait2, l10n.archetypeSunriseTrait3],
      'alchemist' => [l10n.archetypeAlchemistTrait1, l10n.archetypeAlchemistTrait2, l10n.archetypeAlchemistTrait3],
      _ => arch.traits,
    };
  }

  String _getSuperfanBadge(AppLocalizations? l10n, int topArtistPlays) {
    if (l10n == null) {
      return topArtistPlays >= 30
          ? 'Top 0.1% Superfan'
          : (topArtistPlays >= 15 ? 'Top 1% Fan' : 'Top 5% Fan');
    }
    return topArtistPlays >= 30
        ? l10n.superfanBadge01
        : (topArtistPlays >= 15 ? l10n.superfanBadge1 : l10n.superfanBadge5);
  }

  String _getPercentileText(AppLocalizations? l10n, int minutes) {
    if (l10n == null) {
      if (minutes >= 15000) return 'Top 0.5% Global Listener';
      if (minutes >= 8000) return 'Top 1% Global Listener';
      if (minutes >= 4000) return 'Top 5% Global Listener';
      if (minutes >= 1500) return 'Top 10% Global Listener';
      return 'Top Music Aficionado';
    }
    if (minutes >= 15000) return l10n.percentileTop05;
    if (minutes >= 8000) return l10n.percentileTop1;
    if (minutes >= 4000) return l10n.percentileTop5;
    if (minutes >= 1500) return l10n.percentileTop10;
    return l10n.percentileTopAficionado;
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  Widget _buildGlassCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(22),
    BorderRadius? borderRadius,
    Color? backgroundColor,
    Border? border,
    List<BoxShadow>? boxShadow,
  }) {
    final radius = borderRadius ?? BorderRadius.circular(26);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white.withValues(alpha: 0.08),
            borderRadius: radius,
            border: border ??
                Border.all(
                  color: Colors.white.withValues(alpha: 0.16),
                  width: 1.2,
                ),
            boxShadow: boxShadow ??
                [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSeason = WrappedService.isWrappedSeason(devPreview: widget.devPreview);
    final l10n = AppLocalizations.of(context);

    if (!isSeason) {
      return _buildOutOfSeasonScreen();
    }

    if (_isLoading || _data == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF07080C),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFA243C), Color(0xFFFF512F)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFA243C).withValues(alpha: 0.45),
                      blurRadius: 32,
                      spreadRadius: 6,
                    ),
                  ],
                ),
                child: const Center(
                  child: CupertinoActivityIndicator(color: Colors.white, radius: 16),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                '${l10n?.muslyPlayback ?? 'Musly Playback'} ${WrappedService.getWrappedYear()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n?.synthesizingUniverse ?? 'Synthesizing your listening universe',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPressStart: (_) {
          if (!_isSuspenseLocked) {
            setState(() => _isPaused = true);
          }
        },
        onLongPressEnd: (_) {
          if (!_isSuspenseLocked) {
            setState(() => _isPaused = false);
          }
        },
        onTapUp: (details) {
          if (!_isSuspenseLocked) {
            final width = MediaQuery.of(context).size.width;
            if (details.globalPosition.dx < width * 0.3) {
              _prevSlide();
            } else {
              _nextSlide();
            }
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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 380),
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

            // Paused Indicator Overlay
            if (_isPaused)
              Positioned(
                top: 50,
                left: 0,
                right: 0,
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        color: Colors.black45,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.pause_fill, color: Colors.white70, size: 12),
                            SizedBox(width: 6),
                            Text(
                              'PAUSED',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
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

  Widget _buildOutOfSeasonScreen() {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF07080C),
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
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFA243C), Color(0xFFFF512F)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFA243C).withValues(alpha: 0.4),
                      blurRadius: 36,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(CupertinoIcons.gift_fill, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 32),
              Text(
                l10n?.wrappedSeasonal ?? 'Musly Playback is Seasonal',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Text(
                l10n?.muslyPlaybackAnnualSubtitle ??
                    'Your annual Year-in-Review unlocks automatically every year between late November and mid-January.\n\nKeep listening to music to expand your sonic universe!',
                style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.55),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const WrappedScreen(devPreview: true),
                    ),
                  );
                },
                icon: const Icon(CupertinoIcons.sparkles, size: 18),
                label: Text(l10n?.muslyPlaybackDev ?? 'Playback Preview (Test Mode)'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFA243C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 8,
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
      [const Color(0xFFFA243C), const Color(0xFF7928CA), const Color(0xFF030305)], // 0. Intro
      [const Color(0xFF00C6FF), const Color(0xFF0072FF), const Color(0xFF020710)], // 1. Minutes
      [const Color(0xFFFF512F), const Color(0xFFDD2476), const Color(0xFF0C0308)], // 2. Chronotype
      [const Color(0xFF8E2DE2), const Color(0xFF4A00E0), const Color(0xFF080310)], // 3. Genres
      [const Color(0xFFFF0844), const Color(0xFFFFB199), const Color(0xFF0C0305)], // 4. Top Songs
      [const Color(0xFF11998E), const Color(0xFF38EF7D), const Color(0xFF030D08)], // 5. Top Artists
      [const Color(0xFFFF007A), const Color(0xFF7928CA), const Color(0xFF080310)], // 6. Personality
      [const Color(0xFFFA243C), const Color(0xFFFF8C00), const Color(0xFF040406)], // 7. Bento Card
    ];

    final currentColors = palettes[_currentSlide % palettes.length];

    return AnimatedBuilder(
      animation: _auraController,
      builder: (context, _) {
        final shiftX = 0.35 * (_auraController.value - 0.5);
        final shiftY = -0.3 + 0.35 * (_auraController.value - 0.5);

        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(shiftX, shiftY),
              radius: 1.4,
              colors: [
                currentColors[0].withValues(alpha: 0.42),
                currentColors[1].withValues(alpha: 0.18),
                currentColors[2],
              ],
              stops: const [0.0, 0.6, 1.0],
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
            opacity: 0.14 + (_cardFloatController.value * 0.08),
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
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
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
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: fill.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.6),
                            blurRadius: 4,
                          ),
                        ],
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
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFA243C).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFA243C).withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(CupertinoIcons.sparkles, color: Color(0xFFFA243C), size: 12),
                        const SizedBox(width: 6),
                        Text(
                          'PLAYBACK ${_data!.year}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.1),
                    child: IconButton(
                      icon: const Icon(CupertinoIcons.xmark, color: Colors.white70, size: 18),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuspenseCountdownSlide() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: AnimatedBuilder(
          animation: _suspenseController,
          builder: (context, _) {
            final scale = 1.0 + (_suspenseController.value * 0.16);

            return Column(
              key: const ValueKey('suspense'),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF0844).withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFF0844).withValues(alpha: 0.6)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(CupertinoIcons.lock_fill, color: Color(0xFFFF0844), size: 13),
                          const SizedBox(width: 7),
                          Text(
                            l10n?.drumroll ?? 'DRUMROLL...',
                            style: const TextStyle(
                              color: Color(0xFFFF0844),
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                Text(
                  l10n?.readyToDiscoverTopSong ??
                      'Ready to discover\nyour #1 song?',
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.15,
                    letterSpacing: -0.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 124,
                    height: 124,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Color(0xFFFF0844), Color(0xFFFFB199)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF0844).withValues(alpha: 0.65),
                          blurRadius: 44 * scale,
                          spreadRadius: 8 * scale,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$_suspenseCountdown',
                        style: const TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                Text(
                  l10n?.getReadyForBeatDrop ?? 'Get ready for the beat drop...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.75),
                    fontStyle: FontStyle.italic,
                  ),
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
    final l10n = AppLocalizations.of(context);
    return Column(
      key: const ValueKey('intro'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _cardFloatController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, -8 * _cardFloatController.value),
              child: child,
            );
          },
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFA243C), Color(0xFF7928CA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFA243C).withValues(alpha: 0.55),
                  blurRadius: 44,
                  spreadRadius: 4,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(CupertinoIcons.music_albums_fill, color: Colors.white, size: 58),
          ),
        ),
        const SizedBox(height: 38),
        Text(
          l10n?.yourYearInSound(_data!.year) ?? 'Your ${_data!.year}\nin Sound',
          style: const TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.08,
            letterSpacing: -1.0,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            l10n?.yourYearInSoundSubtitle ??
                'You explored sonic depths, relived moments, and built memories through music.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 44),
        _buildGlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
          borderRadius: BorderRadius.circular(30),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n?.tapToBegin ?? 'Tap to begin',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
              ),
              const SizedBox(width: 10),
              const Icon(CupertinoIcons.arrow_right, color: Colors.white, size: 15),
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
    final l10n = AppLocalizations.of(context);

    return Column(
      key: const ValueKey('minutes'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildGlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          borderRadius: BorderRadius.circular(20),
          backgroundColor: const Color(0xFF00C6FF).withValues(alpha: 0.16),
          border: Border.all(color: const Color(0xFF00C6FF).withValues(alpha: 0.45)),
          child: Text(
            _getPercentileText(l10n, mins).toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Color(0xFF00C6FF),
              letterSpacing: 1.3,
            ),
          ),
        ),
        const SizedBox(height: 28),
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: mins),
          duration: const Duration(milliseconds: 1600),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return Text(
              _formatNumber(value),
              style: const TextStyle(
                fontSize: 66,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -2.0,
              ),
            );
          },
        ),
        Text(
          l10n?.minutesListened ?? 'MINUTES LISTENED',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Colors.white.withValues(alpha: 0.65),
            letterSpacing: 2.4,
          ),
        ),
        const SizedBox(height: 38),
        _buildGlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetric(l10n?.totalHours ?? 'Total hours', hours),
              Container(width: 1, height: 42, color: Colors.white24),
              _buildMetric(l10n?.uniqueTracks ?? 'Unique tracks', _formatNumber(_data!.totalUniqueTracks)),
              Container(width: 1, height: 42, color: Colors.white24),
              _buildMetric(l10n?.artists ?? 'Artists', '${_data!.totalUniqueArtists}'),
            ],
          ),
        ),
      ],
    );
  }

  // ── Slide 2: Musical Chronotype ───────────────────────────────────────────
  Widget _buildChronotypeSlide() {
    final l10n = AppLocalizations.of(context);
    final chronoName = _getChronotypeName(l10n, _data!.chronotypeId, _data!.chronotypeName);
    final chronoDesc = _getChronotypeDesc(l10n, _data!.chronotypeId, _data!.chronotypeDescription);

    return Column(
      key: const ValueKey('chronotype'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n?.yourMusicalChronotype ?? 'YOUR MUSICAL CHRONOTYPE',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Color(0xFFFF512F),
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        _buildGlassCard(
          padding: const EdgeInsets.all(28),
          backgroundColor: const Color(0xFFFF512F).withValues(alpha: 0.2),
          border: Border.all(color: const Color(0xFFFF512F).withValues(alpha: 0.45)),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF512F), Color(0xFFDD2476)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF512F).withValues(alpha: 0.45),
                      blurRadius: 28,
                    ),
                  ],
                ),
                child: const Icon(CupertinoIcons.clock_fill, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 22),
              Text(
                chronoName,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                chronoDesc,
                style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.85), height: 1.45),
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
    final l10n = AppLocalizations.of(context);
    return Column(
      key: const ValueKey('genres'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.genreGalaxy ?? 'GENRE GALAXY',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF8E2DE2), letterSpacing: 1.6),
        ),
        const SizedBox(height: 6),
        Text(
          l10n?.soundsThatGuidedYou ?? 'The sounds that guided you',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.4),
        ),
        const SizedBox(height: 22),
        Expanded(
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            itemCount: _data!.topGenres.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final g = _data!.topGenres[i];
              final pct = (g.percentage * 100).round();
              final isTop = i == 0;

              return _buildGlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                backgroundColor: isTop
                    ? g.accentColor.withValues(alpha: 0.16)
                    : Colors.white.withValues(alpha: 0.06),
                border: Border.all(
                  color: isTop ? g.accentColor.withValues(alpha: 0.45) : Colors.white.withValues(alpha: 0.12),
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
                              decoration: BoxDecoration(
                                color: g.accentColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: g.accentColor.withValues(alpha: 0.8),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
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
                    const SizedBox(height: 12),
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
    final l10n = AppLocalizations.of(context);
    final songs = _data!.topSongs;
    final topSong = songs.isNotEmpty ? songs.first : null;

    return Column(
      key: const ValueKey('songs'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n?.topSongsHeader ?? 'TOP SONGS',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFFFF0844), letterSpacing: 1.6),
            ),
            _buildGlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
              borderRadius: BorderRadius.circular(12),
              backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.2),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
              child: Row(
                children: [
                  const _EqualizerBars(color: Color(0xFF10B981)),
                  const SizedBox(width: 7),
                  Text(
                    l10n?.nowPlayingHeader ?? 'NOW PLAYING',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          l10n?.yourMostListenedSongs ?? 'Your most listened songs',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.4),
        ),
        const SizedBox(height: 18),
        // Hero #1 Song Card
        if (topSong != null) ...[
          _buildGlassCard(
            padding: const EdgeInsets.all(16),
            backgroundColor: const Color(0xFFFF0844).withValues(alpha: 0.18),
            border: Border.all(color: const Color(0xFFFF0844).withValues(alpha: 0.5)),
            child: Row(
              children: [
                Stack(
                  children: [
                    AlbumArtwork(coverArt: topSong.song.coverArt, size: 70, borderRadius: 14),
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF0844),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '#1',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topSong.song.title,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        topSong.song.artist ?? (l10n?.unknownArtist ?? 'Unknown Artist'),
                        style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n?.playsCount(topSong.playCount) ?? '${topSong.playCount} plays',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFFB199)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Runner-ups #2 to #5
        Expanded(
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            itemCount: songs.length > 1 ? songs.skip(1).take(4).length : 0,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final rank = songs[i + 1];

              return _buildGlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                child: Row(
                  children: [
                    Text(
                      '#${rank.rank}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    AlbumArtwork(coverArt: rank.song.coverArt, size: 40, borderRadius: 8),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rank.song.title,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            rank.song.artist ?? (l10n?.unknownArtist ?? 'Unknown Artist'),
                            style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${rank.playCount}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.7)),
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
    final l10n = AppLocalizations.of(context);
    final artists = _data!.topArtists;
    final topArtist = artists.isNotEmpty ? artists.first : null;

    return Column(
      key: const ValueKey('artists'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n?.topArtistsHeader ?? 'TOP ARTISTS',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF11998E), letterSpacing: 1.6),
            ),
            _buildGlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
              borderRadius: BorderRadius.circular(12),
              backgroundColor: const Color(0xFF11998E).withValues(alpha: 0.2),
              border: Border.all(color: const Color(0xFF11998E).withValues(alpha: 0.4)),
              child: Text(
                _getSuperfanBadge(l10n, _data!.topArtistPlayCount),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF38EF7D)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          l10n?.yourMusicalAnchors ?? 'Your musical anchors',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.4),
        ),
        const SizedBox(height: 18),
        // Hero #1 Artist
        if (topArtist != null) ...[
          _buildGlassCard(
            padding: const EdgeInsets.all(18),
            backgroundColor: const Color(0xFF11998E).withValues(alpha: 0.2),
            border: Border.all(color: const Color(0xFF38EF7D).withValues(alpha: 0.5)),
            child: Row(
              children: [
                if (topArtist.coverArt != null && topArtist.coverArt!.isNotEmpty)
                  AlbumArtwork(coverArt: topArtist.coverArt, size: 68, borderRadius: 34)
                else
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: const Color(0xFF11998E).withValues(alpha: 0.35),
                    child: Text(
                      topArtist.name.isNotEmpty ? topArtist.name[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38EF7D).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '#1 ARTIST',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF38EF7D)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        topArtist.name,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n?.playsCount(topArtist.playCount) ?? '${topArtist.playCount} plays',
                        style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.75), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Runner-ups #2 to #5
        Expanded(
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            itemCount: artists.length > 1 ? artists.skip(1).take(4).length : 0,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final rank = artists[i + 1];

              return _buildGlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                child: Row(
                  children: [
                    Text(
                      '#${rank.rank}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (rank.coverArt != null && rank.coverArt!.isNotEmpty)
                      AlbumArtwork(coverArt: rank.coverArt, size: 38, borderRadius: 19)
                    else
                      CircleAvatar(
                        radius: 19,
                        backgroundColor: const Color(0xFF11998E).withValues(alpha: 0.3),
                        child: Text(
                          rank.name.isNotEmpty ? rank.name[0].toUpperCase() : '?',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        rank.name,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${rank.playCount}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.7)),
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
    final l10n = AppLocalizations.of(context);
    final arch = _data!.archetype;
    final archTitle = _getArchetypeTitle(l10n, arch);
    final archBadge = _getArchetypeBadge(l10n, arch);
    final archDesc = _getArchetypeDesc(l10n, arch);
    final archTraits = _getArchetypeTraits(l10n, arch);

    return Column(
      key: const ValueKey('personality'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n?.yourListeningPersonality ?? 'YOUR LISTENING PERSONALITY',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFFFF007A), letterSpacing: 1.6),
        ),
        const SizedBox(height: 24),
        _buildGlassCard(
          padding: const EdgeInsets.all(28),
          backgroundColor: arch.gradientColors.first.withValues(alpha: 0.22),
          border: Border.all(color: arch.gradientColors.first.withValues(alpha: 0.5)),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: arch.gradientColors),
                  boxShadow: [
                    BoxShadow(
                      color: arch.gradientColors.first.withValues(alpha: 0.45),
                      blurRadius: 32,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(arch.emoji, style: const TextStyle(fontSize: 40)),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4.5),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  archBadge,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.3),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                archTitle,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                archDesc,
                style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.85), height: 1.45),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: archTraits.map((t) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text(
                      t,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
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
    final l10n = AppLocalizations.of(context);
    return Column(
      key: const ValueKey('summary'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildGlassCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFA243C),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n?.muslyPlaybackHeader ?? 'MUSLY PLAYBACK',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.8,
                          color: Color(0xFFFA243C),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${_data!.year}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_data!.topSongs.isNotEmpty) ...[
                _buildGlassCard(
                  padding: const EdgeInsets.all(12),
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  border: Border.all(color: Colors.white10),
                  child: Row(
                    children: [
                      AlbumArtwork(coverArt: _data!.topSongs.first.song.coverArt, size: 54, borderRadius: 12),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n?.topSongBadge ?? 'Song #1',
                              style: const TextStyle(fontSize: 11, color: Color(0xFFFF0844), fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _data!.topSongs.first.song.title,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
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
                ),
                const SizedBox(height: 16),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetric(l10n?.minutes ?? 'Minutes', _formatNumber(_data!.totalMinutesListened)),
                  Container(width: 1, height: 34, color: Colors.white24),
                  _buildMetric(l10n?.topArtistMetric ?? 'Top Artist', _data!.topArtists.isNotEmpty ? _data!.topArtists.first.name : 'N/A'),
                  Container(width: 1, height: 34, color: Colors.white24),
                  _buildMetric(l10n?.genreMetric ?? 'Genre', _data!.topGenre),
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
            label: Text(
              l10n?.playYourTopSongs ?? 'Play Your Top Songs',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFA243C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.3),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.65), fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _EqualizerBars extends StatefulWidget {
  final Color color;
  final double size;
  const _EqualizerBars({this.color = Colors.white, this.size = 14});

  @override
  State<_EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<_EqualizerBars> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final v = _controller.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _bar(4 + (v * 8)),
            const SizedBox(width: 2),
            _bar(12 - (v * 7)),
            const SizedBox(width: 2),
            _bar(6 + (v * 7)),
            const SizedBox(width: 2),
            _bar(14 - (v * 9)),
          ],
        );
      },
    );
  }

  Widget _bar(double height) {
    return Container(
      width: 2.2,
      height: height.clamp(3.0, widget.size),
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(2),
      ),
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
