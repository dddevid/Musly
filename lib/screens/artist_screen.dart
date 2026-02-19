import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../utils/navigation_helper.dart';
import '../widgets/widgets.dart';
import 'album_screen.dart';

class ArtistScreen extends StatefulWidget {
  final String artistId;

  const ArtistScreen({super.key, required this.artistId});

  @override
  State<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<ArtistScreen> {
  Artist? _artist;
  List<Song> _topSongs = [];
  List<Album> _albums = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArtistDetails();
  }

  Future<void> _loadArtistDetails() async {
    final libraryProvider = Provider.of<LibraryProvider>(
      context,
      listen: false,
    );
    final subsonicService = libraryProvider.subsonicService;

    try {
      Artist? artist;
      List<Song> topSongs = [];
      List<Album> albums = [];

      if (libraryProvider.isLocalOnlyMode) {
        // Local mode: look up data from cached library
        artist = libraryProvider.artists.firstWhere(
          (a) => a.id == widget.artistId,
          orElse: () => Artist(id: widget.artistId, name: 'Unknown Artist'),
        );
        albums = await libraryProvider.getArtistAlbums(widget.artistId);
        // Use all songs by the artist as "top songs"
        topSongs = libraryProvider.cachedAllSongs
            .where((s) => s.artistId == widget.artistId)
            .toList();
      } else {
        artist = await subsonicService.getArtist(widget.artistId);
        topSongs = await subsonicService.getArtistTopSongs(widget.artistId);
        albums = await subsonicService.getArtistAlbums(widget.artistId);
      }

      if (mounted) {
        setState(() {
          _artist = artist;
          _topSongs = topSongs;
          _albums = albums;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _playTopSongs({bool shuffle = false}) {
    if (_topSongs.isEmpty) return;

    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);

    var songs = List<Song>.from(_topSongs);
    if (shuffle) {
      songs.shuffle();
    }

    playerProvider.playSong(songs.first, playlist: songs, startIndex: 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_artist == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(AppLocalizations.of(context)!.artistDataNotFound),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(_artist!.name),
              background: _artist!.coverArt != null
                  ? ShaderMask(
                      shaderCallback: (rect) {
                        return LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black, Colors.transparent],
                        ).createShader(
                          Rect.fromLTRB(0, 0, rect.width, rect.height),
                        );
                      },
                      blendMode: BlendMode.dstIn,
                      child: AlbumArtwork(
                        coverArt: _artist!.coverArt,
                        size: 200,
                      ),
                    )
                  : Container(
                      color: AppTheme.appleMusicRed.withValues(alpha: 0.15),
                      child: const Center(
                        child: Icon(
                          CupertinoIcons.mic_fill,
                          size: 64,
                          color: AppTheme.appleMusicRed,
                        ),
                      ),
                    ),
            ),
            actions: [
              IconButton(
                icon: const Icon(CupertinoIcons.play_circle_fill),
                onPressed: () => _playTopSongs(),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_topSongs.isNotEmpty) ...[
                    Text(
                      AppLocalizations.of(context)!.topSongs,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _topSongs.take(5).length,
                      itemBuilder: (context, index) {
                        final song = _topSongs[index];
                        return SongTile(
                          song: song,
                          playlist: _topSongs,
                          index: index,
                          showAlbum: true,
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],

                  if (_albums.isNotEmpty) ...[
                    Text(
                      AppLocalizations.of(context)!.albums,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.8,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: _albums.length,
                      itemBuilder: (context, index) {
                        final album = _albums[index];
                        return AlbumCard(
                          album: album,
                          size: (MediaQuery.of(context).size.width - 48) / 2,
                          onTap: () => NavigationHelper.push(
                            context,
                            AlbumScreen(albumId: album.id),
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
