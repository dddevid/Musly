import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../cast_button.dart';

class NowPlayingBottomActions extends StatelessWidget {
  final VoidCallback onLyricsTap;
  final VoidCallback onQueueTap;
  final bool isLyricsActive;
  final bool isQueueActive;
  final Color accentColor;

  const NowPlayingBottomActions({
    super.key,
    required this.onLyricsTap,
    required this.onQueueTap,
    this.isLyricsActive = false,
    this.isQueueActive = false,
    this.accentColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          CastButton(
            iconSize: 24,
            iconColor: Colors.white.withOpacity(0.5),
          ),
          _ActionButton(
            icon: Icons.chat_bubble_outline_rounded,
            isActive: isLyricsActive,
            activeColor: accentColor,
            onTap: onLyricsTap,
          ),
          _ActionButton(
            icon: Icons.queue_music_rounded,
            isActive: isQueueActive,
            activeColor: accentColor,
            onTap: onQueueTap,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  final Color activeColor;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    this.isActive = false,
    this.activeColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Icon(
          icon,
          color: isActive ? activeColor : Colors.white.withOpacity(0.5),
          size: 24,
        ),
      ),
      onPressed: () {
        HapticFeedback.lightImpact();
        onTap();
      },
    );
  }
}
