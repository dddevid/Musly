import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/player_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/subsonic_service.dart';
import '../../l10n/app_localizations.dart';
import '../modals/song_options_modal.dart';

class QueueView extends StatelessWidget {
  const QueueView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<PlayerProvider>(
      builder: (context, provider, child) {
        final queue = provider.queue;
        final currentIndex = provider.currentIndex;
        final subsonic = Provider.of<SubsonicService>(context, listen: false);

        if (queue.isEmpty) {
          return Center(
            child: Text(
              l10n.noSongsInQueue,
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
          );
        }

        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;

        return ReorderableListView.builder(
          buildDefaultDragHandles: false,
          padding: EdgeInsets.only(
            top: isLandscape ? 56 : 100,
            bottom: 40,
            left: isLandscape ? 36 : 24,
            right: isLandscape ? 36 : 24,
          ),
          header: Padding(
            padding: const EdgeInsets.only(bottom: 24.0, left: 8.0),
            child: Text(
              l10n.upNext,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          itemCount: queue.length,
          onReorder: (oldIndex, newIndex) {
            provider.reorderQueue(oldIndex, newIndex);
          },
          itemBuilder: (context, index) {
            final song = queue[index];
            final isPlaying = index == currentIndex;
            final isPast = index < currentIndex;

            final coverUrl = song.coverArt != null
                ? subsonic.getCoverArtUrl(song.coverArt, size: 100)
                : null;

            return ListTile(
              key: ValueKey('queue_item_${song.id}_$index'),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: coverUrl != null
                    ? CachedNetworkImage(
                        imageUrl: coverUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: Colors.white10),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.music_note, color: Colors.white54),
                      )
                    : Container(
                        width: 48,
                        height: 48,
                        color: Colors.white10,
                        child: const Icon(Icons.music_note,
                            color: Colors.white54),
                      ),
              ),
              title: Text(
                song.title,
                style: TextStyle(
                  color: isPlaying
                      ? Theme.of(context).colorScheme.primary
                      : (isPast ? Colors.white38 : Colors.white),
                  fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                song.artist ?? l10n.unknownArtist,
                style: TextStyle(
                  color: isPlaying
                      ? Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.8)
                      : (isPast ? Colors.white24 : Colors.white70),
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPlaying)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(
                        Icons.equalizer_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ),
                  IconButton(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: Colors.white70,
                      size: 20,
                    ),
                    splashRadius: 18,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () => SongOptionsModal.show(context, song),
                  ),
                  ReorderableDragStartListener(
                    index: index,
                    child: const Padding(
                      padding: EdgeInsets.only(left: 4, right: 2),
                      child: Icon(
                        Icons.drag_handle_rounded,
                        color: Colors.white38,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
              onTap: () {
                provider.skipToIndex(index);
              },
              onLongPress: () {
                SongOptionsModal.show(context, song);
              },
            );
          },
        );
      },
    );
  }
}
