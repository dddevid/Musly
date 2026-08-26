import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BrowseCategoryCard extends StatefulWidget {
  final String title;
  final List<Color> gradientColors;
  final IconData? icon;
  final String? imageUrl;
  final VoidCallback onTap;

  const BrowseCategoryCard({
    super.key,
    required this.title,
    required this.gradientColors,
    this.icon,
    this.imageUrl,
    required this.onTap,
  });

  @override
  State<BrowseCategoryCard> createState() => _BrowseCategoryCardState();
}

class _BrowseCategoryCardState extends State<BrowseCategoryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: widget.gradientColors.first.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  Positioned(
                    top: 14,
                    left: 14,
                    right: 48,
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Positioned(
                    right: -10,
                    bottom: -6,
                    child: Transform.rotate(
                      angle: 0.42,
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black38,
                              blurRadius: 10,
                              offset: Offset(2, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: widget.imageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: widget.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) =>
                                      _buildFallbackIcon(),
                                )
                              : _buildFallbackIcon(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      color: Colors.black26,
      child: Center(
        child: Icon(
          widget.icon ?? Icons.music_note,
          color: Colors.white.withValues(alpha: 0.9),
          size: 32,
        ),
      ),
    );
  }
}
