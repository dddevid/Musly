import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:musly/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:musly/providers/player_provider.dart';
import 'package:musly/services/subsonic_service.dart';
import 'package:musly/screens/player/now_playing_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
class TvNavigationSidebar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const TvNavigationSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  State<TvNavigationSidebar> createState() => _TvNavigationSidebarState();
}

class _TvNavigationSidebarState extends State<TvNavigationSidebar> {
  bool _isExpanded = false;

  final List<IconData> _icons = [
    CupertinoIcons.home,
    CupertinoIcons.search,
    CupertinoIcons.collections,
    CupertinoIcons.settings,
  ];

  final List<IconData> _activeIcons = [
    CupertinoIcons.house_fill,
    CupertinoIcons.search,
    CupertinoIcons.collections_solid,
    CupertinoIcons.settings_solid,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final List<String> _labels = [
      l10n.home,
      l10n.search,
      l10n.library,
      l10n.settings,
    ];

    return FocusTraversalGroup(
      child: Focus(
        onFocusChange: (hasFocus) {
          setState(() {
            _isExpanded = hasFocus;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: _isExpanded ? 200 : 70,
          color: Colors.black.withValues(alpha: 0.8),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Optional: Logo or Profile here
              for (int i = 0; i < _icons.length; i++)
                _SidebarItem(
                  icon: widget.selectedIndex == i ? _activeIcons[i] : _icons[i],
                  label: _labels[i],
                  isSelected: widget.selectedIndex == i,
                  isExpanded: _isExpanded,
                  onTap: () => widget.onDestinationSelected(i),
                ),
              const Spacer(),
              _TvSidebarPlayer(isExpanded: _isExpanded),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Focus(
        onFocusChange: (focused) {
          setState(() {
            _hasFocus = focused;
          });
        },
        child: Builder(
          builder: (context) {
            return GestureDetector(
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _hasFocus
                      ? Colors.white
                      : (widget.isSelected ? Colors.white12 : Colors.transparent),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.icon,
                      color: _hasFocus ? Colors.black : Colors.white,
                      size: _hasFocus ? 28 : 24,
                    ),
                    if (widget.isExpanded) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          widget.label,
                          style: TextStyle(
                            color: _hasFocus ? Colors.black : Colors.white,
                            fontWeight: _hasFocus || widget.isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TvSidebarPlayer extends StatefulWidget {
  final bool isExpanded;
  const _TvSidebarPlayer({required this.isExpanded});
  @override
  State<_TvSidebarPlayer> createState() => _TvSidebarPlayerState();
}

class _TvSidebarPlayerState extends State<_TvSidebarPlayer> {
  bool _hasFocus = false;

  void _openPlayer(BuildContext context, PlayerProvider provider) {
    final song = provider.currentSong;
    if (song == null) return;
    final subsonic = Provider.of<SubsonicService>(context, listen: false);
    final coverUrl = song.coverArt != null
        ? subsonic.getCoverArtUrl(song.coverArt, size: 600)
        : null;
    final imageProvider = (coverUrl != null && coverUrl.isNotEmpty)
        ? CachedNetworkImageProvider(coverUrl) as ImageProvider
        : const AssetImage('assets/logo.png') as ImageProvider;

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            NowPlayingScreen(
          image: imageProvider,
          title: song.title,
          artist: song.artist ?? '',
          heroTag: 'tv_hero_art',
          song: song,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Selector<PlayerProvider, bool>(
      selector: (_, p) => p.currentSong != null || p.isPlayingRadio,
      builder: (context, hasSong, _) {
        if (!hasSong) return const SizedBox.shrink();
        final provider = context.read<PlayerProvider>();
        final song = provider.currentSong;
        
        ImageProvider? imageProvider;
        if (song?.coverArt != null) {
          final subsonic = Provider.of<SubsonicService>(context, listen: false);
          final coverUrl = subsonic.getCoverArtUrl(song!.coverArt, size: 200);
          if (coverUrl.isNotEmpty) {
            imageProvider = CachedNetworkImageProvider(coverUrl);
          }
        }
        imageProvider ??= const AssetImage('assets/logo.png');

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Focus(
            onFocusChange: (focused) => setState(() => _hasFocus = focused),
            child: Builder(builder: (context) {
              return GestureDetector(
                onTap: () => _openPlayer(context, provider),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(widget.isExpanded ? 8 : 0),
                  decoration: BoxDecoration(
                    color: _hasFocus ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: _hasFocus ? Border.all(color: Colors.white, width: 2) : Border.all(color: Colors.transparent, width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: widget.isExpanded ? 40 : 40,
                        height: widget.isExpanded ? 40 : 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          image: DecorationImage(
                            image: imageProvider!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      if (widget.isExpanded) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                song?.title ?? 'Radio',
                                style: TextStyle(
                                  color: _hasFocus ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                song?.artist ?? 'Live',
                                style: TextStyle(
                                  color: _hasFocus ? Colors.black54 : Colors.white54,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
