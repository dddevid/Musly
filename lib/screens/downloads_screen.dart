import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/library_provider.dart';
import '../services/offline_service.dart';
import '../widgets/widgets.dart';
import 'album_screen.dart';

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
    final allAlbums = libraryProvider.cachedAllAlbums;

    final List<Song> dSongs = [];
    final Set<String> albumIds = {};

    for (final song in allSongs) {
      if (downloadedIds.contains(song.id)) {
        dSongs.add(song);
        if (song.albumId != null) {
          albumIds.add(song.albumId!);
        }
      }
    }

    // Sort songs alphabetically
    dSongs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    // Get albums that have at least one downloaded song
    final List<Album> dAlbums = allAlbums.where((a) => albumIds.contains(a.id)).toList();
    dAlbums.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    if (mounted) {
      setState(() {
        _downloadedSongs = dSongs;
        _downloadedAlbums = dAlbums;
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
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _TabButton(
                  title: 'Songs',
                  isSelected: _selectedTab == 0,
                  onTap: () => setState(() => _selectedTab = 0),
                ),
                const SizedBox(width: 8),
                _TabButton(
                  title: 'Albums',
                  isSelected: _selectedTab == 1,
                  onTap: () => setState(() => _selectedTab = 1),
                ),
              ],
            ),
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
            Icon(Icons.download_done, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No downloaded songs'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 120),
      itemExtent: 68.0,
      cacheExtent: 300,
      itemCount: _downloadedSongs.length,
      itemBuilder: (context, index) {
        final song = _downloadedSongs[index];
        return SongTile(
          song: song,
          playlist: _downloadedSongs,
          index: index,
          showArtwork: true,
          showArtist: true,
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
            Icon(Icons.album, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No downloaded albums'),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16).copyWith(bottom: 120),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
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
  }
}

class _TabButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white : Colors.black)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? (isDark ? Colors.black : Colors.white)
                : (isDark ? Colors.white : Colors.black),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
