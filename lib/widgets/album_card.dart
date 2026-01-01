import 'package:flutter/material.dart';
import '../models/album.dart';
import '../theme/app_theme.dart';
import 'album_artwork.dart';

class AlbumCard extends StatelessWidget {
  final Album album;
  final double size;
  final VoidCallback? onTap;

  const AlbumCard({
    super.key,
    required this.album,
    this.size = 160,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AlbumArtwork(
              coverArt: album.coverArt,
              size: size,
              borderRadius: 10,
            ),
            const SizedBox(height: 8),
            Text(
              album.name,
              style: theme.textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (album.artist != null)
              Text(
                album.artist!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightSecondaryText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}

class AlbumCardWide extends StatelessWidget {
  final Album album;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const AlbumCardWide({
    super.key,
    required this.album,
    this.width = 300,
    this.height = 200,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AlbumArtwork(
                coverArt: album.coverArt,
                size: width,
                borderRadius: 12,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (album.artist != null)
                    Text(
                      album.artist!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}