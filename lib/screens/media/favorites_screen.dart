import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/subsonic_service.dart';
import '../../services/offline_service.dart';
import '../../providers/player_provider.dart';
import '../../utils/navigation_helper.dart';
import '../../widgets/widgets.dart';
import '../../l10n/app_localizations.dart';
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

    try {
      final subsonic = Provider.of<SubsonicService>(context, listen: false);
      final starred = await subsonic.getStarred();

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

  void _playAll({bool shuffle = false}) {
    if (_favoriteSongs.isEmpty) return;

    final player = Provider.of<PlayerProvider>(context, listen: false);
    final songs = List<Song>.from(_favoriteSongs);

    if (shuffle) {
      songs.shuffle();
    }

    player.playSong(songs.first, playlist: songs, startIndex: 0);
  }

  Future<void> _downloadAllFavorites() async {
    if (_favoriteSongs.isEmpty) return;

    final offlineService = Provider.of<OfflineService>(context, listen: false);
    final subsonic = Provider.of<SubsonicService>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    await offlineService.initialize();

    for (final song in _favoriteSongs) {
      await offlineService.downloadSong(song, subsonic);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.queuedSongsForDownload(_favoriteSongs.length)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.favorites),
        actions: [
          if (!_isLoading && _favoriteSongs.isNotEmpty && _selectedTab == 0)
            IconButton(
              icon: const Icon(CupertinoIcons.arrow_down_circle),
              tooltip: l10n.downloadAllFavorites,
              onPressed: _downloadAllFavorites,
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: PillTabBar(
            tabs: [l10n.songs, l10n.albums],
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
    final l10n = AppLocalizations.of(context)!;
    if (_favoriteSongs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(l10n.noFavoriteSongsYet),
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
                    label: Text(l10n.playAll),
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
                    label: Text(l10n.shuffle),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: _downloadAllFavorites,
                  icon: const Icon(CupertinoIcons.arrow_down_circle, size: 18),
                  tooltip: l10n.downloadAll,
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

        return Dismissible(
          key: Key('fav_${song.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(CupertinoIcons.heart_slash, color: Colors.white),
          ),
          onDismissed: (_) => _removeFavorite(context, song, songIndex),
          child: SongTile(
            song: song,
            playlist: _favoriteSongs,
            index: songIndex,
            showAlbum: true,
          ),
        );
      },
    );
  }

  void _removeFavorite(
    BuildContext context,
    Song song,
    int index,
  ) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.removeFromFavoritesTitle),
        content: Text(l10n.removeFromFavoritesConfirm(song.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
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
                    SnackBar(content: Text(l10n.removedFromFavorites)),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.failedToRemove(e.toString()))),
                  );
                }
              }
            },
            child: Text(l10n.remove, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumsList() {
    final l10n = AppLocalizations.of(context)!;
    if (_favoriteAlbums.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.album_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(l10n.noFavoriteAlbumsYet),
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
