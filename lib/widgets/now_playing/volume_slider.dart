import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:volume_controller/volume_controller.dart';
import '../../providers/player_provider.dart';

class VolumeSlider extends StatefulWidget {
  const VolumeSlider({super.key});

  @override
  State<VolumeSlider> createState() => _VolumeSliderState();
}

class _VolumeSliderState extends State<VolumeSlider> {
  bool _isDragging = false;
  double _dragValue = 0.0;
  double _systemVolume = 0.0;

  @override
  void initState() {
    super.initState();
    VolumeController.instance.showSystemUI = false;
    VolumeController.instance.getVolume().then((volume) {
      if (mounted) setState(() => _systemVolume = volume);
    });
    VolumeController.instance.addListener((volume) {
      if (mounted && !_isDragging) {
        setState(() => _systemVolume = volume);
      }
    });
  }

  @override
  void dispose() {
    VolumeController.instance.removeListener();
    super.dispose();
  }

  void _onVolumeChanged(double val, PlayerProvider player) {
    if (player.isRemotePlayback) {
      player.setVolume(val);
    } else {
      VolumeController.instance.setVolume(val);
      player.setVolume(val);
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final isRemote = player.isRemotePlayback;
    final baseVolume = isRemote ? player.volume : _systemVolume;
    final currentVolume = _isDragging ? _dragValue : baseVolume;

    return Row(
      children: [
        Icon(
          Icons.volume_mute_rounded,
          color: Colors.white.withValues(alpha: 0.5),
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (details) {
              setState(() {
                _isDragging = true;
                _dragValue = baseVolume;
              });
            },
            onHorizontalDragUpdate: (details) {
              final box = context.findRenderObject() as RenderBox;
              final dx = details.localPosition.dx.clamp(0.0, box.size.width);
              final val = (dx / box.size.width).clamp(0.0, 1.0);
              setState(() {
                _dragValue = val;
              });
              _onVolumeChanged(val, player);
            },
            onHorizontalDragEnd: (details) {
              setState(() => _isDragging = false);
            },
            onTapDown: (details) {
              final box = context.findRenderObject() as RenderBox;
              final dx = details.localPosition.dx.clamp(0.0, box.size.width);
              final val = (dx / box.size.width).clamp(0.0, 1.0);
              setState(() => _dragValue = val);
              _onVolumeChanged(val, player);
            },
            child: Container(
              height: 24,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: CustomPaint(
                size: const Size(double.infinity, 24),
                painter: _VolumeSliderPainter(
                  volume: currentVolume,
                  isDragging: _isDragging,
                  activeColor: Colors.white,
                  inactiveColor: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Icon(
          Icons.volume_up_rounded,
          color: Colors.white.withValues(alpha: 0.5),
          size: 20,
        ),
      ],
    );
  }
}

class _VolumeSliderPainter extends CustomPainter {
  final double volume;
  final bool isDragging;
  final Color activeColor;
  final Color inactiveColor;

  _VolumeSliderPainter({
    required this.volume,
    required this.isDragging,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    paint.color = inactiveColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, (size.height - 4) / 2, size.width, 4),
        const Radius.circular(2),
      ),
      paint,
    );

    paint.color = activeColor;
    final activeWidth = size.width * volume.clamp(0.0, 1.0);
    if (activeWidth > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, (size.height - 4) / 2, activeWidth, 4),
          const Radius.circular(2),
        ),
        paint,
      );
    }

    if (isDragging) {
      paint.color = Colors.white;
      canvas.drawCircle(Offset(activeWidth, size.height / 2), 8, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _VolumeSliderPainter oldDelegate) {
    return oldDelegate.volume != volume ||
        oldDelegate.isDragging != isDragging ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor;
  }
}
