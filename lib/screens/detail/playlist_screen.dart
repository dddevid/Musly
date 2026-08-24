import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:musly/models/models.dart';
import 'package:musly/providers/providers.dart';
import 'package:musly/services/subsonic_service.dart';
import 'package:musly/services/offline_service.dart';
import 'package:musly/services/favorite_playlists_service.dart';
import 'package:musly/services/playlist_cover_service.dart';
import 'package:musly/theme/app_theme.dart';
import 'package:musly/widgets/widgets.dart';
import 'package:musly/l10n/app_localizations.dart';
import 'package:musly/utils/screen_helper.dart';

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
  bool _isSelecting = false;
  bool _isReordering = false;
  bool _showSearch = false;
  String _searchQuery = '';
  final Set<int> _selectedIndices = {};

  bool _allDownloaded = false;
  bool _isQueued = false;

  @override
  void initState() {
    super.initState();
    _loadPlaylist();
    OfflineService().downloadedPlaylistIds.addListener(_updateDownloadState);
    OfflineService().queuedPlaylistIds.addListener(_updateDownloadState);
  }

  @override
  void dispose() {
    OfflineService().downloadedPlaylistIds.removeListener(_updateDownloadState);
    OfflineService().queuedPlaylistIds.removeListener(_updateDownloadState);
    super.dispose();
  }

  void _updateDownloadState() {
    if (!mounted) return;
    final offline = OfflineService();
    final allDown = offline.downloadedPlaylistIds.value.contains(widget.playlistId);
    final queued = offline.queuedPlaylistIds.value.contains(widget.playlistId);
    if (allDown != _allDownloaded || queued != _isQueued) {
      setState(() {
        _allDownloaded = allDown;
        _isQueued = queued;
      });
    }
  }

  Future<void> _loadPlaylist() async {
    final libraryProvider = Provider.of<LibraryProvider>(
      context,
      listen: false,
    );
    final subsonicService = Provider.of<SubsonicService>(
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
        _updateDownloadState();
      }
      if (playlist.songs != null && playlist.songs!.isNotEmpty) {
        PlaylistCoverService().checkAndGenerateCover(
          playlistId: widget.playlistId,
          songs: playlist.songs!,
          subsonicService: subsonicService,
        );
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
      final updatedSongs = List<Song>.from(_playlist!.songs!)
        ..removeAt(index);
      await subsonicService.updatePlaylist(
        playlistId: widget.playlistId,
        songIndexesToRemove: [index],
      );
      setState(() {
        _playlist = _playlist!.copyWith(
          songCount: updatedSongs.length,
          songs: updatedSongs,
        );
      });
      PlaylistCoverService().checkAndGenerateCover(
        playlistId: widget.playlistId,
        songs: updatedSongs,
        subsonicService: subsonicService,
      );
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

  Future<void> _onSongReorderedItem(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;

    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );

    final updatedSongs = List<Song>.from(_playlist!.songs!);
    final song = updatedSongs.removeAt(oldIndex);
    updatedSongs.insert(newIndex, song);

    setState(() {
      _playlist = _playlist!.copyWith(songs: updatedSongs);
    });

    PlaylistCoverService().checkAndGenerateCover(
      playlistId: widget.playlistId,
      songs: updatedSongs,
      subsonicService: subsonicService,
    );

    try {
      await subsonicService.updatePlaylist(
        playlistId: widget.playlistId,
        songIndexesToRemove: [oldIndex],
        songIdsToAdd: [
          _playlist!.songs![newIndex].id,
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
    final offlineService = OfflineService();
    final subsonicService = Provider.of<SubsonicService>(context, listen: false);
    await offlineService.initialize();
    offlineService.queuePlaylistDownload(widget.playlistId, songs, subsonicService);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Queued ${songs.length} songs for download…'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _cancelDownload() async {
    await OfflineService().cancelPlaylistDownload(widget.playlistId);
  }

  Future<void> _removeDownloads() async {
    final songs = _playlist?.songs ?? [];
    if (songs.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove downloads?'),
        content: Text('Remove all ${songs.length} downloaded songs from "${_playlist!.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await OfflineService().cancelPlaylistDownload(widget.playlistId);
      await OfflineService().deletePlaylistDownloads(songs);
    }
  }

  Widget _buildDownloadButton(BuildContext context) {
    if (_allDownloaded) {
      return IconButton(
        tooltip: 'Downloaded — tap to remove',
        onPressed: _removeDownloads,
        icon: const Icon(Icons.cloud_done, color: Colors.green),
      );
    }
    if (_isQueued) {
      return IconButton(
        tooltip: 'Downloading — tap to cancel',
        onPressed: _cancelDownload,
        icon: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return IconButton(
      tooltip: 'Download playlist',
      onPressed: _downloadPlaylist,
      icon: const Icon(CupertinoIcons.cloud_download),
    );
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
                  ValueListenableBuilder<Set<String>>(
                    valueListenable: OfflineService().downloadedPlaylistIds,
                    builder: (context, downloaded, _) {
                      final allDownloaded = downloaded.contains(widget.playlistId);
                      return Stack(
                        children: [
                          PlaylistArtwork(
                            playlist: _playlist,
                            songs: _playlist?.songs,
                            size: 150,
                            borderRadius: 12,
                          ),
                          if (allDownloaded)
                            Positioned(
                              bottom: 6,
                              right: 6,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 24,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
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
                onReorderItem: _onSongReorderedItem,
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
              collapseMode: CollapseMode.pin,
              background: LayoutBuilder(
                builder: (context, constraints) {
                  final topPadding = MediaQuery.of(context).padding.top;
                  final isSmall = ScreenHelper.isSmallScreen(context);
                  final minHeight = kToolbarHeight + topPadding;
                  final maxHeight = isSmall ? 280.0 : 360.0;
                  final currentHeight = constraints.maxHeight;
                  final delta = (maxHeight - minHeight).clamp(1.0, 999.0);
                  final progress = ((currentHeight - minHeight) / delta).clamp(0.0, 1.0);

                  final maxArtSize = isSmall ? 190.0 : 240.0;
                  final availableHeight = (currentHeight - topPadding - (isSmall ? 16.0 : 24.0)).clamp(0.0, maxHeight);
                  final artDimension = (maxArtSize * progress).clamp(0.0, availableHeight);
                  final opacity = (progress * 1.3 - 0.1).clamp(0.0, 1.0);

                  if (artDimension <= 10.0 || opacity <= 0.0) {
                    return const SizedBox.shrink();
                  }

                  return Center(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: topPadding + (isSmall ? 8.0 : 12.0) * progress,
                        bottom: (isSmall ? 10.0 : 16.0) * progress,
                      ),
                      child: Opacity(
                        opacity: opacity,
                        child: SizedBox.square(
                          dimension: artDimension,
                          child: PlaylistArtwork(
                            playlist: _playlist,
                            songs: _playlist?.songs,
                            size: artDimension,
                            borderRadius: (14.0 * progress).clamp(4.0, 14.0),
                            shadow: progress > 0.3
                                ? BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: (isDark ? 0.35 : 0.2) * progress,
                                    ),
                                    blurRadius: 16.0 * progress,
                                    offset: Offset(0, 8.0 * progress),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  );
                },
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
                IconButton(
                  tooltip: 'Cerca nella playlist',
                  icon: Icon(_showSearch ? CupertinoIcons.search_circle_fill : CupertinoIcons.search),
                  onPressed: () {
                    setState(() {
                      _showSearch = !_showSearch;
                      if (!_showSearch) _searchQuery = '';
                    });
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(CupertinoIcons.ellipsis_circle),
                  tooltip: 'Altro',
                  onSelected: (value) {
                    if (value == 'queue_all') {
                      final songs = _playlist?.songs ?? [];
                      final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
                      for (final s in songs) {
                        playerProvider.addToQueue(s);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${songs.length} brani aggiunti alla coda')),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'queue_all',
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.text_badge_plus, size: 18),
                          SizedBox(width: 12),
                          Text('Aggiungi tutti alla coda'),
                        ],
                      ),
                    ),
                  ],
                ),
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
                if (!isOffline) _buildDownloadButton(context),
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
                  if (_showSearch) ...[
                    const SizedBox(height: 16),
                    CupertinoSearchTextField(
                      placeholder: 'Filtra brani...',
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim().toLowerCase();
                        });
                      },
                    ),
                  ],
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
                    activeColor: AppTheme.brandRed,
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
            Builder(
              builder: (context) {
                final allSongs = _playlist!.songs!;
                final displaySongs = _searchQuery.isEmpty
                    ? allSongs
                    : allSongs.where((s) => s.title.toLowerCase().contains(_searchQuery) || (s.artist?.toLowerCase().contains(_searchQuery) ?? false)).toList();

                return SliverFixedExtentList(
                  itemExtent: 68.0,
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final song = displaySongs[index];
                      final tile = SongTile(
                        song: song,
                        playlist: displaySongs,
                        index: index,
                        showArtist: true,
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
                        onDismissed: (_) {
                          final originalIndex = _playlist!.songs!.indexOf(song);
                          if (originalIndex != -1) {
                            _removeSongFromPlaylist(originalIndex);
                          }
                        },
                        child: tile,
                      );
                    },
                    childCount: displaySongs.length,
                  ),
                );
              },
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
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: accent, size: 20),
              const SizedBox(width: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: accent,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
