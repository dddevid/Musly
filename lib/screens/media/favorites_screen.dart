import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/subsonic_service.dart';
import '../../services/offline_service.dart';
import '../../providers/player_provider.dart';
import '../../utils/navigation_helper.dart';
import '../../widgets/widgets.dart';
import '../detail/album_screen.dart';
import 'package:flutter/cupertino.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Song> _favoriteSongs = [];
  List<Album> _favoriteAlbums = [];
  bool _isLoading = true;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);

    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );

    try {
      final starred = await subsonicService.getStarred();

      if (mounted) {
        setState(() {
          _favoriteSongs = starred.songs;
          _favoriteAlbums = starred.albums;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _downloadAllFavorites() async {
    if (_favoriteSongs.isEmpty) return;
    final offlineService = OfflineService();
    final subsonicService = Provider.of<SubsonicService>(context, listen: false);
    await offlineService.initialize();
    offlineService.queuePlaylistDownload('favorites_all', _favoriteSongs, subsonicService);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(CupertinoIcons.arrow_down_circle_fill, color: Color(0xFF34C759), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Queued ${_favoriteSongs.length} favorite songs for download…',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _playAll({bool shuffle = false}) {
    if (_favoriteSongs.isEmpty) return;
    final player = Provider.of<PlayerProvider>(context, listen: false);
    final songs = List<Song>.from(_favoriteSongs);
    if (shuffle) songs.shuffle();
    player.playSong(songs.first, playlist: songs, startIndex: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        actions: [
          if (!_isLoading && _favoriteSongs.isNotEmpty && _selectedTab == 0)
            IconButton(
              icon: const Icon(CupertinoIcons.arrow_down_circle),
              tooltip: 'Download All Favorites',
              onPressed: _downloadAllFavorites,
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: PillTabBar(
            tabs: const ['Songs', 'Albums'],
            selectedIndex: _selectedTab,
            onTabSelected: (idx) => setState(() => _selectedTab = idx),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _selectedTab == 0
              ? _buildSongsList()
              : _buildAlbumsList(),
    );
  }

  Widget _buildSongsList() {
    if (_favoriteSongs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border_rounded, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No favorite songs yet'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 150),
      itemCount: _favoriteSongs.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _playAll(shuffle: false),
                    icon: const Icon(CupertinoIcons.play_fill, size: 16),
                    label: const Text('Play All'),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _playAll(shuffle: true),
                    icon: const Icon(CupertinoIcons.shuffle, size: 16),
                    label: const Text('Shuffle'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: _downloadAllFavorites,
                  icon: const Icon(CupertinoIcons.arrow_down_circle, size: 18),
                  tooltip: 'Download All',
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          );
        }
        final songIndex = index - 1;
        final song = _favoriteSongs[songIndex];
        return SongTile(
          song: song,
          playlist: _favoriteSongs,
          index: songIndex,
          showAlbum: true,
          onLongPress: () =>
              _showRemoveFromFavoritesDialog(context, song, songIndex),
        );
      },
    );
  }

  void _showRemoveFromFavoritesDialog(
    BuildContext context,
    Song song,
    int index,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Favorites?'),
        content: Text('Do you want to remove "${song.title}" from favorites?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final subsonic = Provider.of<SubsonicService>(
                context,
                listen: false,
              );
              try {
                await subsonic.unstar(id: song.id);
                setState(() {
                  _favoriteSongs.removeAt(index);
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Removed from favorites')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to remove: $e')),
                  );
                }
              }
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumsList() {
    if (_favoriteAlbums.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.album_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No favorite albums yet'),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        if (constraints.maxWidth > 900) {
          crossAxisCount = 5;
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 3;
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 150),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _favoriteAlbums.length,
          itemBuilder: (context, index) {
            final album = _favoriteAlbums[index];
            return AlbumCard(
              album: album,
              size: double.infinity,
              onTap: () => NavigationHelper.push(
                context,
                AlbumScreen(albumId: album.id),
              ),
            );
          },
        );
      },
    );
  }
}
