import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/jukebox_service.dart';
import '../services/subsonic_service.dart';
import '../theme/app_theme.dart';
import '../widgets/album_artwork.dart';

class JukeboxScreen extends StatefulWidget {
  const JukeboxScreen({super.key});

  @override
  State<JukeboxScreen> createState() => _JukeboxScreenState();
}

class _JukeboxScreenState extends State<JukeboxScreen> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _refresh() {
    final jukebox = context.read<JukeboxService>();
    final subsonic = context.read<SubsonicService>();
    jukebox.refresh(subsonic);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.jukeboxMode),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.refresh),
            onPressed: _refresh,
            tooltip: l10n.refresh,
          ),
        ],
      ),
      body: Consumer<JukeboxService>(
        builder: (context, jukebox, _) {
          final status = jukebox.status;
          final song = status.currentSong;

          // ── Error / not-supported banner ─────────────────────────────
          if (jukebox.serverUnsupported) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.exclamationmark_triangle,
                      size: 56,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.jukeboxNotSupported,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(CupertinoIcons.refresh),
                      label: Text(l10n.refresh),
                    ),
                  ],
                ),
              ),
            );
          }

          if (jukebox.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.wifi_slash,
                      size: 56,
                      color: isDark
                          ? AppTheme.darkSecondaryText
                          : AppTheme.lightSecondaryText,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      jukebox.error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(CupertinoIcons.refresh),
                      label: Text(l10n.refresh),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              // ── Now Playing ────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Artwork
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AlbumArtwork(
                        coverArt: song?.coverArt,
                        size: 200,
                        borderRadius: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Title + Artist
                    Text(
                      song?.title ?? l10n.noSongPlaying,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (song?.artist != null)
                      Text(
                        song!.artist!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppTheme.darkSecondaryText
                              : AppTheme.lightSecondaryText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 24),

                    // ── Playback Controls ──────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ControlButton(
                          icon: CupertinoIcons.backward_fill,
                          onPressed: jukebox.isLoading
                              ? null
                              : () {
                                  final subsonic = context
                                      .read<SubsonicService>();
                                  jukebox.skipPrevious(subsonic);
                                },
                        ),
                        _ControlButton(
                          icon: status.playing
                              ? CupertinoIcons.pause_fill
                              : CupertinoIcons.play_fill,
                          size: 56,
                          isPrimary: true,
                          onPressed: jukebox.isLoading
                              ? null
                              : () {
                                  final subsonic = context
                                      .read<SubsonicService>();
                                  if (status.playing) {
                                    jukebox.pause(subsonic);
                                  } else {
                                    jukebox.play(subsonic);
                                  }
                                },
                        ),
                        _ControlButton(
                          icon: CupertinoIcons.forward_fill,
                          onPressed: jukebox.isLoading
                              ? null
                              : () {
                                  final subsonic = context
                                      .read<SubsonicService>();
                                  jukebox.skipNext(subsonic);
                                },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Volume / Gain ───────────────────────────────────
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.volume_mute,
                          size: 18,
                          color: isDark
                              ? AppTheme.darkSecondaryText
                              : AppTheme.lightSecondaryText,
                        ),
                        Expanded(
                          child: Slider(
                            value: status.gain.clamp(0.0, 1.0),
                            activeColor: AppTheme.appleMusicRed,
                            onChanged: (v) {
                              final subsonic = context.read<SubsonicService>();
                              jukebox.setGain(subsonic, v);
                            },
                          ),
                        ),
                        Icon(
                          CupertinoIcons.volume_up,
                          size: 18,
                          color: isDark
                              ? AppTheme.darkSecondaryText
                              : AppTheme.lightSecondaryText,
                        ),
                      ],
                    ),

                    // ── Extra Actions ────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton.icon(
                          onPressed: jukebox.isLoading
                              ? null
                              : () {
                                  final subsonic = context
                                      .read<SubsonicService>();
                                  jukebox.shuffleQueue(subsonic);
                                },
                          icon: const Icon(CupertinoIcons.shuffle),
                          label: Text(l10n.shuffle),
                        ),
                        TextButton.icon(
                          onPressed: jukebox.isLoading
                              ? null
                              : () {
                                  final subsonic = context
                                      .read<SubsonicService>();
                                  jukebox.clearQueue(subsonic);
                                },
                          icon: const Icon(CupertinoIcons.trash),
                          label: Text(l10n.jukeboxClearQueue),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Queue ──────────────────────────────────────────────────
              if (status.playlist.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Text(
                        l10n.queue,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        '${status.playlist.length} ${l10n.songs.toLowerCase()}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: status.playlist.length,
                    itemBuilder: (context, index) {
                      final s = status.playlist[index];
                      final isCurrent = index == status.currentIndex;
                      return ListTile(
                        dense: true,
                        leading: isCurrent
                            ? Icon(
                                CupertinoIcons.speaker_2_fill,
                                color: AppTheme.appleMusicRed,
                                size: 20,
                              )
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isDark
                                      ? AppTheme.darkSecondaryText
                                      : AppTheme.lightSecondaryText,
                                ),
                              ),
                        title: Text(
                          s.title,
                          style: TextStyle(
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isCurrent ? AppTheme.appleMusicRed : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: s.artist != null
                            ? Text(
                                s.artist!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        onTap: () {
                          final subsonic = context.read<SubsonicService>();
                          jukebox.skip(subsonic, index);
                        },
                        trailing: IconButton(
                          icon: const Icon(CupertinoIcons.trash, size: 18),
                          onPressed: () {
                            final subsonic = context.read<SubsonicService>();
                            jukebox.removeFromQueue(subsonic, index);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ] else
                Expanded(
                  child: Center(
                    child: Text(
                      l10n.jukeboxQueueEmpty,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppTheme.darkSecondaryText
                            : AppTheme.lightSecondaryText,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final bool isPrimary;

  const _ControlButton({
    required this.icon,
    required this.onPressed,
    this.size = 40,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return SizedBox(
        width: size + 16,
        height: size + 16,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            backgroundColor: AppTheme.appleMusicRed,
            foregroundColor: Colors.white,
            padding: EdgeInsets.zero,
          ),
          child: Icon(icon, size: size * 0.6),
        ),
      );
    }
    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      iconSize: size * 0.7,
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : Colors.black,
    );
  }
}
