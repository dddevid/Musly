import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import '../theme/app_theme.dart';

enum SongSortOption {
  titleAsc,
  titleDesc,
  artistAsc,
  artistDesc,
  albumAsc,
  albumDesc,
  recentlyAdded,
}

class AllSongsScreen extends StatefulWidget {
  const AllSongsScreen({super.key});

  @override
  State<AllSongsScreen> createState() => _AllSongsScreenState();
}

class _AllSongsScreenState extends State<AllSongsScreen> {
  List<Song> _songs = [];
  List<Song> _sortedSongs = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  SongSortOption _currentSort = SongSortOption.titleAsc;

  @override
  void initState() {
    super.initState();
    _loadCachedData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {}

  Future<void> _loadCachedData() async {
    final libraryProvider = Provider.of<LibraryProvider>(
      context,
      listen: false,
    );

    await libraryProvider.ensureLibraryLoaded();

    if (mounted) {
      setState(() {
        _songs = libraryProvider.cachedAllSongs;
        _sortSongs();
        _isLoading = false;
      });
    }
  }

  void _sortSongs() {
    _sortedSongs = List.from(_songs);
    switch (_currentSort) {
      case SongSortOption.titleAsc:
        _sortedSongs.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
      case SongSortOption.titleDesc:
        _sortedSongs.sort(
          (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()),
        );
        break;
      case SongSortOption.artistAsc:
        _sortedSongs.sort(
          (a, b) => (a.artist ?? '').toLowerCase().compareTo(
            (b.artist ?? '').toLowerCase(),
          ),
        );
        break;
      case SongSortOption.artistDesc:
        _sortedSongs.sort(
          (a, b) => (b.artist ?? '').toLowerCase().compareTo(
            (a.artist ?? '').toLowerCase(),
          ),
        );
        break;
      case SongSortOption.albumAsc:
        _sortedSongs.sort(
          (a, b) => (a.album ?? '').toLowerCase().compareTo(
            (b.album ?? '').toLowerCase(),
          ),
        );
        break;
      case SongSortOption.albumDesc:
        _sortedSongs.sort(
          (a, b) => (b.album ?? '').toLowerCase().compareTo(
            (a.album ?? '').toLowerCase(),
          ),
        );
        break;
      case SongSortOption.recentlyAdded:
        // Keep original order (usually server returns recently added first) or reverse
        _sortedSongs = List.from(_songs.reversed);
        break;
    }
  }

  void _showSortOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sort By',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            _buildSortOption('Title (A-Z)', SongSortOption.titleAsc, isDark),
            _buildSortOption('Title (Z-A)', SongSortOption.titleDesc, isDark),
            _buildSortOption('Artist (A-Z)', SongSortOption.artistAsc, isDark),
            _buildSortOption('Artist (Z-A)', SongSortOption.artistDesc, isDark),
            _buildSortOption('Album (A-Z)', SongSortOption.albumAsc, isDark),
            _buildSortOption('Album (Z-A)', SongSortOption.albumDesc, isDark),
            _buildSortOption(
              'Recently Added',
              SongSortOption.recentlyAdded,
              isDark,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String title, SongSortOption option, bool isDark) {
    final isSelected = _currentSort == option;
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: isSelected
              ? AppTheme.appleMusicRed
              : (isDark ? Colors.white : Colors.black),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check, color: AppTheme.appleMusicRed)
          : null,
      onTap: () {
        Navigator.pop(context);
        setState(() {
          _currentSort = option;
          _sortSongs();
        });
      },
    );
  }

  void _playAll({bool shuffle = false}) {
    if (_sortedSongs.isEmpty) return;

    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);

    List<Song> playlist = List.from(_sortedSongs);
    if (shuffle) {
      playlist.shuffle();
    }

    playerProvider.playSong(playlist.first, playlist: playlist, startIndex: 0);
  }

  String _getSortLabel() {
    switch (_currentSort) {
      case SongSortOption.titleAsc:
        return 'Title (A-Z)';
      case SongSortOption.titleDesc:
        return 'Title (Z-A)';
      case SongSortOption.artistAsc:
        return 'Artist (A-Z)';
      case SongSortOption.artistDesc:
        return 'Artist (Z-A)';
      case SongSortOption.albumAsc:
        return 'Album (A-Z)';
      case SongSortOption.albumDesc:
        return 'Album (Z-A)';
      case SongSortOption.recentlyAdded:
        return 'Recently Added';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Songs'),
        backgroundColor: isDark ? AppTheme.darkBackground : Colors.white,
        actions: [
          if (_sortedSongs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.sort_rounded),
              onPressed: _showSortOptions,
              tooltip: 'Sort',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _songs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.music_note_outlined,
                    size: 64,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No songs found',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Header with count, sort info, and playback controls
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_sortedSongs.length} songs',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            GestureDetector(
                              onTap: _showSortOptions,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.sort_rounded,
                                    size: 14,
                                    color: AppTheme.appleMusicRed,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _getSortLabel(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.appleMusicRed,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Shuffle button
                      IconButton(
                        onPressed: () => _playAll(shuffle: true),
                        icon: Icon(
                          Icons.shuffle_rounded,
                          color: isDark ? Colors.white70 : Colors.black54,
                          size: 28,
                        ),
                        tooltip: 'Shuffle play',
                      ),
                      const SizedBox(width: 8),
                      // Play button
                      Consumer<PlayerProvider>(
                        builder: (context, playerProvider, _) {
                          final isCurrentPlaylist =
                              playerProvider.queue.isNotEmpty &&
                              playerProvider.queue.any(
                                (song) =>
                                    _sortedSongs.any((s) => s.id == song.id),
                              );
                          final isPlaying =
                              isCurrentPlaylist && playerProvider.isPlaying;

                          return GestureDetector(
                            onTap: () {
                              if (isCurrentPlaylist &&
                                  playerProvider.currentSong != null) {
                                if (playerProvider.isPlaying) {
                                  playerProvider.pause();
                                } else {
                                  playerProvider.play();
                                }
                              } else {
                                _playAll();
                              }
                            },
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppTheme.appleMusicRed,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.appleMusicRed.withOpacity(
                                      0.4,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: _sortedSongs.length,
                    itemBuilder: (context, index) {
                      return SongTile(
                        song: _sortedSongs[index],
                        playlist: _sortedSongs,
                        index: index,
                        showAlbum: true,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
