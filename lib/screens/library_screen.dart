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
import 'package:musly/screens/genres_screen.dart';
import 'package:musly/screens/playlist_screen.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';
import 'all_albums_screen.dart';
import 'all_songs_screen.dart';
import 'search_screen.dart';
import 'library_search_delegate.dart';
import 'artist_screen.dart';
import 'radio_screen.dart';

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
              'Your Library',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            actions: [
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
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
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
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                if (_selectedFilter == 'All') ...[
                  _SpotifyLibraryTile(
                    icon: CupertinoIcons.heart_fill,
                    iconColor: const Color(0xFF8B5CF6),
                    title: 'Liked Songs',
                    subtitle: 'Playlist',
                    isGradient: true,
                    onTap: () => _navigate(context, const FavoritesScreen()),
                  ),
                  _SpotifyLibraryTile(
                    icon: CupertinoIcons.music_albums,
                    iconColor: const Color(0xFFEC4899),
                    title: 'All Albums',
                    subtitle: 'Albums',
                    isGradient: false,
                    onTap: () => _navigate(context, const AllAlbumsScreen()),
                  ),
                  _SpotifyLibraryTile(
                    icon: CupertinoIcons.music_note_list,
                    iconColor: const Color(0xFF10B981),
                    title: 'All Songs',
                    subtitle: 'Songs',
                    isGradient: false,
                    onTap: () => _navigate(context, const AllSongsScreen()),
                  ),
                  _SpotifyLibraryTile(
                    icon: CupertinoIcons.radiowaves_right,
                    iconColor: const Color(0xFF3B82F6),
                    title: 'Radio Stations',
                    subtitle: 'Internet Radio',
                    isGradient: false,
                    onTap: () => _navigate(context, const RadioScreen()),
                  ),
                ],
              ],
            ),
          ),

          Consumer<LibraryProvider>(
            builder: (context, libraryProvider, _) {
              final items = _getFilteredItems(libraryProvider);

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

  List<_LibraryItem> _getFilteredItems(LibraryProvider provider) {
    List<_LibraryItem> items = [];

    if (_selectedFilter == 'All' || _selectedFilter == 'Playlists') {
      items.addAll(
        provider.playlists.map(
          (p) => _LibraryItem(
            type: 'Playlist',
            id: p.id,
            name: p.name,
            subtitle: '${p.songCount ?? 0} songs',
            coverArt: p.coverArt,
          ),
        ),
      );
    }

    if (_selectedFilter == 'All' || _selectedFilter == 'Albums') {
      items.addAll(
        provider.recentAlbums
            .take(20)
            .map(
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
            subtitle: '${a.albumCount ?? 0} albums',
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
    final coverArtUrl = item.coverArt != null
        ? subsonicService.getCoverArtUrl(item.coverArt!, size: 120)
        : null;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(item.type == 'Artist' ? 28 : 4),
        child: SizedBox(
          width: 56,
          height: 56,
          child: coverArtUrl != null
              ? CachedNetworkImage(
                  imageUrl: coverArtUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: Colors.grey[800]),
                  errorWidget: (_, __, ___) =>
                      _buildPlaceholder(item.type, isDark),
                )
              : _buildPlaceholder(item.type, isDark),
        ),
      ),
      title: Text(
        item.name,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${item.type} • ${item.subtitle}',
        style: TextStyle(
          color: isDark ? Colors.white60 : Colors.black54,
          fontSize: 13,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => _openItem(context, item),
      onLongPress: item.type == 'Playlist'
          ? () => _showDeletePlaylistDialog(context, item)
          : null,
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
        title: const Text('Elimina Playlist'),
        content: Text(
          'Sei sicuro di voler eliminare la playlist "${item.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
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
                      content: Text('Playlist "${item.name}" eliminata'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Errore: $e'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Elimina'),
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
        title: const Text('New Playlist'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Playlist name',
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
            child: const Text('Cancel'),
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
                        content: Text('Playlist "${controller.text}" created'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Create'),
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

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          gradient: isGradient
              ? LinearGradient(
                  colors: [iconColor.withOpacity(0.8), iconColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isGradient ? null : iconColor.withOpacity(0.15),
        ),
        child: Icon(
          icon,
          color: isGradient ? Colors.white : iconColor,
          size: 28,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDark ? Colors.white60 : Colors.black54,
          fontSize: 13,
        ),
      ),
      onTap: onTap,
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
            Text('Settings', style: theme.textTheme.headlineMedium),
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
                              'Connected',
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
              title: const Text('Settings'),
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
              title: const Text('Disconnect'),
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
