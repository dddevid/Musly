import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:musly/providers/providers.dart';
import 'package:musly/services/subsonic_service.dart';
import 'package:musly/theme/app_theme.dart';
import 'package:musly/widgets/common/album_artwork.dart';
import 'package:musly/utils/navigation_helper.dart';
import 'package:musly/screens/detail/album_screen.dart';
import 'package:musly/screens/detail/playlist_screen.dart';
import 'package:musly/screens/media/favorites_screen.dart';
import 'package:musly/screens/media/album_collection_screen.dart';
import 'library_search_delegate.dart';
import 'package:musly/screens/detail/artist_screen.dart';
import 'package:musly/screens/media/radio_screen.dart';
import 'package:musly/screens/media/downloads_screen.dart';
import 'package:musly/screens/auth/add_server_screen.dart';
import 'package:musly/l10n/app_localizations.dart';
import 'package:musly/services/offline_service.dart';
import 'package:musly/widgets/common/playlist_artwork.dart';
import 'package:musly/screens/settings/settings_screen.dart';
import 'package:musly/models/playlist.dart';
import 'package:musly/models/album.dart';
import 'package:musly/models/artist.dart';
import 'package:musly/models/song.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

enum _SortOption {
  recents,
  recentlyAdded,
  alphabetical,
  creator,
}

enum _LibraryItemType {
  likedSongs,
  downloadedSongs,
  radioStations,
  likedAlbums,
  playlist,
  album,
  artist,
  song,
}

class _LibraryItem {
  final _LibraryItemType type;
  final String title;
  final String subtitle;
  final dynamic data;
  final VoidCallback onTap;

  const _LibraryItem({
    required this.type,
    required this.title,
    required this.subtitle,
    this.data,
    required this.onTap,
  });
}

class _LibraryScreenState extends State<LibraryScreen> {
  String? _selectedFilter; // null (All) | 'Playlists' | 'Albums' | 'Artists' | 'Downloaded' | 'Songs'
  bool _isGridView = false;
  _SortOption _currentSort = _SortOption.recents;

  bool get _isDesktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  void _navigate(BuildContext context, Widget screen) {
    NavigationHelper.push(context, screen);
  }

