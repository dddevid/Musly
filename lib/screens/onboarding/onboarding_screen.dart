import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musly/services/storage_service.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onFinished;

  const OnboardingScreen({super.key, this.onFinished});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
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

  const _OnboardingItem({
    required this.titlePrefix,
    required this.titleHighlight,
    required this.description,
    required this.highlightColor,
    required this.auraColors,
    required this.buttonGradient,
    required this.glowColor,
    required this.buttonText,
  });
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
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
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
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

  void _onNextPressed() {
    if (_currentPage < _slides.length - 1) {
      HapticFeedback.lightImpact();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = _slides[_currentPage];

    return Scaffold(
      backgroundColor: const Color(0xFF090A0E),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          children: [
            // Top Immersive Ambient Aura Gradient that animates with page changes
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.4, -0.65),
                    radius: 1.15,
                    colors: [
                      currentItem.auraColors[1].withValues(alpha: 0.85),
                      currentItem.auraColors[0].withValues(alpha: 0.65),
                      currentItem.auraColors[2].withValues(alpha: 0.35),
                      const Color(0xFF090A0E).withValues(alpha: 0.95),
                      const Color(0xFF090A0E),
                    ],
                    stops: const [0.0, 0.3, 0.55, 0.85, 1.0],
                  ),
                ),
              ),
            ),

            // Subtle secondary ambient glow for depth
            Positioned(
              top: -80,
              left: -60,
              width: 320,
              height: 320,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 450),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: currentItem.auraColors[3].withValues(alpha: 0.18),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                  child: const SizedBox(),
                ),
              ),
            ),

            // Main Content Area
            SafeArea(
              child: Column(
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
                            child: Image.asset(
                              'assets/logobig.png',
                              fit: BoxFit.cover,
                            ),
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

                              // Headline with accent keyword
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
                              widget.onFinished == null
                                  ? 'Close'
                                  : (_currentPage == _slides.length - 1
                                      ? 'Already have an account? Sign in'
                                      : 'Skip'),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
