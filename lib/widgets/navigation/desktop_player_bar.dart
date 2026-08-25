import 'package:flutter/material.dart' hide RepeatMode;
import 'package:provider/provider.dart';
import 'package:musly/l10n/app_localizations.dart';
import 'package:musly/models/song.dart';
import 'package:musly/models/radio_station.dart';
import 'package:musly/providers/player_provider.dart';
import 'package:musly/theme/app_theme.dart';
import 'package:musly/widgets/common/multi_artist_widget.dart';
import 'package:musly/widgets/common/album_artwork.dart';
import 'package:musly/utils/navigation_helper.dart';
import 'package:musly/screens/connect/connect_devices_modal.dart';
// import 'package:musly/services/musly_connect_service.dart';

class DesktopPlayerBar extends StatefulWidget {
  final GlobalKey<NavigatorState>? navigatorKey;

  const DesktopPlayerBar({super.key, this.navigatorKey});

  @override
  State<DesktopPlayerBar> createState() => _DesktopPlayerBarState();
}

class _DesktopPlayerBarState extends State<DesktopPlayerBar> {



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Selector<PlayerProvider, (Song?, RadioStation?, bool)>(
      selector: (_, p) =>
          (p.currentSong, p.currentRadioStation, p.isPlayingRadio),
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

  Widget _buildRadioBar(BuildContext context, ThemeData theme, bool isDark,
      RadioStation station) {
    final barColor = isDark ? AppTheme.playerBarDark : AppTheme.playerBarLight;
    final borderColor =
        isDark ? AppTheme.playerBarBorder : const Color(0xFFDDDDDD);
    final iconColor =
        isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText;

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
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.red.withValues(alpha: 0.5),
                                    blurRadius: 4)
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'LIVE',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
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
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 32,
                          color: Colors.black,
                        ),
                        onPressed: provider.togglePlayPause,
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon:
                          Icon(Icons.stop_rounded, size: 26, color: iconColor),
                      onPressed: provider.stop,
                      tooltip: AppLocalizations.of(context)!.stop,
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

  Widget _buildSongBar(
      BuildContext context, ThemeData theme, bool isDark, Song currentSong) {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.playerBarDark : AppTheme.playerBarLight,
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.playerBarBorder : const Color(0xFFDDDDDD),
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
                      /*
                      Consumer<MuslyConnectService>(
                        builder: (context, connect, _) {
                          if (!connect.isControllingRemoteDevice) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.devices_rounded, size: 11, color: Color(0xFF1DB954)),
                                const SizedBox(width: 4),
                                Text(
                                  'Playing on ${connect.activeRemoteDevice?.name ?? "Device"}',
                                  style: const TextStyle(
                                    color: Color(0xFF1DB954),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      */
                      const SizedBox(height: 2),
                      if (currentSong.artist != null || currentSong.artistParticipants != null)
                        MultiArtistWidget(
                          artists: currentSong.artistParticipants,
                          artistFallback: currentSong.artist,
                          artistIdFallback: currentSong.artistId,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? Colors.grey[400]
                                : Colors.grey[600],
                            fontSize: 12,
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
                            ? AppTheme.brandRed
                            : (isDark
                                ? const Color(0xFFB3B3B3)
                                : const Color(0xFF6B6B6B)),
                      ),
                      onPressed: () {
                        Provider.of<PlayerProvider>(context, listen: false)
                            .toggleFavorite();
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
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.devices_other_rounded,
                      size: 20,
                      color: isDark ? const Color(0xFFB3B3B3) : const Color(0xFF6B6B6B),
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    tooltip: AppLocalizations.of(context)!.connectToDevice,
                    onPressed: () => ConnectDevicesModal.show(context),
                  ),
                  const SizedBox(width: 6),
                  ValueListenableBuilder<bool>(
                    valueListenable: NavigationHelper.isDesktopQueueOpen,
                    builder: (context, isOpen, _) {
                      return IconButton(
                        icon: Icon(
                          Icons.queue_music_rounded,
                          size: 20,
                          color: isOpen
                              ? AppTheme.brandRed
                              : (isDark
                                  ? const Color(0xFFB3B3B3)
                                  : const Color(0xFF6B6B6B)),
                        ),
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                        onPressed: NavigationHelper.toggleDesktopQueue,
                        tooltip: isOpen ? 'Hide Queue' : 'Show Queue',
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  const _VolumeControl(),
                ],
              ),
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
                    ? AppTheme.brandRed
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
                    ? AppTheme.brandRed
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
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 5,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14,
                      ),
                      activeTrackColor: AppTheme.brandRed,
                      inactiveTrackColor:
                          isDark ? const Color(0xFF3A3A3A) : Colors.grey[300],
                      thumbColor: Colors.white,
                      overlayColor: AppTheme.brandRed.withValues(
                        alpha: 0.2,
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
                provider.toggleMute();
              },
              tooltip: isMuted ? 'Unmute' : 'Mute',
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            SizedBox(
              width: 100,
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 5,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 14,
                  ),
                  activeTrackColor: AppTheme.brandRed,
                  inactiveTrackColor:
                      isDark ? const Color(0xFF3A3A3A) : Colors.grey[300],
                  thumbColor: Colors.white,
                  overlayColor: AppTheme.brandRed.withValues(alpha: 0.2),
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
