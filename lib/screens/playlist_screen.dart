import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/subsonic_service.dart';
import '../services/offline_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class PlaylistScreen extends StatefulWidget {
  final String playlistId;
  final String? playlistName;

  const PlaylistScreen({
    super.key,
    required this.playlistId,
    this.playlistName,
  });

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  Playlist? _playlist;
  bool _isLoading = true;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _loadPlaylist();
  }

  Future<void> _loadPlaylist() async {
    final libraryProvider = Provider.of<LibraryProvider>(
      context,
      listen: false,
    );

    try {
      final playlist = await libraryProvider.getPlaylist(widget.playlistId);
      if (mounted) {
        setState(() {
          _playlist = playlist;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _playAll({bool shuffle = false}) {
    if (_playlist?.songs == null || _playlist!.songs!.isEmpty) return;

    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);

    var songs = List.from(_playlist!.songs!);
    if (shuffle) {
      songs.shuffle();
    }

    playerProvider.playSong(songs.first, playlist: songs.cast(), startIndex: 0);
  }

  Future<void> _removeSongFromPlaylist(int index) async {
    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );
    try {
      await subsonicService.updatePlaylist(
        playlistId: widget.playlistId,
        songIndexesToRemove: [index],
      );
      setState(() {
        final updatedSongs = List<Song>.from(_playlist!.songs!)..removeAt(index);
        _playlist = _playlist!.copyWith(
          songCount: updatedSongs.length,
          songs: updatedSongs,
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Song removed from playlist'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing song: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _downloadPlaylist() async {
    final songs = _playlist?.songs;
    if (songs == null || songs.isEmpty) return;

    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );
    final offlineService = OfflineService();
    await offlineService.initialize();

    setState(() => _isDownloading = true);

    offlineService.startBackgroundDownload(songs, subsonicService).then((_) {
      if (mounted) {
        setState(() => _isDownloading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded ${songs.length} songs from ${_playlist!.name}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloading ${songs.length} songs in background…'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: widget.playlistName != null
              ? Text(widget.playlistName!)
              : null,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_playlist == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Playlist not found')),
      );
    }

    final isOffline =
        Provider.of<AuthProvider>(context, listen: false).state ==
        AuthState.offlineMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(_playlist!.name),
        actions: [
          if (!isOffline)
            
            IconButton(
              tooltip: 'Download playlist',
              onPressed: _isDownloading ? null : _downloadPlaylist,
              icon: _isDownloading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(CupertinoIcons.cloud_download),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: AppTheme.appleMusicRed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _playlist!.coverArt != null
                      ? AlbumArtwork(
                          coverArt: _playlist!.coverArt,
                          size: 150,
                          borderRadius: 12,
                        )
                      : const Icon(
                          CupertinoIcons.music_note_list,
                          color: AppTheme.appleMusicRed,
                          size: 64,
                        ),
                ),
                const SizedBox(height: 16),
                Text(
                  _playlist!.name,
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${_playlist!.songs?.length ?? 0} songs • ${_playlist!.formattedDuration}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _playAll(),
                        icon: const Icon(CupertinoIcons.play_fill),
                        label: const Text('Play'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.appleMusicRed,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _playAll(shuffle: true),
                        icon: const Icon(CupertinoIcons.shuffle),
                        label: const Text('Shuffle'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.appleMusicRed,
                          side: const BorderSide(color: AppTheme.appleMusicRed),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),

          Expanded(
            child: _playlist!.songs?.isEmpty ?? true
                ? Center(
                    child: Text(
                      'No songs in this playlist',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightSecondaryText,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 150),
                    itemCount: _playlist!.songs!.length,
                    itemBuilder: (context, index) {
                      final song = _playlist!.songs![index];
                      
                      return Dismissible(
                        key: ValueKey('${song.id}_$index'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Icon(
                            CupertinoIcons.trash,
                            color: Colors.white,
                          ),
                        ),
                        confirmDismiss: (_) async {
                          return await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Remove from playlist'),
                                  content: Text(
                                    'Remove "${song.title}" from this playlist?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, true),
                                      child: const Text(
                                        'Remove',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ) ??
                              false;
                        },
                        onDismissed: (_) => _removeSongFromPlaylist(index),
                        child: SongTile(
                          song: song,
                          playlist: _playlist!.songs,
                          index: index,
                          showArtist: true,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
