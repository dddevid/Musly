import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';
import '../screens/artist_screen.dart';
import '../widgets/synced_lyrics_view.dart';
import 'album_artwork.dart';

class DesktopPlayerBar extends StatefulWidget {
  final GlobalKey<NavigatorState>? navigatorKey;

  const DesktopPlayerBar({super.key, this.navigatorKey});

  @override
  State<DesktopPlayerBar> createState() => _DesktopPlayerBarState();
}

class _DesktopPlayerBarState extends State<DesktopPlayerBar> {
  bool _lyricsOpen = false;

  void _navigateToArtist(BuildContext context, String artistId) {
    if (widget.navigatorKey?.currentState != null) {
      widget.navigatorKey!.currentState!.push(
        MaterialPageRoute(
          builder: (context) => ArtistScreen(artistId: artistId),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ArtistScreen(artistId: artistId),
        ),
      );
    }
  }

  void _toggleLyrics(BuildContext context, Song song) {
    if (_lyricsOpen) {
      // Close lyrics
      if (widget.navigatorKey?.currentState != null) {
        widget.navigatorKey!.currentState!.pop();
      } else {
        Navigator.of(context).pop();
      }
      setState(() => _lyricsOpen = false);
    } else {
      // Open lyrics
      final nav = widget.navigatorKey?.currentState ?? Navigator.of(context);
      nav
          .push(
            MaterialPageRoute(
              builder: (ctx) => SyncedLyricsView(
                song: song,
                onClose: () {
                  Navigator.pop(ctx);
                  setState(() => _lyricsOpen = false);
                },
              ),
            ),
          )
          .then((_) {
            // In case user closes via back gesture or other means
            if (mounted) setState(() => _lyricsOpen = false);
          });
      setState(() => _lyricsOpen = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Selector<PlayerProvider, Song?>(
      selector: (_, p) => p.currentSong,
      builder: (context, currentSong, _) {
        if (currentSong == null) return const SizedBox.shrink();

        return Container(
          height: 90,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF181818) : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark
                    ? const Color(0xFF282828)
                    : const Color(0xFFE5E5E5),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    AlbumArtwork(
                      coverArt: currentSong.coverArt,
                      size: 56,
                      borderRadius: 4,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentSong.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (currentSong.artist != null)
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () {
                                  if (currentSong.artistId != null) {
                                    _navigateToArtist(
                                      context,
                                      currentSong.artistId!,
                                    );
                                  }
                                },
                                child: Text(
                                  currentSong.artist!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Selector<PlayerProvider, bool>(
                      selector: (_, p) => p.currentSong?.starred == true,
                      builder: (context, isStarred, _) {
                        return IconButton(
                          icon: Icon(
                            isStarred
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 20,
                            color: isStarred
                                ? AppTheme.appleMusicRed
                                : (isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600]),
                          ),
                          onPressed: () {
                            Provider.of<PlayerProvider>(
                              context,
                              listen: false,
                            ).toggleFavorite();
                          },
                          tooltip: isStarred
                              ? 'Remove from favorites'
                              : 'Add to favorites',
                        );
                      },
                    ),
                  ],
                ),
              ),

              Expanded(
                flex: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _PlayerControls(),
                    const SizedBox(height: 4),
                    const _ProgressBar(),
                  ],
                ),
              ),

              Expanded(
                flex: 3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.lyrics_rounded,
                        size: 20,
                        color: _lyricsOpen
                            ? AppTheme.appleMusicRed
                            : (isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                      onPressed: () => _toggleLyrics(context, currentSong),
                      tooltip: _lyricsOpen ? 'Close Lyrics' : 'Lyrics',
                    ),
                    IconButton(
                      icon: const Icon(Icons.queue_music_rounded, size: 20),
                      onPressed: () {},
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    const _VolumeControl(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PlayerControls extends StatelessWidget {
  const _PlayerControls();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.white : Colors.black;
    final disabledColor = isDark ? Colors.grey[800] : Colors.grey[300];

    return Consumer<PlayerProvider>(
      builder: (context, provider, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                Icons.shuffle_rounded,
                size: 20,
                color: provider.shuffleEnabled
                    ? AppTheme.appleMusicRed
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
              onPressed: provider.toggleShuffle,
              tooltip: 'Enable shuffle',
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.skip_previous_rounded, size: 28),
              onPressed: provider.hasPrevious ? provider.skipPrevious : null,
              color: color,
              disabledColor: disabledColor,
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  provider.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  size: 32,
                  color: Colors.black,
                ),
                onPressed: provider.togglePlayPause,
                padding: const EdgeInsets.all(8),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.skip_next_rounded, size: 28),
              onPressed: provider.hasNext ? provider.skipNext : null,
              color: color,
              disabledColor: disabledColor,
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                provider.repeatMode == RepeatMode.one
                    ? Icons.repeat_one_rounded
                    : Icons.repeat_rounded,
                size: 20,
                color: provider.repeatMode != RepeatMode.off
                    ? AppTheme.appleMusicRed
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
              onPressed: provider.toggleRepeat,
              tooltip: 'Enable repeat',
            ),
          ],
        );
      },
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar();

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${duration.inMinutes}:$twoDigitSeconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final timeStyle = theme.textTheme.bodySmall?.copyWith(
      fontSize: 11,
      color: isDark ? Colors.grey[400] : Colors.grey[600],
    );

    return Consumer<PlayerProvider>(
      builder: (context, provider, _) {
        return SizedBox(
          width: 400,
          child: Row(
            children: [
              Text(_formatDuration(provider.position), style: timeStyle),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 20,
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 12,
                      ),
                      activeTrackColor: isDark ? Colors.white : Colors.black,
                      inactiveTrackColor: isDark
                          ? Colors.grey[800]
                          : Colors.grey[300],
                      thumbColor: isDark ? Colors.white : Colors.black,
                      overlayColor: (isDark ? Colors.white : Colors.black)
                          .withOpacity(0.12),
                    ),
                    child: Slider(
                      value: provider.position.inMilliseconds.toDouble().clamp(
                        0.0,
                        provider.duration.inMilliseconds.toDouble(),
                      ),
                      min: 0.0,
                      max: provider.duration.inMilliseconds.toDouble(),
                      onChanged: (value) {
                        provider.seek(Duration(milliseconds: value.round()));
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(_formatDuration(provider.duration), style: timeStyle),
            ],
          ),
        );
      },
    );
  }
}

class _VolumeControl extends StatelessWidget {
  const _VolumeControl();

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, provider, _) {
        final volume = provider.volume;
        final isMuted = volume == 0;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                isMuted
                    ? Icons.volume_off_rounded
                    : volume < 0.5
                    ? Icons.volume_down_rounded
                    : Icons.volume_up_rounded,
                size: 20,
              ),
              onPressed: () {
                provider.setVolume(isMuted ? 0.5 : 0.0);
              },
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            SizedBox(
              width: 100,
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 12,
                  ),
                  activeTrackColor: isDark ? Colors.white : Colors.black,
                  inactiveTrackColor: isDark
                      ? Colors.grey[800]
                      : Colors.grey[300],
                  thumbColor: isDark ? Colors.white : Colors.black,
                  overlayColor: (isDark ? Colors.white : Colors.black)
                      .withOpacity(0.12),
                ),
                child: Slider(
                  value: volume,
                  onChanged: (value) => provider.setVolume(value),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
