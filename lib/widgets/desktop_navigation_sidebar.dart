import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../l10n/app_localizations.dart';
import '../providers/library_provider.dart';
import '../models/playlist.dart';
import '../screens/playlist_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/settings_screen.dart';

/// Spotify-style desktop navigation sidebar.
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

  void _toggleCollapse() => setState(() => _isCollapsed = !_isCollapsed);

  void _navigateToPlaylist(Playlist playlist) {
    final route = MaterialPageRoute(
      builder: (_) =>
          PlaylistScreen(playlistId: playlist.id, playlistName: playlist.name),
    );
    _push(route);
  }

  void _navigateToFavorites() {
    _push(MaterialPageRoute(builder: (_) => const FavoritesScreen()));
  }

  void _navigateToSettings() {
    _push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  void _push(Route<dynamic> route) {
    if (widget.navigatorKey?.currentState != null) {
      widget.navigatorKey!.currentState!.push(route);
    } else {
      Navigator.of(context).push(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final width = _isCollapsed ? 72.0 : 260.0;
    final sidebarBg = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFEEEEEE);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: width,
      color: sidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LogoRow(isCollapsed: _isCollapsed),
          const SizedBox(height: 4),
          _NavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: l10n.home,
            isSelected: widget.selectedIndex == 0,
            isCollapsed: _isCollapsed,
            onTap: () => widget.onDestinationSelected(0),
          ),
          _NavItem(
            icon: Icons.search_rounded,
            activeIcon: Icons.search_rounded,
            label: l10n.search,
            isSelected: widget.selectedIndex == 2,
            isCollapsed: _isCollapsed,
            onTap: () => widget.onDestinationSelected(2),
          ),
          const SizedBox(height: 8),
          _LibrarySection(
            isCollapsed: _isCollapsed,
            selectedIndex: widget.selectedIndex,
            navigatorKey: widget.navigatorKey,
            onLibraryTap: () => widget.onDestinationSelected(1),
            onFavoritesTap: _navigateToFavorites,
            onPlaylistTap: _navigateToPlaylist,
          ),
          _NavItem(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings_rounded,
            label: l10n.settings,
            isSelected: false,
            isCollapsed: _isCollapsed,
            onTap: _navigateToSettings,
          ),
          _CollapseButton(
            isCollapsed: _isCollapsed,
            onTap: _toggleCollapse,
            label: l10n.collapse,
            expandLabel: l10n.expand,
          ),
        ],
      ),
    );
  }
}

// Logo row
class _LogoRow extends StatelessWidget {
  final bool isCollapsed;
  const _LogoRow({required this.isCollapsed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isCollapsed ? 0 : 20,
        20,
        isCollapsed ? 0 : 16,
        12,
      ),
      child: isCollapsed
          ? Center(child: Image.asset('assets/logo.png', width: 30, height: 30))
          : Row(
              children: [
                Image.asset('assets/logo.png', width: 30, height: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Musly',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
    );
  }
}

// Primary nav item
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final bool isCollapsed;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isSelected
        ? (isDark ? Colors.white : Colors.black)
        : (isDark ? const Color(0xFFB3B3B3) : const Color(0xFF6B6B6B));
    final hoverBg = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.06);

