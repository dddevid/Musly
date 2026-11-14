import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter/cupertino.dart' hide RepeatMode;
import 'package:flutter/services.dart';
import '../../providers/player_provider.dart' show RepeatMode;

class PlaybackControls extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final bool isShuffleEnabled;
  final VoidCallback onShuffleToggle;
  final RepeatMode? repeatMode;
  final bool? isRepeatEnabled;
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
    this.repeatMode,
    this.isRepeatEnabled,
    required this.onRepeatToggle,
    this.accentColor = Colors.white,
  });

  RepeatMode get _effectiveRepeatMode {
    if (repeatMode != null) return repeatMode!;
    if (isRepeatEnabled != null) {
      return isRepeatEnabled! ? RepeatMode.all : RepeatMode.off;
    }
    return RepeatMode.off;
  }

  @override
  Widget build(BuildContext context) {
    final isApple = Theme.of(context).platform == TargetPlatform.iOS ||
        Theme.of(context).platform == TargetPlatform.macOS;
    final mode = _effectiveRepeatMode;
    final isRepeatActive = mode != RepeatMode.off;
    final IconData repeatIcon;
    if (isApple) {
      repeatIcon = mode == RepeatMode.one
          ? CupertinoIcons.repeat_1
          : CupertinoIcons.repeat;
    } else {
      repeatIcon = mode == RepeatMode.one
          ? Icons.repeat_one_rounded
          : Icons.repeat_rounded;
    }

    final themePrimary = Theme.of(context).colorScheme.primary;
    final effectiveActiveColor = (accentColor == Colors.white ||
            accentColor.computeLuminance() > 0.85)
        ? (themePrimary != Colors.white ? themePrimary : const Color(0xFFFA243C))
        : accentColor;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _SecondaryControlButton(
          icon: isApple ? CupertinoIcons.shuffle : Icons.shuffle_rounded,
          isActive: isShuffleEnabled,
          activeColor: effectiveActiveColor,
          onTap: onShuffleToggle,
        ),
        _MainControlButton(
          icon: isApple
              ? CupertinoIcons.backward_fill
              : Icons.skip_previous_rounded,
          size: isApple ? 40 : 48,
          onTap: onPrevious,
        ),
        _PlayPauseButton(
          isPlaying: isPlaying,
          onTap: onPlayPause,
          size: 72,
        ),
        _MainControlButton(
          icon: isApple
              ? CupertinoIcons.forward_fill
              : Icons.skip_next_rounded,
          size: isApple ? 40 : 48,
          onTap: onNext,
        ),
        _SecondaryControlButton(
          icon: repeatIcon,
          isActive: isRepeatActive,
          activeColor: effectiveActiveColor,
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
    final isApple = Theme.of(context).platform == TargetPlatform.iOS ||
        Theme.of(context).platform == TargetPlatform.macOS;

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
        scale: _isPressed ? 0.96 : 1.0,
        duration: Duration(milliseconds: _isPressed ? 140 : 100),
        curve: const Cubic(0.23, 1, 0.32, 1),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            switchInCurve: const Cubic(0.23, 1, 0.32, 1),
            switchOutCurve: const Cubic(0.23, 1, 0.32, 1),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.88, end: 1.0).animate(animation),
                child: child,
              ),
            ),
            child: Icon(
              key: ValueKey<bool>(widget.isPlaying),
              widget.isPlaying
                  ? (isApple
                      ? CupertinoIcons.pause_fill
                      : Icons.pause_rounded)
                  : (isApple
                      ? CupertinoIcons.play_fill
                      : Icons.play_arrow_rounded),
              size: isApple ? widget.size * 0.5 : widget.size * 0.6,
              color: Colors.white,
            ),
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
        scale: _isPressed ? 0.96 : 1.0,
        duration: Duration(milliseconds: _isPressed ? 140 : 100),
        curve: const Cubic(0.23, 1, 0.32, 1),
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
      icon: SizedBox(
        width: 38,
        height: 38,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: const Cubic(0.23, 1, 0.32, 1),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? activeColor.withValues(alpha: 0.16)
                    : Colors.transparent,
              ),
              child: Icon(
                icon,
                color: isActive
                    ? activeColor
                    : Colors.white.withValues(alpha: 0.45),
                size: 24,
              ),
            ),
            Positioned(
              bottom: 2,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: isActive ? 1.0 : 0.0,
                curve: Curves.easeOut,
                child: AnimatedScale(
                  scale: isActive ? 1.0 : 0.4,
                  duration: const Duration(milliseconds: 180),
                  curve: const Cubic(0.23, 1, 0.32, 1),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: activeColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      onPressed: () {
        HapticFeedback.lightImpact();
        onTap();
      },
    );
  }
}
