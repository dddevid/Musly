import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlaybackControls extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final bool isShuffleEnabled;
  final VoidCallback onShuffleToggle;
  final bool isRepeatEnabled;
  final VoidCallback onRepeatToggle;
  final Color accentColor;

  const PlaybackControls({
    super.key,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
    required this.isShuffleEnabled,
    required this.onShuffleToggle,
    required this.isRepeatEnabled,
    required this.onRepeatToggle,
    this.accentColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _SecondaryControlButton(
          icon: Icons.shuffle,
          isActive: isShuffleEnabled,
          activeColor: accentColor,
          onTap: onShuffleToggle,
        ),
        _MainControlButton(
          icon: Icons.skip_previous_rounded,
          size: 48,
          onTap: onPrevious,
        ),
        _PlayPauseButton(
          isPlaying: isPlaying,
          onTap: onPlayPause,
          size: 72,
        ),
        _MainControlButton(
          icon: Icons.skip_next_rounded,
          size: 48,
          onTap: onNext,
        ),
        _SecondaryControlButton(
          icon: Icons.repeat,
          isActive: isRepeatEnabled,
          activeColor: accentColor,
          onTap: onRepeatToggle,
        ),
      ],
    );
  }
}

class _PlayPauseButton extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback onTap;
  final double size;

  const _PlayPauseButton({
    required this.isPlaying,
    required this.onTap,
    this.size = 72,
  });

  @override
  State<_PlayPauseButton> createState() => _PlayPauseButtonState();
}

class _PlayPauseButtonState extends State<_PlayPauseButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.2), // Apple Music uses a slightly translucent white/grey fill
          ),
          child: Icon(
            widget.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: widget.size * 0.6,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _MainControlButton extends StatefulWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;

  const _MainControlButton({
    required this.icon,
    required this.onTap,
    this.size = 48,
  });

  @override
  State<_MainControlButton> createState() => _MainControlButtonState();
}

class _MainControlButtonState extends State<_MainControlButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.85 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Icon(
          widget.icon,
          size: widget.size,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _SecondaryControlButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _SecondaryControlButton({
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            icon,
            color: isActive ? activeColor : Colors.white.withOpacity(0.5),
            size: 24,
          ),
          if (isActive)
            Positioned(
              bottom: -6,
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: activeColor,
                ),
              ),
            ),
        ],
      ),
      onPressed: () {
        HapticFeedback.lightImpact();
        onTap();
      },
    );
  }
}
