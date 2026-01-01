import 'package:flutter/material.dart';
import '../models/artist.dart';
import '../theme/app_theme.dart';
import 'album_artwork.dart';

class ArtistCard extends StatelessWidget {
  final Artist artist;
  final double size;
  final VoidCallback? onTap;

  const ArtistCard({
    super.key,
    required this.artist,
    this.size = 140,
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
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: AlbumArtwork(
                  coverArt: artist.coverArt,
                  size: size,
                  borderRadius: size / 2,
                  shadow: const BoxShadow(color: Colors.transparent),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              artist.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            if (artist.albumCount != null)
              Text(
                '${artist.albumCount} albums',
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

class ArtistTile extends StatelessWidget {
  final Artist artist;
  final VoidCallback? onTap;

  const ArtistTile({super.key, required this.artist, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 50,
        height: 50,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: ClipOval(
          child: AlbumArtwork(
            coverArt: artist.coverArt,
            size: 50,
            borderRadius: 25,
            shadow: const BoxShadow(color: Colors.transparent),
          ),
        ),
      ),
      title: Text(
        artist.name,
        style: theme.textTheme.bodyLarge,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppTheme.lightSecondaryText,
      ),
      onTap: onTap,
    );
  }
}