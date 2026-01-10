import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../services/subsonic_service.dart';
import '../widgets/widgets.dart';
import 'album_screen.dart';

class AlbumsScreen extends StatefulWidget {
  const AlbumsScreen({super.key});

  @override
  State<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends State<AlbumsScreen> {
  final List<Album> _albums = [];
  bool _isLoading = true;
  bool _hasMore = false;
  int _currentArtistIndex = 0;
  List<Artist> _allArtists = [];

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadAlbums();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      _loadMore();
    }
  }

  Future<void> _loadAlbums() async {
    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );

    try {
      // First, get all artists
      _allArtists = await subsonicService.getArtists();

      // Then load albums from the first batch of artists
      await _loadAlbumsFromArtists(0, 20);

      if (mounted) {
        setState(() {
          _hasMore = _currentArtistIndex < _allArtists.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadAlbumsFromArtists(int startIndex, int count) async {
    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );

    final endIndex = (startIndex + count).clamp(0, _allArtists.length);

    for (int i = startIndex; i < endIndex; i++) {
      try {
        final artistAlbums = await subsonicService.getArtistAlbums(
          _allArtists[i].id,
        );
        _albums.addAll(artistAlbums);
      } catch (e) {
        debugPrint(
          'Error loading albums for artist ${_allArtists[i].name}: $e',
        );
      }
    }

    // Sort albums alphabetically by name
    _albums.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    _currentArtistIndex = endIndex;
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      await _loadAlbumsFromArtists(_currentArtistIndex, 20);

      if (mounted) {
        setState(() {
          _hasMore = _currentArtistIndex < _allArtists.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Albums')),
      body: _albums.isEmpty && _isLoading
          ? GridView.builder(
              padding: const EdgeInsets.all(16).copyWith(bottom: 150),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: 10,
              itemBuilder: (context, index) =>
                  const AlbumCardShimmer(size: double.infinity),
            )
          : GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16).copyWith(bottom: 150),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: _albums.length + (_hasMore ? 2 : 0),
              itemBuilder: (context, index) {
                if (index >= _albums.length) {
                  return const AlbumCardShimmer(size: double.infinity);
                }

                final album = _albums[index];
                return AlbumCard(
                  album: album,
                  size: double.infinity,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AlbumScreen(albumId: album.id),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
