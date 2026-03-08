import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../services/subsonic_service.dart';
import '../services/recommendation_service.dart';
import '../theme/app_theme.dart';
import '../utils/navigation_helper.dart';
import '../widgets/widgets.dart';
import 'album_screen.dart';
import 'playlist_screen.dart';
import 'history_screen.dart';
import '../l10n/app_localizations.dart';

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
    if (hour < 12) return AppLocalizations.of(context)!.goodMorning;
    if (hour < 17) return AppLocalizations.of(context)!.goodAfternoon;
    return AppLocalizations.of(context)!.goodEvening;
  }

  String _computeRandomKey(List<Song> songs) {
    if (songs.isEmpty) return '';
    
    return songs.map((s) => s.id).join('|');
  }

  bool get _isDesktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = _isDesktop;
    final hPad = isDesktop ? 32.0 : 16.0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            expandedHeight: isDesktop ? 80 : 70,
            backgroundColor: isDark ? AppTheme.darkBackground : Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(left: hPad, bottom: 14),
              title: Text(
                _getGreeting(),
                style: TextStyle(
                  fontSize: isDesktop ? 28 : 24,
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
                  NavigationHelper.push(context, const HistoryScreen());
                },
              ),
              if (isDesktop) const SizedBox(width: 8),
            ],
          ),

          SliverToBoxAdapter(
            child: Consumer2<LibraryProvider, RecommendationService>(
              builder: (context, libraryProvider, recommendationService, _) {
                if (libraryProvider.isLoading &&
                    !libraryProvider.isInitialized) {
                  return _buildLoadingState(isDesktop, hPad);
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

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: isDesktop ? 0 : 0),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (libraryProvider.recentAlbums.isNotEmpty ||
                        libraryProvider.playlists.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _QuickAccessGrid(
                        albums: libraryProvider.recentAlbums.take(isDesktop ? 6 : 4).toList(),
                        playlists: libraryProvider.playlists.take(isDesktop ? 3 : 2).toList(),
                        isDesktop: isDesktop,
                        hPad: hPad,
                      ),
                    ],

                    const SizedBox(height: 24),

                    if (recommendationService.enabled &&
                        personalizedFeed.isNotEmpty) ...[
                      _SectionTitle(title: AppLocalizations.of(context)!.forYou, icon: Icons.stars_rounded, hPad: hPad),
                      if (isDesktop) _DesktopSongTableHeader(hPad: hPad),
                      ...personalizedFeed.take(5).map((song) {
                        if (isDesktop) return _DesktopSongRow(song: song, playlist: personalizedFeed, index: personalizedFeed.indexOf(song), hPad: hPad);
                        return SongTile(song: song, playlist: personalizedFeed, index: personalizedFeed.indexOf(song), showAlbum: true);
                      }),
                      const SizedBox(height: 24),
                    ],

                    if (mixes.containsKey('Quick Picks')) ...[
                      _SectionTitle(title: AppLocalizations.of(context)!.quickPicks, icon: Icons.bolt_rounded, hPad: hPad),
                      if (isDesktop) _DesktopSongTableHeader(hPad: hPad),
                      ...mixes['Quick Picks']!.take(5).map((song) {
                        if (isDesktop) return _DesktopSongRow(song: song, playlist: mixes['Quick Picks']!, index: mixes['Quick Picks']!.indexOf(song), hPad: hPad);
                        return SongTile(song: song, playlist: mixes['Quick Picks']!, index: mixes['Quick Picks']!.indexOf(song), showAlbum: true);
                      }),
                      const SizedBox(height: 24),
                    ],

                    if (mixes.containsKey('Discover Mix')) ...[
                      _SectionTitle(title: AppLocalizations.of(context)!.discoverMix, icon: Icons.explore_rounded, hPad: hPad),
                      if (isDesktop) _DesktopSongTableHeader(hPad: hPad),
                      ...mixes['Discover Mix']!.take(5).map((song) {
                        if (isDesktop) return _DesktopSongRow(song: song, playlist: mixes['Discover Mix']!, index: mixes['Discover Mix']!.indexOf(song), hPad: hPad);
                        return SongTile(song: song, playlist: mixes['Discover Mix']!, index: mixes['Discover Mix']!.indexOf(song), showAlbum: true);
                      }),
                      const SizedBox(height: 24),
                    ],

                    for (final entry in mixes.entries.where(
                      (e) =>
                          e.key != 'Quick Picks' &&
                          e.key != 'Discover Mix' &&
                          !e.key.contains('Vibes'),
                    )) ...[
                      _SectionTitle(title: entry.key, icon: Icons.album_rounded, hPad: hPad),
                      if (isDesktop) _DesktopSongTableHeader(hPad: hPad),
                      ...entry.value.take(5).map((song) {
                        if (isDesktop) return _DesktopSongRow(song: song, playlist: entry.value, index: entry.value.indexOf(song), hPad: hPad);
                        return SongTile(song: song, playlist: entry.value, index: entry.value.indexOf(song), showAlbum: true);
                      }),
                      const SizedBox(height: 24),
                    ],

                    for (final entry in mixes.entries.where(
                      (e) => e.key.contains('Vibes'),
                    )) ...[
                      _SectionTitle(title: entry.key, icon: Icons.nightlight_round, hPad: hPad),
                      if (isDesktop) _DesktopSongTableHeader(hPad: hPad),
                      ...entry.value.take(5).map((song) {
                        if (isDesktop) return _DesktopSongRow(song: song, playlist: entry.value, index: entry.value.indexOf(song), hPad: hPad);
                        return SongTile(song: song, playlist: entry.value, index: entry.value.indexOf(song), showAlbum: true);
                      }),
                      const SizedBox(height: 24),
                    ],

                    if (libraryProvider.recentAlbums.isNotEmpty) ...[
                      HorizontalScrollSection(
                        title: AppLocalizations.of(context)!.recentlyPlayed,
                        padding: EdgeInsets.symmetric(horizontal: hPad),
                        cardSize: isDesktop ? 180 : 150,
                        children: libraryProvider.recentAlbums
                            .take(10)
                            .map(
                              (album) => AlbumCard(
                                album: album,
                                size: isDesktop ? 180 : 150,
                                onTap: () => _openAlbum(context, album.id),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    if (libraryProvider.playlists.isNotEmpty) ...[
                      HorizontalScrollSection(
                        title: AppLocalizations.of(context)!.yourPlaylists,
                        padding: EdgeInsets.symmetric(horizontal: hPad),
                        cardSize: isDesktop ? 180 : 150,
                        children: libraryProvider.playlists
                            .take(10)
                            .map(
                              (playlist) => _PlaylistCard(
                                playlist: playlist,
                                size: isDesktop ? 180 : 150,
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
                      _SectionTitle(title: AppLocalizations.of(context)!.madeForYou, hPad: hPad),
                      if (isDesktop) _DesktopSongTableHeader(hPad: hPad),
                      ...libraryProvider.randomSongs.take(5).map((song) {
                        final index = libraryProvider.randomSongs.indexOf(song);
                        if (isDesktop) return _DesktopSongRow(song: song, playlist: libraryProvider.randomSongs, index: index, hPad: hPad);
                        return SongTile(song: song, playlist: libraryProvider.randomSongs, index: index, showAlbum: true);
                      }),
                      const SizedBox(height: 24),
                    ],

                    if (libraryProvider.recentAlbums.isEmpty &&
                        libraryProvider.playlists.isEmpty &&
                        libraryProvider.randomSongs.isEmpty &&
                        mixes.isEmpty) ...[
                      const SizedBox(height: 48),
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.music_note_rounded,
                              size: 64,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(context)!.noContentAvailable,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppLocalizations.of(context)!.tryRefreshing,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () => libraryProvider.refresh(),
                              icon: const Icon(Icons.refresh),
                              label: Text(
                                AppLocalizations.of(context)!.refresh,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 150),
                  ],
                ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isDesktop, double hPad) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isDesktop ? 3 : 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 3.5,
            children: List.generate(
              isDesktop ? 6 : 6,
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
          child: AlbumCardShimmer(size: isDesktop ? 180 : 150),
        ),
      ],
    );
  }

  void _openAlbum(BuildContext context, String albumId) {
    NavigationHelper.push(context, AlbumScreen(albumId: albumId));
  }
}

class _QuickAccessGrid extends StatelessWidget {
  final List<dynamic> albums;
  final List<dynamic> playlists;
  final bool isDesktop;
  final double hPad;

  const _QuickAccessGrid({
    required this.albums,
    required this.playlists,
    this.isDesktop = false,
    this.hPad = 16,
  });

  @override
  Widget build(BuildContext context) {
    final raw = [...albums, ...playlists].take(isDesktop ? 9 : 6).toList();

    final items = (!isDesktop && raw.length.isOdd)
        ? raw.sublist(0, raw.length - 1)
        : raw;

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final subsonicService = Provider.of<SubsonicService>(context, listen: false);

    if (isDesktop) {
      
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: hPad),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 280,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 3.2,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) =>
              _buildTile(context, items[index], subsonicService),
        ),
      );
    }

    const tileHeight = 56.0;
    const spacing = 8.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tileWidth = (constraints.maxWidth - spacing) / 2;
          final ratio = tileWidth / tileHeight;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              childAspectRatio: ratio,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) =>
                _buildTile(context, items[index], subsonicService),
          );
        },
      ),
    );
  }

  Widget _buildTile(
    BuildContext context,
    dynamic item,
    SubsonicService subsonicService,
  ) {
    final isPlaylist = item.runtimeType.toString().contains('Playlist');
    String? imageUrl;
    String title;
    VoidCallback onTap;

    if (isPlaylist) {
      title = item.name;
      imageUrl = item.coverArt != null
          ? (isLocalFilePath(item.coverArt)
                ? item.coverArt
                : subsonicService.getCoverArtUrl(item.coverArt!, size: 100))
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
          ? (isLocalFilePath(item.coverArt)
                ? item.coverArt
                : subsonicService.getCoverArtUrl(item.coverArt!, size: 100))
          : null;
      onTap = () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AlbumScreen(albumId: item.id)),
      );
    }

    return _QuickAccessTile(title: title, imageUrl: imageUrl, onTap: onTap);
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
                    ? (isLocalFilePath(imageUrl)
                          ? Image.file(
                              File(imageUrl!),
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, e, _) => Container(
                                color: Colors.grey[800],
                                child: const Icon(
                                  Icons.music_note,
                                  color: Colors.white30,
                                ),
                              ),
                            )
                          : CachedNetworkImage(
                              imageUrl: imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (ctx, e) =>
                                  Container(color: Colors.grey[800]),
                              errorWidget: (ctx, e, _) => Container(
                                color: Colors.grey[800],
                                child: const Icon(
                                  Icons.music_note,
                                  color: Colors.white30,
                                ),
                              ),
                            ))
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
  final double size;

  const _PlaylistCard({required this.playlist, this.onTap, this.size = 150});

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
        width: size,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
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
                        placeholder: (_, _) => Container(
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
                        errorWidget: (_, _, _) => Container(
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData? icon;
  final double hPad;

  const _SectionTitle({required this.title, this.icon, this.hPad = 16});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: AppTheme.appleMusicRed),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopSongTableHeader extends StatelessWidget {
  final double hPad;
  const _DesktopSongTableHeader({this.hPad = 16});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.1,
      color: isDark ? Colors.white38 : Colors.black38,
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 4),
      child: Row(
        children: [
          SizedBox(width: 32, child: Text('#', style: labelStyle, textAlign: TextAlign.center)),
          const SizedBox(width: 12),
          const SizedBox(width: 40), 
          const SizedBox(width: 12),
          Expanded(flex: 5, child: Text('TITLE', style: labelStyle)),
          Expanded(flex: 3, child: Text('ALBUM', style: labelStyle)),
          const SizedBox(width: 40),
          SizedBox(width: 52, child: Text('TIME', style: labelStyle, textAlign: TextAlign.right)),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _DesktopSongRow extends StatefulWidget {
  final Song song;
  final List<Song> playlist;
  final int index;
  final double hPad;

  const _DesktopSongRow({
    required this.song,
    required this.playlist,
    required this.index,
    this.hPad = 16,
  });

  @override
  State<_DesktopSongRow> createState() => _DesktopSongRowState();
}

class _DesktopSongRowState extends State<_DesktopSongRow> {
  bool _hovered = false;

  String _formatDuration(int? seconds) {
    if (seconds == null) return '--:--';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final song = widget.song;
    final subsonicService = Provider.of<SubsonicService>(context, listen: false);

    final isPlaying = context.select<PlayerProvider, bool>(
      (p) => (p.currentSong?.id == song.id) && p.isPlaying,
    );

    final rowBg = _hovered
        ? (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04))
        : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.read<PlayerProvider>().playSong(song, playlist: widget.playlist, startIndex: widget.index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: rowBg,
          padding: EdgeInsets.fromLTRB(widget.hPad, 6, widget.hPad, 6),
          child: Row(
            children: [
              
              SizedBox(
                width: 32,
                child: Center(
                  child: _hovered
                      ? Icon(Icons.play_arrow_rounded, size: 18,
                          color: isDark ? Colors.white : Colors.black)
                      : isPlaying
                          ? Icon(Icons.bar_chart_rounded, size: 18,
                              color: AppTheme.appleMusicRed)
                          : Text(
                              '${widget.index + 1}',
                              style: TextStyle(
                                fontSize: 13,
                                color: isPlaying
                                    ? AppTheme.appleMusicRed
                                    : (isDark ? Colors.white60 : Colors.black54),
                              ),
                              textAlign: TextAlign.center,
                            ),
                ),
              ),
              const SizedBox(width: 12),
              
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: song.coverArt != null
                      ? CachedNetworkImage(
                          imageUrl: subsonicService.getCoverArtUrl(song.coverArt!, size: 80),
                          fit: BoxFit.cover,
                          placeholder: (_, _) => Container(color: Colors.grey[800]),
                          errorWidget: (_, _, _) => Container(color: Colors.grey[800],
                              child: const Icon(Icons.music_note, size: 16, color: Colors.white30)),
                        )
                      : Container(color: Colors.grey[800],
                          child: const Icon(Icons.music_note, size: 16, color: Colors.white30)),
                ),
              ),
              const SizedBox(width: 12),
              
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      song.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isPlaying
                            ? AppTheme.appleMusicRed
                            : (isDark ? Colors.white : Colors.black),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (song.artist != null)
                      Text(
                        song.artist!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              
              Expanded(
                flex: 3,
                child: Text(
                  song.album ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              SizedBox(
                width: 40,
                child: _hovered || song.starred == true
                    ? IconButton(
                        icon: Icon(
                          song.starred == true
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 16,
                          color: song.starred == true
                              ? AppTheme.appleMusicRed
                              : (isDark ? Colors.white38 : Colors.black38),
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          context.read<PlayerProvider>().toggleFavoriteForSong(song);
                        },
                      )
                    : const SizedBox.shrink(),
              ),
              
              SizedBox(
                width: 52,
                child: Text(
                  _formatDuration(song.duration),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
