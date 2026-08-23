import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:musly/services/storage_service.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onFinished;

  const OnboardingScreen({super.key, this.onFinished});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingFeature {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingFeature({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _OnboardingItem {
  final String titlePrefix;
  final String titleHighlight;
  final String description;
  final Color highlightColor;
  final List<Color> auraColors;
  final List<Color> buttonGradient;
  final Color glowColor;
  final String buttonText;
  final List<_OnboardingFeature> features;

  const _OnboardingItem({
    required this.titlePrefix,
    required this.titleHighlight,
    required this.description,
    required this.highlightColor,
    required this.auraColors,
    required this.buttonGradient,
    required this.glowColor,
    required this.buttonText,
    required this.features,
  });
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final FocusNode _keyboardFocusNode = FocusNode();
  int _currentPage = 0;

  static const List<_OnboardingItem> _slides = [
    _OnboardingItem(
      titlePrefix: 'Your Music Library,\n',
      titleHighlight: 'In Your Pocket.',
      description:
          'Connect to Navidrome, Subsonic, Jellyfin, or play local files with bit-perfect lossless quality.',
      highlightColor: Color(0xFF60A5FA),
      auraColors: [
        Color(0xFF1E3A8A),
        Color(0xFF2563EB),
        Color(0xFF38BDF8),
        Color(0xFF60A5FA),
      ],
      buttonGradient: [Color(0xFF2563EB), Color(0xFF38BDF8)],
      glowColor: Color(0xFF2563EB),
      buttonText: 'Next',
      features: [
        _OnboardingFeature(
          icon: CupertinoIcons.music_note_2,
          title: 'Self-Hosted Freedom',
          description: 'Full compatibility with Subsonic, Navidrome, and Jellyfin APIs.',
        ),
        _OnboardingFeature(
          icon: CupertinoIcons.folder_fill,
          title: 'Local Music Support',
          description: 'Play your offline collection directly without server setup.',
        ),
        _OnboardingFeature(
          icon: CupertinoIcons.waveform,
          title: 'Lossless Hi-Res Audio',
          description: 'Bit-perfect FLAC, ALAC, Opus, and gapless audio playback.',
        ),
      ],
    ),
    _OnboardingItem(
      titlePrefix: 'Smart Mixes,\n',
      titleHighlight: 'Built Around You.',
      description:
          'Musly learns your listening habits on-device to craft dynamic daily mixes and surface forgotten favorites.',
      highlightColor: Color(0xFFFB923C),
      auraColors: [
        Color(0xFF7C2D12),
        Color(0xFFEA580C),
        Color(0xFFF97316),
        Color(0xFFFBBF24),
      ],
      buttonGradient: [Color(0xFFEA580C), Color(0xFFF97316)],
      glowColor: Color(0xFFEA580C),
      buttonText: 'Next',
      features: [
        _OnboardingFeature(
          icon: CupertinoIcons.sparkles,
          title: 'Algorithmic Taste Profiling',
          description: 'Learns play frequencies, skips, and ratings with recency decay.',
        ),
        _OnboardingFeature(
          icon: CupertinoIcons.antenna_radiowaves_left_right,
          title: 'Personalized Daily Mixes',
          description: 'Automatic Made For You, Listen Again, and Top Hits playlists.',
        ),
        _OnboardingFeature(
          icon: CupertinoIcons.device_laptop,
          title: '100% On-Device Processing',
          description: 'Your listening profile stays strictly on your hardware.',
        ),
      ],
    ),
    _OnboardingItem(
      titlePrefix: 'Completely Private.\n',
      titleHighlight: 'No Ads, No Tracking.',
      description:
          'Zero analytics, zero telemetry. Enjoy time-synced lyrics, offline downloads, and desktop sync in total privacy.',
      highlightColor: Color(0xFF34D399),
      auraColors: [
        Color(0xFF064E3B),
        Color(0xFF059669),
        Color(0xFF10B981),
        Color(0xFF34D399),
      ],
      buttonGradient: [Color(0xFF059669), Color(0xFF10B981)],
      glowColor: Color(0xFF10B981),
      buttonText: 'Get Started',
      features: [
        _OnboardingFeature(
          icon: CupertinoIcons.shield_fill,
          title: 'Zero Telemetry & Tracking',
          description: 'No third-party SDKs, no trackers, no ads, completely open source.',
        ),
        _OnboardingFeature(
          icon: CupertinoIcons.text_quote,
          title: 'Time-Synced Lyrics',
          description: 'Real-time synchronized karaoke lyrics with LRCLIB fallback.',
        ),
        _OnboardingFeature(
          icon: CupertinoIcons.arrow_down_circle_fill,
          title: 'Offline Download Manager',
          description: 'Cache full playlists and albums with batch downloading.',
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _keyboardFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    HapticFeedback.mediumImpact();
    await StorageService().setOnboardingCompleted(true);
    if (widget.onFinished != null) {
      widget.onFinished!();
    } else if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _goToPage(int page) {
    if (page < 0 || page >= _slides.length) return;
    HapticFeedback.lightImpact();
    setState(() => _currentPage = page);
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _onNextPressed() {
    if (_currentPage < _slides.length - 1) {
      _goToPage(_currentPage + 1);
    } else {
      _completeOnboarding();
    }
  }

  void _onPrevPressed() {
    if (_currentPage > 0) {
      _goToPage(_currentPage - 1);
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.space) {
      _onNextPressed();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _onPrevPressed();
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      _onNextPressed();
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = _slides[_currentPage];
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 820;

    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: const Color(0xFF090A0E),
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Stack(
            children: [
              // Ambient Aura Mesh Gradient
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: isDesktop
                          ? const Alignment(-0.35, -0.2)
                          : const Alignment(0.4, -0.65),
                      radius: isDesktop ? 1.35 : 1.15,
                      colors: [
                        currentItem.auraColors[1].withValues(alpha: isDesktop ? 0.75 : 0.85),
                        currentItem.auraColors[0].withValues(alpha: isDesktop ? 0.55 : 0.65),
                        currentItem.auraColors[2].withValues(alpha: 0.25),
                        const Color(0xFF090A0E).withValues(alpha: 0.95),
                        const Color(0xFF090A0E),
                      ],
                      stops: const [0.0, 0.35, 0.65, 0.88, 1.0],
                    ),
                  ),
                ),
              ),

              // Secondary soft blurred orb
              Positioned(
                top: isDesktop ? -40 : -80,
                left: isDesktop ? 100 : -60,
                width: isDesktop ? 450 : 320,
                height: isDesktop ? 450 : 320,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: currentItem.auraColors[3].withValues(alpha: 0.16),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                    child: const SizedBox(),
                  ),
                ),
              ),

              // Content Canvas
              SafeArea(
                child: isDesktop
                    ? _buildDesktopLayout(context, currentItem)
                    : _buildMobileLayout(context, currentItem),
              ),

              // Desktop floating prev/next navigation chevrons on window edges
              if (isDesktop) ...[
                if (_currentPage > 0)
                  Positioned(
                    left: 24,
                    top: size.height / 2 - 24,
                    child: _buildFloatingNavButton(
                      icon: CupertinoIcons.chevron_left,
                      tooltip: 'Previous (Left Arrow)',
                      onTap: _onPrevPressed,
                    ),
                  ),
                if (_currentPage < _slides.length - 1)
                  Positioned(
                    right: 24,
                    top: size.height / 2 - 24,
                    child: _buildFloatingNavButton(
                      icon: CupertinoIcons.chevron_right,
                      tooltip: 'Next (Right Arrow / Space)',
                      onTap: _onNextPressed,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Desktop Layout ─────────────────────────────────────────────────────────

  Widget _buildDesktopLayout(BuildContext context, _OnboardingItem currentItem) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: Column(
            children: [
              // Top Bar: Logo + App Name + Close / Skip button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.asset('assets/logobig.png', fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Musly',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: _completeOnboarding,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.onFinished == null ? 'Close' : 'Skip Tour',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(CupertinoIcons.xmark, size: 14, color: Colors.white70),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Split Columns
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left Showcase Showcase Card
                    Expanded(
                      flex: 5,
                      child: _buildShowcaseVisualCard(currentItem),
                    ),

                    const SizedBox(width: 48),

                    // Right Content Pane
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 320),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            child: KeyedSubtree(
                              key: ValueKey<int>(_currentPage),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Headline
                                  RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                        fontSize: 38,
                                        fontWeight: FontWeight.w800,
                                        height: 1.15,
                                        letterSpacing: -0.8,
                                        color: Colors.white,
                                      ),
                                      children: [
                                        TextSpan(text: currentItem.titlePrefix),
                                        TextSpan(
                                          text: currentItem.titleHighlight,
                                          style: TextStyle(
                                            color: currentItem.highlightColor,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 14),

                                  // Subtitle
                                  Text(
                                    currentItem.description,
                                    style: TextStyle(
                                      fontSize: 15.5,
                                      height: 1.5,
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // Feature Bullet List
                                  ...currentItem.features.map((feature) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: currentItem.highlightColor.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              feature.icon,
                                              color: currentItem.highlightColor,
                                              size: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  feature.title,
                                                  style: const TextStyle(
                                                    fontSize: 14.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  feature.description,
                                                  style: TextStyle(
                                                    fontSize: 12.5,
                                                    color: Colors.white.withValues(alpha: 0.55),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Slide Indicators & Navigation Buttons
                          Row(
                            children: [
                              // Slide Indicators
                              Row(
                                children: List.generate(_slides.length, (index) {
                                  final isActive = index == _currentPage;
                                  return GestureDetector(
                                    onTap: () => _goToPage(index),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 260),
                                      margin: const EdgeInsets.only(right: 8),
                                      width: isActive ? 28 : 8,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? currentItem.highlightColor
                                            : Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  );
                                }),
                              ),

                              const Spacer(),

                              if (_currentPage > 0) ...[
                                TextButton(
                                  onPressed: _onPrevPressed,
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white70,
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                  ),
                                  child: const Text('Back'),
                                ),
                                const SizedBox(width: 8),
                              ],

                              // Primary CTA button
                              Container(
                                height: 46,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: currentItem.buttonGradient,
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(23),
                                  boxShadow: [
                                    BoxShadow(
                                      color: currentItem.glowColor.withValues(alpha: 0.35),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _onNextPressed,
                                    borderRadius: BorderRadius.circular(23),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 28),
                                      child: Center(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              widget.onFinished == null && _currentPage == _slides.length - 1
                                                  ? 'Finish Tour'
                                                  : currentItem.buttonText,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(CupertinoIcons.arrow_right, size: 16, color: Colors.white),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  // Visual showcase card on the left side of desktop
  Widget _buildShowcaseVisualCard(_OnboardingItem currentItem) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 450),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: currentItem.glowColor.withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Dynamic showcase icon/artwork
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: currentItem.buttonGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: currentItem.glowColor.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              _currentPage == 0
                  ? CupertinoIcons.music_note_2
                  : (_currentPage == 1 ? CupertinoIcons.sparkles : CupertinoIcons.shield_fill),
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),

          // Chips showcase
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _getShowcaseChipsForPage(_currentPage, currentItem.highlightColor),
          ),
        ],
      ),
    );
  }

  List<Widget> _getShowcaseChipsForPage(int page, Color accent) {
    final chipData = switch (page) {
      0 => [
          ('Subsonic', CupertinoIcons.music_note_2),
          ('Navidrome', CupertinoIcons.waveform),
          ('Jellyfin', CupertinoIcons.tv_fill),
          ('FLAC 24-bit', CupertinoIcons.music_mic),
          ('Local Files', CupertinoIcons.folder_fill),
        ],
      1 => [
          ('Daily Mixes', CupertinoIcons.sparkles),
          ('Smart Radar', CupertinoIcons.antenna_radiowaves_left_right),
          ('Made For You', CupertinoIcons.heart_fill),
          ('Auto Scrobbling', CupertinoIcons.chart_bar_alt_fill),
          ('On-Device', CupertinoIcons.device_laptop),
        ],
      _ => [
          ('Zero Telemetry', CupertinoIcons.shield_fill),
          ('Open Source', CupertinoIcons.chevron_left_slash_chevron_right),
          ('Synced Lyrics', CupertinoIcons.text_quote),
          ('Offline Mode', CupertinoIcons.arrow_down_circle_fill),
          ('Discord RPC', CupertinoIcons.chat_bubble_fill),
        ],
    };

    return chipData.map((data) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(data.$2, size: 14, color: accent),
            const SizedBox(width: 6),
            Text(
              data.$1,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildFloatingNavButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  // ── Mobile Layout ──────────────────────────────────────────────────────────

  Widget _buildMobileLayout(BuildContext context, _OnboardingItem currentItem) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        // Top App Branding
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset('assets/logobig.png', fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Musly',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // Swipeable Slides Content
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              final slide = _slides[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),

                    // Headline
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          height: 1.18,
                          letterSpacing: -0.6,
                          color: Colors.white,
                        ),
                        children: [
                          TextSpan(text: slide.titlePrefix),
                          TextSpan(
                            text: slide.titleHighlight,
                            style: TextStyle(
                              color: slide.highlightColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Subtitle
                    Text(
                      slide.description,
                      style: TextStyle(
                        fontSize: 14.5,
                        height: 1.45,
                        color: Colors.white.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ),

        // Bottom Controls (Page Indicators & Action Buttons)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Slide Indicators
              Row(
                children: List.generate(_slides.length, (index) {
                  final isActive = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    margin: const EdgeInsets.only(right: 6),
                    width: isActive ? 26 : 6,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: isActive
                          ? currentItem.highlightColor
                          : Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 28),

              // Primary CTA Button
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: currentItem.buttonGradient,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: currentItem.glowColor.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _onNextPressed,
                    borderRadius: BorderRadius.circular(26),
                    child: Center(
                      child: Text(
                        widget.onFinished == null && _currentPage == _slides.length - 1
                            ? 'Finish Tour'
                            : currentItem.buttonText,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Secondary Action
              Center(
                child: TextButton(
                  onPressed: _completeOnboarding,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white60,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  child: Text(
                    widget.onFinished == null ? 'Close' : 'Skip',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }
}
