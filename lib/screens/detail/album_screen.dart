import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:musly/models/models.dart';
import 'package:musly/providers/providers.dart';
import 'package:musly/services/subsonic_service.dart';
import 'package:musly/theme/app_theme.dart';
import 'package:musly/widgets/widgets.dart';
import 'package:musly/l10n/app_localizations.dart';
import 'package:musly/utils/screen_helper.dart';
import 'package:musly/services/offline_service.dart';

class AlbumScreen extends StatefulWidget {
  final String albumId;

  const AlbumScreen({super.key, required this.albumId});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  Album? _album;
  List<Song> _songs = [];
  bool _isLoading = true;
  bool _showSearch = false;
  String _searchQuery = '';

  bool _allDownloaded = false;
  bool _isQueued = false;

  @override
  void initState() {
    super.initState();
    _loadAlbum();
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
    if (!mounted || _album == null) return;
    final offline = OfflineService();
    final allDown = offline.downloadedPlaylistIds.value.contains(_album!.id);
    final queued = offline.queuedPlaylistIds.value.contains(_album!.id);
    if (allDown != _allDownloaded || queued != _isQueued) {
      setState(() {
        _allDownloaded = allDown;
        _isQueued = queued;
      });
    }
  }

  Future<void> _loadAlbum() async {
    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );
    final libraryProvider = Provider.of<LibraryProvider>(
      context,
      listen: false,
    );

