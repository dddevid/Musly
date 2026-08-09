import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/player_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/subsonic_service.dart';

class QueueView extends StatelessWidget {
  const QueueView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, provider, child) {
        final queue = provider.queue;
        final currentIndex = provider.currentIndex;
        final subsonic = Provider.of<SubsonicService>(context, listen: false);

        if (queue.isEmpty) {
          return const Center(
            child: Text(
              "Nessun brano in coda",
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 100, bottom: 40, left: 24, right: 24),
          itemCount: queue.length + 1, // +1 for the "Up Next" header
          itemBuilder: (context, index) {
            if (index == 0) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 24.0, left: 8.0),
                child: Text(
                  "Up Next",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }

            final songIndex = index - 1;
            final song = queue[songIndex];
            final isPlaying = songIndex == currentIndex;
            final isPast = songIndex < currentIndex;

            final coverUrl = song.coverArt != null 
                ? subsonic.getCoverArtUrl(song.coverArt, size: 100)
                : null;

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: coverUrl != null 
                    ? CachedNetworkImage(
                        imageUrl: coverUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: Colors.white10),
                        errorWidget: (context, url, error) => const Icon(Icons.music_note, color: Colors.white54),
                      )
                    : Container(
                        width: 48,
                        height: 48,
                        color: Colors.white10,
                        child: const Icon(Icons.music_note, color: Colors.white54),
                      ),
              ),
              title: Text(
                song.title ?? 'Sconosciuto',
                style: TextStyle(
                  color: isPlaying ? Theme.of(context).colorScheme.primary : (isPast ? Colors.white38 : Colors.white),
                  fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                song.artist ?? 'Artista Sconosciuto',
                style: TextStyle(
                  color: isPlaying ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.8) : (isPast ? Colors.white24 : Colors.white70),
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: isPlaying
                  ? Icon(Icons.equalizer_rounded, color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () {
                provider.skipToIndex(songIndex);
              },
            );
          },
        );
      },
    );
  }
}
