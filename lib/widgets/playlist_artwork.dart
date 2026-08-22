import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../providers/library_provider.dart';
import '../services/playlist_cover_service.dart';
import 'album_artwork.dart';

/// A Spotify-style 1:1 playlist artwork widget that generates a 2x2 dynamic collage
/// from the songs inside the playlist if multiple distinct album covers are present.
class PlaylistArtwork extends StatelessWidget {
  final Playlist? playlist;
  final List<Song>? songs;
  final String? coverArt;
  final double size;
  final double borderRadius;
  final BoxShadow? shadow;

  const PlaylistArtwork({
    super.key,
    this.playlist,
    this.songs,
    this.coverArt,
    this.size = 150,
    this.borderRadius = 12,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    final validSize = size.isFinite && !size.isNaN && size > 0 ? size : 150.0;

    return ValueListenableBuilder<int>(
      valueListenable: PlaylistCoverService().coverUpdates,
      builder: (context, _, __) {
        final playlistId = playlist?.id ?? '';

        // 1. Check if a pre-rendered composite 2x2 image file exists on disk
        if (playlistId.isNotEmpty) {
          final cachedMosaicPath = PlaylistCoverService().getCoverPath(playlistId);
          if (cachedMosaicPath != null) {
            return AlbumArtwork(
              coverArt: cachedMosaicPath,
              size: validSize,
              borderRadius: borderRadius,
              shadow: shadow,
            );
          }
        }

        // Collect songs from parameter, playlist object, or look up in LibraryProvider
        List<Song> allSongs = songs ?? playlist?.songs ?? [];
        if (allSongs.isEmpty && playlist != null) {
          try {
            final lib = Provider.of<LibraryProvider>(context, listen: false);
            final found = lib.playlists.firstWhere(
              (p) => p.id == playlist!.id,
              orElse: () => playlist!,
            );
            if (found.songs != null && found.songs!.isNotEmpty) {
              allSongs = found.songs!;
            }
          } catch (_) {}
        }

        final distinctCovers = <String>[];
        final seen = <String>{};
        for (final s in allSongs) {
          final c = s.coverArt ?? (s.id.isNotEmpty ? s.id : null);
          if (c != null && c.isNotEmpty && !seen.contains(c)) {
            seen.add(c);
            distinctCovers.add(c);
          }
        }

        // 2. Dynamic Spotify-style collage from songs if 2 or more distinct covers exist
        if (distinctCovers.length >= 4) {
          return _build2x2Grid(
            validSize,
            distinctCovers[0],
            distinctCovers[1],
            distinctCovers[2],
            distinctCovers[3],
          );
        } else if (distinctCovers.length == 3) {
          return _build2x2Grid(
            validSize,
            distinctCovers[0],
            distinctCovers[1],
            distinctCovers[2],
            distinctCovers[0],
          );
        } else if (distinctCovers.length == 2) {
          return _build2x2Grid(
            validSize,
            distinctCovers[0],
            distinctCovers[1],
            distinctCovers[1],
            distinctCovers[0],
          );
        } else if (distinctCovers.length == 1) {
          return AlbumArtwork(
            coverArt: distinctCovers.first,
            size: validSize,
            borderRadius: borderRadius,
            shadow: shadow,
          );
        }

        // 3. Fallback to explicit coverArt if non-empty and no song collage
        final explicitArt = coverArt ?? playlist?.coverArt;
        if (explicitArt != null && explicitArt.isNotEmpty) {
          return AlbumArtwork(
            coverArt: explicitArt,
            size: validSize,
            borderRadius: borderRadius,
            shadow: shadow,
          );
        }

        // 4. Fallback placeholder (0 songs / no artwork)
        return Container(
          width: validSize,
          height: validSize,
          decoration: BoxDecoration(
            color: AppTheme.appleMusicRed.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: shadow != null ? [shadow!] : null,
          ),
          child: Center(
            child: Icon(
              CupertinoIcons.music_note_list,
              color: AppTheme.appleMusicRed,
              size: validSize * 0.4,
            ),
          ),
        );
      },
    );
  }

  Widget _build2x2Grid(
    double totalSize,
    String topLeft,
    String topRight,
    String bottomLeft,
    String bottomRight,
  ) {
    final half = totalSize / 2.0;

    return Container(
      width: totalSize,
      height: totalSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadow != null ? [shadow!] : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: AspectRatio(
          aspectRatio: 1.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: AlbumArtwork(
                        coverArt: topLeft,
                        size: half,
                        borderRadius: 0,
                        shadow: const BoxShadow(color: Colors.transparent),
                      ),
                    ),
                    Expanded(
                      child: AlbumArtwork(
                        coverArt: topRight,
                        size: half,
                        borderRadius: 0,
                        shadow: const BoxShadow(color: Colors.transparent),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: AlbumArtwork(
                        coverArt: bottomLeft,
                        size: half,
                        borderRadius: 0,
                        shadow: const BoxShadow(color: Colors.transparent),
                      ),
                    ),
                    Expanded(
                      child: AlbumArtwork(
                        coverArt: bottomRight,
                        size: half,
                        borderRadius: 0,
                        shadow: const BoxShadow(color: Colors.transparent),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
