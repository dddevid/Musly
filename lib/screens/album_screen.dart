import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/subsonic_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'artist_screen.dart';
import '../l10n/app_localizations.dart';

class AlbumScreen extends StatefulWidget {
  final String albumId;

  const AlbumScreen({super.key, required this.albumId});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  Album? _album;
  List<Song> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlbum();
  }

  Future<void> _loadAlbum() async {
    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );
    final libraryProvider = Provider.of<LibraryProvider>(
      context,
      listen: false,
    );

    try {
      Album? album;

      // In local-only mode, look up from cached albums
      if (libraryProvider.isLocalOnlyMode) {
        album = libraryProvider.cachedAllAlbums.firstWhere(
          (a) => a.id == widget.albumId,
          orElse: () => Album(id: widget.albumId, name: 'Unknown Album'),
        );
      } else {
        album = await subsonicService.getAlbum(widget.albumId);
      }

      final songs = await libraryProvider.getAlbumSongs(widget.albumId);

      if (mounted) {
        setState(() {
          _album = album;
          _songs = songs;
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
    if (_songs.isEmpty) return;

    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);

    List<Song> playlist = List.from(_songs);
    if (shuffle) {
      playlist.shuffle();
    }

    playerProvider.playSong(playlist.first, playlist: playlist, startIndex: 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const AlbumArtworkShimmer(size: 250),
                    const SizedBox(height: 24),
                    Shimmer.fromColors(
                      baseColor: isDark
                          ? AppTheme.darkCard
                          : const Color(0xFFE0E0E0),
                      highlightColor: isDark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFF5F5F5),
                      child: Container(
                        width: 200,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Shimmer.fromColors(
                      baseColor: isDark
                          ? AppTheme.darkCard
                          : const Color(0xFFE0E0E0),
                      highlightColor: isDark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFF5F5F5),
                      child: Container(
                        width: 150,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => const SongTileShimmer(),
                childCount: 10,
              ),
            ),
          ],
        ),
      );
    }

    if (_album == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(AppLocalizations.of(context)!.albumNotFound)),
      );
    }

    final totalDuration = _songs.fold<int>(
      0,
      (sum, song) => sum + (song.duration ?? 0),
    );
    final hours = totalDuration ~/ 3600;
    final minutes = (totalDuration % 3600) ~/ 60;

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 360,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      CupertinoIcons.back,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 60,
                          left: 40,
                          right: 40,
                          bottom: 80,
                        ),
                        child: AlbumArtwork(
                          coverArt: _album!.coverArt,
                          size: 280,
                          borderRadius: 10,
                          preserveAspectRatio: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _album!.name,
                        style: theme.textTheme.headlineLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () {
                          if (_album!.artistId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ArtistScreen(artistId: _album!.artistId!),
                              ),
                            );
                          }
                        },
                        child: Text(
                          _album!.artist ??
                              AppLocalizations.of(context)!.unknownArtist,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: AppTheme.appleMusicRed,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (_album!.genre != null)
                            _album!.genre!.toUpperCase(),
                          if (_album!.year != null) _album!.year.toString(),
                          if (hours > 0)
                            '$hours HR $minutes MIN'
                          else
                            '$minutes MIN',
                        ].join(' • '),
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: _PlayButton(
                              icon: CupertinoIcons.play_fill,
                              label: AppLocalizations.of(context)!.play,
                              onTap: () => _playAll(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _PlayButton(
                              icon: CupertinoIcons.shuffle,
                              label: AppLocalizations.of(context)!.shuffle,
                              onTap: () => _playAll(shuffle: true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final song = _songs[index];
                  return SongTile(
                    song: song,
                    playlist: _songs,
                    index: index,
                    showArtwork: false,
                    showTrackNumber: true,
                    showArtist: false,
                  );
                }, childCount: _songs.length),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 150)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PlayButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark
          ? AppTheme.appleMusicRed.withValues(alpha: 0.15)
          : AppTheme.appleMusicRed.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppTheme.appleMusicRed, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.appleMusicRed,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
