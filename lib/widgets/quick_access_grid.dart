import 'package:flutter/material.dart';
import '../models/album.dart';
import '../models/playlist.dart';
import '../theme/app_theme.dart';

class QuickAccessGrid extends StatelessWidget {
  final List<Album> albums;
  final List<Playlist> playlists;
  final Function(Album)? onAlbumTap;
  final Function(Playlist)? onPlaylistTap;
  final int columns;

  const QuickAccessGrid({
    super.key,
    this.albums = const [],
    this.playlists = const [],
    this.onAlbumTap,
    this.onPlaylistTap,
    this.columns = 3,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_QuickAccessItem>[];

    for (final album in albums) {
      items.add(_QuickAccessItem(
        coverArt: album.coverArt,
        title: album.name,
        onTap: () => onAlbumTap?.call(album),
      ));
    }

    for (final playlist in playlists) {
      items.add(_QuickAccessItem(
        coverArt: playlist.coverArt,
        title: playlist.name,
        onTap: () => onPlaylistTap?.call(playlist),
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: 3.5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => items[index],
    );
  }
}

class _QuickAccessItem extends StatefulWidget {
  final String? coverArt;
  final String title;
  final VoidCallback? onTap;

  const _QuickAccessItem({
    this.coverArt,
    required this.title,
    this.onTap,
  });

  @override
  State<_QuickAccessItem> createState() => _QuickAccessItemState();
}

class _QuickAccessItemState extends State<_QuickAccessItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isDark
                ? (_isHovered ? AppTheme.darkElevated : AppTheme.darkCard)
                : (_isHovered ? const Color(0xFFE0E0E0) : AppTheme.lightCard),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                ),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: widget.coverArt != null
                      ? Image.network(
                          widget.coverArt!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildPlaceholder(isDark),
                        )
                      : _buildPlaceholder(isDark),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    widget.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      color: isDark ? AppTheme.darkElevated : const Color(0xFFE0E0E0),
      child: Icon(
        Icons.music_note_rounded,
        size: 32,
        color: isDark ? Colors.white24 : Colors.black26,
      ),
    );
  }
}
