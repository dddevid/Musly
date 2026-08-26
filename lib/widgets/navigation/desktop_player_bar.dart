import 'package:flutter/material.dart' hide RepeatMode;
import 'package:provider/provider.dart';
import 'package:musly/l10n/app_localizations.dart';
import 'package:musly/models/song.dart';
import 'package:musly/models/radio_station.dart';
import 'package:musly/providers/player_provider.dart';
import 'package:musly/widgets/common/album_artwork.dart';
import 'package:musly/widgets/common/multi_artist_widget.dart';
import 'package:musly/utils/navigation_helper.dart';
import 'package:musly/screens/connect/connect_devices_modal.dart';

class DesktopPlayerBar extends StatefulWidget {
  final GlobalKey<NavigatorState>? navigatorKey;

  const DesktopPlayerBar({super.key, this.navigatorKey});

  @override
  State<DesktopPlayerBar> createState() => _DesktopPlayerBarState();
}

class _DesktopPlayerBarState extends State<DesktopPlayerBar> {
  @override
  Widget build(BuildContext context) {
    return Selector<PlayerProvider, (Song?, RadioStation?, bool)>(
      selector: (_, p) =>
          (p.currentSong, p.currentRadioStation, p.isPlayingRadio),
      builder: (context, data, _) {
        final (currentSong, radioStation, isPlayingRadio) = data;

        if (isPlayingRadio && radioStation != null) {
          return _buildRadioBar(context, radioStation);
        }

        if (currentSong == null) return const SizedBox.shrink();

        return _buildSongBar(context, currentSong);
      },
    );
  }

  Widget _buildRadioBar(BuildContext context, RadioStation station) {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF181818),
        border: Border(top: BorderSide(color: Color(0xFF282828), width: 1)),
      ),
      child: Row(
        children: [
          // Left: Radio Info
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(Icons.radio_rounded,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFA243C),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFA243C).withValues(alpha: 0.5),
                                  blurRadius: 4,
                                )
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Color(0xFFB3B3B3),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
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

          // Center: Radio Play/Pause
          Expanded(
            flex: 4,
            child: Selector<PlayerProvider, bool>(
              selector: (_, p) => p.isPlaying,
              builder: (context, isPlaying, _) {
                final provider = context.read<PlayerProvider>();
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _PlayPauseCircle(
                      isPlaying: isPlaying,
                      onTap: provider.togglePlayPause,
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(
                        Icons.stop_rounded,
                        size: 22,
                        color: Color(0xFFB3B3B3),
                      ),
                      onPressed: provider.stop,
                      tooltip: 'Stop',
                    ),
                  ],
                );
              },
            ),
          ),

          // Right: Volume
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

  Widget _buildSongBar(BuildContext context, Song currentSong) {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF181818),
        border: Border(
          top: BorderSide(
            color: Color(0xFF282828),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Left: Track Info + Cover + Like
          Expanded(
            flex: 3,
            child: Row(
              children: [
                AlbumArtwork(
                  coverArt: currentSong.coverArt,
                  size: 56,
                  borderRadius: 8,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentSong.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      if (currentSong.artist != null || currentSong.artistParticipants != null)
                        MultiArtistWidget(
                          artists: currentSong.artistParticipants,
                          artistFallback: currentSong.artist,
                          artistIdFallback: currentSong.artistId,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFB3B3B3),
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
                        size: 18,
                        color: isStarred
                            ? const Color(0xFFFA243C)
                            : const Color(0xFF6B7280),
                      ),
                      onPressed: () {
                        Provider.of<PlayerProvider>(context, listen: false)
                            .toggleFavorite();
                      },
                      tooltip: isStarred
                          ? AppLocalizations.of(context)!.removeFromFavorites
                          : AppLocalizations.of(context)!.addToFavorites,
                      hoverColor: Colors.white.withValues(alpha: 0.1),
                    );
                  },
                ),
              ],
            ),
          ),

          // Center: Controls + Progress Bar
          Expanded(
            flex: 5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                _PlayerControls(),
                SizedBox(height: 6),
                _ProgressBar(),
              ],
            ),
          ),

          // Right: Lyrics, Queue, Cast, Volume
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Lyrics Button
                ValueListenableBuilder<bool>(
                  valueListenable: NavigationHelper.isDesktopLyricsOpen,
                  builder: (context, isLyricsOpen, _) {
                    return IconButton(
                      icon: Icon(
                        Icons.mic_rounded,
                        size: 18,
                        color: isLyricsOpen
                            ? const Color(0xFFFA243C)
                            : const Color(0xFF6B7280),
                      ),
                      tooltip: 'Lyrics',
                      hoverColor: Colors.white.withValues(alpha: 0.1),
                      onPressed: NavigationHelper.toggleDesktopLyrics,
                    );
                  },
                ),
                const SizedBox(width: 4),

                // Queue Button
                ValueListenableBuilder<bool>(
                  valueListenable: NavigationHelper.isDesktopQueueOpen,
                  builder: (context, isQueueOpen, _) {
                    return IconButton(
                      icon: Icon(
                        Icons.queue_music_rounded,
                        size: 18,
                        color: isQueueOpen
                            ? const Color(0xFFFA243C)
                            : const Color(0xFF6B7280),
                      ),
                      tooltip: isQueueOpen ? 'Hide Queue' : 'Queue',
                      hoverColor: Colors.white.withValues(alpha: 0.1),
                      onPressed: NavigationHelper.toggleDesktopQueue,
                    );
                  },
                ),
                const SizedBox(width: 4),

                // Connect to device
                IconButton(
                  icon: const Icon(
                    Icons.devices_other_rounded,
                    size: 18,
                    color: Color(0xFF6B7280),
                  ),
                  tooltip: AppLocalizations.of(context)!.connectToDevice,
                  hoverColor: Colors.white.withValues(alpha: 0.1),
                  onPressed: () => ConnectDevicesModal.show(context),
                ),
                const SizedBox(width: 8),

                // Volume slider
                const _VolumeControl(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayPauseCircle extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback onTap;

  const _PlayPauseCircle({required this.isPlaying, required this.onTap});

  @override
  State<_PlayPauseCircle> createState() => _PlayPauseCircleState();
}

