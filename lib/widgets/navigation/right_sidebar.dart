import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:musly/models/song.dart';
import 'package:musly/providers/player_provider.dart';
import 'package:musly/widgets/common/album_artwork.dart';
import 'package:musly/utils/navigation_helper.dart';
import 'package:musly/utils/screen_helper.dart';
import 'package:musly/utils/ui_feedback.dart';
import 'package:musly/l10n/app_localizations.dart';

class RightSidebar extends StatelessWidget {
  final VoidCallback? onClose;

  const RightSidebar({super.key, this.onClose});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
                Text(
                  l10n?.queue ?? 'Queue',
                  style: const TextStyle(
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
                  tooltip: l10n?.closeQueue ?? 'Close Queue',
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.music_note_rounded,
                          size: 32,
                          color: Color(0xFF4B5563),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n?.noSongsInQueue ?? 'Queue is empty',
                          style: const TextStyle(
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
                    if (queue.length == 1 ||
                        (upcomingCount == 0 &&
                            (currentSong != null || queue.isNotEmpty)))
                      _DesktopGenerateMoreSongsButton(
                        seedSong: currentSong ?? queue.first,
                      ),
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
                tooltip: AppLocalizations.of(context)?.removeFromQueue ?? 'Remove from queue',
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

class _DesktopGenerateMoreSongsButton extends StatelessWidget {
  final Song seedSong;

  const _DesktopGenerateMoreSongsButton({required this.seedSong});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isApple = ScreenHelper.isApple(context);
    final accentColor = theme.colorScheme.primary;
    final l10n = AppLocalizations.of(context);

    return Consumer<PlayerProvider>(
      builder: (context, player, _) {
        final isLoading = player.isGeneratingSimilarSongs;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading
                  ? null
                  : () async {
                      final added = await player.generateSimilarSongs(
                        seedSong: seedSong,
                      );
                      if (context.mounted) {
                        if (added > 0) {
                          UiFeedback.showSuccess(
                            context,
                            l10n?.similarSongsAdded(added) ??
                                'Added $added similar songs to queue',
                          );
                        } else {
                          UiFeedback.showInfo(
                            context,
                            l10n?.noSimilarSongsFound ??
                                'No similar songs found',
                          );
                        }
                      }
                    },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: accentColor.withValues(alpha: 0.12),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isLoading)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: accentColor,
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(
                          isApple
                              ? CupertinoIcons.sparkles
                              : Icons.auto_awesome_rounded,
                          color: accentColor,
                          size: 16,
                        ),
                      ),
                    Text(
                      isLoading
                          ? (l10n?.generatingSimilarSongs ??
                              'Finding similar songs…')
                          : (l10n?.generateMoreSongs ?? 'Generate more songs'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
