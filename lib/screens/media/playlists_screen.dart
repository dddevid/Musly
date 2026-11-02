import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:musly/models/models.dart';
import 'package:musly/providers/providers.dart';
import 'package:musly/services/offline_service.dart';
import 'package:musly/theme/app_theme.dart';
import 'package:musly/widgets/widgets.dart';
import 'package:musly/l10n/app_localizations.dart';
import 'package:musly/screens/detail/playlist_screen.dart';
import 'package:musly/utils/navigation_helper.dart';
import 'package:musly/screens/main/main_screen.dart' show MainScreen;

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<LibraryProvider>(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.playlists),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.square_arrow_down),
            tooltip: l10n.importPlaylist,
            onPressed: () => ImportPlaylistDialog.show(context),
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.add),
            tooltip: l10n.newPlaylist,
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
                  Text(l10n.noPlaylists, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    l10n.createPlaylistToGetStarted,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightSecondaryText,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _showCreatePlaylistDialog(context),
                        icon: const Icon(CupertinoIcons.add),
                        label: Text(l10n.newPlaylist),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: ThemeData.estimateBrightnessForColor(
                                      theme.colorScheme.primary) ==
                                  Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => ImportPlaylistDialog.show(context),
                        icon: const Icon(CupertinoIcons.square_arrow_down),
                        label: Text(l10n.importPlaylist),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.only(
                  bottom: MainScreen.scrollEndPadding(context, 150)),
              itemExtent: 72.0,
              itemCount: libraryProvider.playlists.length,
              itemBuilder: (context, index) {
                final playlist = libraryProvider.playlists[index];
                return _PlaylistTile(
                  playlist: playlist,
                  onTap: () => _openPlaylist(context, playlist),
                  onOptions: () => _showPlaylistOptions(context, playlist),
                  onLongPress: () => _showPlaylistOptions(context, playlist),
                );
              },
            ),
    );
  }

  void _openPlaylist(BuildContext context, Playlist playlist) {
    NavigationHelper.push(
      context,
      PlaylistScreen(
        playlistId: playlist.id,
        playlistName: playlist.name,
      ),
    );
  }

  Future<void> _showCreatePlaylistDialog(BuildContext context) async {
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context)!;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.newPlaylist),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.playlistNameHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
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
            child: Text(l10n.create),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  void _showPlaylistOptions(BuildContext context, Playlist playlist) {
    PlaylistOptionsModal.show(context, playlist);
  }
}

class _PlaylistTile extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback? onTap;
  final VoidCallback? onOptions;
  final VoidCallback? onLongPress;

  const _PlaylistTile({
    required this.playlist,
    this.onTap,
    this.onOptions,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: PlaylistArtwork(
        playlist: playlist,
        size: 56,
        borderRadius: 8,
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder<Set<String>>(
            valueListenable: OfflineService().downloadedPlaylistIds,
            builder: (context, downloaded, _) {
              return ValueListenableBuilder<Set<String>>(
                valueListenable: OfflineService().queuedPlaylistIds,
                builder: (context, queued, _) {
                  if (downloaded.contains(playlist.id)) {
                    return const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.check_circle,
                          size: 20, color: Colors.green),
                    );
                  }
                  if (queued.contains(playlist.id)) {
                    return const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.check_circle_outline,
                          size: 20, color: Colors.green),
                    );
                  }
                  return const SizedBox.shrink();
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 20),
            onPressed: onOptions ??
                () => PlaylistOptionsModal.show(context, playlist),
          ),
        ],
      ),
      onTap: onTap,
      onLongPress: onLongPress ??
          () => PlaylistOptionsModal.show(context, playlist),
    );
  }
}
