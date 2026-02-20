import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../models/album.dart';
import '../models/song.dart';
import '../providers/library_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import '../utils/navigation_helper.dart';
import 'album_screen.dart';

class GenreScreen extends StatefulWidget {
  final String genre;

  const GenreScreen({super.key, required this.genre});

  @override
  State<GenreScreen> createState() => _GenreScreenState();
}

class _GenreScreenState extends State<GenreScreen>
    with SingleTickerProviderStateMixin {
  List<Song>? _songs;
  List<Album>? _albums;
  bool _isLoadingSongs = true;
  bool _isLoadingAlbums = true;
  String? _songsError;
  String? _albumsError;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSongs();
    _loadAlbums();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSongs() async {
    setState(() {
      _isLoadingSongs = true;
      _songsError = null;
    });
    try {
      final libraryProvider = Provider.of<LibraryProvider>(
        context,
        listen: false,
      );
      final songs = await libraryProvider.subsonicService.getSongsByGenre(
        widget.genre,
        count: 200,
      );
      if (mounted) {
        setState(() {
          _songs = songs;
          _isLoadingSongs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _songsError = e.toString();
          _isLoadingSongs = false;
        });
      }
    }
  }

  Future<void> _loadAlbums() async {
    setState(() {
      _isLoadingAlbums = true;
      _albumsError = null;
    });
    try {
      final libraryProvider = Provider.of<LibraryProvider>(
        context,
        listen: false,
      );
      final albums = await libraryProvider.getAlbumsByGenre(widget.genre);
      if (mounted) {
        setState(() {
          _albums = albums;
          _isLoadingAlbums = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _albumsError = e.toString();
          _isLoadingAlbums = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 140,
            forceElevated: innerBoxIsScrolled,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.genre,
                style: Theme.of(context).appBarTheme.titleTextStyle,
              ),
              titlePadding: const EdgeInsets.only(left: 52, bottom: 48),
            ),
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: l10n.songs),
                Tab(text: l10n.albums),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [_buildSongsTab(l10n), _buildAlbumsTab(l10n)],
        ),
      ),
    );
  }

  Widget _buildSongsTab(AppLocalizations l10n) {
    if (_isLoadingSongs) {
      return ListView(
        children: List.generate(10, (_) => const SongTileShimmer()),
      );
    }
    if (_songsError != null) {
      return Center(
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
              l10n.errorLoadingSongs,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadSongs,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      );
    }
    if (_songs == null || _songs!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_off, size: 64, color: AppTheme.lightSecondaryText),
            const SizedBox(height: 16),
            Text(
              l10n.noSongsInGenre,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: _songs!.length + 1,
      itemBuilder: (context, index) {
        if (index == _songs!.length) return const SizedBox(height: 100);
        return SongTile(
          song: _songs![index],
          playlist: _songs,
          index: index,
          showArtist: true,
          showAlbum: true,
        );
      },
    );
  }

  Widget _buildAlbumsTab(AppLocalizations l10n) {
    if (_isLoadingAlbums) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_albumsError != null) {
      return Center(
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
              l10n.errorLoadingAlbums,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadAlbums,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      );
    }
    if (_albums == null || _albums!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.album, size: 64, color: AppTheme.lightSecondaryText),
            const SizedBox(height: 16),
            Text(
              l10n.noAlbumsInGenre,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _albums!.length,
      itemBuilder: (context, index) {
        final album = _albums![index];
        return AlbumCard(
          album: album,
          onTap: () =>
              NavigationHelper.push(context, AlbumScreen(albumId: album.id)),
        );
      },
    );
  }
}