    try {
      Album? album;

      if (libraryProvider.isLocalOnlyMode) {
        album = libraryProvider.cachedAllAlbums.firstWhere(
          (a) => a.id == widget.albumId,
          orElse: () => Album(id: widget.albumId, name: 'Unknown Album'),
        );
      } else {
        album = await subsonicService.getAlbum(widget.albumId);
      }

      final songs = await libraryProvider.getAlbumSongs(widget.albumId);

      if (mounted) {
        setState(() {
          _album = album;
          _songs = songs;
          _isLoading = false;
        });
        _updateDownloadState();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _playAll({bool shuffle = false}) {
    if (_songs.isEmpty) return;

    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);

    List<Song> playlist = List.from(_songs);
    if (shuffle) {
      playlist.shuffle();
    }

    playerProvider.playSong(playlist.first, playlist: playlist, startIndex: 0);
  }

  Future<void> _downloadAlbum() async {
    if (_songs.isEmpty || _album == null) return;
    final offlineService = OfflineService();
    final subsonicService = Provider.of<SubsonicService>(context, listen: false);
    await offlineService.initialize();
    offlineService.queuePlaylistDownload(_album!.id, _songs, subsonicService);
    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.queuedSongsForDownload(_songs.length)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _cancelDownload() async {
    if (_album == null) return;
    await OfflineService().cancelPlaylistDownload(_album!.id);
  }

  Future<void> _removeDownloads() async {
    if (_songs.isEmpty || _album == null) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.removeDownloadsTitle),
        content: Text(l10n.removeAlbumDownloadsConfirm(_songs.length, _album!.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.remove, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await OfflineService().cancelPlaylistDownload(_album!.id);
      await OfflineService().deletePlaylistDownloads(_songs);
    }
  }

  Widget _buildDownloadButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_allDownloaded) {
      return IconButton(
        tooltip: l10n.downloadedTapToRemove,
        onPressed: _removeDownloads,
        icon: const Icon(Icons.cloud_done, color: Colors.green),
      );
    }
    if (_isQueued) {
      return IconButton(
        tooltip: l10n.downloadingTapToCancel,
        onPressed: _cancelDownload,
        icon: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return IconButton(
      tooltip: l10n.downloadAlbum,
      onPressed: _downloadAlbum,
      icon: const Icon(CupertinoIcons.cloud_download),
    );
  }

  Future<void> _toggleLike() async {
    if (_album == null) return;
    
    final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
    final isStarred = _album!.starred == true;
    
    setState(() {
      _album!.starred = !isStarred;
    });

    try {
      if (isStarred) {
        await libraryProvider.unstar(albumId: _album!.id);
      } else {
        await libraryProvider.star(albumId: _album!.id);
      }
    } catch (e) {
      // Revert on failure
      setState(() {
        _album!.starred = isStarred;
      });
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToUpdateFavorite)),
        );
      }
    }
  }

  Widget _buildLikeButton(BuildContext context) {
    if (_album == null) return const SizedBox.shrink();
    final isStarred = _album!.starred == true;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final l10n = AppLocalizations.of(context)!;
    
    return IconButton(
      tooltip: isStarred ? l10n.removeFromFavorites : l10n.addToFavorites,
      onPressed: _toggleLike,
      icon: Icon(
        isStarred ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
        color: isStarred ? primaryColor : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const AlbumArtworkShimmer(size: 250),
                    const SizedBox(height: 24),
                    Shimmer.fromColors(
                      baseColor:
                          isDark ? AppTheme.darkCard : const Color(0xFFE0E0E0),
                      highlightColor: isDark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFF5F5F5),
                      child: Container(
                        width: 200,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Shimmer.fromColors(
                      baseColor:
                          isDark ? AppTheme.darkCard : const Color(0xFFE0E0E0),
                      highlightColor: isDark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFF5F5F5),
                      child: Container(
                        width: 150,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => const SongTileShimmer(),
                childCount: 10,
              ),
            ),
          ],
        ),
      );
    }

    if (_album == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(AppLocalizations.of(context)!.albumNotFound)),
      );
    }

    final totalDuration = _songs.fold<int>(
      0,
      (sum, song) => sum + (song.duration ?? 0),
    );
    final hours = totalDuration ~/ 3600;
    final minutes = (totalDuration % 3600) ~/ 60;

    final isOffline = Provider.of<AuthProvider>(context, listen: false).state ==
        AuthState.offlineMode;

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
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
                  background: ValueListenableBuilder<Set<String>>(
                    valueListenable: OfflineService().downloadedPlaylistIds,
                    builder: (context, downloaded, _) {
                      final allDownloaded = _album != null && downloaded.contains(_album!.id);
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              top: MediaQuery.of(context).padding.top + 40,
                              left: ScreenHelper.isSmallScreen(context) ? 24 : 40,
                              right: ScreenHelper.isSmallScreen(context) ? 24 : 40,
                              bottom: ScreenHelper.isSmallScreen(context) ? 60 : 80,
                            ),
                            child: AlbumArtwork(
                              coverArt: _album!.coverArt,
                              size: ScreenHelper.isSmallScreen(context) ? 200 : 280,
                              borderRadius: 10,
                              preserveAspectRatio: true,
                            ),
                          ),
                          if (allDownloaded)
                            Positioned(
                              bottom: 86,
                              right: 46,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  CupertinoIcons.arrow_down_circle_fill,
                                  color: Colors.grey,
                                  size: 28,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                actions: [
                  IconButton(
                    tooltip: AppLocalizations.of(context)!.searchInAlbum,
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
                    tooltip: AppLocalizations.of(context)!.moreOptions,
                    onSelected: (value) {
                      if (value == 'queue_all') {
                        final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
                        for (final s in _songs) {
                          playerProvider.addToQueue(s);
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppLocalizations.of(context)!.songsAddedToQueue(_songs.length))),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'queue_all',
                        child: Row(
                          children: [
                            const Icon(CupertinoIcons.text_badge_plus, size: 18),
                            const SizedBox(width: 12),
                            Text(AppLocalizations.of(context)!.addAllToQueue),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (!isOffline) _buildLikeButton(context),
                  if (!isOffline) _buildDownloadButton(context),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _album!.name,
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontSize:
                              ScreenHelper.isSmallScreen(context) ? 22 : null,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      MultiArtistWidget(
                        artists: _album!.artistParticipants,
                        artistFallback: _album!.artist ??
                            AppLocalizations.of(context)!.unknownArtist,
                        artistIdFallback: _album!.artistId,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppTheme.brandRed,
                          fontSize:
                              ScreenHelper.isSmallScreen(context) ? 16 : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          AppLocalizations.of(context)!.songsCount(_songs.length),
                          if (_album!.genre != null)
                            _album!.genre!.toUpperCase(),
                          if (_album!.year != null) _album!.year.toString(),
                          if (hours > 0)
                            '$hours HR $minutes MIN'
                          else
                            '$minutes MIN',
                        ].join(' • '),
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
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
                          placeholder: AppLocalizations.of(context)!.filterTracks,
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
              Builder(
                builder: (context) {
                  final displaySongs = _searchQuery.isEmpty
                      ? _songs
                      : _songs.where((s) => s.title.toLowerCase().contains(_searchQuery) || (s.artist?.toLowerCase().contains(_searchQuery) ?? false)).toList();
                  return SliverFixedExtentList(
                    itemExtent: 58.0,
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final song = displaySongs[index];
                      return SongTile(
                        song: song,
                        playlist: displaySongs,
                        index: index,
                        showArtwork: false,
                        showTrackNumber: true,
                        showArtist: false,
                      );
                    }, childCount: displaySongs.length),
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 150)),
            ],
          ),
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
