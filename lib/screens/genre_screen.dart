import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/subsonic_service.dart';
import '../models/song.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class GenreScreen extends StatefulWidget {
  final String genre;

  const GenreScreen({super.key, required this.genre});

  @override
  State<GenreScreen> createState() => _GenreScreenState();
}

class _GenreScreenState extends State<GenreScreen> {
  List<Song>? _songs;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    try {
      final subsonicService = Provider.of<SubsonicService>(
        context,
        listen: false,
      );
      final songs = await subsonicService.getSongsByGenre(
        widget.genre,
        count: 100,
      );
      if (mounted) {
        setState(() {
          _songs = songs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 140,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.genre,
                style: Theme.of(context).appBarTheme.titleTextStyle,
              ),
              titlePadding: const EdgeInsets.only(left: 52, bottom: 16),
            ),
          ),
          if (_isLoading)
            SliverToBoxAdapter(
              child: Column(
                children: List.generate(10, (_) => const SongTileShimmer()),
              ),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppTheme.lightSecondaryText,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading songs',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
            )
          else if (_songs == null || _songs!.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.music_off,
                      size: 64,
                      color: AppTheme.lightSecondaryText,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No songs in this genre',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index == _songs!.length) {
                  return const SizedBox(height: 100);
                }
                return SongTile(
                  song: _songs![index],
                  playlist: _songs,
                  index: index,
                  showArtist: true,
                  showAlbum: true,
                );
              }, childCount: _songs!.length + 1),
            ),
        ],
      ),
    );
  }
}
