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
            physics: const BouncingScrollPhysics(),
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
                          _buildFilterChip('Playlists', 'Playlists', isDark),
                          const SizedBox(width: 8),
                          _buildFilterChip('Albums', 'Albums', isDark),
                          const SizedBox(width: 8),
                          _buildFilterChip('Artists', 'Artists', isDark),
                          const SizedBox(width: 8),
                          _buildFilterChip('Downloaded', 'Downloaded', isDark),
                          if (!isYoutube) ...[
                            const SizedBox(width: 8),
                            _buildFilterChip('Songs', 'Songs', isDark),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Modern music player design
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

              // 3. Dynamic Items (List View or Grid View)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 8),
                  child: _isGridView
                      ? _buildGridView(context, libraryProvider, isDark, isYoutube)
                      : _buildListView(context, libraryProvider, isDark, isYoutube),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 48)),
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

  Widget _buildListView(BuildContext context, LibraryProvider libraryProvider, bool isDark, bool isYoutube) {
    final offlineService = OfflineService();
    final downloadedCount = offlineService.getDownloadedSongIds().length;

    var playlists = libraryProvider.playlists;
    var albums = libraryProvider.recentAlbums;
    var artists = libraryProvider.artists;

    // Apply Sorting
    playlists = _sortList(playlists, (p) => p.name);
    albums = _sortList(albums, (a) => a.name);
    artists = _sortList(artists, (a) => a.name);

    return Column(
      children: [
        // Pinned Liked Songs tile (if no filter or Playlists filter)
        if (_selectedFilter == null || _selectedFilter == 'Playlists') ...[
          _buildPinnedItemTile(
            title: 'Liked Songs',
            subtitle: 'Playlist • Favorites',
            gradientColors: const [Color(0xFF450AF5), Color(0xFF8E8EE5)],
            icon: CupertinoIcons.heart_fill,
            onTap: () => _navigate(context, const FavoritesScreen()),
          ),
        ],

        // Pinned Downloaded tile (if no filter or Downloaded filter)
        if (_selectedFilter == null || _selectedFilter == 'Downloaded') ...[
          _buildPinnedItemTile(
            title: 'Downloaded Songs',
            subtitle: '$downloadedCount songs saved offline',
            gradientColors: const [Color(0xFF006450), Color(0xFF00897B)],
            icon: CupertinoIcons.arrow_down_circle_fill,
            onTap: () => _navigate(context, const DownloadsScreen()),
          ),
        ],

        // Playlists
        if (_selectedFilter == null || _selectedFilter == 'Playlists') ...[
          ...playlists.map((playlist) {
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
                'Playlist • ${playlist.songCount ?? 0} songs',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
                ),
              ),
              onTap: () => _navigate(context, PlaylistScreen(playlistId: playlist.id, playlistName: playlist.name)),
            );
          }),
        ],

        // Albums (only on server mode or when filtered)
        if ((_selectedFilter == null && !isYoutube) || _selectedFilter == 'Albums') ...[
          ...albums.map((album) {
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
                'Album • ${album.artist}',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
                ),
              ),
              onTap: () => _navigate(context, AlbumScreen(albumId: album.id)),
            );
          }),
        ],

        // Artists (only on server mode or when filtered)
        if ((_selectedFilter == null && !isYoutube) || _selectedFilter == 'Artists') ...[
          ...artists.map((artist) {
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              leading: AlbumArtwork(
                coverArt: artist.coverArt ??
                    artist.artistImageUrl ??
                    (artist.id.isNotEmpty ? 'ar-${artist.id}' : null),
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
                'Artist',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
                ),
              ),
              onTap: () => _navigate(context, ArtistScreen(artistId: artist.id)),
            );
          }),
        ],

        // Folders when no filter selected
        if (_selectedFilter == null && !isYoutube) ...[
          ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
            leading: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFF34C759).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(CupertinoIcons.antenna_radiowaves_left_right, color: Color(0xFF34C759), size: 24),
            ),
            title: Text(AppLocalizations.of(context)!.radioStations, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            subtitle: Text(AppLocalizations.of(context)!.radios, style: const TextStyle(fontSize: 13, color: Colors.grey)),
            onTap: () => _navigate(context, const RadioScreen()),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
            leading: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFFF9500).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(CupertinoIcons.star_fill, color: Color(0xFFFF9500), size: 24),
            ),
            title: Text(AppLocalizations.of(context)!.likedAlbums, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            subtitle: Text(AppLocalizations.of(context)!.albums, style: const TextStyle(fontSize: 13, color: Colors.grey)),
            onTap: () => _navigate(context, const LikedAlbumsScreen()),
          ),
        ],
      ],
    );
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

  Widget _buildGridView(BuildContext context, LibraryProvider libraryProvider, bool isDark, bool isYoutube) {
    final cols = _isDesktop ? 4 : 2;

    var playlists = libraryProvider.playlists;
    var albums = libraryProvider.recentAlbums;
    var artists = libraryProvider.artists;

    playlists = _sortList(playlists, (p) => p.name);
    albums = _sortList(albums, (a) => a.name);
    artists = _sortList(artists, (a) => a.name);

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = 12.0;
        final cardWidth = (constraints.maxWidth - spacing * (cols - 1)) / cols;

        return Wrap(
          spacing: spacing,
          runSpacing: 16,
          children: [
            // Pinned Liked Songs Card
            if (_selectedFilter == null || _selectedFilter == 'Playlists')
              SizedBox(
                width: cardWidth,
                child: _buildGridItemCard(
                  title: 'Liked Songs',
                  subtitle: 'Playlist • Favorites',
                  customArtwork: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF450AF5), Color(0xFF8E8EE5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Icon(CupertinoIcons.heart_fill, color: Colors.white, size: 36),
                    ),
                  ),
                  onTap: () => _navigate(context, const FavoritesScreen()),
                ),
              ),

            // Playlists
            if (_selectedFilter == null || _selectedFilter == 'Playlists')
              ...playlists.map((playlist) {
                return SizedBox(
                  width: cardWidth,
                  child: _buildGridItemCard(
                    title: playlist.name,
                    subtitle: 'Playlist • Musly',
                    customArtwork: PlaylistArtwork(playlist: playlist, size: cardWidth),
                    onTap: () => _navigate(context, PlaylistScreen(playlistId: playlist.id, playlistName: playlist.name)),
                  ),
                );
              }),

            // Albums (only on server mode or when filtered)
            if ((_selectedFilter == null && !isYoutube) || _selectedFilter == 'Albums')
              ...albums.map((album) {
                return SizedBox(
                  width: cardWidth,
                  child: _buildGridItemCard(
                    title: album.name,
                    subtitle: 'Album • ${album.artist}',
                    imageUrl: album.coverArt,
                    onTap: () => _navigate(context, AlbumScreen(albumId: album.id)),
                  ),
                );
              }),

            // Artists (only on server mode or when filtered)
            if ((_selectedFilter == null && !isYoutube) || _selectedFilter == 'Artists')
              ...artists.map((artist) {
                final coverArt = artist.coverArt ??
                    artist.artistImageUrl ??
                    (artist.id.isNotEmpty ? 'ar-${artist.id}' : null);
                return SizedBox(
                  width: cardWidth,
                  child: _buildGridItemCard(
                    title: artist.name,
                    subtitle: 'Artist',
                    imageUrl: coverArt,
                    isRound: true,
                    onTap: () => _navigate(context, ArtistScreen(artistId: artist.id)),
                  ),
                );
              }),
          ],
        );
      },
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