  void _showLibrarySearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: LibrarySearchDelegate(
        libraryProvider: Provider.of<LibraryProvider>(context, listen: false),
        isDark: Theme.of(context).brightness == Brightness.dark,
      ),
    );
  }

  void _showAddMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(CupertinoIcons.music_note_list, color: Theme.of(context).colorScheme.primary, size: 22),
              ),
              title: Text(AppLocalizations.of(context)!.createPlaylist, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(AppLocalizations.of(context)!.createPlaylistSubtitle, style: const TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _showCreatePlaylistDialog(context);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.dns_rounded, color: Color(0xFF6366F1), size: 22),
              ),
              title: Text(AppLocalizations.of(context)!.addMusicSource, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(AppLocalizations.of(context)!.addMusicSourceSubtitle, style: const TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                NavigationHelper.push(context, const AddServerScreen());
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.createPlaylist),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.playlistName,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
                await libraryProvider.createPlaylist(name);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: Text(AppLocalizations.of(context)!.create),
          ),
        ],
      ),
    );
  }

  void _showSortMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // fix #230: account for mini player height (~80px) + system bottom inset
    // so all sort options are fully visible and tappable when a song is playing.
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom + 80.0 + 16.0;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Sort by',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            _buildSortOptionTile(ctx, 'Recents', _SortOption.recents),
            _buildSortOptionTile(ctx, 'Recently added', _SortOption.recentlyAdded),
            _buildSortOptionTile(ctx, 'Alphabetical', _SortOption.alphabetical),
            _buildSortOptionTile(ctx, 'Creator', _SortOption.creator),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOptionTile(BuildContext ctx, String title, _SortOption option) {
    final isSelected = _currentSort == option;
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
        ),
      ),
      trailing: isSelected
          ? Icon(CupertinoIcons.checkmark, color: Theme.of(context).colorScheme.primary, size: 18)
          : null,
      onTap: () {
        setState(() => _currentSort = option);
        Navigator.pop(ctx);
      },
    );
  }

  List<_LibraryItem> _getFilteredAndSortedItems({
    required BuildContext context,
    required LibraryProvider libraryProvider,
    required bool isDark,
    required bool isYoutube,
    required int downloadedCount,
    required AppLocalizations? l10n,
  }) {
    final items = <_LibraryItem>[];
    final offlineService = OfflineService();

    // Pinned Liked Songs
    if (_selectedFilter == null || _selectedFilter == 'Playlists') {
      items.add(
        _LibraryItem(
          type: _LibraryItemType.likedSongs,
          title: l10n?.likedSongs ?? 'Liked Songs',
          subtitle: 'Playlist • Favorites',
          onTap: () => _navigate(context, const FavoritesScreen()),
        ),
      );
    }

    // Pinned Downloaded Songs
    if (_selectedFilter == null || _selectedFilter == 'Downloaded') {
      items.add(
        _LibraryItem(
          type: _LibraryItemType.downloadedSongs,
          title: l10n?.downloadedSongs ?? 'Downloaded Songs',
          subtitle: '$downloadedCount songs saved offline',
          onTap: () => _navigate(context, const DownloadsScreen()),
        ),
      );
    }

    // Playlists
    if (_selectedFilter == null || _selectedFilter == 'Playlists') {
      var playlists = libraryProvider.playlists;
      playlists = _sortList(playlists, (p) => p.name);
      for (final p in playlists) {
        items.add(
          _LibraryItem(
            type: _LibraryItemType.playlist,
            title: p.name,
            subtitle: 'Playlist • ${p.songCount ?? 0} songs',
            data: p,
            onTap: () => _navigate(
              context,
              PlaylistScreen(playlistId: p.id, playlistName: p.name),
            ),
          ),
        );
      }
    }

    // Albums (only on server mode or when filtered)
    if ((_selectedFilter == null && !isYoutube) || _selectedFilter == 'Albums') {
      var albums = libraryProvider.recentAlbums;
      albums = _sortList(albums, (a) => a.name);
      for (final a in albums) {
        items.add(
          _LibraryItem(
            type: _LibraryItemType.album,
            title: a.name,
            subtitle: 'Album • ${a.artist}',
            data: a,
            onTap: () => _navigate(context, AlbumScreen(albumId: a.id)),
          ),
        );
      }
    }

    // Artists (only on server mode or when filtered)
    if ((_selectedFilter == null && !isYoutube) || _selectedFilter == 'Artists') {
      var artists = libraryProvider.artists;
      artists = _sortList(artists, (a) => a.name);
      for (final art in artists) {
        items.add(
          _LibraryItem(
            type: _LibraryItemType.artist,
            title: art.name,
            subtitle: 'Artist',
            data: art,
            onTap: () => _navigate(context, ArtistScreen(artistId: art.id)),
          ),
        );
      }
    }

    // Radio stations & Liked Albums shortcuts
    if (_selectedFilter == null && !isYoutube) {
      items.add(
        _LibraryItem(
          type: _LibraryItemType.radioStations,
          title: l10n?.radioStations ?? 'Radio Stations',
          subtitle: l10n?.radios ?? 'Radio',
          onTap: () => _navigate(context, const RadioScreen()),
        ),
      );
      items.add(
        _LibraryItem(
          type: _LibraryItemType.likedAlbums,
          title: l10n?.likedAlbums ?? 'Liked Albums',
          subtitle: l10n?.albums ?? 'Albums',
          onTap: () => _navigate(context, const LikedAlbumsScreen()),
        ),
      );
    }

    // Downloaded Filter items
    if (_selectedFilter == 'Downloaded') {
      final downloadedIds = offlineService.getDownloadedSongIds();
      final downloadedSongs = (libraryProvider.cachedAllSongs ?? [])
          .where((s) => downloadedIds.contains(s.id))
          .toList();
      for (final song in downloadedSongs) {
        items.add(
          _LibraryItem(
            type: _LibraryItemType.song,
            title: song.title,
            subtitle: song.artist ?? 'Unknown Artist',
            data: song,
            onTap: () {
              final player = Provider.of<PlayerProvider>(context, listen: false);
              player.playSong(song, playlist: downloadedSongs);
            },
          ),
        );
      }
    }

    // Songs Filter items
    if (_selectedFilter == 'Songs' && !isYoutube) {
      var allSongs = libraryProvider.cachedAllSongs ?? [];
      allSongs = _sortList(allSongs, (s) => s.title);
      for (final song in allSongs) {
        items.add(
          _LibraryItem(
            type: _LibraryItemType.song,
            title: song.title,
            subtitle: song.artist ?? 'Unknown Artist',
            data: song,
            onTap: () {
              final player = Provider.of<PlayerProvider>(context, listen: false);
              player.playSong(song, playlist: allSongs);
            },
          ),
        );
      }
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hPad = _isDesktop ? 32.0 : 16.0;
    final authProvider = Provider.of<AuthProvider>(context);
    final subsonicService = Provider.of<SubsonicService>(context);
    final isYoutube = subsonicService.isYoutube || authProvider.config?.isYoutube == true;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      body: Consumer<LibraryProvider>(
        builder: (context, libraryProvider, _) {
          return CustomScrollView(
            cacheExtent: 600.0,
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // 1. Header
              SliverAppBar(
                automaticallyImplyLeading: false,
                pinned: true,
                floating: true,
                expandedHeight: 120,
                backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: EdgeInsets.only(left: hPad, bottom: 44),
                  title: Text(
                    AppLocalizations.of(context)?.yourLibrary ?? 'Your Library',
                    style: TextStyle(
                      fontSize: _isDesktop ? 24 : 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(CupertinoIcons.search, color: isDark ? Colors.white : Colors.black87, size: 22),
                    tooltip: AppLocalizations.of(context)!.searchInLibrary,
                    onPressed: () => _showLibrarySearch(context),
                  ),
                  IconButton(
                    icon: Icon(CupertinoIcons.plus, color: isDark ? Colors.white : Colors.black87, size: 24),
                    tooltip: AppLocalizations.of(context)!.add,
                    onPressed: () => _showAddMenu(context),
                  ),
                  IconButton(
                    icon: Icon(CupertinoIcons.gear_alt, color: isDark ? Colors.white : Colors.black87, size: 22),
                    tooltip: AppLocalizations.of(context)!.settings,
                    onPressed: () => NavigationHelper.push(context, const SettingsScreen()),
                  ),
                  if (_isDesktop) const SizedBox(width: 12),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: Container(
                    height: 48,
                    padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 6),
                    alignment: Alignment.centerLeft,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          if (_selectedFilter != null) ...[
                            GestureDetector(
                              onTap: () => setState(() => _selectedFilter = null),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF282828) : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(CupertinoIcons.clear, size: 14, color: isDark ? Colors.white : Colors.black),
                              ),
                            ),
                          ],
                          _buildFilterChip('Playlists', AppLocalizations.of(context)?.playlists ?? 'Playlists', isDark),
                          const SizedBox(width: 8),
                          _buildFilterChip('Albums', AppLocalizations.of(context)?.albums ?? 'Albums', isDark),
                          const SizedBox(width: 8),
                          _buildFilterChip('Artists', AppLocalizations.of(context)?.artists ?? 'Artists', isDark),
                          const SizedBox(width: 8),
                          _buildFilterChip('Downloaded', AppLocalizations.of(context)?.downloadedSongs ?? 'Downloaded', isDark),
                          if (!isYoutube) ...[
                            const SizedBox(width: 8),
                            _buildFilterChip('Songs', AppLocalizations.of(context)?.songs ?? 'Songs', isDark),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Sort Option & Grid/List Toggle
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Sort Option Button
                      InkWell(
                        onTap: () => _showSortMenu(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                          child: Row(
                            children: [
                              const Icon(CupertinoIcons.arrow_up_arrow_down, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                switch (_currentSort) {
                                  _SortOption.recents => 'Recents',
                                  _SortOption.recentlyAdded => 'Recently added',
                                  _SortOption.alphabetical => 'Alphabetical',
                                  _SortOption.creator => 'Creator',
                                },
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // View Mode Toggle (List / Grid)
                      IconButton(
                        icon: Icon(
                          _isGridView ? CupertinoIcons.list_bullet : CupertinoIcons.square_grid_2x2,
                          size: 18,
                        ),
                        tooltip: _isGridView ? 'Switch to List' : 'Switch to Grid',
                        onPressed: () => setState(() => _isGridView = !_isGridView),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Dynamic Items (Virtual List or Virtual Grid for 60/120 FPS performance)
              if (_isGridView)
                _buildSliverGrid(context, libraryProvider, isDark, isYoutube, hPad)
              else
                _buildSliverList(context, libraryProvider, isDark, isYoutube, hPad),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, bool isDark) {
    final isSelected = _selectedFilter == key;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = isSelected ? null : key;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : (isDark ? const Color(0xFF282828) : const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? (ThemeData.estimateBrightnessForColor(Theme.of(context).colorScheme.primary) == Brightness.dark
                    ? Colors.white
                    : Colors.black)
                : (isDark ? Colors.white : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverList(
    BuildContext context,
    LibraryProvider libraryProvider,
    bool isDark,
    bool isYoutube,
    double hPad,
  ) {
    final offlineService = OfflineService();
    final downloadedCount = offlineService.getDownloadedSongIds().length;
    final l10n = AppLocalizations.of(context);

    final items = _getFilteredAndSortedItems(
      context: context,
      libraryProvider: libraryProvider,
      isDark: isDark,
      isYoutube: isYoutube,
      downloadedCount: downloadedCount,
      l10n: l10n,
    );

    if (items.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.music_albums,
                  size: 56,
                  color: isDark ? Colors.white30 : Colors.black26,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n?.noSongsFound ?? 'No items found in your library',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 8),
      sliver: SliverList.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return RepaintBoundary(
            child: _buildListItemTile(context, item, isDark),
          );
        },
      ),
    );
  }

  Widget _buildSliverGrid(
    BuildContext context,
    LibraryProvider libraryProvider,
    bool isDark,
    bool isYoutube,
    double hPad,
  ) {
    final offlineService = OfflineService();
    final downloadedCount = offlineService.getDownloadedSongIds().length;
    final l10n = AppLocalizations.of(context);

    final items = _getFilteredAndSortedItems(
      context: context,
      libraryProvider: libraryProvider,
      isDark: isDark,
      isYoutube: isYoutube,
      downloadedCount: downloadedCount,
      l10n: l10n,
    );

    if (items.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.music_albums,
                  size: 56,
                  color: isDark ? Colors.white30 : Colors.black26,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n?.noSongsFound ?? 'No items found in your library',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 8),
      sliver: SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _isDesktop ? 4 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
          childAspectRatio: 0.78,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return RepaintBoundary(
            child: _buildGridItemTile(context, item, isDark),
          );
        },
      ),
    );
  }

  Widget _buildListItemTile(
    BuildContext context,
    _LibraryItem item,
    bool isDark,
  ) {
    switch (item.type) {
      case _LibraryItemType.likedSongs:
        return _buildPinnedItemTile(
          title: item.title,
          subtitle: item.subtitle,
          gradientColors: const [Color(0xFF450AF5), Color(0xFF8E8EE5)],
          icon: CupertinoIcons.heart_fill,
          onTap: item.onTap,
        );

      case _LibraryItemType.downloadedSongs:
        return _buildPinnedItemTile(
          title: item.title,
          subtitle: item.subtitle,
          gradientColors: const [Color(0xFF006450), Color(0xFF00897B)],
          icon: CupertinoIcons.arrow_down_circle_fill,
          onTap: item.onTap,
        );

      case _LibraryItemType.radioStations:
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          leading: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFF34C759).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              CupertinoIcons.antenna_radiowaves_left_right,
              color: Color(0xFF34C759),
              size: 24,
            ),
          ),
          title: Text(
            item.title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            item.subtitle,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          onTap: item.onTap,
        );

      case _LibraryItemType.likedAlbums:
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          leading: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFFF9500).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              CupertinoIcons.star_fill,
              color: Color(0xFFFF9500),
              size: 24,
            ),
          ),
          title: Text(
            item.title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            item.subtitle,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          onTap: item.onTap,
        );

      case _LibraryItemType.playlist:
        final playlist = item.data as Playlist;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 54,
              height: 54,
              child: PlaylistArtwork(playlist: playlist, size: 54),
            ),
          ),
          title: Text(
            playlist.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            item.subtitle,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
            ),
          ),
          onTap: item.onTap,
        );

      case _LibraryItemType.album:
        final album = item.data as Album;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          leading: AlbumArtwork(
            coverArt: album.coverArt,
            size: 54,
            borderRadius: 6,
          ),
          title: Text(
            album.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            item.subtitle,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
            ),
          ),
          onTap: item.onTap,
        );

      case _LibraryItemType.artist:
        final artist = item.data as Artist;
        final coverArt = artist.coverArt ??
            artist.artistImageUrl ??
            (artist.id.isNotEmpty ? 'ar-${artist.id}' : null);
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          leading: AlbumArtwork(
            coverArt: coverArt,
            size: 54,
            borderRadius: 999,
          ),
          title: Text(
            artist.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            item.subtitle,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
            ),
          ),
          onTap: item.onTap,
        );

      case _LibraryItemType.song:
        final song = item.data as Song;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          leading: AlbumArtwork(
            coverArt: song.coverArt,
            size: 54,
            borderRadius: 6,
          ),
          title: Text(
            song.title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            item.subtitle,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
            ),
          ),
          onTap: item.onTap,
        );
    }
  }

  Widget _buildGridItemTile(
    BuildContext context,
    _LibraryItem item,
    bool isDark,
  ) {
    switch (item.type) {
      case _LibraryItemType.likedSongs:
        return _buildGridItemCard(
          title: item.title,
          subtitle: item.subtitle,
          customArtwork: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF450AF5), Color(0xFF8E8EE5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            child: const Center(
              child: Icon(CupertinoIcons.heart_fill, color: Colors.white, size: 36),
            ),
          ),
          onTap: item.onTap,
        );

      case _LibraryItemType.downloadedSongs:
        return _buildGridItemCard(
          title: item.title,
          subtitle: item.subtitle,
          customArtwork: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF006450), Color(0xFF00897B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            child: const Center(
              child: Icon(CupertinoIcons.arrow_down_circle_fill, color: Colors.white, size: 36),
            ),
          ),
          onTap: item.onTap,
        );

      case _LibraryItemType.radioStations:
        return _buildGridItemCard(
          title: item.title,
          subtitle: item.subtitle,
          customArtwork: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF34C759).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(CupertinoIcons.antenna_radiowaves_left_right, color: Color(0xFF34C759), size: 36),
            ),
          ),
          onTap: item.onTap,
        );

      case _LibraryItemType.likedAlbums:
        return _buildGridItemCard(
          title: item.title,
          subtitle: item.subtitle,
          customArtwork: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFF9500).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(CupertinoIcons.star_fill, color: Color(0xFFFF9500), size: 36),
            ),
          ),
          onTap: item.onTap,
        );

      case _LibraryItemType.playlist:
        final playlist = item.data as Playlist;
        return _buildGridItemCard(
          title: playlist.name,
          subtitle: item.subtitle,
          customArtwork: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: PlaylistArtwork(playlist: playlist, size: 240),
          ),
          onTap: item.onTap,
        );

      case _LibraryItemType.album:
        final album = item.data as Album;
        return _buildGridItemCard(
          title: album.name,
          subtitle: item.subtitle,
          imageUrl: album.coverArt,
          onTap: item.onTap,
        );

      case _LibraryItemType.artist:
        final artist = item.data as Artist;
        final coverArt = artist.coverArt ??
            artist.artistImageUrl ??
            (artist.id.isNotEmpty ? 'ar-${artist.id}' : null);
        return _buildGridItemCard(
          title: artist.name,
          subtitle: item.subtitle,
          imageUrl: coverArt,
          isRound: true,
          onTap: item.onTap,
        );

      case _LibraryItemType.song:
        final song = item.data as Song;
        return _buildGridItemCard(
          title: song.title,
          subtitle: item.subtitle,
          imageUrl: song.coverArt,
          onTap: item.onTap,
        );
    }
  }

  Widget _buildPinnedItemTile({
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradientColors),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.pin_fill, size: 12, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              subtitle,
              style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildGridItemCard({
    required String title,
    required String subtitle,
    String? imageUrl,
    Widget? customArtwork,
    bool isRound = false,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        crossAxisAlignment: isRound ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.0,
            child: customArtwork ??
                AlbumArtwork(
                  coverArt: imageUrl,
                  size: 240,
                  borderRadius: isRound ? 999 : 8,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  List<T> _sortList<T>(List<T> items, String Function(T) nameSelector) {
    final list = List<T>.from(items);
    switch (_currentSort) {
      case _SortOption.alphabetical:
        list.sort((a, b) => nameSelector(a).toLowerCase().compareTo(nameSelector(b).toLowerCase()));
        break;
      case _SortOption.recents:
      case _SortOption.recentlyAdded:
      case _SortOption.creator:
        // Preserves default recent or natural order
        break;
    }
    return list;
  }
}
