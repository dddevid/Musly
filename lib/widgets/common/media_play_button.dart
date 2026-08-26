import 'package:flutter/material.dart';

/// Standard primary action button (e.g. Play, Shuffle) for detail headers across Musly.
class MediaPlayButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const MediaPlayButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.backgroundColor,
    this.foregroundColor,
    this.fontSize = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? Theme.of(context).colorScheme.primary;
    final fg = foregroundColor ??
        (ThemeData.estimateBrightnessForColor(bg) == Brightness.dark
            ? Colors.white
            : Colors.black);

    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: fg, size: 22),
      label: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        padding: padding,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}

/// Circular floating play button with hover scaling and shadow, used on cards and artworks.
class MediaFloatingPlayButton extends StatefulWidget {
  final VoidCallback onPressed;
  final double size;
  final double iconSize;
  final Color? backgroundColor;
  final Color? iconColor;
  final IconData icon;

  const MediaFloatingPlayButton({
    super.key,
    required this.onPressed,
    this.size = 48,
    this.iconSize = 24,
    this.backgroundColor,
    this.iconColor,
    this.icon = Icons.play_arrow_rounded,
  });

  @override
  State<MediaFloatingPlayButton> createState() => _MediaFloatingPlayButtonState();
}

class _MediaFloatingPlayButtonState extends State<MediaFloatingPlayButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.backgroundColor ?? Theme.of(context).colorScheme.primary;
    final iconCol = widget.iconColor ??
        (ThemeData.estimateBrightnessForColor(bg) == Brightness.dark
            ? Colors.white
            : Colors.black);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bg,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isHovered ? 0.4 : 0.25),
                blurRadius: _isHovered ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(widget.icon, color: iconCol, size: widget.iconSize),
            onPressed: widget.onPressed,
            splashRadius: widget.size / 2,
          ),
        ),
      ),
    );
  }
}
