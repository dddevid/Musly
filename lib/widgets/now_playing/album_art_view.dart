import 'package:flutter/material.dart';

class AlbumArtView extends StatelessWidget {
  final ImageProvider image;
  final String tag;
  final double borderRadius;

  const AlbumArtView({
    super.key,
    required this.image,
    required this.tag,
    this.borderRadius = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24.0,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Image(
              image: image,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 250,
                height: 250,
                color: Colors.grey[850],
                child: const Icon(Icons.music_note_rounded,
                    size: 64, color: Colors.white54),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
