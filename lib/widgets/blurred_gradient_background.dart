import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class BlurredGradientBackground extends StatefulWidget {
  final List<Color> colors;
  final Widget child;

  const BlurredGradientBackground({
    super.key,
    required this.colors,
    required this.child,
  });

  @override
  State<BlurredGradientBackground> createState() => _BlurredGradientBackgroundState();
}

class _BlurredGradientBackgroundState extends State<BlurredGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
    
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If no colors provided, use a default dark fallback
    final safeColors = widget.colors.isNotEmpty 
      ? widget.colors 
      : [const Color(0xFF1E1E1E), const Color(0xFF2C2C2C), const Color(0xFF1A1A1A)];
      
    // Ensure we have at least 3 colors for the blobs
    while (safeColors.length < 3) {
      safeColors.add(safeColors.last.withOpacity(0.8));
    }

    return Stack(
      children: [
        // Base dark background
        Container(color: Colors.black),
        
        // Animated blobs
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final value = _animation.value;
            return Stack(
              children: [
                // Blob 1 (Top Left moving towards Bottom Right)
                Positioned(
                  top: -100 + (100 * value),
                  left: -100 + (50 * math.sin(value * math.pi)),
                  width: 400,
                  height: 400,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          safeColors[0].withOpacity(0.8),
                          safeColors[0].withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Blob 2 (Bottom Right moving towards Top Left)
                Positioned(
                  bottom: -150 + (100 * (1 - value)),
                  right: -100 + (80 * math.cos(value * math.pi)),
                  width: 500,
                  height: 500,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          safeColors[1].withOpacity(0.8),
                          safeColors[1].withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Blob 3 (Center moving around)
                Positioned(
                  top: MediaQuery.of(context).size.height / 2 - 200 + (150 * math.sin(value * math.pi * 2)),
                  left: MediaQuery.of(context).size.width / 2 - 200 + (100 * math.cos(value * math.pi * 2)),
                  width: 400,
                  height: 400,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          safeColors[2].withOpacity(0.7),
                          safeColors[2].withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        // Dark overlay for text contrast and to blend the colors better
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.35),
          ),
        ),

        // The actual content (Now Playing or Lyrics)
        // Using RepaintBoundary prevents the content from repainting every frame of the background animation
        RepaintBoundary(
          child: widget.child,
        ),
      ],
    );
  }
}
