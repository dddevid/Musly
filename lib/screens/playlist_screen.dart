import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:palette_generator/palette_generator.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/subsonic_service.dart';
import '../services/offline_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class PlaylistScreen extends StatefulWidget {
  final String playlistId;
  final String playlistName;

  const PlaylistScreen({
    super.key,
    required this.playlistId,
    required this.playlistName,
  });

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  Playlist? _playlist;
  List<Song> _songs = [];
  bool _isLoading = true;

  Color _dominantColor = AppTheme.appleMusicRed;

  bool _isReorderMode = false;
  Set<int> _selectedIndices = {};

  bool get _isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  @override
  void initState() {
    super.initState();
    _loadPlaylist();
  }

  Future<void> _loadPlaylist() async {
    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );

    try {
      final playlist = await subsonicService.getPlaylist(widget.playlistId);
      if (mounted) {
        setState(() {
          _playlist = playlist;
          _songs = playlist.songs ?? [];
          _isLoading = false;
        });
        _extractDominantColor();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleReorderMode() {
    setState(() {
      _isReorderMode = !_isReorderMode;
      if (!_isReorderMode) {
        _selectedIndices.clear();
      }
    });
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

  Future<void> _reorderSongs(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    setState(() {
      final song = _songs.removeAt(oldIndex);
      _songs.insert(newIndex, song);
    });
  }

  Future<void> _extractDominantColor() async {
    if (_playlist == null) return;

    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );

    String? coverArtId;
    if (_songs.isNotEmpty && _songs.first.coverArt != null) {
      coverArtId = _songs.first.coverArt;
    }

    if (coverArtId == null) {
      final hash = widget.playlistName.hashCode;
      final colors = [
        const Color(0xFF1DB954),
        const Color(0xFFE91E63),
        const Color(0xFF9C27B0),
        const Color(0xFF2196F3),
        const Color(0xFFFF5722),
        const Color(0xFF00BCD4),
        const Color(0xFFFF9800),
        const Color(0xFF673AB7),
      ];
      if (mounted) {
        setState(() {
          _dominantColor = colors[hash.abs() % colors.length];
        });
      }
      return;
    }

    try {
      final imageUrl = subsonicService.getCoverArtUrl(coverArtId, size: 300);
      final imageProvider = CachedNetworkImageProvider(imageUrl);

      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: 10,
      );

      if (mounted) {
        Color? extractedColor;

        if (paletteGenerator.vibrantColor != null) {
          extractedColor = paletteGenerator.vibrantColor!.color;
        } else if (paletteGenerator.dominantColor != null) {
          extractedColor = paletteGenerator.dominantColor!.color;
        } else if (paletteGenerator.darkVibrantColor != null) {
          extractedColor = paletteGenerator.darkVibrantColor!.color;
        } else if (paletteGenerator.lightVibrantColor != null) {
          extractedColor = paletteGenerator.lightVibrantColor!.color;
        }

        if (extractedColor != null) {
          setState(() {
            _dominantColor = extractedColor!;
          });
        }
      }
    } catch (e) {
      print('Error extracting dominant color: $e');
    }
  }

  void _playAll({bool shuffle = false}) {
    if (_songs.isEmpty) return;

    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);

    // Check if we're playing from THIS specific playlist by comparing the queue
    // The queue should match this playlist's songs in order (or shuffled order)
    final queueIds = playerProvider.queue.map((s) => s.id).toList();
    final playlistIds = _songs.map((s) => s.id).toSet();

    // We're playing from this playlist if ALL queue songs are from this playlist
    // and the current song is in this playlist
    final isPlayingFromThisPlaylist =
        playerProvider.currentSong != null &&
        playlistIds.contains(playerProvider.currentSong!.id) &&
        queueIds.every((id) => playlistIds.contains(id));

    // If shuffle is requested, always start a new shuffled playlist
    if (shuffle) {
      List<Song> playlist = List.from(_songs);
      playlist.shuffle();
      playerProvider.playSong(
        playlist.first,
        playlist: playlist,
        startIndex: 0,
      );
      return;
    }

    // If playing from this playlist, toggle play/pause
    if (isPlayingFromThisPlaylist) {
      if (playerProvider.isPlaying) {
        playerProvider.pause();
      } else {
        playerProvider.play();
      }
      return;
    }

    // Otherwise, start playing this playlist from the beginning
    List<Song> playlist = List.from(_songs);
    playerProvider.playSong(playlist.first, playlist: playlist, startIndex: 0);
  }

  Future<void> _downloadPlaylist(BuildContext context) async {
    if (_songs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No songs to download'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final offlineService = Provider.of<OfflineService>(context, listen: false);
    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading ${_songs.length} songs...'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      await offlineService.downloadSongs(
        _songs,
        subsonicService,
        onProgress: (current, total) {
          // Progress updates are handled by the service
        },
        onComplete: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Downloaded ${_songs.length} songs'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppTheme.darkBackground : Colors.white,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_playlist == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.playlistName)),
        body: const Center(child: Text('Playlist not found')),
      );
    }

    final coverArtUrl = _playlist!.coverArt != null
        ? subsonicService.getCoverArtUrl(_playlist!.coverArt!, size: 300)
        : null;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _dominantColor,
                  _dominantColor.withOpacity(0.3),
                  isDark ? AppTheme.darkBackground : Colors.white,
                ],
                stops: const [0.0, 0.3, 0.5],
              ),
            ),
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 340,
                  backgroundColor: Colors.transparent,
                  leading: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.more_vert,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      onPressed: () => _showOptionsSheet(context),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Hero(
                            tag: 'playlist_${widget.playlistId}',
                            child: Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 30,
                                    offset: const Offset(0, 15),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: coverArtUrl != null
                                    ? CachedNetworkImage(
                                        imageUrl: coverArtUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) =>
                                            _buildPlaylistArtPlaceholder(),
                                        errorWidget: (_, __, ___) =>
                                            _buildPlaylistArtPlaceholder(),
                                      )
                                    : _buildPlaylistArtPlaceholder(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Text(
                            _playlist!.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),

                          Builder(
                            builder: (context) {
                              final totalSeconds = _songs.fold<int>(
                                0,
                                (sum, song) => sum + (song.duration ?? 0),
                              );
                              final hours = totalSeconds ~/ 3600;
                              final minutes = (totalSeconds % 3600) ~/ 60;
                              final durationStr = hours > 0
                                  ? '$hours hr $minutes min'
                                  : '$minutes min';
                              return Text(
                                '${_songs.length} songs • $durationStr',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Container(
                    color: isDark ? AppTheme.darkBackground : Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(CupertinoIcons.heart),
                            ),

                            IconButton(
                              onPressed: () => _downloadPlaylist(context),
                              icon: const Icon(
                                CupertinoIcons.arrow_down_circle,
                              ),
                            ),

                            const Spacer(),

                            IconButton(
                              onPressed: () => _playAll(shuffle: true),
                              icon: Icon(
                                Icons.shuffle_rounded,
                                color: isDark ? Colors.white70 : Colors.black54,
                                size: 28,
                              ),
                            ),

                            const SizedBox(width: 8),

                            Consumer<PlayerProvider>(
                              builder: (context, playerProvider, _) {
                                // Check if we're playing from THIS specific playlist
                                final queueIds = playerProvider.queue
                                    .map((s) => s.id)
                                    .toList();
                                final playlistIds = _songs
                                    .map((s) => s.id)
                                    .toSet();

                                final isPlayingFromThisPlaylist =
                                    playerProvider.currentSong != null &&
                                    playlistIds.contains(
                                      playerProvider.currentSong!.id,
                                    ) &&
                                    queueIds.every(
                                      (id) => playlistIds.contains(id),
                                    );

                                final isPlaying =
                                    isPlayingFromThisPlaylist &&
                                    playerProvider.isPlaying;

                                return GestureDetector(
                                  onTap: () => _playAll(),
                                  child: Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: _dominantColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: _dominantColor.withOpacity(
                                            0.4,
                                          ),
                                          blurRadius: 15,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 36,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Container(
                    color: isDark ? AppTheme.darkBackground : Colors.white,
                    child: _songs.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(48),
                            child: Column(
                              children: [
                                Icon(
                                  CupertinoIcons.music_note_list,
                                  size: 64,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black26,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No songs in this playlist',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black45,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add songs to get started',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.black26,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _isReorderMode
                        ? ReorderableListView(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            onReorder: _reorderSongs,
                            children: List.generate(
                              _songs.length,
                              (index) => Container(
                                key: ValueKey(_songs[index].id),
                                child: _SpotifySongTile(
                                  song: _songs[index],
                                  index: index,
                                  songs: _songs,
                                  isReorderMode: _isReorderMode,
                                  isSelected: _selectedIndices.contains(index),
                                  onLongPress: () {
                                    if (!_isReorderMode) {
                                      _toggleReorderMode();
                                      _toggleSelection(index);
                                    }
                                  },
                                  onSelectionToggle: _isReorderMode
                                      ? () => _toggleSelection(index)
                                      : null,
                                ),
                              ),
                            ),
                          )
                        : Column(
                            children: List.generate(
                              _songs.length,
                              (index) => _SpotifySongTile(
                                song: _songs[index],
                                index: index,
                                songs: _songs,
                                isReorderMode: _isReorderMode,
                                isSelected: _selectedIndices.contains(index),
                                onLongPress: () {
                                  if (!_isReorderMode) {
                                    _toggleReorderMode();
                                    _toggleSelection(index);
                                  }
                                },
                                onSelectionToggle: _isReorderMode
                                    ? () => _toggleSelection(index)
                                    : null,
                              ),
                            ),
                          ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Container(
                    height: 200,
                    color: isDark ? AppTheme.darkBackground : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _isReorderMode
          ? FloatingActionButton.extended(
              onPressed: _toggleReorderMode,
              backgroundColor: AppTheme.appleMusicRed,
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text('Done', style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }

  Widget _buildBottomNav(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                icon: CupertinoIcons.music_house,
                activeIcon: CupertinoIcons.music_house_fill,
                label: 'Home',
                isActive: false,
                onTap: () => Navigator.pop(context),
              ),
              _buildNavItem(
                context,
                icon: CupertinoIcons.collections,
                activeIcon: CupertinoIcons.collections_solid,
                label: 'Library',
                isActive: true,
                onTap: () => Navigator.pop(context),
              ),
              _buildNavItem(
                context,
                icon: CupertinoIcons.search,
                activeIcon: CupertinoIcons.search,
                label: 'Search',
                isActive: false,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive
                  ? AppTheme.appleMusicRed
                  : (isDark ? Colors.white54 : Colors.black45),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive
                    ? AppTheme.appleMusicRed
                    : (isDark ? Colors.white54 : Colors.black45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistArtPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_dominantColor.withOpacity(0.8), _dominantColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(
        CupertinoIcons.music_note_list,
        color: Colors.white,
        size: 64,
      ),
    );
  }

  void _showOptionsSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(CupertinoIcons.pencil),
                title: const Text('Edit Playlist'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.share),
                title: const Text('Share'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.trash, color: Colors.red),
                title: const Text(
                  'Delete Playlist',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteDialog(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Playlist'),
        content: Text(
          'Are you sure you want to delete "${_playlist?.name ?? widget.playlistName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deletePlaylist();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePlaylist() async {
    try {
      final libraryProvider = Provider.of<LibraryProvider>(
        context,
        listen: false,
      );

      await libraryProvider.deletePlaylist(widget.playlistId);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Playlist "${_playlist?.name ?? widget.playlistName}" deleted',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _SpotifySongTile extends StatelessWidget {
  final Song song;
  final int index;
  final List<Song> songs;
  final bool isReorderMode;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final VoidCallback? onSelectionToggle;

  const _SpotifySongTile({
    required this.song,
    required this.index,
    required this.songs,
    this.isReorderMode = false,
    this.isSelected = false,
    this.onLongPress,
    this.onSelectionToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final playerProvider = Provider.of<PlayerProvider>(context);
    final isPlaying = playerProvider.currentSong?.id == song.id;

    return ListTile(
      selected: isSelected,
      selectedTileColor: AppTheme.appleMusicRed.withOpacity(0.15),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onLongPress: onLongPress,
      onTap: isReorderMode && onSelectionToggle != null
          ? onSelectionToggle
          : () {
              if (!isReorderMode) {
                final playerProvider = Provider.of<PlayerProvider>(
                  context,
                  listen: false,
                );
                playerProvider.playSong(
                  song,
                  playlist: songs,
                  startIndex: index,
                );
              }
            },
      leading: isReorderMode
          ? ReorderableDragStartListener(
              index: index,
              child: Icon(
                Icons.drag_handle,
                color: isSelected
                    ? AppTheme.appleMusicRed
                    : (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white54
                          : Colors.black45),
              ),
            )
          : SizedBox(
              width: 48,
              height: 48,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: AlbumArtwork(
                  coverArt: song.coverArt,
                  size: 48,
                  borderRadius: 4,
                ),
              ),
            ),
      title: Text(
        song.title,
        style: TextStyle(
          color: isPlaying
              ? AppTheme.appleMusicRed
              : (isDark ? Colors.white : Colors.black),
          fontWeight: isPlaying ? FontWeight.w600 : FontWeight.normal,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        song.artist ?? '',
        style: TextStyle(
          color: isDark ? Colors.white54 : Colors.black45,
          fontSize: 13,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isReorderMode
          ? (isSelected
                ? Icon(
                    Icons.check_circle,
                    color: AppTheme.appleMusicRed,
                    size: 24,
                  )
                : Icon(
                    Icons.radio_button_unchecked,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white54
                        : Colors.black45,
                    size: 24,
                  ))
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isPlaying)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AnimatedEqualizer(
                      color: AppTheme.appleMusicRed,
                      isPlaying: playerProvider.isPlaying,
                    ),
                  ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: isDark ? Colors.white54 : Colors.black45,
                    size: 20,
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'queue',
                      child: Row(
                        children: [
                          Icon(Icons.queue_music, size: 20),
                          SizedBox(width: 12),
                          Text('Add to Queue'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'playlist',
                      child: Row(
                        children: [
                          Icon(Icons.playlist_add, size: 20),
                          SizedBox(width: 12),
                          Text('Add to Playlist'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
