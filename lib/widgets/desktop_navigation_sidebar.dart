import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/library_provider.dart';
import '../models/playlist.dart';
import '../theme/app_theme.dart';
import '../screens/playlist_screen.dart';
import '../screens/favorites_screen.dart';

class DesktopNavigationSidebar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final GlobalKey<NavigatorState>? navigatorKey;

  const DesktopNavigationSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.navigatorKey,
  });

  @override
  State<DesktopNavigationSidebar> createState() =>
      _DesktopNavigationSidebarState();
}

class _DesktopNavigationSidebarState extends State<DesktopNavigationSidebar> {
  bool _isCollapsed = false;

  void _toggleCollapse() {
    setState(() {
      _isCollapsed = !_isCollapsed;
    });
  }

  void _navigateToPlaylist(BuildContext context, Playlist playlist) {
    final route = MaterialPageRoute(
      builder: (context) =>
          PlaylistScreen(playlistId: playlist.id, playlistName: playlist.name),
    );

    if (widget.navigatorKey?.currentState != null) {
      widget.navigatorKey!.currentState!.push(route);
    } else {
      Navigator.push(context, route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final width = _isCollapsed ? 72.0 : 240.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      color: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _isCollapsed ? 20 : 24,
              vertical: 24,
            ),
            child: Row(
              children: [
                Image.asset('assets/logo.png', width: 32, height: 32),
                if (!_isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Musly',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 8),

          _SidebarItem(
            icon: CupertinoIcons.music_house,
            activeIcon: CupertinoIcons.music_house_fill,
            label: 'Home',
            isSelected: widget.selectedIndex == 0,
            isCollapsed: _isCollapsed,
            onTap: () => widget.onDestinationSelected(0),
          ),
          _SidebarItem(
            icon: CupertinoIcons.collections,
            activeIcon: CupertinoIcons.collections_solid,
            label: 'Library',
            isSelected: widget.selectedIndex == 1,
            isCollapsed: _isCollapsed,
            onTap: () => widget.onDestinationSelected(1),
          ),
          _SidebarItem(
            icon: CupertinoIcons.search,
            activeIcon: CupertinoIcons.search,
            label: 'Search',
            isSelected: widget.selectedIndex == 2,
            isCollapsed: _isCollapsed,
            onTap: () => widget.onDestinationSelected(2),
          ),

          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Divider(
              height: 1,
              color: isDark ? Colors.grey[800] : Colors.grey[300],
            ),
          ),

          Expanded(
            child: Consumer<LibraryProvider>(
              builder: (context, libraryProvider, child) {
                if (!_isCollapsed) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Text(
                          'PLAYLISTS',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      _LikedSongsItem(
                        isCollapsed: _isCollapsed,
                        onTap: () {
                          final route = MaterialPageRoute(
                            builder: (context) => const FavoritesScreen(),
                          );
                          if (widget.navigatorKey?.currentState != null) {
                            widget.navigatorKey!.currentState!.push(route);
                          } else {
                            Navigator.push(context, route);
                          }
                        },
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: libraryProvider.playlists.length,
                          itemBuilder: (context, index) {
                            final playlist = libraryProvider.playlists[index];
                            return _PlaylistItem(
                              playlist: playlist,
                              isCollapsed: _isCollapsed,
                              onTap: () =>
                                  _navigateToPlaylist(context, playlist),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: libraryProvider.playlists.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _LikedSongsItem(
                        isCollapsed: _isCollapsed,
                        onTap: () {
                          final route = MaterialPageRoute(
                            builder: (context) => const FavoritesScreen(),
                          );
                          if (widget.navigatorKey?.currentState != null) {
                            widget.navigatorKey!.currentState!.push(route);
                          } else {
                            Navigator.push(context, route);
                          }
                        },
                      );
                    }
                    final playlist = libraryProvider.playlists[index - 1];
                    return _PlaylistItem(
                      playlist: playlist,
                      isCollapsed: _isCollapsed,
                      onTap: () => _navigateToPlaylist(context, playlist),
                    );
                  },
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: InkWell(
              onTap: _toggleCollapse,
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: isDark ? Colors.transparent : Colors.transparent,
                ),
                child: Row(
                  mainAxisAlignment: _isCollapsed
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    Icon(
                      _isCollapsed
                          ? Icons.keyboard_double_arrow_right
                          : Icons.keyboard_double_arrow_left,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      size: 24,
                    ),
                    if (!_isCollapsed) ...[
                      const SizedBox(width: 12),
                      Text(
                        'Collapse',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final bool isCollapsed;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final color = isSelected
        ? (isDark ? Colors.white : Colors.black)
        : (isDark ? Colors.grey[400] : Colors.grey[600]);

    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 0 : 24),
        alignment: isCollapsed ? Alignment.center : Alignment.centerLeft,
        decoration: BoxDecoration(
          border: isSelected && !isCollapsed
              ? Border(
                  left: BorderSide(color: AppTheme.appleMusicRed, width: 4),
                )
              : null,
        ),
        child: isCollapsed
            ? Icon(isSelected ? activeIcon : icon, color: color, size: 24)
            : Row(
                children: [
                  Icon(isSelected ? activeIcon : icon, color: color, size: 24),
                  const SizedBox(width: 16),
                  Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _PlaylistImage extends StatelessWidget {
  final String? coverArtUrl;
  final bool isDark;

  const _PlaylistImage({required this.coverArtUrl, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final placeholderColor = isDark ? Colors.grey[800] : Colors.grey[300];
    final iconColor = isDark ? Colors.white30 : Colors.black26;

    return Container(
      color: placeholderColor,
      child: coverArtUrl != null
          ? CachedNetworkImage(
              imageUrl: coverArtUrl!,
              cacheKey: coverArtUrl,
              fit: BoxFit.cover,
              memCacheHeight: 200,
              memCacheWidth: 200,
              fadeInDuration: Duration.zero,
              fadeOutDuration: Duration.zero,
              placeholder: (_, __) => Container(color: placeholderColor),
              errorWidget: (_, __, ___) =>
                  Center(child: Icon(Icons.music_note, color: iconColor)),
            )
          : Center(child: Icon(Icons.music_note, color: iconColor)),
    );
  }
}

class _PlaylistItem extends StatelessWidget {
  final Playlist playlist;
  final bool isCollapsed;
  final VoidCallback onTap;

  const _PlaylistItem({
    required this.playlist,
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final libraryProvider = Provider.of<LibraryProvider>(
      context,
      listen: false,
    );

    final coverArtUrl = playlist.coverArt != null
        ? libraryProvider.getCoverArtUrl(playlist.coverArt)
        : null;

    if (isCollapsed) {
      return Padding(
        key: ValueKey(playlist.id),
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Tooltip(
            message: playlist.name,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 48,
                height: 48,
                child: _PlaylistImage(coverArtUrl: coverArtUrl, isDark: isDark),
              ),
            ),
          ),
        ),
      );
    }

    return InkWell(
      key: ValueKey(playlist.id),
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 48,
                height: 48,
                child: _PlaylistImage(coverArtUrl: coverArtUrl, isDark: isDark),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.grey[300] : Colors.grey[800],
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (playlist.songCount != null)
                    Text(
                      'Playlist • ${playlist.songCount} songs',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                        fontSize: 11,
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

class _LikedSongsItem extends StatelessWidget {
  final bool isCollapsed;
  final VoidCallback onTap;

  const _LikedSongsItem({required this.isCollapsed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isCollapsed) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Tooltip(
            message: 'Liked Songs',
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF450AF5), Color(0xFFC4EFDA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.favorite, color: Colors.white, size: 20),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF450AF5), Color(0xFFC4EFDA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Liked Songs',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.grey[300] : Colors.grey[800],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
