import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:musly/l10n/app_localizations.dart';
import 'package:musly/providers/auth_provider.dart';
import 'package:musly/providers/library_provider.dart';
import 'package:musly/services/subsonic_service.dart';
import 'package:musly/models/playlist.dart';
import 'package:musly/screens/detail/playlist_screen.dart';
import 'package:musly/screens/media/favorites_screen.dart';
import 'package:musly/screens/media/playlists_screen.dart';
import 'package:musly/screens/media/radio_screen.dart';
import 'package:musly/screens/settings/settings_screen.dart';
import 'package:musly/widgets/common/playlist_artwork.dart';

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
  bool _isPushing = false;

  void _toggleCollapse() => setState(() => _isCollapsed = !_isCollapsed);

  void _navigateToPlaylist(Playlist playlist) {
    final route = MaterialPageRoute(
      builder: (_) =>
          PlaylistScreen(playlistId: playlist.id, playlistName: playlist.name),
    );
    _push(route);
  }

  void _navigateToPlaylistsList() {
    _push(MaterialPageRoute(builder: (_) => const PlaylistsScreen()));
  }

  void _navigateToFavorites() {
    _push(MaterialPageRoute(builder: (_) => const FavoritesScreen()));
  }

  void _navigateToRadio() {
    _push(MaterialPageRoute(builder: (_) => const RadioScreen()));
  }

  void _navigateToSettings() {
    _push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  void _push(Route<dynamic> route) {
    if (_isPushing) return;
    _isPushing = true;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _isPushing = false;
    });
    if (widget.navigatorKey?.currentState != null) {
      widget.navigatorKey!.currentState!.push(route);
    } else {
      Navigator.of(context).push(route);
    }
  }

  Future<void> _handleDisconnect() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: const Text('Disconnect', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to disconnect from this server?',
          style: TextStyle(color: Color(0xFFB3B3B3)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel,
                style: const TextStyle(color: Color(0xFFB3B3B3))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFA243C),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final width = _isCollapsed ? 72.0 : 240.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: width,
      decoration: const BoxDecoration(
        color: Color(0xFF000000),
        border: Border(
          right: BorderSide(color: Color(0xFF1A1A1A), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LogoRow(isCollapsed: _isCollapsed),
          const SizedBox(height: 6),
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
          _NavItem(
            icon: Icons.library_music_outlined,
            activeIcon: Icons.library_music_rounded,
            label: l10n.library,
            isSelected: widget.selectedIndex == 1,
            isCollapsed: _isCollapsed,
            onTap: () => widget.onDestinationSelected(1),
          ),
          _NavItem(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings_rounded,
            label: l10n.settings,
            isSelected: false,
            isCollapsed: _isCollapsed,
            onTap: _navigateToSettings,
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF1A1A1A),
          ),
          _LibrarySection(
            isCollapsed: _isCollapsed,
            selectedIndex: widget.selectedIndex,
            navigatorKey: widget.navigatorKey,
            onLibraryTap: () => widget.onDestinationSelected(1),
            onPlaylistsTap: _navigateToPlaylistsList,
            onFavoritesTap: _navigateToFavorites,
            onPlaylistTap: _navigateToPlaylist,
          ),
          Consumer<SubsonicService>(
            builder: (context, subsonic, _) {
              if (subsonic.isYoutube) return const SizedBox.shrink();
              return _NavItem(
                icon: Icons.radio_rounded,
                activeIcon: Icons.radio_rounded,
                label: l10n.categoryRadio,
                isSelected: false,
                isCollapsed: _isCollapsed,
                onTap: _navigateToRadio,
              );
            },
          ),
          _DisconnectButton(
            isCollapsed: _isCollapsed,
            onTap: _handleDisconnect,
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

class _LogoRow extends StatelessWidget {
  final bool isCollapsed;
  const _LogoRow({required this.isCollapsed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isCollapsed ? 0 : 20,
        20,
        isCollapsed ? 0 : 16,
        14,
      ),
      child: isCollapsed
          ? Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset('assets/logo.png', width: 32, height: 32),
              ),
            )
          : Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset('assets/logo.png', width: 32, height: 32),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Musly',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

class _NavItem extends StatefulWidget {
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
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isSelected
        ? Colors.white
        : (_isHovered ? Colors.white : const Color(0xFF9CA3AF));
    final bgColor = widget.isSelected
        ? Colors.white.withValues(alpha: 0.10)
        : (_isHovered
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.transparent);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: widget.isCollapsed ? widget.label : '',
        waitDuration: const Duration(milliseconds: 400),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(8),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          child: Container(
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            padding:
                EdgeInsets.symmetric(horizontal: widget.isCollapsed ? 0 : 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment:
                widget.isCollapsed ? Alignment.center : Alignment.centerLeft,
            child: widget.isCollapsed
                ? Icon(
                    widget.isSelected ? widget.activeIcon : widget.icon,
                    color: textColor,
                    size: 20,
                  )
                : Row(
                    children: [
                      Icon(
                        widget.isSelected ? widget.activeIcon : widget.icon,
                        color: textColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.label,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: widget.isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _LibrarySection extends StatelessWidget {
  final bool isCollapsed;
  final int selectedIndex;
  final GlobalKey<NavigatorState>? navigatorKey;
  final VoidCallback onLibraryTap;
  final VoidCallback onPlaylistsTap;
  final VoidCallback onFavoritesTap;
  final ValueChanged<Playlist> onPlaylistTap;

  const _LibrarySection({
    required this.isCollapsed,
    required this.selectedIndex,
    this.navigatorKey,
    required this.onLibraryTap,
    required this.onPlaylistsTap,
    required this.onFavoritesTap,
    required this.onPlaylistTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isCollapsed)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 16, 6),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'YOUR LIBRARY',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  Tooltip(
                    message: 'Create playlist',
                    child: InkWell(
                      onTap: () => _showCreatePlaylist(context),
                      borderRadius: BorderRadius.circular(50),
                      hoverColor: Colors.white.withValues(alpha: 0.1),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.add_rounded,
                          size: 18,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          _NavItem(
            icon: Icons.queue_music_rounded,
            activeIcon: Icons.queue_music_rounded,
            label: 'Playlists',
            isSelected: false,
            isCollapsed: isCollapsed,
            onTap: onPlaylistsTap,
          ),
          _NavItem(
            icon: Icons.favorite_rounded,
            activeIcon: Icons.favorite_rounded,
            label: 'Liked Songs',
            isSelected: false,
            isCollapsed: isCollapsed,
            onTap: onFavoritesTap,
          ),
          Expanded(
            child: Consumer<LibraryProvider>(
              builder: (context, libraryProvider, _) {
                final playlists = libraryProvider.playlists;
                if (playlists.isEmpty) return const SizedBox.shrink();
                return ListView.builder(
                  padding: EdgeInsets.only(
                    top: 4,
                    bottom: 8,
                    left: isCollapsed ? 8 : 4,
                    right: isCollapsed ? 8 : 4,
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
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title:
            Text(l10n.newPlaylist, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: l10n.playlistName,
            hintStyle: const TextStyle(color: Color(0xFF6B7280)),
            filled: true,
            fillColor: const Color(0xFF383838),
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
            child: Text(l10n.cancel,
                style: const TextStyle(color: Color(0xFFB3B3B3))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFA243C),
              foregroundColor: Colors.white,
            ),
            onPressed: () => _doCreate(ctx, controller, libraryProvider, l10n),
            child: Text(l10n.create),
          ),
        ],
      ),
    );
    controller.dispose();
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

class _PlaylistTile extends StatefulWidget {
  final Playlist playlist;
  final bool isCollapsed;
  final VoidCallback onTap;

  const _PlaylistTile({
    required this.playlist,
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  State<_PlaylistTile> createState() => _PlaylistTileState();
}

class _PlaylistTileState extends State<_PlaylistTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isCollapsed) {
      return Padding(
        key: ValueKey(widget.playlist.id),
        padding: const EdgeInsets.only(bottom: 8),
        child: Tooltip(
          message: widget.playlist.name,
          waitDuration: const Duration(milliseconds: 400),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(4),
            hoverColor: Colors.white.withValues(alpha: 0.08),
            child: PlaylistArtwork(
              playlist: widget.playlist,
              size: 40,
              borderRadius: 4,
            ),
          ),
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        key: ValueKey(widget.playlist.id),
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(6),
        hoverColor: Colors.white.withValues(alpha: 0.05),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              PlaylistArtwork(
                playlist: widget.playlist,
                size: 32,
                borderRadius: 4,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.playlist.name,
                      style: TextStyle(
                        color:
                            _isHovered ? Colors.white : const Color(0xFFE5E7EB),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.playlist.songCount != null)
                      Text(
                        '${widget.playlist.songCount} songs',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
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
      ),
    );
  }
}

class _DisconnectButton extends StatefulWidget {
  final bool isCollapsed;
  final VoidCallback onTap;

  const _DisconnectButton({required this.isCollapsed, required this.onTap});

  @override
  State<_DisconnectButton> createState() => _DisconnectButtonState();
}

class _DisconnectButtonState extends State<_DisconnectButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: widget.isCollapsed ? 'Disconnect' : '',
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(8),
          hoverColor: Colors.white.withValues(alpha: 0.05),
          child: Container(
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            padding:
                EdgeInsets.symmetric(horizontal: widget.isCollapsed ? 0 : 12),
            alignment:
                widget.isCollapsed ? Alignment.center : Alignment.centerLeft,
            child: widget.isCollapsed
                ? Icon(
                    Icons.logout_rounded,
                    size: 20,
                    color: _isHovered ? Colors.white : const Color(0xFF9CA3AF),
                  )
                : Row(
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        size: 20,
                        color:
                            _isHovered ? Colors.white : const Color(0xFF9CA3AF),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Disconnect',
                        style: TextStyle(
                          color: _isHovered
                              ? Colors.white
                              : const Color(0xFF9CA3AF),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

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
    return Tooltip(
      message: isCollapsed ? expandLabel : '',
      waitDuration: const Duration(milliseconds: 400),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: Colors.white.withValues(alpha: 0.05),
        child: Container(
          height: 36,
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 0 : 12),
          alignment: isCollapsed ? Alignment.center : Alignment.centerLeft,
          child: Row(
            mainAxisSize: isCollapsed ? MainAxisSize.min : MainAxisSize.max,
            children: [
              Icon(
                isCollapsed
                    ? Icons.keyboard_double_arrow_right_rounded
                    : Icons.keyboard_double_arrow_left_rounded,
                color: const Color(0xFF6B7280),
                size: 18,
              ),
              if (!isCollapsed) ...[
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
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
