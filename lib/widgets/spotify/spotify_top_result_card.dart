import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../album_artwork.dart';

class SpotifyTopResultCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String typeLabel; // e.g. "Song", "Artist", "Album", "Playlist"
  final String? imageUrl;
  final bool isArtist;
  final VoidCallback onTap;
  final VoidCallback onPlayPressed;

  const SpotifyTopResultCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.typeLabel,
    this.imageUrl,
    this.isArtist = false,
    required this.onTap,
    required this.onPlayPressed,
  });

  @override
  State<SpotifyTopResultCard> createState() => _SpotifyTopResultCardState();
}

class _SpotifyTopResultCardState extends State<SpotifyTopResultCard> {
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? (_isHovered ? const Color(0xFF282828) : const Color(0xFF1E1E1E))
                : (_isHovered ? const Color(0xFFF3F4F6) : const Color(0xFFF9FAFB)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Artwork
                  AlbumArtwork(
                    coverArt: widget.imageUrl,
                    size: 72,
                    borderRadius: widget.isArtist ? 999 : 8,
                  ),
                  const SizedBox(height: 14),

                  // Title
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Subtitle & Type Pill
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black45 : Colors.black12,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          widget.typeLabel.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Spotify Circular Green Play Button on Bottom Right
              Positioned(
                bottom: 0,
                right: 0,
                child: AnimatedScale(
                  scale: _isHovered ? 1.08 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1DB954),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 30),
                      onPressed: widget.onPlayPressed,
                    ),
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
