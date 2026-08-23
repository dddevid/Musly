import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A widget that wraps any song tile to enable a Spotify-style "Swipe to Queue" gesture.
/// Swiping right reveals an animated queue icon and triggers haptic feedback on passing the threshold.
class SwipeableSongTile extends StatefulWidget {
  final Widget child;
  final VoidCallback onSwipeToQueue;
  final bool enabled;

  const SwipeableSongTile({
    super.key,
    required this.child,
    required this.onSwipeToQueue,
    this.enabled = true,
  });

  @override
  State<SwipeableSongTile> createState() => _SwipeableSongTileState();
}

class _SwipeableSongTileState extends State<SwipeableSongTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;
  double _dragOffset = 0.0;
  bool _thresholdReached = false;
  static const double _threshold = 72.0;
  static const double _maxDrag = 110.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    )..addListener(() {
        setState(() {
          _dragOffset = _animation.value;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!widget.enabled) return;

    // Only allow swiping right (positive delta)
    final newOffset = (_dragOffset + details.primaryDelta!).clamp(0.0, _maxDrag);
    if (newOffset != _dragOffset) {
      final wasReached = _thresholdReached;
      final isReached = newOffset >= _threshold;

      if (!wasReached && isReached) {
        HapticFeedback.mediumImpact();
      }

      setState(() {
        _dragOffset = newOffset;
        _thresholdReached = isReached;
      });
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!widget.enabled) return;

    if (_thresholdReached) {
      widget.onSwipeToQueue();
      HapticFeedback.lightImpact();
    }

    _animation = Tween<double>(begin: _dragOffset, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward(from: 0.0);
    _thresholdReached = false;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    final progress = (_dragOffset / _threshold).clamp(0.0, 1.0);
    final iconScale = 0.6 + (0.5 * progress) + (_thresholdReached ? 0.15 : 0.0);
    final iconColor = _thresholdReached ? Colors.white : const Color(0xFF1DB954);
    final bgColor = _thresholdReached
        ? const Color(0xFF1DB954)
        : const Color(0xFF1DB954).withValues(alpha: 0.18);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background swipe indicator
        Positioned.fill(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: _dragOffset > 0 ? _dragOffset : 0,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 18),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: _dragOffset > 15
                  ? Transform.scale(
                      scale: iconScale,
                      child: Icon(
                        CupertinoIcons.text_badge_plus,
                        color: iconColor,
                        size: 22,
                      ),
                    )
                  : null,
            ),
          ),
        ),

        // Foreground Tile
        Transform.translate(
          offset: Offset(_dragOffset, 0),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragUpdate: _onHorizontalDragUpdate,
            onHorizontalDragEnd: _onHorizontalDragEnd,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
