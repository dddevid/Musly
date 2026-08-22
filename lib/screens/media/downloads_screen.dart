import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/library_provider.dart';
import '../../services/offline_service.dart';
import '../../widgets/widgets.dart';
import '../detail/album_screen.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  List<Song> _downloadedSongs = [];
  List<Album> _downloadedAlbums = [];
  bool _isLoading = true;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  void _loadDownloads() {
    setState(() => _isLoading = true);

    final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
    final offlineService = OfflineService();
    final downloadedIds = offlineService.getDownloadedSongIds().toSet();

    final allSongs = libraryProvider.cachedAllSongs;
    final allAlbums = libraryProvider.recentAlbums;

    final songs = allSongs.where((s) => downloadedIds.contains(s.id)).toList();

    final albumIdsWithDownloads = songs.map((s) => s.albumId).toSet();
    final albums = allAlbums.where((a) => albumIdsWithDownloads.contains(a.id)).toList();

    if (mounted) {
      setState(() {
        _downloadedSongs = songs;
        _downloadedAlbums = albums;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
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
    if (_downloadedSongs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.download_done_rounded, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No downloaded songs yet'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 150),
      itemExtent: 68.0,
      itemCount: _downloadedSongs.length,
      itemBuilder: (context, index) {
        final song = _downloadedSongs[index];
        return SongTile(
          song: song,
          playlist: _downloadedSongs,
          index: index,
          showAlbum: true,
        );
      },
    );
  }

  Widget _buildAlbumsList() {
    if (_downloadedAlbums.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.album_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No downloaded albums yet'),
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
          itemCount: _downloadedAlbums.length,
          itemBuilder: (context, index) {
            final album = _downloadedAlbums[index];
            return AlbumCard(
              album: album,
              size: double.infinity,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AlbumScreen(albumId: album.id),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
