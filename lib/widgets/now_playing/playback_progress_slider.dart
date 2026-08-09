import 'package:flutter/material.dart';

class PlaybackProgressSlider extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onChanged;
  final Color accentColor;

  const PlaybackProgressSlider({
    super.key,
    required this.position,
    required this.duration,
    required this.onChanged,
    required this.accentColor,
  });

  @override
  State<PlaybackProgressSlider> createState() => _PlaybackProgressSliderState();
}

class _PlaybackProgressSliderState extends State<PlaybackProgressSlider> {
  bool _isDragging = false;
  double _dragValue = 0.0;

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${duration.inHours}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final maxDuration = widget.duration.inMilliseconds.toDouble();
    final currentDuration = _isDragging 
        ? _dragValue 
        : widget.position.inMilliseconds.toDouble();
        
    final safeMax = maxDuration > 0 ? maxDuration : 1.0;
    final progress = (currentDuration / safeMax).clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (details) {
            setState(() {
              _isDragging = true;
            });
          },
          onHorizontalDragUpdate: (details) {
            final box = context.findRenderObject() as RenderBox;
            final dx = details.localPosition.dx.clamp(0.0, box.size.width);
            setState(() {
              _dragValue = (dx / box.size.width) * safeMax;
            });
          },
          onHorizontalDragEnd: (details) {
            setState(() {
              _isDragging = false;
            });
            widget.onChanged(Duration(milliseconds: _dragValue.toInt()));
          },
          onTapDown: (details) {
            final box = context.findRenderObject() as RenderBox;
            final dx = details.localPosition.dx.clamp(0.0, box.size.width);
            final tapValue = (dx / box.size.width) * safeMax;
            widget.onChanged(Duration(milliseconds: tapValue.toInt()));
          },
          child: Container(
            height: 30, // Tappable area
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: CustomPaint(
              size: const Size(double.infinity, 30),
              painter: _SliderPainter(
                progress: progress,
                isDragging: _isDragging,
                activeColor: widget.accentColor,
                inactiveColor: Colors.white.withOpacity(0.3),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(Duration(milliseconds: currentDuration.toInt())),
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              "-${_formatDuration(widget.duration - Duration(milliseconds: currentDuration.toInt()))}",
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SliderPainter extends CustomPainter {
  final double progress;
  final bool isDragging;
  final Color activeColor;
  final Color inactiveColor;

  _SliderPainter({
    required this.progress,
    required this.isDragging,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final trackHeight = isDragging ? 8.0 : 4.0;
    final trackRadius = Radius.circular(trackHeight / 2);
    
    final centerY = size.height / 2;
    
    // Inactive track
    final inactivePaint = Paint()
      ..color = inactiveColor
      ..style = PaintingStyle.fill;
    
    final inactiveRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, centerY - trackHeight / 2, size.width, trackHeight),
      trackRadius,
    );
    canvas.drawRRect(inactiveRect, inactivePaint);
    
    // Active track
    final activeWidth = size.width * progress;
    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.fill;
      
    final activeRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, centerY - trackHeight / 2, activeWidth, trackHeight),
      trackRadius,
    );
    canvas.drawRRect(activeRect, activePaint);

    // Thumb (only visible when dragging)
    if (isDragging) {
      final thumbRadius = trackHeight + 2;
      final thumbPaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(activeWidth, centerY), thumbRadius, thumbPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SliderPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.isDragging != isDragging ||
           oldDelegate.activeColor != activeColor ||
           oldDelegate.inactiveColor != inactiveColor;
  }
}
