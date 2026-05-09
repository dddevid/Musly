import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/server_config.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../providers/providers.dart';
import '../services/subsonic_service.dart';
import '../services/local_music_service.dart';
import '../theme/app_theme.dart';
import '../utils/navigation_helper.dart';
import 'album_screen.dart';
import 'package:musly/screens/playlist_screen.dart';
import 'favorites_screen.dart';
import 'liked_albums_screen.dart';
import 'playlists_screen.dart';
import 'settings_screen.dart';
import 'library_search_delegate.dart';
import 'artist_screen.dart';
import 'radio_screen.dart';
import 'all_songs_screen.dart';
import '../l10n/app_localizations.dart';
import '../widgets/album_artwork.dart' show isLocalFilePath;

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _selectedFilter = 'Faves';

  List<String> _getFilters(BuildContext context) {
    final libraryProvider =
        Provider.of<LibraryProvider>(context, listen: false);
    if (libraryProvider.isLocalOnlyMode) {
      return ['Faves', 'Albums', 'Artists', 'Songs', 'Genres', 'Years'];
    }
    return ['Faves', 'Albums', 'Artists', 'Songs'];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            expandedHeight: 60,
            backgroundColor: isDark ? AppTheme.darkBackground : Colors.white,
            title: Text(
              AppLocalizations.of(context)!.yourLibrary,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  CupertinoIcons.refresh,
                  color: isDark ? Colors.white : Colors.black,
                ),
                onPressed: () {
                  final libraryProvider = Provider.of<LibraryProvider>(
                    context,
                    listen: false,
                  );
                  libraryProvider.refresh();
                },
              ),
              IconButton(
                icon: Icon(
                  CupertinoIcons.search,
                  color: isDark ? Colors.white : Colors.black,
                ),
                onPressed: () => _showLibrarySearch(context),
              ),
              IconButton(
                icon: Icon(
                  CupertinoIcons.plus,
                  color: isDark ? Colors.white : Colors.black,
                ),
                onPressed: () => _showCreatePlaylistDialog(context),
              ),
              IconButton(
                icon: Icon(
                  CupertinoIcons.gear,
                  color: isDark ? Colors.white : Colors.black,
                ),
                onPressed: () => _showSettings(context),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                final filters = _getFilters(context);
                final filterLabels = {
                  'Faves': l10n.faves,
                  'Albums': l10n.filterAlbums,
                  'Artists': l10n.filterArtists,
                  'Songs': l10n.songs,
                  'Genres': l10n.genres,
                  'Years': l10n.years,
                };
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filterLabels[filter]!),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = selected ? filter : 'Faves';
                            });
                          },
                          backgroundColor: isDark
                              ? const Color(0xFF282828)
                              : Colors.grey[200],
                          selectedColor: isDark ? Colors.white : Colors.black,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? (isDark ? Colors.black : Colors.white)
                                : (isDark ? Colors.white : Colors.black),
                            fontWeight: FontWeight.w500,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          side: BorderSide.none,
                          showCheckmark: false,
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                if (_selectedFilter == 'Faves') ...[
                  // Playlists folder
                  _SpotifyLibraryTile(
                    icon: CupertinoIcons.list_bullet,
                    iconColor: const Color(0xFF3B82F6),
                    title: AppLocalizations.of(context)!.playlists,
                    subtitle: AppLocalizations.of(context)!.yourPlaylists,
                    isGradient: false,
                    onTap: () => _navigate(context, const PlaylistsScreen()),
                  ),
                  // Liked Songs folder
                  _SpotifyLibraryTile(
                    icon: CupertinoIcons.heart_fill,
                    iconColor: const Color(0xFF8B5CF6),
                    title: AppLocalizations.of(context)!.likedSongs,
                    subtitle: AppLocalizations.of(context)!.playlist,
                    isGradient: true,
                    onTap: () => _navigate(context, const FavoritesScreen()),
                  ),
                  // All Songs folder
                  _SpotifyLibraryTile(
                    icon: CupertinoIcons.music_note_list,
                    iconColor: const Color(0xFF34C759),
                    title: AppLocalizations.of(context)!.songs,
                    subtitle: AppLocalizations.of(context)!.songs,
                    isGradient: false,
                    onTap: () => _navigate(context, const AllSongsScreen()),
                  ),
                  // Liked Albums folder
                  _SpotifyLibraryTile(
                    icon: CupertinoIcons.star_fill,
                    iconColor: const Color(0xFFFF9500),
                    title: AppLocalizations.of(context)!.likedAlbums,
                    subtitle: AppLocalizations.of(context)!.albums,
                    isGradient: false,
                    onTap: () => _navigate(context, const LikedAlbumsScreen()),
                  ),
                  // Radio Stations folder
                  _SpotifyLibraryTile(
                    icon: CupertinoIcons.antenna_radiowaves_left_right,
                    iconColor: const Color(0xFF34C759),
                    title: AppLocalizations.of(context)!.radioStations,
                    subtitle: AppLocalizations.of(context)!.internetRadio,
                    isGradient: false,
                    onTap: () => _navigate(context, const RadioScreen()),
                  ),
                ],
              ],
            ),
          ),
          Consumer<LibraryProvider>(
            builder: (context, libraryProvider, _) {
              final items = _getFilteredItems(context, libraryProvider);

              if (items.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _LibraryEmptyState(
                    isLocalMode: libraryProvider.isLocalOnlyMode,
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final item = items[index];
                  return _buildLibraryItem(context, item);
                }, childCount: items.length),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 150)),
        ],
      ),
    );
  }

  List<_LibraryItem> _getFilteredItems(
    BuildContext context,
    LibraryProvider provider,
  ) {
    final l10n = AppLocalizations.of(context)!;
    List<_LibraryItem> items = [];

    // Faves tab: show Playlists and Recent Albums
    if (_selectedFilter == 'Faves') {
      // Add playlists
      items.addAll(
        provider.playlists.map(
          (p) => _LibraryItem(
            type: 'Playlist',
            id: p.id,
            name: p.name,
            subtitle: l10n.songsCount(p.songCount ?? 0),
            coverArt: p.coverArt,
          ),
        ),
      );
      // Add recent albums (limited to 10)
      final recent = provider.isLocalOnlyMode
          ? provider.cachedAllAlbums.take(10).toList()
          : provider.recentAlbums.take(10).toList();
      items.addAll(
        recent.map(
          (a) => _LibraryItem(
            type: 'Album',
            id: a.id,
            name: a.name,
            subtitle:
                a.artistParticipants != null && a.artistParticipants!.isNotEmpty
                    ? a.artistParticipants!.map((r) => r.name).join(', ')
                    : (a.artist ?? ''),
            coverArt: a.coverArt,
          ),
        ),
      );
    }

    // Albums tab: show all albums
    if (_selectedFilter == 'Albums') {
      final albums = provider.isLocalOnlyMode
          ? provider.cachedAllAlbums
          : (provider.cachedAllAlbums.isNotEmpty
              ? provider.cachedAllAlbums
              : provider.recentAlbums);
      items.addAll(
        albums.map(
          (a) => _LibraryItem(
            type: 'Album',
            id: a.id,
            name: a.name,
            subtitle: () {
              final artistStr = a.artistParticipants != null &&
                      a.artistParticipants!.isNotEmpty
                  ? a.artistParticipants!.map((r) => r.name).join(', ')
                  : (a.artist ?? '');
              if (a.year != null && artistStr.isNotEmpty) {
                return '$artistStr • ${a.year}';
              }
              return artistStr.isNotEmpty
                  ? artistStr
                  : (a.year?.toString() ?? '');
            }(),
            coverArt: a.coverArt,
          ),
        ),
      );
    }

    if (_selectedFilter == 'Artists') {
      items.addAll(
        provider.artists.map(
          (a) => _LibraryItem(
            type: 'Artist',
            id: a.id,
            name: a.name,
            subtitle: l10n.albumsCount(a.albumCount ?? 0),
            coverArt: a.coverArt,
          ),
        ),
      );
    }

    if (_selectedFilter == 'Songs') {
      items.addAll(
        provider.cachedAllSongs.map(
          (s) => _LibraryItem(
            type: 'Song',
            id: s.id,
            name: s.title,
            subtitle: s.artist ?? '',
            coverArt: s.coverArt,
          ),
        ),
      );
    }

    if (_selectedFilter == 'Genres') {
      final genreMap = <String, List<Song>>{};
      for (final s in provider.cachedAllSongs) {
        final g = (s.genre ?? 'Unknown').trim();
        if (g.isEmpty) continue;
        genreMap.putIfAbsent(g, () => []).add(s);
      }
      final sortedGenres = genreMap.keys.toList()..sort();
      items.addAll(
        sortedGenres.map(
          (g) => _LibraryItem(
            type: 'Genre',
            id: 'genre_$g',
            name: g,
            subtitle: l10n.songsCount(genreMap[g]!.length),
            coverArt: genreMap[g]!
                    .firstWhere(
                      (s) => s.coverArt != null,
                      orElse: () => genreMap[g]!.first,
                    )
                    .coverArt ??
                '',
          ),
        ),
      );
    }

    if (_selectedFilter == 'Years') {
      final yearMap = <int, List<Album>>{};
      for (final a in provider.cachedAllAlbums) {
        if (a.year != null) {
          yearMap.putIfAbsent(a.year!, () => []).add(a);
        }
      }
      final sortedYears = yearMap.keys.toList()..sort((a, b) => b.compareTo(a));
      items.addAll(
        sortedYears.map(
          (y) => _LibraryItem(
            type: 'Year',
            id: 'year_$y',
            name: y.toString(),
            subtitle: l10n.albumsCount(yearMap[y]!.length),
            coverArt: yearMap[y]!
                    .firstWhere(
                      (a) => a.coverArt != null,
                      orElse: () => yearMap[y]!.first,
                    )
                    .coverArt ??
                '',
          ),
        ),
      );
    }

    return items;
  }

  Widget _buildLibraryItem(BuildContext context, _LibraryItem item) {
    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final coverArtUrl = item.coverArt != null
        ? (isLocalFilePath(item.coverArt)
            ? item.coverArt!
            : subsonicService.getCoverArtUrl(item.coverArt!, size: 120))
        : null;

    final String typeLabel = switch (item.type) {
      'Playlist' => l10n.filterPlaylists,
      'Album' => l10n.filterAlbums,
      'Artist' => l10n.filterArtists,
      'Song' => l10n.songs,
      _ => item.type,
    };

    final Widget artwork = ClipRRect(
      borderRadius: BorderRadius.circular(item.type == 'Artist' ? 28 : 4),
      child: SizedBox(
        width: 56,
        height: 56,
        child: coverArtUrl != null
            ? (isLocalFilePath(coverArtUrl)
                ? Image.file(
                    File(coverArtUrl),
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) =>
                        _buildPlaceholder(item.type, isDark),
                  )
                : CachedNetworkImage(
                    imageUrl: coverArtUrl,
                    fit: BoxFit.cover,
                    placeholder: (ctx, url) =>
                        Container(color: Colors.grey[800]),
                    errorWidget: (ctx, url, err) =>
                        _buildPlaceholder(item.type, isDark),
                  ))
            : _buildPlaceholder(item.type, isDark),
      ),
    );

    return InkWell(
      onTap: () => _openItem(context, item),
      onLongPress: item.type == 'Playlist'
          ? () => _showDeletePlaylistDialog(context, item)
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            artwork,
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$typeLabel • ${item.subtitle}',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String type, bool isDark) {
    IconData icon;
    switch (type) {
      case 'Playlist':
        icon = Icons.queue_music;
        break;
      case 'Album':
        icon = Icons.album;
        break;
      case 'Artist':
        icon = Icons.person;
        break;
      case 'Song':
        icon = Icons.music_note;
        break;
      case 'Genre':
        icon = Icons.local_offer;
        break;
      case 'Year':
        icon = Icons.calendar_today;
        break;
      default:
        icon = Icons.music_note;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2C2C2E), const Color(0xFF1C1C1E)]
              : [const Color(0xFFF2F2F7), const Color(0xFFE5E5EA)],
        ),
        borderRadius: BorderRadius.circular(type == 'Artist' ? 28 : 4),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 24,
          color: isDark ? Colors.white24 : Colors.black12,
        ),
      ),
    );
  }

  void _openItem(BuildContext context, _LibraryItem item) {
    switch (item.type) {
      case 'Playlist':
        NavigationHelper.push(
          context,
          PlaylistScreen(playlistId: item.id, playlistName: item.name),
        );
        break;
      case 'Album':
        NavigationHelper.push(context, AlbumScreen(albumId: item.id));
        break;
      case 'Artist':
        NavigationHelper.push(context, ArtistScreen(artistId: item.id));
        break;
      case 'Song':
        final libraryProvider = Provider.of<LibraryProvider>(
          context,
          listen: false,
        );
        final playerProvider = Provider.of<PlayerProvider>(
          context,
          listen: false,
        );
        final songs = libraryProvider.cachedAllSongs;
        final index = songs.indexWhere((s) => s.id == item.id);
        if (index >= 0) {
          playerProvider.playSong(
            songs[index],
            playlist: songs,
            startIndex: index,
          );
        }
        break;
      case 'Genre':
        final genreName = item.name;
        final libraryProvider = Provider.of<LibraryProvider>(
          context,
          listen: false,
        );
        final songs = libraryProvider.cachedAllSongs
            .where((s) => s.genre == genreName)
            .toList();
        if (songs.isNotEmpty) {
          final playerProvider = Provider.of<PlayerProvider>(
            context,
            listen: false,
          );
          playerProvider.playSong(songs.first, playlist: songs, startIndex: 0);
        }
        break;
      case 'Year':
        final yearStr = item.name;
        final libraryProvider = Provider.of<LibraryProvider>(
          context,
          listen: false,
        );
        final albums = libraryProvider.cachedAllAlbums
            .where((a) => a.year?.toString() == yearStr)
            .toList();
        if (albums.isNotEmpty) {
          NavigationHelper.push(context, AlbumScreen(albumId: albums.first.id));
        }
        break;
    }
  }

  void _navigate(BuildContext context, Widget screen) {
    NavigationHelper.push(context, screen);
  }

  void _showDeletePlaylistDialog(BuildContext context, _LibraryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deletePlaylist),
        content: Text(
          AppLocalizations.of(context)!.deletePlaylistConfirmation(item.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final libraryProvider = Provider.of<LibraryProvider>(
                context,
                listen: false,
              );
              try {
                await libraryProvider.deletePlaylist(item.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(
                          context,
                        )!
                            .playlistDeleted(item.name),
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.errorDeletingPlaylist(e),
                      ),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreatePlaylistDialog(BuildContext context) async {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.newPlaylist),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.playlistName,
              filled: true,
              fillColor:
                  isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final libraryProvider = Provider.of<LibraryProvider>(
                  context,
                  listen: false,
                );
                try {
                  await libraryProvider.createPlaylist(controller.text.trim());
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(
                            context,
                          )!
                              .playlistCreated(controller.text),
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(
                            context,
                          )!
                              .errorCreatingPlaylist(e),
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: Text(AppLocalizations.of(context)!.create),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  void _showLibrarySearch(BuildContext context) {
    final libraryProvider = Provider.of<LibraryProvider>(
      context,
      listen: false,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showSearch(
      context: context,
      delegate: LibrarySearchDelegate(
        libraryProvider: libraryProvider,
        isDark: isDark,
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const _SettingsSheet(),
    );
  }
}

class _LibraryEmptyState extends StatelessWidget {
  final bool isLocalMode;

  const _LibraryEmptyState({required this.isLocalMode});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_music_outlined,
            size: 64,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
          const SizedBox(height: 16),
          Text(
            isLocalMode ? l10n.localLibraryEmpty : l10n.libraryEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isLocalMode
                ? l10n.localLibraryEmptySubtitle
                : l10n.libraryEmptySubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
          if (isLocalMode) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                final localService = Provider.of<LocalMusicService>(
                  context,
                  listen: false,
                );
                if (!localService.isScanning) {
                  localService.scanForMusic();
                }
              },
              icon: const Icon(Icons.refresh),
              label: Text(l10n.scanForMusic),
              style: ElevatedButton.styleFrom(
                foregroundColor: isDark ? Colors.black : Colors.white,
                backgroundColor: isDark ? Colors.white : Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LibraryItem {
  final String type;
  final String id;
  final String name;
  final String subtitle;
  final String? coverArt;

  _LibraryItem({
    required this.type,
    required this.id,
    required this.name,
    required this.subtitle,
    this.coverArt,
  });
}

class _SpotifyLibraryTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isGradient;
  final VoidCallback? onTap;

  const _SpotifyLibraryTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.isGradient = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: isGradient
                    ? LinearGradient(
                        colors: [iconColor.withValues(alpha: 0.8), iconColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isGradient ? null : iconColor.withValues(alpha: 0.15),
              ),
              child: Icon(
                icon,
                color: isGradient ? Colors.white : iconColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)!.settingsTitle,
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              if (authProvider.config != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          isDark ? AppTheme.darkCard : AppTheme.lightBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          authProvider.state == AuthState.offlineMode
                              ? CupertinoIcons.wifi_slash
                              : CupertinoIcons.checkmark_circle_fill,
                          color: authProvider.state == AuthState.offlineMode
                              ? Colors.orange
                              : Colors.green,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                authProvider.state == AuthState.offlineMode
                                    ? AppLocalizations.of(context)!.offlineMode
                                    : AppLocalizations.of(context)!.connected,
                                style: theme.textTheme.titleMedium,
                              ),
                              Text(
                                authProvider.config!.serverUrl,
                                style: theme.textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        _buildSwitchServerButton(context),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              ListTile(
                leading: Icon(
                  CupertinoIcons.gear_alt,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                title: Text(AppLocalizations.of(context)!.settingsTitle),
                trailing: Icon(
                  CupertinoIcons.chevron_forward,
                  size: 18,
                  color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
                ),
                onTap: () {
                  Navigator.pop(context);
                  NavigationHelper.push(context, const SettingsScreen());
                },
              ),
              ListTile(
                leading: const Icon(
                  CupertinoIcons.arrow_right_square,
                  color: Colors.red,
                ),
                title: Text(AppLocalizations.of(context)!.logout),
                onTap: () async {
                  final playerProvider = Provider.of<PlayerProvider>(
                    context,
                    listen: false,
                  );
                  Navigator.pop(context);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(AppLocalizations.of(context)!.logout),
                      content: Text(
                        AppLocalizations.of(context)!.logoutConfirmation,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(AppLocalizations.of(context)!.cancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(
                            AppLocalizations.of(context)!.logout,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await playerProvider.stop();
                    await authProvider.logout();
                  }
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchServerButton(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<List<ServerConfig>>(
      future: authProvider.getSavedProfiles(),
      builder: (context, snapshot) {
        final profiles = snapshot.data ?? [];
        if (profiles.length < 2) return const SizedBox.shrink();

        return IconButton(
          onPressed: () => _showSwitchServerDialog(context),
          icon: Icon(
            CupertinoIcons.arrow_right_arrow_left,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
          ),
          tooltip: l10n.switchServer,
        );
      },
    );
  }

  void _showSwitchServerDialog(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).brightness == Brightness.dark
              ? AppTheme.darkSurface
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: Theme.of(ctx).brightness == Brightness.dark
                      ? AppTheme.darkDivider
                      : AppTheme.lightDivider,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.switchServer,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<ServerConfig>>(
                future: authProvider.getSavedProfiles(),
                builder: (context, snapshot) {
                  final profiles = snapshot.data ?? [];
                  final currentConfig = authProvider.config;
                  final otherProfiles = profiles
                      .where(
                        (p) =>
                            p.serverUrl != currentConfig?.serverUrl ||
                            p.username != currentConfig?.username,
                      )
                      .toList();

                  return Column(
                    children: otherProfiles.map((profile) {
                      final label = profile.name?.isNotEmpty == true
                          ? profile.name!
                          : '${profile.username}@${Uri.tryParse(profile.serverUrl)?.host ?? profile.serverUrl}';
                      return ListTile(
                        leading: const Icon(CupertinoIcons.person_crop_circle),
                        title: Text(label),
                        subtitle: Text(
                          profile.serverUrl,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () async {
                          Navigator.pop(ctx);
                          final playerProvider = Provider.of<PlayerProvider>(
                              context,
                              listen: false);
                          await playerProvider.stop();
                          await authProvider.switchProfile(profile);
                        },
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
