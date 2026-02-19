import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'playlist_screen.dart';

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<LibraryProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists'),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.add),
            onPressed: () => _showCreatePlaylistDialog(context),
          ),
        ],
      ),
      body: libraryProvider.playlists.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.music_note_list,
                    size: 64,
                    color: AppTheme.lightSecondaryText,
                  ),
                  const SizedBox(height: 16),
                  Text('No Playlists', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Create a playlist to get started',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightSecondaryText,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showCreatePlaylistDialog(context),
                    icon: const Icon(CupertinoIcons.add),
                    label: const Text('New Playlist'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.appleMusicRed,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 150),
              itemCount: libraryProvider.playlists.length,
              itemBuilder: (context, index) {
                final playlist = libraryProvider.playlists[index];
                return _PlaylistTile(
                  playlist: playlist,
                  onTap: () => _openPlaylist(context, playlist),
                  onLongPress: () => _showPlaylistOptions(context, playlist),
                );
              },
            ),
    );
  }

  void _openPlaylist(BuildContext context, Playlist playlist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistScreen(
          playlistId: playlist.id,
          playlistName: playlist.name,
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Playlist name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final libraryProvider = Provider.of<LibraryProvider>(
                  context,
                  listen: false,
                );
                await libraryProvider.createPlaylist(controller.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showPlaylistOptions(BuildContext context, Playlist playlist) {
    final libraryProvider = Provider.of<LibraryProvider>(
      context,
      listen: false,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(CupertinoIcons.trash, color: Colors.red),
                title: const Text('Delete Playlist'),
                onTap: () async {
                  Navigator.pop(context);
                  await libraryProvider.deletePlaylist(playlist.id);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaylistTile extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _PlaylistTile({required this.playlist, this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppTheme.appleMusicRed.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: playlist.coverArt != null
            ? AlbumArtwork(
                coverArt: playlist.coverArt,
                size: 56,
                borderRadius: 8,
              )
            : const Icon(
                CupertinoIcons.music_note_list,
                color: AppTheme.appleMusicRed,
                size: 28,
              ),
      ),
      title: Text(
        playlist.name,
        style: theme.textTheme.bodyLarge,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${playlist.songCount ?? 0} songs',
        style: theme.textTheme.bodySmall,
      ),
      trailing: const Icon(
        CupertinoIcons.chevron_right,
        size: 18,
        color: AppTheme.lightSecondaryText,
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
