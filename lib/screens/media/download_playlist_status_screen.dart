import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:musly/providers/library_provider.dart';
import 'package:musly/services/offline_service.dart';
import 'package:musly/theme/app_theme.dart';
import 'package:musly/widgets/widgets.dart';
import 'package:musly/l10n/app_localizations.dart';

class DownloadPlaylistStatusScreen extends StatelessWidget {
  const DownloadPlaylistStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<LibraryProvider>(context);
    final playlists = libraryProvider.playlists;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.playlistDownloads),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ValueListenableBuilder<Set<String>>(
        valueListenable: OfflineService().downloadedSongIds,
        builder: (context, ids, _) {
          if (playlists.isEmpty) {
            return Center(child: Text(l10n.noPlaylistsFound));
          }
          return ListView.builder(
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              final songs = playlist.songs;
              final total = songs?.length ?? playlist.songCount ?? 0;
              final downloaded = songs != null
                  ? songs.where((s) => ids.contains(s.id)).length
                  : 0;
              final allDownloaded = total > 0 && downloaded == total;
              final hasSongs = songs != null;

              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: playlist.coverArt != null
                      ? AlbumArtwork(
                          coverArt: playlist.coverArt,
                          size: 48,
                          borderRadius: 8,
                        )
                      : Icon(
                          CupertinoIcons.music_note_list,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                ),
                title: Text(
                  playlist.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: hasSongs
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$downloaded / $total',
                            style: TextStyle(
                              fontSize: 14,
                              color: allDownloaded
                                  ? Colors.green
                                  : downloaded > 0
                                      ? Colors.orange
                                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                              fontWeight: allDownloaded
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          if (allDownloaded) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 18),
                          ],
                        ],
                      )
                    : Text(
                        '$total songs',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
              );
            },
          );
        },
      ),
    );
  }
}
