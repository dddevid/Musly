import 'dart:math' as math;
import 'package:flutter/material.dart';

class MusicVisualizerView extends StatefulWidget {
  final bool isPlaying;
  final String style;
  final String colorMode;
  final Color accentColor;
  final List<Color> paletteColors;
  final VoidCallback? onTap;
  final ImageProvider? centerImage;

  const MusicVisualizerView({
    super.key,
    required this.isPlaying,
    this.style = 'bars',
    this.colorMode = 'artwork',
    this.accentColor = Colors.deepPurpleAccent,
    this.paletteColors = const [],
    this.onTap,
    this.centerImage,
  });

  @override
  State<MusicVisualizerView> createState() => _MusicVisualizerViewState();
}

class _MusicVisualizerViewState extends State<MusicVisualizerView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(MusicVisualizerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        if (!_controller.isAnimating) _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Color> _resolveColors() {
    if (widget.colorMode == 'rainbow') {
      return const [
        Color(0xFFFF2A6D),
        Color(0xFFFF8A00),
        Color(0xFFFFE600),
        Color(0xFF05FFA1),
        Color(0xFF00E1D9),
        Color(0xFF00B2FE),
        Color(0xFF7B2CBF),
      ];
    } else if (widget.colorMode == 'artwork' && widget.paletteColors.length >= 2) {
      return widget.paletteColors.take(4).toList();
    } else {
      return [
        widget.accentColor,
        widget.accentColor.withValues(alpha: 0.7),
        widget.accentColor.withValues(alpha: 0.4),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _resolveColors();

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.black.withValues(alpha: 0.25),
              boxShadow: [
                BoxShadow(
                  color: (colors.first).withValues(alpha: 0.2),
                  blurRadius: 32,
                  spreadRadius: 2,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _VisualizerPainter(
                    animationValue: _controller.value,
                    isPlaying: widget.isPlaying,
                    style: widget.style,
                    colors: colors,
                  ),
                  child: widget.style == 'circle' && widget.centerImage != null
                      ? Center(
                          child: ClipOval(
                            child: SizedBox(
                              width: 80,
                              height: 80,
                              child: Image(
                                image: widget.centerImage!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        )
                      : null,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _VisualizerPainter extends CustomPainter {
  final double animationValue;
  final bool isPlaying;
  final String style;
  final List<Color> colors;

  static const int _barCount = 28;

  _VisualizerPainter({
    required this.animationValue,
    required this.isPlaying,
    required this.style,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    switch (style) {
      case 'wave':
        _paintWave(canvas, size);
        break;
      case 'circle':
        _paintCircle(canvas, size);
        break;
      case 'bars':
      default:
        _paintBars(canvas, size);
        break;
    }
  }

  void _paintBars(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final barWidth = (w / _barCount) * 0.65;
    final step = w / _barCount;
    final phase = animationValue * 2 * math.pi;

    final paint = Paint()..style = PaintingStyle.fill;
    final capPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: 0.85);

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colors,
    );

    paint.shader = gradient.createShader(Rect.fromLTWH(0, 0, w, h));

    for (int i = 0; i < _barCount; i++) {
      final t = i / _barCount;
      double magnitude = isPlaying
          ? (0.25 +
              0.35 * math.sin(phase * 2.5 + i * 0.42).abs() +
              0.25 * math.cos(phase * 1.8 - i * 0.28).abs() +
              0.15 * math.sin(phase * 4.2 + i * 0.8).abs())
          : 0.08 + 0.04 * math.sin(i * 0.3);

      magnitude = magnitude.clamp(0.06, 0.95);
      final barHeight = magnitude * (h * 0.75);
      final x = (i * step) + (step - barWidth) / 2;
      final y = h * 0.85 - barHeight;

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(rrect, paint);

      if (isPlaying) {
        final capY = (y - 5.0).clamp(10.0, h);
        canvas.drawCircle(Offset(x + barWidth / 2, capY), barWidth * 0.35, capPaint);
      }
    }
  }

  void _paintWave(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final phase = animationValue * 2 * math.pi;

    for (int layer = 0; layer < 3; layer++) {
      final path = Path();
      final fillPath = Path();
      final layerPhase = phase * (1.2 + layer * 0.4) + (layer * math.pi / 3);
      final layerColor = colors[layer % colors.length]
          .withValues(alpha: 0.35 + layer * 0.25);

      final linePaint = Paint()
        ..color = layerColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0 - (layer * 0.5);

      final fillPaint = Paint()
        ..color = layerColor.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill;

      final centerY = h * 0.55 + (layer * 12);
      path.moveTo(0, centerY);
      fillPath.moveTo(0, h);
      fillPath.lineTo(0, centerY);

      final segments = 40;
      for (int i = 0; i <= segments; i++) {
        final x = (i / segments) * w;
        final normX = i / segments;
        final amp = isPlaying
            ? (h * 0.22) *
                math.sin(normX * math.pi) *
                (math.sin(normX * 6 + layerPhase) * 0.6 +
                    math.cos(normX * 10 - layerPhase * 0.8) * 0.4)
            : (h * 0.04) * math.sin(normX * math.pi * 2);
        final y = centerY + amp;
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      fillPath.lineTo(w, h);
      fillPath.close();

      canvas.drawPath(fillPath, fillPaint);
      canvas.drawPath(path, linePaint);
    }
  }

  void _paintCircle(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.24;
    final phase = animationValue * 2 * math.pi;
    const rayCount = 48;
    final angleStep = (2 * math.pi) / rayCount;

    final rayPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = colors.first.withValues(alpha: 0.4);

    canvas.drawCircle(center, baseRadius, ringPaint);

    for (int i = 0; i < rayCount; i++) {
      final angle = i * angleStep;
      final rayColor = colors[i % colors.length];
      rayPaint.color = rayColor;

      double mag = isPlaying
          ? (0.2 +
              0.4 * math.sin(phase * 3 + i * 0.5).abs() +
              0.4 * math.cos(phase * 2 - i * 0.35).abs())
          : 0.1;
      mag = mag.clamp(0.05, 0.95);
      final rayLength = mag * (size.width * 0.18);

      final startX = center.dx + math.cos(angle) * (baseRadius + 4);
      final startY = center.dy + math.sin(angle) * (baseRadius + 4);
      final endX = center.dx + math.cos(angle) * (baseRadius + 4 + rayLength);
      final endY = center.dy + math.sin(angle) * (baseRadius + 4 + rayLength);

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), rayPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _VisualizerPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isPlaying != isPlaying ||
        oldDelegate.style != style ||
        oldDelegate.colors != colors;
  }
}
