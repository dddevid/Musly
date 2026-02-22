import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/providers.dart';
import '../providers/library_provider.dart';
import '../services/subsonic_service.dart';
import '../theme/app_theme.dart';
import '../utils/navigation_helper.dart';
import 'album_screen.dart';
import 'package:musly/screens/playlist_screen.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';
import 'all_albums_screen.dart';
import 'all_songs_screen.dart';
import 'library_search_delegate.dart';
import 'artist_screen.dart';
import 'radio_screen.dart';
import '../l10n/app_localizations.dart';
import '../widgets/album_artwork.dart' show isLocalFilePath;

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Playlists', 'Albums', 'Artists'];

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
              // Code from https://github.com/dingtwo/Musly
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
                final filterLabels = {
                  'All': l10n.filterAll,
                  'Playlists': l10n.filterPlaylists,
                  'Albums': l10n.filterAlbums,
                  'Artists': l10n.filterArtists,
                };
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filterLabels[filter]!),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = selected ? filter : 'All';
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
                if (_selectedFilter == 'All') ...[
                  _SpotifyLibraryTile(
                    icon: CupertinoIcons.heart_fill,
                    iconColor: const Color(0xFF8B5CF6),
                    title: AppLocalizations.of(context)!.likedSongs,
                    subtitle: AppLocalizations.of(context)!.playlist,
                    isGradient: true,
                    onTap: () => _navigate(context, const FavoritesScreen()),
                  ),
                  _SpotifyLibraryTile(
                    icon: CupertinoIcons.music_albums,
                    iconColor: const Color(0xFFEC4899),
                    title: AppLocalizations.of(context)!.allAlbums,
                    subtitle: AppLocalizations.of(context)!.filterAlbums,
                    isGradient: false,
                    onTap: () => _navigate(context, const AllAlbumsScreen()),
                  ),
                  _SpotifyLibraryTile(
                    icon: CupertinoIcons.music_note_list,
                    iconColor: const Color(0xFF10B981),
                    title: AppLocalizations.of(context)!.allSongs,
                    subtitle: AppLocalizations.of(context)!.songs,
                    isGradient: false,
                    onTap: () => _navigate(context, const AllSongsScreen()),
                  ),
                  _SpotifyLibraryTile(
                    icon: CupertinoIcons.radiowaves_right,
                    iconColor: const Color(0xFF3B82F6),
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

    if (_selectedFilter == 'All' || _selectedFilter == 'Playlists') {
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
    }

    if (_selectedFilter == 'All' || _selectedFilter == 'Albums') {
      // In local mode use all cached albums; otherwise recent albums (max 20)
      final albums = provider.isLocalOnlyMode
          ? provider.cachedAllAlbums
          : provider.recentAlbums.take(20).toList();
      items.addAll(
        albums.map(
          (a) => _LibraryItem(
            type: 'Album',
            id: a.id,
            name: a.name,
            subtitle: a.artist ?? '',
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
      default:
        icon = Icons.music_note;
    }

    return Container(
      color: isDark ? const Color(0xFF282828) : Colors.grey[300],
      child: Icon(icon, color: Colors.white54),
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
                        )!.playlistDeleted(item.name),
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

  void _showCreatePlaylistDialog(BuildContext context) {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
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
              fillColor: isDark
                  ? const Color(0xFF2C2C2E)
                  : const Color(0xFFF2F2F7),
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
                          )!.playlistCreated(controller.text),
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
                          )!.errorCreatingPlaylist(e),
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
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 13,
                    ),
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
                    color: isDark
                        ? AppTheme.darkCard
                        : AppTheme.lightBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.checkmark_circle_fill,
                        color: Colors.green,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.connected,
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
                Navigator.pop(context);
                await authProvider.logout();
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
