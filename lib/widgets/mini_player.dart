import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart' hide RepeatMode;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../models/radio_station.dart';
import '../providers/player_provider.dart';
import '../services/player_ui_settings_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../utils/screen_helper.dart';
import 'album_artwork.dart';

class MiniPlayer extends StatelessWidget {
  final VoidCallback? onTap;

  const MiniPlayer({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
    if (isDesktop) return const SizedBox.shrink();

    return Selector<PlayerProvider, (Song?, RadioStation?, bool)>(
      selector: (_, p) =>
          (p.currentSong, p.currentRadioStation, p.isPlayingRadio),
      builder: (context, data, _) {
        final (currentSong, currentRadioStation, isPlayingRadio) = data;

        if (currentSong == null && !isPlayingRadio) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        final String title;
        final String? subtitle;
        final String? coverArt;

        if (isPlayingRadio && currentRadioStation != null) {
          title = currentRadioStation.name;
          subtitle = 'Internet Radio • LIVE';
          coverArt = null;
        } else if (currentSong != null) {
          title = currentSong.title;
          subtitle =
              currentSong.artistParticipants != null &&
                  currentSong.artistParticipants!.isNotEmpty
              ? currentSong.artistParticipants!.map((a) => a.name).join(', ')
              : currentSong.artist;
          coverArt = currentSong.coverArt;
        } else {
          return const SizedBox.shrink();
        }

        final bool isGlass = Provider.of<ThemeService>(context).liquidGlass;

        final Widget row = _MiniPlayerRow(
          title: title,
          subtitle: subtitle,
          coverArt: coverArt,
          isPlayingRadio: isPlayingRadio,
        );

        if (isGlass) {
          return RepaintBoundary(
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                  child: GestureDetector(
                    onTap: onTap,
                    child: Container(
                      height: 64,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.45)
                            : Colors.white.withValues(alpha: 0.62),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.14)
                              : Colors.white.withValues(alpha: 0.85),
                          width: 0.8,
                        ),
                      ),
                      child: row,
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return RepaintBoundary(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.95)
                    : Colors.white.withValues(alpha: 0.95),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? AppTheme.darkDivider
                        : AppTheme.lightDivider,
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                children: [
                  if (!isPlayingRadio)
                    Selector<PlayerProvider, double>(
                      selector: (ctx, p) => p.progress,
                      builder: (ctx, progress, __) => LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                        minHeight: 2,
                      ),
                    )
                  else
                    const SizedBox(height: 2),
                  Expanded(child: row),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MiniPlayerRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? coverArt;
  final bool isPlayingRadio;

  const _MiniPlayerRow({
    required this.title,
    required this.subtitle,
    required this.coverArt,
    required this.isPlayingRadio,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (isPlayingRadio)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFF2D55), Color(0xFFFF6B35)],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.radio, color: Colors.white, size: 24),
            )
          else
            AlbumArtwork(coverArt: coverArt, size: 44, borderRadius: 6),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Row(
                    children: [
                      if (isPlayingRadio) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      Expanded(
                        child: Text(
                          isPlayingRadio ? 'Internet Radio' : subtitle!,
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          _MiniPlayerControls(isRadio: isPlayingRadio),
        ],
      ),
    );
  }
}

class _MiniPlayerControls extends StatelessWidget {
  final bool isRadio;

  const _MiniPlayerControls({this.isRadio = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.white : Colors.black;

    return Selector<PlayerProvider, (bool, bool)>(
      selector: (_, p) => (p.isPlaying, p.hasNext),
      builder: (context, data, _) {
        final (isPlaying, hasNext) = data;
        final provider = context.read<PlayerProvider>();
        final playerUiSettings = PlayerUiSettingsService();

        return ValueListenableBuilder<bool>(
          valueListenable: playerUiSettings.showMiniPlayerHeartNotifier,
          builder: (context, showHeart, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: playerUiSettings.showMiniPlayerRepeatNotifier,
              builder: (context, showRepeat, _) {
                return ValueListenableBuilder<bool>(
                  valueListenable: playerUiSettings.showMiniPlayerShuffleNotifier,
                  builder: (context, showShuffle, _) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showHeart && !isRadio)
                          Selector<PlayerProvider, bool>(
                            selector: (_, p) => p.currentSong?.starred == true,
                            builder: (context, isStarred, _) {
                              return IconButton(
                                onPressed: provider.toggleFavorite,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                icon: Icon(
                                  isStarred ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  size: ScreenHelper.miniPlayerIconSize(context),
                                ),
                                color: isStarred ? AppTheme.appleMusicRed : color,
                              );
                            },
                          ),

                        if (showShuffle && !isRadio)
                          Selector<PlayerProvider, bool>(
                            selector: (_, p) => p.shuffleEnabled,
                            builder: (context, shuffleEnabled, _) {
                              return IconButton(
                                onPressed: provider.toggleShuffle,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                icon: Icon(
                                  CupertinoIcons.shuffle,
                                  size: ScreenHelper.miniPlayerIconSize(context),
                                ),
                                color: shuffleEnabled ? Theme.of(context).colorScheme.primary : color,
                              );
                            },
                          ),

                        IconButton(
                          onPressed: provider.togglePlayPause,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                          icon: Icon(
                            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            size: ScreenHelper.miniPlayerPlayIconSize(context),
                          ),
                          color: color,
                        ),

                        if (showRepeat && !isRadio)
                          Selector<PlayerProvider, RepeatMode>(
                            selector: (_, p) => p.repeatMode,
                            builder: (context, repeatMode, _) {
                              IconData icon;
                              bool active = repeatMode != RepeatMode.off;
                              if (repeatMode == RepeatMode.one) {
                                icon = CupertinoIcons.repeat_1;
                              } else {
                                icon = CupertinoIcons.repeat;
                              }
                              return IconButton(
                                onPressed: provider.toggleRepeat,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                icon: Icon(icon, size: ScreenHelper.miniPlayerIconSize(context)),
                                color: active ? Theme.of(context).colorScheme.primary : color,
                              );
                            },
                          ),

                        if (!isRadio)
                          IconButton(
                            onPressed: hasNext ? provider.skipNext : null,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            icon: Icon(Icons.skip_next_rounded, size: ScreenHelper.miniPlayerSkipIconSize(context)),
                            color: color,
                          ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
