import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';
import 'album_artwork.dart';

class MiniPlayer extends StatelessWidget {
  final VoidCallback? onTap;

  const MiniPlayer({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
    if (isDesktop) return const SizedBox.shrink();

    return Selector<PlayerProvider, Song?>(
      selector: (_, p) => p.currentSong,
      builder: (context, currentSong, _) {
        if (currentSong == null) return const SizedBox.shrink();

        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return RepaintBoundary(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withOpacity(0.95)
                    : Colors.white.withOpacity(0.95),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? AppTheme.darkDivider
                        : AppTheme.lightDivider,
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Selector<PlayerProvider, double>(
                    selector: (_, p) => p.progress,
                    builder: (_, progress, __) => LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.transparent,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.appleMusicRed,
                      ),
                      minHeight: 2,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          AlbumArtwork(
                            coverArt: currentSong.coverArt,
                            size: 44,
                            borderRadius: 6,
                          ),
                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentSong.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (currentSong.artist != null)
                                  Text(
                                    currentSong.artist!,
                                    style: theme.textTheme.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),

                          const _MiniPlayerControls(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MiniPlayerControls extends StatelessWidget {
  const _MiniPlayerControls();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.white : Colors.black;

    return Selector<PlayerProvider, (bool, bool)>(
      selector: (_, p) => (p.isPlaying, p.hasNext),
      builder: (context, data, _) {
        final (isPlaying, hasNext) = data;
        final provider = context.read<PlayerProvider>();

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: provider.togglePlayPause,
              icon: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 32,
              ),
              color: color,
            ),
            IconButton(
              onPressed: hasNext ? provider.skipNext : null,
              icon: const Icon(Icons.skip_next_rounded, size: 28),
              color: color,
            ),
          ],
        );
      },
    );
  }
}
