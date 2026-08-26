import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:musly/models/song.dart';
import 'package:musly/providers/player_provider.dart';
import 'package:musly/widgets/common/album_artwork.dart';
import 'package:musly/utils/navigation_helper.dart';

class RightSidebar extends StatelessWidget {
  final VoidCallback? onClose;

  const RightSidebar({super.key, this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        border: Border(
          left: BorderSide(color: Color(0xFF282828), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF282828), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Queue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: Color(0xFF9CA3AF),
                  ),
                  onPressed: () {
                    onClose?.call();
                    NavigationHelper.isDesktopQueueOpen.value = false;
                  },
                  tooltip: 'Close Queue',
                  splashRadius: 18,
                  hoverColor: Colors.white.withValues(alpha: 0.1),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<PlayerProvider>(
              builder: (context, player, _) {
                final currentSong = player.currentSong;
                final queue = player.queue;
                final currentIndex = player.currentIndex;

                if (queue.isEmpty && currentSong == null) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.music_note_rounded,
                          size: 32,
                          color: Color(0xFF4B5563),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Queue is empty',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final upcomingCount =
                    (queue.length - currentIndex - 1).clamp(0, queue.length);

                return ListView(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  children: [
                    if (currentSong != null) ...[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(8, 4, 8, 8),
                        child: Text(
                          'NOW PLAYING',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6B7280),
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFA243C).withValues(alpha: 0.1),
                          border: Border.all(
                            color:
                                const Color(0xFFFA243C).withValues(alpha: 0.2),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            AlbumArtwork(
                              coverArt: currentSong.coverArt,
                              size: 40,
                              borderRadius: 6,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentSong.title,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFFC5C65),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    currentSong.artist ?? 'Unknown Artist',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFFB3B3B3),
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
                    ],
                    if (upcomingCount > 0) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                        child: Text(
                          'NEXT UP · $upcomingCount songs',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6B7280),
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      for (int i = currentIndex + 1; i < queue.length; i++)
                        _UpcomingSongTile(
                          song: queue[i],
                          index: i,
                          onPlay: () => player.skipToIndex(i),
                          onRemove: () => player.removeFromQueue(i),
                        ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingSongTile extends StatefulWidget {
  final Song song;
  final int index;
  final VoidCallback onPlay;
  final VoidCallback onRemove;

  const _UpcomingSongTile({
    required this.song,
    required this.index,
    required this.onPlay,
    required this.onRemove,
  });

  @override
  State<_UpcomingSongTile> createState() => _UpcomingSongTileState();
}

class _UpcomingSongTileState extends State<_UpcomingSongTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: _isHovered
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            AlbumArtwork(
              coverArt: widget.song.coverArt,
              size: 36,
              borderRadius: 6,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.song.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.song.artist ?? 'Unknown Artist',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFB3B3B3),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (_isHovered) ...[
              IconButton(
                icon: const Icon(
                  Icons.play_arrow_rounded,
                  size: 16,
                  color: Color(0xFF9CA3AF),
                ),
                onPressed: widget.onPlay,
                tooltip: 'Play',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
                hoverColor: Colors.white.withValues(alpha: 0.1),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 16,
                  color: Color(0xFF9CA3AF),
                ),
                onPressed: widget.onRemove,
                tooltip: 'Remove',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
                hoverColor: Colors.red.withValues(alpha: 0.2),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
