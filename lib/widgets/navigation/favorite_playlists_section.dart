import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:musly/models/playlist.dart';
import 'package:musly/providers/library_provider.dart';
import 'package:musly/screens/detail/playlist_screen.dart';
import 'package:musly/services/favorite_playlists_service.dart';
import 'package:musly/services/offline_service.dart';
import 'package:musly/theme/app_theme.dart';
import 'package:musly/l10n/app_localizations.dart';
import 'package:musly/widgets/common/playlist_artwork.dart';

class FavoritePlaylistsSection extends StatelessWidget {
  const FavoritePlaylistsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return AnimatedBuilder(
      animation: FavoritePlaylistsService(),
      builder: (context, child) {
        final favoriteIds = FavoritePlaylistsService().getFavoriteIds();

        if (favoriteIds.isEmpty) {
          return const SizedBox.shrink();
        }

        return Consumer<LibraryProvider>(
          builder: (context, libraryProvider, child) {
            final offlineService = OfflineService();
            final isOffline = offlineService.isOfflineMode;
            final downloadedPlaylistIds =
                offlineService.downloadedPlaylistIds.value.toSet();

            var favoritePlaylists = libraryProvider.playlists
                .where((p) => favoriteIds.contains(p.id))
                .toList();

            if (isOffline) {
              favoritePlaylists = favoritePlaylists
                  .where((p) => downloadedPlaylistIds.contains(p.id))
                  .toList();
            }

            if (favoritePlaylists.isEmpty) {
              return const SizedBox.shrink();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n?.favoritePlaylists ?? 'Favorite Playlists',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (favoritePlaylists.length > 5)
                        TextButton(
                          onPressed: () {},
                          child: Text(l10n?.seeAll ?? 'See All'),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: favoritePlaylists.length,
                    itemBuilder: (context, index) {
                      final playlist = favoritePlaylists[index];
                      return _PlaylistCard(
                        playlist: playlist,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlaylistScreen(
                                playlistId: playlist.id,
                                playlistName: playlist.name,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onTap;

  const _PlaylistCard({
    required this.playlist,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                PlaylistArtwork(
                  playlist: playlist,
                  size: 140,
                  borderRadius: 8,
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      CupertinoIcons.heart_fill,
                      size: 14,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              playlist.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (playlist.songCount != null)
              Text(
                '${playlist.songCount} ${playlist.songCount == 1 ? 'song' : 'songs'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppTheme.darkSecondaryText
                      : AppTheme.lightSecondaryText,
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
