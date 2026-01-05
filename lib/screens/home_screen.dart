import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../providers/library_provider.dart';
import '../services/subsonic_service.dart';
import '../services/recommendation_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'album_screen.dart';
import 'playlist_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, List<Song>> _cachedMixes = const {};
  List<Song> _cachedPersonalized = const [];
  String _lastRandomKey = '';

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _computeRandomKey(List<Song> songs) {
    if (songs.isEmpty) return '';
    // Stable key based on song ids to avoid regenerating mixes on every rebuild.
    return songs.map((s) => s.id).join('|');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      bottomNavigationBar: const MiniPlayer(),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            expandedHeight: 70,
            backgroundColor: isDark ? AppTheme.darkBackground : Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 12),
              title: Text(
                _getGreeting(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  CupertinoIcons.clock,
                  color: isDark ? Colors.white : Colors.black,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HistoryScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Consumer2<LibraryProvider, RecommendationService>(
              builder: (context, libraryProvider, recommendationService, _) {
                if (libraryProvider.isLoading &&
                    !libraryProvider.isInitialized) {
                  return _buildLoadingState();
                }

                final allSongs = libraryProvider.randomSongs;
                final key = _computeRandomKey(allSongs);

                if (recommendationService.enabled && key.isNotEmpty) {
                  if (key != _lastRandomKey) {
                    _cachedMixes = recommendationService.generateMixes(
                      allSongs,
                    );
                    _cachedPersonalized = recommendationService
                        .getPersonalizedFeed(allSongs, limit: 10);
                    _lastRandomKey = key;
                  }
                } else {
                  _cachedMixes = const {};
                  _cachedPersonalized = const [];
                  _lastRandomKey = '';
                }

                final mixes = _cachedMixes;
                final personalizedFeed = _cachedPersonalized;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (libraryProvider.recentAlbums.isNotEmpty ||
                        libraryProvider.playlists.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _QuickAccessGrid(
                        albums: libraryProvider.recentAlbums.take(4).toList(),
                        playlists: libraryProvider.playlists.take(2).toList(),
                      ),
                    ],

                    const SizedBox(height: 24),

                    if (recommendationService.enabled &&
                        personalizedFeed.isNotEmpty) ...[
                      const SectionHeader(
                        title: 'For You',
                        icon: Icons.stars_rounded,
                      ),
                      ...personalizedFeed.take(5).map((song) {
                        return SongTile(
                          song: song,
                          playlist: personalizedFeed,
                          index: personalizedFeed.indexOf(song),
                          showAlbum: true,
                        );
                      }),
                      const SizedBox(height: 24),
                    ],

                    if (mixes.containsKey('Quick Picks')) ...[
                      const SectionHeader(
                        title: 'Quick Picks',
                        icon: Icons.bolt_rounded,
                      ),
                      ...mixes['Quick Picks']!.take(5).map((song) {
                        return SongTile(
                          song: song,
                          playlist: mixes['Quick Picks']!,
                          index: mixes['Quick Picks']!.indexOf(song),
                          showAlbum: true,
                        );
                      }),
                      const SizedBox(height: 24),
                    ],

                    if (mixes.containsKey('Discover Mix')) ...[
                      const SectionHeader(
                        title: 'Discover Mix',
                        icon: Icons.explore_rounded,
                      ),
                      ...mixes['Discover Mix']!.take(5).map((song) {
                        return SongTile(
                          song: song,
                          playlist: mixes['Discover Mix']!,
                          index: mixes['Discover Mix']!.indexOf(song),
                          showAlbum: true,
                        );
                      }),
                      const SizedBox(height: 24),
                    ],

                    for (final entry in mixes.entries.where(
                      (e) =>
                          e.key != 'Quick Picks' &&
                          e.key != 'Discover Mix' &&
                          !e.key.contains('Vibes'),
                    )) ...[
                      SectionHeader(
                        title: entry.key,
                        icon: Icons.album_rounded,
                      ),
                      ...entry.value.take(5).map((song) {
                        return SongTile(
                          song: song,
                          playlist: entry.value,
                          index: entry.value.indexOf(song),
                          showAlbum: true,
                        );
                      }),
                      const SizedBox(height: 24),
                    ],

                    for (final entry in mixes.entries.where(
                      (e) => e.key.contains('Vibes'),
                    )) ...[
                      SectionHeader(
                        title: entry.key,
                        icon: Icons.nightlight_round,
                      ),
                      ...entry.value.take(5).map((song) {
                        return SongTile(
                          song: song,
                          playlist: entry.value,
                          index: entry.value.indexOf(song),
                          showAlbum: true,
                        );
                      }),
                      const SizedBox(height: 24),
                    ],

                    if (libraryProvider.recentAlbums.isNotEmpty) ...[
                      HorizontalScrollSection(
                        title: 'Recently Played',
                        children: libraryProvider.recentAlbums
                            .take(10)
                            .map(
                              (album) => AlbumCard(
                                album: album,
                                size: 150,
                                onTap: () => _openAlbum(context, album.id),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    if (libraryProvider.playlists.isNotEmpty) ...[
                      HorizontalScrollSection(
                        title: 'Your Playlists',
                        children: libraryProvider.playlists
                            .take(10)
                            .map(
                              (playlist) => _PlaylistCard(
                                playlist: playlist,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PlaylistScreen(
                                      playlistId: playlist.id,
                                      playlistName: playlist.name,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    if (!recommendationService.enabled &&
                        libraryProvider.randomSongs.isNotEmpty) ...[
                      const SectionHeader(title: 'Made For You'),
                      ...libraryProvider.randomSongs.take(5).map((song) {
                        final index = libraryProvider.randomSongs.indexOf(song);
                        return SongTile(
                          song: song,
                          playlist: libraryProvider.randomSongs,
                          index: index,
                          showAlbum: true,
                        );
                      }),
                      const SizedBox(height: 24),
                    ],

                    const SizedBox(height: 150),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 3.5,
            children: List.generate(
              6,
              (_) => Container(
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        HorizontalShimmerList(
          count: 5,
          child: const AlbumCardShimmer(size: 150),
        ),
      ],
    );
  }

  void _openAlbum(BuildContext context, String albumId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => AlbumScreen(albumId: albumId)),
    );
  }
}

class _QuickAccessGrid extends StatelessWidget {
  final List<dynamic> albums;
  final List<dynamic> playlists;

  const _QuickAccessGrid({required this.albums, required this.playlists});

  @override
  Widget build(BuildContext context) {
    final items = [...albums, ...playlists].take(6).toList();

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 220,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.8,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isPlaylist = item.runtimeType.toString().contains('Playlist');
          final subsonicService = Provider.of<SubsonicService>(
            context,
            listen: false,
          );

          String? imageUrl;
          String title;
          VoidCallback onTap;

          if (isPlaylist) {
            title = item.name;
            imageUrl = item.coverArt != null
                ? subsonicService.getCoverArtUrl(item.coverArt!, size: 100)
                : null;
            onTap = () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlaylistScreen(
                  playlistId: item.id,
                  playlistName: item.name,
                ),
              ),
            );
          } else {
            title = item.name;
            imageUrl = item.coverArt != null
                ? subsonicService.getCoverArtUrl(item.coverArt!, size: 100)
                : null;
            onTap = () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AlbumScreen(albumId: item.id),
              ),
            );
          }

          return _QuickAccessTile(
            title: title,
            imageUrl: imageUrl,
            onTap: onTap,
          );
        },
      ),
    );
  }
}

class _QuickAccessTile extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final VoidCallback onTap;

  const _QuickAccessTile({
    required this.title,
    this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF282828) : Colors.grey[200],
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(4),
              ),
              child: SizedBox(
                width: 48,
                height: 48,
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: Colors.grey[800]),
                        errorWidget: (_, __, ___) => Container(
                          color: Colors.grey[800],
                          child: const Icon(
                            Icons.music_note,
                            color: Colors.white30,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.music_note,
                          color: Colors.white30,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final dynamic playlist;
  final VoidCallback? onTap;

  const _PlaylistCard({required this.playlist, this.onTap});

  @override
  Widget build(BuildContext context) {
    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final coverArtUrl = playlist.coverArt != null
        ? subsonicService.getCoverArtUrl(playlist.coverArt!, size: 300)
        : null;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: coverArtUrl != null
                    ? CachedNetworkImage(
                        imageUrl: coverArtUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: isDark
                              ? const Color(0xFF2C2C2E)
                              : Colors.grey[300],
                          child: const Center(
                            child: Icon(
                              Icons.queue_music_rounded,
                              size: 50,
                              color: Colors.white30,
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: isDark
                              ? const Color(0xFF2C2C2E)
                              : Colors.grey[300],
                          child: const Center(
                            child: Icon(
                              Icons.queue_music_rounded,
                              size: 50,
                              color: Colors.white30,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color: isDark
                            ? const Color(0xFF2C2C2E)
                            : Colors.grey[300],
                        child: const Center(
                          child: Icon(
                            Icons.queue_music_rounded,
                            size: 50,
                            color: Colors.white30,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              playlist.name,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            if (playlist.songCount != null)
              Text(
                '${playlist.songCount} songs',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
