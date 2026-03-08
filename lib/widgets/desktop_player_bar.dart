import 'package:flutter/material.dart' hide RepeatMode;
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/song.dart';
import '../models/radio_station.dart';
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
    final rootNav = Navigator.of(context, rootNavigator: true);
    if (_lyricsOpen) {
      rootNav.pop();
      setState(() => _lyricsOpen = false);
    } else {
      rootNav
          .push(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (ctx) => SyncedLyricsView(
                song: song,
                onClose: () {
                  Navigator.of(ctx, rootNavigator: true).pop();
                  setState(() => _lyricsOpen = false);
                },
              ),
            ),
          )
          .then((_) {
            if (mounted) setState(() => _lyricsOpen = false);
          });
      setState(() => _lyricsOpen = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Selector<PlayerProvider, (Song?, RadioStation?, bool)>(
      selector: (_, p) => (p.currentSong, p.currentRadioStation, p.isPlayingRadio),
      builder: (context, data, _) {
        final (currentSong, radioStation, isPlayingRadio) = data;

        if (isPlayingRadio && radioStation != null) {
          return _buildRadioBar(context, theme, isDark, radioStation);
        }

        if (currentSong == null) return const SizedBox.shrink();

        return _buildSongBar(context, theme, isDark, currentSong);
      },
    );
  }

  Widget _buildRadioBar(BuildContext context, ThemeData theme, bool isDark, RadioStation station) {
    final barColor = isDark ? const Color(0xFF181818) : const Color(0xFFF8F8F8);
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFDDDDDD);
    final iconColor = isDark ? const Color(0xFFB3B3B3) : const Color(0xFF6B6B6B);

    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: barColor,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        children: [
          
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(Icons.radio_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.5), blurRadius: 4)],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'LIVE',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            flex: 4,
            child: Selector<PlayerProvider, bool>(
              selector: (_, p) => p.isPlaying,
              builder: (context, isPlaying, _) {
                final provider = context.read<PlayerProvider>();
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          size: 32,
                          color: Colors.black,
                        ),
                        onPressed: provider.togglePlayPause,
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: Icon(Icons.stop_rounded, size: 26, color: iconColor),
                      onPressed: provider.stop,
                      tooltip: 'Stop',
                    ),
                  ],
                );
              },
            ),
          ),

          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [_VolumeControl()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongBar(BuildContext context, ThemeData theme, bool isDark, Song currentSong) {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181818) : const Color(0xFFF8F8F8),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFDDDDDD),
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
                                _navigateToArtist(context, currentSong.artistId!);
                              }
                            },
                            child: Text(
                              currentSong.artist!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
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
                        isStarred ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 20,
                        color: isStarred
                            ? AppTheme.appleMusicRed
                            : (isDark ? const Color(0xFFB3B3B3) : const Color(0xFF6B6B6B)),
                      ),
                      onPressed: () {
                        Provider.of<PlayerProvider>(context, listen: false).toggleFavorite();
                      },
                      tooltip: isStarred
                          ? AppLocalizations.of(context)!.removeFromFavorites
                          : AppLocalizations.of(context)!.addToFavorites,
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
                        : (isDark ? const Color(0xFFB3B3B3) : const Color(0xFF6B6B6B)),
                  ),
                  onPressed: () => _toggleLyrics(context, currentSong),
                  tooltip: _lyricsOpen
                      ? AppLocalizations.of(context)!.closeLyrics
                      : AppLocalizations.of(context)!.lyrics,
                ),
                IconButton(
                  icon: const Icon(Icons.queue_music_rounded, size: 20),
                  onPressed: () {},
                  color: isDark ? const Color(0xFFB3B3B3) : const Color(0xFF6B6B6B),
                ),
                const SizedBox(width: 8),
                const _VolumeControl(),
              ],
            ),
          ),
        ],
      ),
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

    return Selector<PlayerProvider, (bool, bool, bool, bool, RepeatMode)>(
      selector: (_, p) => (
        p.isPlaying,
        p.shuffleEnabled,
        p.hasPrevious,
        p.hasNext,
        p.repeatMode,
      ),
      builder: (context, data, _) {
        final (isPlaying, shuffleEnabled, hasPrevious, hasNext, repeatMode) =
            data;
        final provider = context.read<PlayerProvider>();

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                Icons.shuffle_rounded,
                size: 20,
                color: shuffleEnabled
                    ? AppTheme.appleMusicRed
                    : (isDark
                          ? const Color(0xFFB3B3B3)
                          : const Color(0xFF6B6B6B)),
              ),
              onPressed: provider.toggleShuffle,
              tooltip: AppLocalizations.of(context)!.enableShuffle,
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.skip_previous_rounded, size: 28),
              onPressed: hasPrevious ? provider.skipPrevious : null,
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
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
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
              onPressed: hasNext ? provider.skipNext : null,
              color: color,
              disabledColor: disabledColor,
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                repeatMode == RepeatMode.one
                    ? Icons.repeat_one_rounded
                    : Icons.repeat_rounded,
                size: 20,
                color: repeatMode != RepeatMode.off
                    ? AppTheme.appleMusicRed
                    : (isDark
                          ? const Color(0xFFB3B3B3)
                          : const Color(0xFF6B6B6B)),
              ),
              onPressed: provider.toggleRepeat,
              tooltip: AppLocalizations.of(context)!.enableRepeat,
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

    return Selector<PlayerProvider, (Duration, Duration)>(
      selector: (_, p) => (p.position, p.duration),
      builder: (context, data, _) {
        final (position, duration) = data;
        final provider = context.read<PlayerProvider>();

        return SizedBox(
          width: 400,
          child: Row(
            children: [
              Text(_formatDuration(position), style: timeStyle),
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
                      activeTrackColor: AppTheme.appleMusicRed,
                      inactiveTrackColor: isDark
                          ? const Color(0xFF535353)
                          : Colors.grey[300],
                      thumbColor: Colors.white,
                      overlayColor: AppTheme.appleMusicRed.withValues(
                        alpha: 0.15,
                      ),
                    ),
                    child: Slider(
                      value: position.inMilliseconds.toDouble().clamp(
                        0.0,
                        duration.inMilliseconds.toDouble(),
                      ),
                      min: 0.0,
                      max: duration.inMilliseconds.toDouble(),
                      onChanged: (value) {
                        provider.seek(Duration(milliseconds: value.round()));
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(_formatDuration(duration), style: timeStyle),
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
    
    return Selector<PlayerProvider, double>(
      selector: (_, p) => p.volume,
      builder: (context, volume, _) {
        final isMuted = volume == 0;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final provider = context.read<PlayerProvider>();

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
                  activeTrackColor: AppTheme.appleMusicRed,
                  inactiveTrackColor: isDark
                      ? const Color(0xFF535353)
                      : Colors.grey[300],
                  thumbColor: Colors.white,
                  overlayColor: AppTheme.appleMusicRed.withValues(alpha: 0.15),
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