class _PlayPauseCircleState extends State<_PlayPauseCircle> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 20,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerControls extends StatelessWidget {
  const _PlayerControls();

  @override
  Widget build(BuildContext context) {
    return Selector<PlayerProvider, (bool, bool, bool, bool, RepeatMode)>(
      selector: (_, p) => (
        p.isPlaying,
        p.shuffleEnabled,
        p.hasPrevious,
        p.hasNext,
        p.repeatMode,
      ),
      builder: (context, data, _) {
        final (isPlaying, shuffleEnabled, hasPrevious, hasNext, repeatMode) = data;
        final provider = context.read<PlayerProvider>();

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Shuffle
            IconButton(
              icon: Icon(
                Icons.shuffle_rounded,
                size: 18,
                color: shuffleEnabled
                    ? const Color(0xFFFA243C)
                    : const Color(0xFFB3B3B3),
              ),
              onPressed: provider.toggleShuffle,
              tooltip: AppLocalizations.of(context)!.enableShuffle,
              hoverColor: Colors.white.withValues(alpha: 0.1),
            ),
            const SizedBox(width: 8),

            // Previous
            IconButton(
              icon: Icon(
                Icons.skip_previous_rounded,
                size: 22,
                color: hasPrevious
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.2),
              ),
              onPressed: hasPrevious ? provider.skipPrevious : null,
              hoverColor: Colors.white.withValues(alpha: 0.1),
            ),
            const SizedBox(width: 12),

            // Play / Pause Circle
            _PlayPauseCircle(
              isPlaying: isPlaying,
              onTap: provider.togglePlayPause,
            ),
            const SizedBox(width: 12),

            // Next
            IconButton(
              icon: Icon(
                Icons.skip_next_rounded,
                size: 22,
                color: hasNext
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.2),
              ),
              onPressed: hasNext ? provider.skipNext : null,
              hoverColor: Colors.white.withValues(alpha: 0.1),
            ),
            const SizedBox(width: 8),

            // Repeat
            IconButton(
              icon: Icon(
                repeatMode == RepeatMode.one
                    ? Icons.repeat_one_rounded
                    : Icons.repeat_rounded,
                size: 18,
                color: repeatMode != RepeatMode.off
                    ? const Color(0xFFFA243C)
                    : const Color(0xFFB3B3B3),
              ),
              onPressed: provider.toggleRepeat,
              tooltip: AppLocalizations.of(context)!.enableRepeat,
              hoverColor: Colors.white.withValues(alpha: 0.1),
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
    const timeStyle = TextStyle(
      fontSize: 11,
      color: Color(0xFFB3B3B3),
      fontFamily: 'Inter',
    );

    return Selector<PlayerProvider, (Duration, Duration)>(
      selector: (_, p) => (p.position, p.duration),
      builder: (context, data, _) {
        final (position, duration) = data;
        final provider = context.read<PlayerProvider>();

        return SizedBox(
          width: 480,
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  _formatDuration(position),
                  style: timeStyle,
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 16,
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3.5,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 5,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 12,
                      ),
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: const Color(0xFF4A4A4A),
                      thumbColor: Colors.white,
                      overlayColor: Colors.white.withValues(alpha: 0.15),
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
              SizedBox(
                width: 36,
                child: Text(
                  _formatDuration(duration),
                  style: timeStyle,
                  textAlign: TextAlign.left,
                ),
              ),
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
                size: 18,
                color: const Color(0xFF6B7280),
              ),
              onPressed: provider.toggleMute,
              tooltip: isMuted ? 'Unmute' : 'Mute',
              hoverColor: Colors.white.withValues(alpha: 0.1),
            ),
            SizedBox(
              width: 110,
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3.5,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 4.5,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 10,
                  ),
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: const Color(0xFF4A4A4A),
                  thumbColor: Colors.white,
                  overlayColor: Colors.white.withValues(alpha: 0.15),
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
