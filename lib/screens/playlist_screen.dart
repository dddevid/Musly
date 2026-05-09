import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/subsonic_service.dart';
import '../services/offline_service.dart';
import '../services/favorite_playlists_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import '../l10n/app_localizations.dart';
import '../utils/screen_helper.dart';

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
  bool _isSelecting = false;
  bool _isReordering = false;
  final Set<int> _selectedIndices = {};

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
        final updatedSongs = List<Song>.from(_playlist!.songs!)
          ..removeAt(index);
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

  void _toggleSelectMode() {
    setState(() {
      _isSelecting = !_isSelecting;
      _isReordering = false;
      _selectedIndices.clear();
    });
  }

  void _toggleReorderMode() {
    setState(() {
      _isReordering = !_isReordering;
      _isSelecting = false;
      _selectedIndices.clear();
    });
  }

  Future<void> _onSongReordered(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;

    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );

    setState(() {
      final updatedSongs = List<Song>.from(_playlist!.songs!);
      final song = updatedSongs.removeAt(oldIndex);
      updatedSongs.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, song);
      _playlist = _playlist!.copyWith(songs: updatedSongs);
    });

    try {
      await subsonicService.updatePlaylist(
        playlistId: widget.playlistId,
        songIndexesToRemove: [oldIndex],
        songIdsToAdd: [
          _playlist!.songs![newIndex > oldIndex ? newIndex - 1 : newIndex].id,
        ],
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reordering song: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      _loadPlaylist();
    }
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _toggleSelectAll() {
    final songCount = _playlist?.songs?.length ?? 0;
    setState(() {
      if (_selectedIndices.length == songCount) {
        _selectedIndices.clear();
      } else {
        _selectedIndices.addAll(List.generate(songCount, (i) => i));
      }
    });
  }

  Future<void> _removeSelected() async {
    if (_selectedIndices.isEmpty) return;
    final count = _selectedIndices.length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove songs'),
        content: Text(
          'Remove $count ${count == 1 ? 'song' : 'songs'} from this playlist?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );

    // Sort descending so we can remove from end first without shifting indices
    final sortedIndices = _selectedIndices.toList()
      ..sort((a, b) => b.compareTo(a));

    try {
      await subsonicService.updatePlaylist(
        playlistId: widget.playlistId,
        songIndexesToRemove: sortedIndices,
      );
      setState(() {
        final updatedSongs = List<Song>.from(_playlist!.songs!);
        for (final idx in sortedIndices) {
          updatedSongs.removeAt(idx);
        }
        _playlist = _playlist!.copyWith(
          songCount: updatedSongs.length,
          songs: updatedSongs,
        );
        _selectedIndices.clear();
        _isSelecting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$count ${count == 1 ? 'song' : 'songs'} removed from playlist',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing songs: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_playlist == null) return;
    await FavoritePlaylistsService().toggleFavorite(widget.playlistId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            FavoritePlaylistsService().isFavorite(widget.playlistId)
                ? 'Added to favorites'
                : 'Removed from favorites',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
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
            content: Text(
              'Downloaded ${songs.length} songs from ${_playlist!.name}',
            ),
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
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title:
              widget.playlistName != null ? Text(widget.playlistName!) : null,
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

    final isOffline = Provider.of<AuthProvider>(context, listen: false).state ==
        AuthState.offlineMode;

    if (_isReordering) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Reorder Songs'),
          leading: IconButton(
            icon: const Icon(CupertinoIcons.xmark),
            onPressed: _toggleReorderMode,
          ),
          actions: [
            IconButton(
              tooltip: 'Done reordering',
              icon: const Icon(CupertinoIcons.checkmark),
              onPressed: _toggleReorderMode,
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_playlist!.songs?.length ?? 0} songs • ${_playlist!.formattedDuration}',
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _PlayButton(
                          icon: CupertinoIcons.play_fill,
                          label: AppLocalizations.of(context)!.play,
                          onTap: () => _playAll(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PlayButton(
                          icon: CupertinoIcons.shuffle,
                          label: AppLocalizations.of(context)!.shuffle,
                          onTap: () => _playAll(shuffle: true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.only(bottom: 150),
                itemCount: _playlist!.songs!.length,
                buildDefaultDragHandles: false,
                onReorder: _onSongReordered,
                itemBuilder: (context, index) {
                  final song = _playlist!.songs![index];
                  return ListTile(
                    key: ValueKey('reorder_${song.id}_$index'),
                    leading: ReorderableDragStartListener(
                      index: index,
                      child: Icon(
                        CupertinoIcons.line_horizontal_3,
                        color: isDark
                            ? AppTheme.darkSecondaryText
                            : AppTheme.lightSecondaryText,
                      ),
                    ),
                    title: Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      song.artist ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: ScreenHelper.isSmallScreen(context) ? 280 : 360,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.back,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 40,
                      left: ScreenHelper.isSmallScreen(context) ? 24 : 40,
                      right: ScreenHelper.isSmallScreen(context) ? 24 : 40,
                      bottom: ScreenHelper.isSmallScreen(context) ? 60 : 80,
                    ),
                    child: Container(
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
                  ),
                ],
              ),
            ),
            actions: [
              if (_isSelecting) ...[
                IconButton(
                  tooltip:
                      _selectedIndices.length == (_playlist?.songs?.length ?? 0)
                          ? 'Deselect all'
                          : 'Select all',
                  icon: Icon(
                    _selectedIndices.length == (_playlist?.songs?.length ?? 0)
                        ? CupertinoIcons.checkmark_square
                        : CupertinoIcons.square,
                  ),
                  onPressed: _toggleSelectAll,
                ),
                IconButton(
                  tooltip: 'Remove selected',
                  icon: const Icon(CupertinoIcons.trash),
                  color: _selectedIndices.isNotEmpty ? Colors.red : null,
                  onPressed:
                      _selectedIndices.isNotEmpty ? _removeSelected : null,
                ),
              ] else ...[
                AnimatedBuilder(
                  animation: FavoritePlaylistsService(),
                  builder: (context, child) {
                    final isFavorite = FavoritePlaylistsService()
                        .isFavorite(widget.playlistId);
                    return IconButton(
                      tooltip: isFavorite
                          ? 'Remove from favorites'
                          : 'Add to favorites',
                      icon: Icon(
                        isFavorite
                            ? CupertinoIcons.heart_fill
                            : CupertinoIcons.heart,
                        color: isFavorite ? Colors.red : null,
                      ),
                      onPressed: _toggleFavorite,
                    );
                  },
                ),
                IconButton(
                  tooltip: 'Reorder songs',
                  icon: const Icon(CupertinoIcons.arrow_up_arrow_down),
                  onPressed:
                      _playlist!.songs != null && _playlist!.songs!.length > 1
                          ? _toggleReorderMode
                          : null,
                ),
                IconButton(
                  tooltip: 'Select songs',
                  icon: const Icon(CupertinoIcons.checkmark_circle),
                  onPressed: _toggleSelectMode,
                ),
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
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _playlist!.name,
                    style: theme.textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_playlist!.songs?.length ?? 0} songs • ${_playlist!.formattedDuration}',
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _PlayButton(
                          icon: CupertinoIcons.play_fill,
                          label: AppLocalizations.of(context)!.play,
                          onTap: () => _playAll(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PlayButton(
                          icon: CupertinoIcons.shuffle,
                          label: AppLocalizations.of(context)!.shuffle,
                          onTap: () => _playAll(shuffle: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: Divider()),
          if (_playlist!.songs?.isEmpty ?? true)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Text(
                    'No songs in this playlist',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightSecondaryText,
                    ),
                  ),
                ),
              ),
            )
          else if (_isSelecting)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final song = _playlist!.songs![index];
                  final isSelected = _selectedIndices.contains(index);
                  return CheckboxListTile(
                    key: ValueKey('sel_${song.id}_$index'),
                    value: isSelected,
                    onChanged: (_) => _toggleSelection(index),
                    activeColor: AppTheme.appleMusicRed,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: const EdgeInsets.only(
                      left: 4,
                      right: 16,
                    ),
                    title: Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      song.artist ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    secondary: IconButton(
                      icon: const Icon(CupertinoIcons.trash, size: 20),
                      color: Colors.red,
                      tooltip: 'Remove from playlist',
                      onPressed: () async {
                        setState(() => _selectedIndices.remove(index));
                        await _removeSongFromPlaylist(index);
                      },
                    ),
                  );
                },
                childCount: _playlist!.songs!.length,
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final song = _playlist!.songs![index];
                  final tile = SongTile(
                    song: song,
                    playlist: _playlist!.songs,
                    index: index,
                    showArtist: true,
                    onLongPress: () {
                      _toggleSelectMode();
                      _toggleSelection(index);
                    },
                  );
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
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
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
                    child: tile,
                  );
                },
                childCount: _playlist!.songs!.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 150)),
        ],
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PlayButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;

    return Material(
      color: accent.withValues(alpha: isDark ? 0.15 : 0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: accent, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: accent,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
