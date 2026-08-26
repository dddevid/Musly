import 'package:flutter/material.dart';

class InterludeDotsWidget extends StatefulWidget {
  final Duration currentTime;
  final Duration targetTime;

  const InterludeDotsWidget({
    super.key,
    required this.currentTime,
    required this.targetTime,
  });

  @override
  State<InterludeDotsWidget> createState() => _InterludeDotsWidgetState();
}

class _InterludeDotsWidgetState extends State<InterludeDotsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeLeft = widget.targetTime - widget.currentTime;
    final msLeft = timeLeft.inMilliseconds;

    int visibleDots = 3;
    if (msLeft <= 1000) {
      visibleDots = 0;
    } else if (msLeft <= 2000) {
      visibleDots = 1;
    } else if (msLeft <= 3000) {
      visibleDots = 2;
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      child: visibleDots == 0
          ? const SizedBox(width: double.infinity, height: 0)
          : Container(
              height: 40,
              alignment: Alignment.centerLeft,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (index) {
                      final phase = index * 0.33;
                      final progress = (_pulseController.value + phase) % 1.0;

                      final sineValue =
                          (0.5 - (0.5 * (1.0 - progress * 2.0).abs())) * 2.0;

                      final isVisible = index < visibleDots;

                      final scale = isVisible ? 0.7 + (0.8 * sineValue) : 0.0;
                      final color = Color.lerp(
                        Colors.white.withValues(alpha: 0.3),
                        Colors.white,
                        sineValue,
                      );

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 14.0),
                        width: isVisible ? 10 : 0,
                        height: isVisible ? 10 : 0,
                        child: Transform.scale(
                          scale: scale,
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
    );
  }
}
