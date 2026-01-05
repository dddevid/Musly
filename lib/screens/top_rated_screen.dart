import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/subsonic_service.dart';
import '../models/album.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'album_screen.dart';

class TopRatedScreen extends StatefulWidget {
  const TopRatedScreen({super.key});

  @override
  State<TopRatedScreen> createState() => _TopRatedScreenState();
}

class _TopRatedScreenState extends State<TopRatedScreen> {
  List<Album>? _albums;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    try {
      final subsonicService = Provider.of<SubsonicService>(
        context,
        listen: false,
      );
      final albums = await subsonicService.getAlbumList(
        type: 'highest',
        size: 50,
      );
      if (mounted) {
        setState(() {
          _albums = albums;
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
    final theme = Theme.of(context);

    return Scaffold(
      bottomNavigationBar: const MiniPlayer(),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 140,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('Top Rated', style: theme.appBarTheme.titleTextStyle),
              titlePadding: const EdgeInsets.only(left: 52, bottom: 16),
            ),
          ),
          if (_isLoading)
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      const AlbumCardShimmer(size: double.infinity),
                  childCount: 8,
                ),
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
                      'Error loading albums',
                      style: theme.textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
            )
          else if (_albums == null || _albums!.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.album,
                      size: 64,
                      color: AppTheme.lightSecondaryText,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No top rated albums',
                      style: theme.textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final album = _albums![index];
                  return AlbumCard(
                    album: album,
                    size: double.infinity,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AlbumScreen(albumId: album.id),
                        ),
                      );
                    },
                  );
                }, childCount: _albums!.length),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
