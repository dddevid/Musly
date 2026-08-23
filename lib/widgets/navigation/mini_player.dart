import 'dart:io';
import 'package:flutter/cupertino.dart' hide RepeatMode;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:provider/provider.dart';
import 'package:musly/models/song.dart';
import 'package:musly/models/artist_ref.dart';
import 'package:musly/models/radio_station.dart';
import 'package:musly/providers/player_provider.dart';
import 'package:musly/services/player_ui_settings_service.dart';
import 'package:musly/services/theme_service.dart';
import 'package:musly/theme/app_theme.dart';
import 'package:musly/utils/screen_helper.dart';
import 'package:musly/services/subsonic_service.dart';
import 'package:musly/widgets/common/album_artwork.dart';
import 'package:musly/screens/player/now_playing_screen.dart';
import 'package:musly/services/musly_connect_service.dart';

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

        void handleTap() {
          if (onTap != null) {
            onTap!();
            return;
          }
          if (currentSong != null) {
            final subsonic = Provider.of<SubsonicService>(context, listen: false);
            final coverUrl = currentSong.coverArt != null ? subsonic.getCoverArtUrl(currentSong.coverArt, size: 600) : null;
            final imageProvider = coverUrl != null 
                ? CachedNetworkImageProvider(coverUrl) as ImageProvider
                : const AssetImage('assets/default_cover.png') as ImageProvider;
            final topPadding = MediaQuery.of(context).padding.top;    

            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useRootNavigator: true,
              backgroundColor: Colors.transparent,
              builder: (ctx) => NowPlayingScreen(
                topPadding: topPadding,
                image: imageProvider,
                title: currentSong.title,
                artist: (currentSong.artistParticipants?.isNotEmpty == true
                    ? currentSong.artistParticipants!.map((a) => a.name).join(', ')
                    : currentSong.artist) ?? '',
                heroTag: 'cover_${currentSong.id}',
                song: currentSong,
              ),
            );
          }
        }

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
              : (currentSong.artist != null
                  ? ArtistRef.splitArtistNames(currentSong.artist!).join(', ')
                  : null);
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
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: GestureDetector(
                onTap: handleTap,
                child: Container(
                  height: 64,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xF01C1C1E)
                        : const Color(0xF5FFFFFF),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.14)
                          : Colors.black.withValues(alpha: 0.08),
                      width: 0.8,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(child: row),
                      const Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _MiniPlayerProgressBar(borderRadius: 22, isGlass: true),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return RepaintBoundary(
          child: GestureDetector(
            onTap: handleTap,
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
              child: Stack(
                children: [
                  Positioned.fill(child: row),
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _MiniPlayerProgressBar(borderRadius: 0, isGlass: false),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Smooth, high-precision progress bar for the mini player.
class _MiniPlayerProgressBar extends StatelessWidget {
  final double borderRadius;
  final bool isGlass;

  const _MiniPlayerProgressBar({
    this.borderRadius = 0,
    this.isGlass = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Selector<PlayerProvider, (double, bool)>(
      selector: (_, p) => (p.progress, p.isPlayingRadio),
      builder: (context, data, _) {
        final (progress, isRadio) = data;
        if (isRadio) return const SizedBox.shrink();

        final cleanProgress = progress.isNaN || progress.isInfinite
            ? 0.0
            : progress.clamp(0.0, 1.0);

        final trackColor = isDark
            ? (isGlass ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.12))
            : (isGlass ? Colors.black.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.08));

        return ClipRRect(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(borderRadius)),
          child: Container(
            height: 2.5,
            width: double.infinity,
            color: trackColor,
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: cleanProgress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primary,
                      primary.withValues(alpha: 0.85),
                    ],
                  ),
                  borderRadius: cleanProgress >= 0.98
                      ? BorderRadius.vertical(bottom: Radius.circular(borderRadius))
                      : BorderRadius.zero,
                ),
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
                      Consumer<MuslyConnectService>(
                        builder: (context, connect, _) {
                          if (!connect.isControllingRemoteDevice) return const SizedBox.shrink();
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1DB954).withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFF1DB954).withValues(alpha: 0.4), width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.devices_rounded, size: 10, color: Color(0xFF1DB954)),
                                const SizedBox(width: 3),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 80),
                                  child: Text(
                                    connect.activeRemoteDevice?.name ?? 'Connected',
                                    style: const TextStyle(
                                      color: Color(0xFF1DB954),
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
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
                                color: isStarred ? AppTheme.brandRed : color,
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
