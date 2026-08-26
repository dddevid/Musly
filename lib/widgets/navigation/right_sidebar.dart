import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:musly/models/song.dart';
import 'package:musly/providers/player_provider.dart';
import 'package:musly/theme/app_theme.dart';
import 'package:musly/widgets/common/album_artwork.dart';

import 'package:musly/utils/navigation_helper.dart';
import 'package:musly/l10n/app_localizations.dart';

class RightSidebar extends StatelessWidget {
  final VoidCallback? onClose;

  const RightSidebar({super.key, this.onClose});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackground : Colors.white,
        border: Border(
          left: BorderSide(
            color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
          ),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.queue,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: isDark
                        ? AppTheme.darkSecondaryText
                        : AppTheme.lightSecondaryText,
                  ),
                  onPressed: () {
                    onClose?.call();
                    NavigationHelper.isDesktopQueueOpen.value = false;
                  },
                  tooltip: AppLocalizations.of(context)!.closeQueue,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Consumer<PlayerProvider>(
              builder: (context, player, _) {
                final queue = player.queue;

                if (queue.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.queue_music_rounded,
                          size: 64,
                          color: isDark
                              ? AppTheme.darkTertiaryText
                              : AppTheme.lightSecondaryText,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No songs in queue',
                          style: TextStyle(
                            color: isDark
                                ? AppTheme.darkSecondaryText
                                : AppTheme.lightSecondaryText,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: queue.length,
                  itemBuilder: (context, index) {
                    final song = queue[index];
                    final isPlaying = player.currentIndex == index;

                    return _QueueItem(
                      song: song,
                      isPlaying: isPlaying,
                      onTap: () => player.skipToIndex(index),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueItem extends StatefulWidget {
  final Song song;
  final bool isPlaying;
  final VoidCallback onTap;

  const _QueueItem({
    required this.song,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  State<_QueueItem> createState() => _QueueItemState();
}

class _QueueItemState extends State<_QueueItem> {
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
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: _isHovered
              ? (isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05))
              : Colors.transparent,
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: AlbumArtwork(
                  coverArt: widget.song.coverArt,
                  size: 48,
                  borderRadius: 4,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.song.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: widget.isPlaying
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: widget.isPlaying
                            ? theme.colorScheme.primary
                            : (isDark ? Colors.white : Colors.black),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.song.artist != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.song.artist!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppTheme.darkSecondaryText
                              : AppTheme.lightSecondaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.isPlaying)
                Icon(
                  Icons.volume_up_rounded,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
