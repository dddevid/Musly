import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/song.dart';
import '../../models/playlist.dart';
import '../../services/subsonic_service.dart';
import '../../l10n/app_localizations.dart';

class AddToMenu extends StatelessWidget {
  final Song song;
  final ImageProvider? coverProvider;

  const AddToMenu({
    super.key,
    required this.song,
    this.coverProvider,
  });

  @override
  Widget build(BuildContext context) {
    final isStarred = song.starred ?? false;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(bottom: 32, top: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 24),

          // Header (Cover, Title, Artist)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 56,
                    height: 56,
                    color: Colors.grey.withValues(alpha: 0.2),
                    child: coverProvider != null
                        ? Image(image: coverProvider!, fit: BoxFit.cover)
                        : const Icon(Icons.music_note, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song.artist ?? AppLocalizations.of(context)!.unknownArtist,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.black54,
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
          
          const SizedBox(height: 16),
          Divider(color: Colors.grey.withValues(alpha: 0.2)),
          
          // Menu Options
          ListTile(
            leading: const Icon(Icons.playlist_add_rounded),
            title: Text(AppLocalizations.of(context)!.addToPlaylist),
            onTap: () {
              Navigator.of(context).pop();
              _showPlaylistSelector(context, song);
            },
          ),
          ListTile(
            leading: const Icon(Icons.library_add_check_rounded),
            title: Text(AppLocalizations.of(context)!.addToLibrary),
            onTap: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.alreadyInLibrary)),
              );
            },
          ),
          ListTile(
            leading: Icon(isStarred ? Icons.favorite_rounded : Icons.favorite_border_rounded),
            title: Text(isStarred ? AppLocalizations.of(context)!.removeFromFavorites : AppLocalizations.of(context)!.addToFavorites),
            onTap: () async {
              Navigator.of(context).pop();
              final subsonic = Provider.of<SubsonicService>(context, listen: false);
              try {
                if (isStarred) {
                  await subsonic.unstar(id: song.id);
                } else {
                  await subsonic.star(id: song.id);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isStarred ? AppLocalizations.of(context)!.removeFromFavorites : AppLocalizations.of(context)!.addToFavorites)),
                  );
                }
              } catch (e) {
                debugPrint('Error toggling favorite: $e');
              }
            },
          ),
        ],
      ),
    );
  }

  void _showPlaylistSelector(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => _PlaylistSelectionBottomSheet(song: song),
    );
  }
}

class _PlaylistSelectionBottomSheet extends StatefulWidget {
  final Song song;

  const _PlaylistSelectionBottomSheet({required this.song});

  @override
  State<_PlaylistSelectionBottomSheet> createState() => _PlaylistSelectionBottomSheetState();
}

class _PlaylistSelectionBottomSheetState extends State<_PlaylistSelectionBottomSheet> {
  List<Playlist>? _playlists;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    final subsonic = Provider.of<SubsonicService>(context, listen: false);
    try {
      final playlists = await subsonic.getPlaylists();
      if (mounted) {
        setState(() {
          _playlists = playlists;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorLoadingPlaylists(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(bottom: 32, top: 16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.selectPlaylist,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            )
          else if (_playlists == null || _playlists!.isEmpty)
             Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(AppLocalizations.of(context)!.noPlaylists),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _playlists!.length,
                itemBuilder: (context, index) {
                  final playlist = _playlists![index];
                  return ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: playlist.coverArt != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: CachedNetworkImage(
                                imageUrl: Provider.of<SubsonicService>(context, listen: false)
                                    .getCoverArtUrl(playlist.coverArt!, size: 100),
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) => const Icon(Icons.queue_music_rounded, color: Colors.grey),
                              ),
                            )
                          : const Icon(Icons.queue_music_rounded, color: Colors.grey),
                    ),
                    title: Text(playlist.name),
                    subtitle: Text(AppLocalizations.of(context)!.songsCount(playlist.songCount ?? 0)),
                    onTap: () async {
                      Navigator.of(context).pop();
                      final subsonic = Provider.of<SubsonicService>(context, listen: false);
                      try {
                        await subsonic.updatePlaylist(playlistId: playlist.id, songIdsToAdd: [widget.song.id]);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppLocalizations.of(context)!.addedToPlaylist(widget.song.title, playlist.name))),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text(AppLocalizations.of(context)!.errorAddingToPlaylist(e.toString()))),
                          );
                        }
                      }
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
