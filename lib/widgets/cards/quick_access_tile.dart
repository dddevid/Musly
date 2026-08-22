import 'package:flutter/material.dart';
import 'package:musly/widgets/common/album_artwork.dart';

class QuickAccessTile extends StatefulWidget {
  final String title;
  final String? imageUrl;
  final Widget? customArtwork;
  final VoidCallback onTap;
  final VoidCallback? onPlayPressed;

  const QuickAccessTile({
    super.key,
    required this.title,
    this.imageUrl,
    this.customArtwork,
    required this.onTap,
    this.onPlayPressed,
  });

  @override
  State<QuickAccessTile> createState() => _QuickAccessTileState();
}

class _QuickAccessTileState extends State<QuickAccessTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: isDark
                ? (_isHovered ? const Color(0xFF383838) : const Color(0xFF282828))
                : (_isHovered ? const Color(0xFFE5E7EB) : const Color(0xFFF3F4F6)),
            borderRadius: BorderRadius.circular(6),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Left Artwork thumbnail
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: widget.customArtwork ??
                      AlbumArtwork(
                        coverArt: widget.imageUrl,
                        size: 56,
                        borderRadius: 0,
                      ),
                ),
              ),

              // Title
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              // Green Play Button on Hover/Tap
              if (_isHovered && widget.onPlayPressed != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1DB954),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 22),
                      onPressed: widget.onPlayPressed,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