    return Tooltip(
      message: isCollapsed ? label : '',
      waitDuration: const Duration(milliseconds: 400),
      child: InkWell(
        onTap: onTap,
        hoverColor: hoverBg,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          height: 44,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 0 : 12),
          alignment: isCollapsed ? Alignment.center : Alignment.centerLeft,
          child: isCollapsed
              ? Icon(isSelected ? activeIcon : icon, color: textColor, size: 26)
              : Row(
                  children: [
                    Icon(
                      isSelected ? activeIcon : icon,
                      color: textColor,
                      size: 26,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
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

// Your Library section
class _LibrarySection extends StatelessWidget {
  final bool isCollapsed;
  final int selectedIndex;
  final GlobalKey<NavigatorState>? navigatorKey;
  final VoidCallback onLibraryTap;
  final VoidCallback onFavoritesTap;
  final ValueChanged<Playlist> onPlaylistTap;

  const _LibrarySection({
    required this.isCollapsed,
    required this.selectedIndex,
    this.navigatorKey,
    required this.onLibraryTap,
    required this.onFavoritesTap,
    required this.onPlaylistTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final headerColor = selectedIndex == 1
        ? (isDark ? Colors.white : Colors.black)
        : (isDark ? const Color(0xFFB3B3B3) : const Color(0xFF6B6B6B));
    final hoverBg = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.06);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Your Library + create button
          if (!isCollapsed)
            InkWell(
              onTap: onLibraryTap,
              hoverColor: hoverBg,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.yourLibrary,
                        style: TextStyle(
                          color: headerColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                    Tooltip(
                      message: l10n.createPlaylist,
                      child: InkWell(
                        onTap: () => _showCreatePlaylist(context),
                        borderRadius: BorderRadius.circular(50),
                        hoverColor: hoverBg,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.add_rounded,
                            size: 20,
                            color: isDark
                                ? const Color(0xFFB3B3B3)
                                : const Color(0xFF6B6B6B),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Collapsed: library icon button
          if (isCollapsed)
            Tooltip(
              message: l10n.yourLibrary,
              waitDuration: const Duration(milliseconds: 400),
              child: InkWell(
                onTap: onLibraryTap,
                hoverColor: hoverBg,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: Container(
                  height: 44,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.library_music_rounded,
                    size: 26,
                    color: selectedIndex == 1
                        ? (isDark ? Colors.white : Colors.black)
                        : (isDark
                              ? const Color(0xFFB3B3B3)
                              : const Color(0xFF6B6B6B)),
                  ),
                ),
              ),
            ),
          // Liked Songs
          _LikedSongsItem(isCollapsed: isCollapsed, onTap: onFavoritesTap),
          // Playlist list
          Expanded(
            child: Consumer<LibraryProvider>(
              builder: (context, libraryProvider, _) {
                final playlists = libraryProvider.playlists;
                if (playlists.isEmpty) return const SizedBox.shrink();
                return ListView.builder(
                  padding: EdgeInsets.only(
                    top: 4,
                    bottom: 8,
                    left: isCollapsed ? 12 : 0,
                    right: isCollapsed ? 12 : 0,
                  ),
                  itemCount: playlists.length,
                  itemBuilder: (context, index) => _PlaylistTile(
                    playlist: playlists[index],
                    isCollapsed: isCollapsed,
                    onTap: () => onPlaylistTap(playlists[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreatePlaylist(BuildContext context) async {
    final libraryProvider = Provider.of<LibraryProvider>(
      context,
      listen: false,
    );
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF282828) : Colors.white,
        title: Text(l10n.newPlaylist),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.playlistName,
            filled: true,
            fillColor: isDark
                ? const Color(0xFF383838)
                : const Color(0xFFF2F2F7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          onSubmitted: (_) => _doCreate(ctx, controller, libraryProvider, l10n),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => _doCreate(ctx, controller, libraryProvider, l10n),
            child: Text(l10n.create),
          ),
        ],
      ),
    );
  }

  Future<void> _doCreate(
    BuildContext ctx,
    TextEditingController ctrl,
    LibraryProvider provider,
    AppLocalizations l10n,
  ) async {
    final name = ctrl.text.trim();
    if (name.isEmpty) return;
    try {
      await provider.createPlaylist(name);
      if (ctx.mounted) {
        Navigator.pop(ctx);
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(l10n.playlistCreated(name)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (ctx.mounted) {
        Navigator.pop(ctx);
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(l10n.errorCreatingPlaylist(e)),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Liked Songs item
class _LikedSongsItem extends StatelessWidget {
  final bool isCollapsed;
  final VoidCallback onTap;
  const _LikedSongsItem({required this.isCollapsed, required this.onTap});

  static const _gradient = LinearGradient(
    colors: [Color(0xFF4B0082), Color(0xFFADD8E6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final hoverBg = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.06);

    if (isCollapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Tooltip(
          message: l10n.likedSongsSidebar,
          waitDuration: const Duration(milliseconds: 400),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(4),
            hoverColor: hoverBg,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                gradient: _gradient,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      hoverColor: hoverBg,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(gradient: _gradient),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.likedSongsSidebar,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    l10n.playlist,
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFF9B9B9B)
                          : const Color(0xFF6B6B6B),
                      fontSize: 11,
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

// Playlist tile
class _PlaylistTile extends StatelessWidget {
  final Playlist playlist;
  final bool isCollapsed;
  final VoidCallback onTap;
  const _PlaylistTile({
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
    final l10n = AppLocalizations.of(context)!;
    final coverArtUrl = playlist.coverArt != null
        ? libraryProvider.getCoverArtUrl(playlist.coverArt)
        : null;
    final hoverBg = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.06);

    if (isCollapsed) {
      return Padding(
        key: ValueKey(playlist.id),
        padding: const EdgeInsets.only(bottom: 8),
        child: Tooltip(
          message: playlist.name,
          waitDuration: const Duration(milliseconds: 400),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(4),
            hoverColor: hoverBg,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 48,
                height: 48,
                child: _ArtworkImage(url: coverArtUrl, isDark: isDark),
              ),
            ),
          ),
        ),
      );
    }

    return InkWell(
      key: ValueKey(playlist.id),
      onTap: onTap,
      hoverColor: hoverBg,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 44,
                height: 44,
                child: _ArtworkImage(url: coverArtUrl, isDark: isDark),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    playlist.name,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (playlist.songCount != null)
                    Text(
                      l10n.playlistSongsCount(playlist.songCount!),
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF9B9B9B)
                            : const Color(0xFF6B6B6B),
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

// Artwork image with placeholder
class _ArtworkImage extends StatelessWidget {
  final String? url;
  final bool isDark;
  const _ArtworkImage({required this.url, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF282828) : const Color(0xFFD0D0D0);
    if (url == null) {
      return Container(
        color: bg,
        child: Icon(
          Icons.music_note_rounded,
          color: isDark ? Colors.white24 : Colors.black26,
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: url!,
      cacheKey: url,
      fit: BoxFit.cover,
      memCacheHeight: 200,
      memCacheWidth: 200,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholder: (context, url) => Container(color: bg),
      errorWidget: (context, url, error) => Container(
        color: bg,
        child: Icon(
          Icons.music_note_rounded,
          color: isDark ? Colors.white24 : Colors.black26,
        ),
      ),
    );
  }
}

// Collapse / expand button
class _CollapseButton extends StatelessWidget {
  final bool isCollapsed;
  final VoidCallback onTap;
  final String label;
  final String expandLabel;
  const _CollapseButton({
    required this.isCollapsed,
    required this.onTap,
    required this.label,
    required this.expandLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark
        ? const Color(0xFF9B9B9B)
        : const Color(0xFF6B6B6B);
    final hoverBg = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.06);

    return Tooltip(
      message: isCollapsed ? expandLabel : '',
      waitDuration: const Duration(milliseconds: 400),
      child: InkWell(
        onTap: onTap,
        hoverColor: hoverBg,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          height: 40,
          margin: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 0 : 12),
          alignment: isCollapsed ? Alignment.center : Alignment.centerLeft,
          child: Row(
            mainAxisSize: isCollapsed ? MainAxisSize.min : MainAxisSize.max,
            children: [
              Icon(
                isCollapsed
                    ? Icons.keyboard_double_arrow_right_rounded
                    : Icons.keyboard_double_arrow_left_rounded,
                color: iconColor,
                size: 20,
              ),
              if (!isCollapsed) ...[
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
