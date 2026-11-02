import 'dart:io';
import 'package:flutter/cupertino.dart' hide RepeatMode;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:cached_network_image/cached_network_image.dart';
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
import 'package:musly/widgets/common/glass_container.dart';
import 'package:musly/screens/player/now_playing_screen.dart';
import 'package:musly/widgets/modals/song_options_modal.dart';

const double _kGlassMiniPlayerHeight = 56;

class MiniPlayer extends StatelessWidget {
  final VoidCallback? onTap;

  const MiniPlayer({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
    if (isDesktop && ScreenHelper.isDesktop(context)) return const SizedBox.shrink();

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
            final subsonic =
                Provider.of<SubsonicService>(context, listen: false);
            final coverUrl = currentSong.coverArt != null
                ? subsonic.getCoverArtUrl(currentSong.coverArt, size: 800)
                : null;
            final imageProvider = (coverUrl != null && coverUrl.isNotEmpty)
                ? CachedNetworkImageProvider(coverUrl) as ImageProvider
                : const AssetImage('assets/logo.png') as ImageProvider;
            final topPadding = MediaQuery.of(context).padding.top;

            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useRootNavigator: true,
              backgroundColor: Colors.transparent,
              constraints: const BoxConstraints(maxWidth: double.infinity),
              builder: (ctx) => NowPlayingScreen(
                topPadding: topPadding,
                image: imageProvider,
                title: currentSong.title,
                artist: (currentSong.artistParticipants?.isNotEmpty == true
                        ? currentSong.artistParticipants!
                            .map((a) => a.name)
                            .join(', ')
                        : currentSong.artist) ??
                    '',
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
          subtitle = currentSong.artistParticipants != null &&
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
          isGlass: isGlass,
        );

        if (isGlass) {
          // iOS 26-style floating Liquid Glass capsule.
          return RepaintBoundary(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
              child: GlassContainer.capsule(
                height: _kGlassMiniPlayerHeight,
                onTap: handleTap,
                onLongPress: currentSong != null
                    ? () => SongOptionsModal.show(context, currentSong)
                    : null,
                child: Stack(
                  children: [
                    Positioned.fill(child: row),
                    // Inset hairline progress, kept clear of the rounded ends.
                    const Positioned(
                      left: _kGlassMiniPlayerHeight / 2 - 4,
                      right: _kGlassMiniPlayerHeight / 2 - 4,
                      bottom: 3,
                      child: _MiniPlayerProgressBar(isGlass: true),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return RepaintBoundary(
          child: GestureDetector(
            onTap: handleTap,
            onLongPress: currentSong != null
                ? () => SongOptionsModal.show(context, currentSong)
                : null,
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.95)
                    : Colors.white.withValues(alpha: 0.95),
                border: Border(
                  top: BorderSide(
                    color:
                        isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
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
                    child:
                        _MiniPlayerProgressBar(borderRadius: 0, isGlass: false),
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

    return Selector<PlayerProvider, (Duration, int?, bool)>(
      selector: (_, p) =>
          (p.duration, p.currentSong?.duration, p.isPlayingRadio),
      builder: (context, data, _) {
        final (duration, songDurationSec, isRadio) = data;
        if (isRadio) return const SizedBox.shrink();

        final trackColor = isDark
            ? (isGlass
                ? Colors.white.withValues(alpha: 0.14)
                : Colors.white.withValues(alpha: 0.12))
            : (isGlass
                ? Colors.black.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.08));

        // Glass: a free-floating rounded hairline. Classic: flush bottom bar.
        final double barHeight = isGlass ? 2.0 : 2.5;
        final BorderRadius clipRadius = isGlass
            ? BorderRadius.circular(barHeight / 2)
            : BorderRadius.vertical(bottom: Radius.circular(borderRadius));

        final totalMs = duration.inMilliseconds > 0
            ? duration.inMilliseconds
            : (songDurationSec != null && songDurationSec > 0
                ? songDurationSec * 1000
                : 0);

        final playerProvider = context.read<PlayerProvider>();

        return StreamBuilder<Duration>(
          stream: playerProvider.positionStream,
          initialData: playerProvider.position,
          builder: (context, snapshot) {
            final position = snapshot.data ?? playerProvider.position;
            final progress = totalMs > 0
                ? (position.inMilliseconds / totalMs).clamp(0.0, 1.0)
                : 0.0;
            final cleanProgress = progress.isNaN || progress.isInfinite
                ? 0.0
                : progress.clamp(0.0, 1.0);

            final Widget bar = ClipRRect(
              borderRadius: clipRadius,
              child: Container(
                height: barHeight,
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
                      borderRadius: isGlass
                          ? clipRadius
                          : (cleanProgress >= 0.98
                              ? BorderRadius.vertical(
                                  bottom: Radius.circular(borderRadius))
                              : BorderRadius.zero),
                    ),
                  ),
                ),
              ),
            );
            // Keep per-tick progress repaints from repainting the glass layers.
            return isGlass ? RepaintBoundary(child: bar) : bar;
          },
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
  final bool isGlass;

  const _MiniPlayerRow({
    required this.title,
    required this.subtitle,
    required this.coverArt,
    required this.isPlayingRadio,
    this.isGlass = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Glass capsule: artwork inset equally from top/left/bottom so it nests
    // inside the rounded end; controls tuck closer to the trailing curve.
    final double artSize = isGlass ? 40 : 44;
    final double artRadius = isGlass ? 8 : 6;
    final EdgeInsets padding = isGlass
        ? const EdgeInsets.only(
            left: (_kGlassMiniPlayerHeight - 40) / 2, right: 6)
        : const EdgeInsets.symmetric(horizontal: 16);
    return Padding(
      padding: padding,
      child: Row(
        children: [
          if (isPlayingRadio)
            Container(
              width: artSize,
              height: artSize,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFF2D55), Color(0xFFFF6B35)],
                ),
                borderRadius: BorderRadius.circular(artRadius),
              ),
              child: const Icon(Icons.radio, color: Colors.white, size: 24),
            )
          else
            AlbumArtwork(
                coverArt: coverArt, size: artSize, borderRadius: artRadius),
          SizedBox(width: isGlass ? 10 : 12),
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
          _MiniPlayerControls(isRadio: isPlayingRadio, isGlass: isGlass),
        ],
      ),
    );
  }
}

class _MiniPlayerControls extends StatelessWidget {
  final bool isRadio;
  final bool isGlass;

  const _MiniPlayerControls({this.isRadio = false, this.isGlass = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.white : Colors.black;

    // Glass uses SF Symbols-style filled Cupertino glyphs. They fill more of
    // their em-box than the Material rounded icons, hence the smaller sizes.
    final double iconSize =
        ScreenHelper.miniPlayerIconSize(context) - (isGlass ? 2 : 0);
    final double playIconSize =
        ScreenHelper.miniPlayerPlayIconSize(context) - (isGlass ? 6 : 0);
    final double skipIconSize =
        ScreenHelper.miniPlayerSkipIconSize(context) - (isGlass ? 4 : 0);
    final IconData playIcon =
        isGlass ? CupertinoIcons.play_fill : Icons.play_arrow_rounded;
    final IconData pauseIcon =
        isGlass ? CupertinoIcons.pause_fill : Icons.pause_rounded;
    final IconData skipIcon =
        isGlass ? CupertinoIcons.forward_fill : Icons.skip_next_rounded;
    final IconData heartIcon =
        isGlass ? CupertinoIcons.heart : Icons.favorite_border_rounded;
    final IconData heartFillIcon =
        isGlass ? CupertinoIcons.heart_fill : Icons.favorite_rounded;

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
                  valueListenable:
                      playerUiSettings.showMiniPlayerShuffleNotifier,
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
                                constraints: const BoxConstraints(
                                    minWidth: 36, minHeight: 36),
                                icon: Icon(
                                  isStarred ? heartFillIcon : heartIcon,
                                  size: iconSize,
                                ),
                                color: isStarred
                                    ? Theme.of(context).colorScheme.primary
                                    : color,
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
                                constraints: const BoxConstraints(
                                    minWidth: 36, minHeight: 36),
                                icon: Icon(
                                  CupertinoIcons.shuffle,
                                  size: iconSize,
                                ),
                                color: shuffleEnabled
                                    ? Theme.of(context).colorScheme.primary
                                    : color,
                              );
                            },
                          ),
                        IconButton(
                          onPressed: provider.togglePlayPause,
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(minWidth: 40, minHeight: 40),
                          icon: Icon(
                            isPlaying ? pauseIcon : playIcon,
                            size: playIconSize,
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
                                constraints: const BoxConstraints(
                                    minWidth: 36, minHeight: 36),
                                icon: Icon(icon, size: iconSize),
                                color: active
                                    ? Theme.of(context).colorScheme.primary
                                    : color,
                              );
                            },
                          ),
                        if (!isRadio)
                          IconButton(
                            onPressed: hasNext ? provider.skipNext : null,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 36, minHeight: 36),
                            icon: Icon(skipIcon, size: skipIconSize),
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
