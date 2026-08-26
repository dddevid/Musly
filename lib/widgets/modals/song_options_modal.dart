import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/artist_ref.dart';
import '../../models/song.dart';
import '../../utils/navigation_helper.dart';
import '../../providers/player_provider.dart';
import '../../providers/library_provider.dart';
import '../../services/jukebox_service.dart';
import '../../services/subsonic_service.dart';
import '../../services/offline_service.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../common/album_artwork.dart';
import '../common/multi_artist_widget.dart';
import '../../screens/detail/album_screen.dart';
import '../../screens/detail/artist_screen.dart';

class SongOptionsModal extends StatefulWidget {
  static Future<void> show(BuildContext context, Song song) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SongOptionsModal(song: song),
    );
  }

  final Song song;

  const SongOptionsModal({super.key, required this.song});

  @override
  State<SongOptionsModal> createState() => _SongOptionsModalState();
}

class _SongOptionsModalState extends State<SongOptionsModal> {
  late bool _isStarred;
  bool _isDownloaded = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  final _offlineService = OfflineService();

  @override
  void initState() {
    super.initState();
    _isStarred = widget.song.starred ?? false;
    _checkDownloadStatus();
  }

  void _checkDownloadStatus() {
    _isDownloaded = _offlineService.isSongDownloaded(widget.song.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  AlbumArtwork(coverArt: widget.song.coverArt, size: 60),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.song.title,
                          style: theme.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.song.artist != null)
                          Text(
                            widget.song.artist!,
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _OptionTile(
                      icon: _isStarred
                          ? CupertinoIcons.heart_fill
                          : CupertinoIcons.heart,
                      title: _isStarred
                          ? 'Remove from Liked Songs'
                          : 'Add to Liked Songs',
                      iconColor: _isStarred
                          ? Theme.of(context).colorScheme.primary
                          : null,
                      onTap: () async {
                        await _toggleFavorite(context);
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                    _OptionTile(
                      icon: Icons.play_arrow_rounded,
                      title: 'Play Next',
                      onTap: () {
                        playerProvider.addToQueueNext(widget.song);
                        Navigator.pop(context);
                      },
                    ),
                    _OptionTile(
                      icon: Icons.queue_music_rounded,
                      title: 'Add to Queue',
                      onTap: () {
                        playerProvider.addToQueue(widget.song);
                        Navigator.pop(context);
                      },
                    ),
                    Builder(
                      builder: (context) {
                        final jukebox = Provider.of<JukeboxService>(
                          context,
                          listen: false,
                        );
                        final subsonic = Provider.of<SubsonicService>(
                          context,
                          listen: false,
                        );
                        if (!jukebox.enabled) return const SizedBox.shrink();
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _OptionTile(
                              icon: Icons.speaker_rounded,
                              title: AppLocalizations.of(
                                context,
                              )!
                                  .playOnJukebox,
                              onTap: () {
                                Navigator.pop(context);
                                jukebox.setQueue(
                                    subsonic,
                                    [
                                      widget.song,
                                    ],
                                    startIndex: 0);
                              },
                            ),
                            _OptionTile(
                              icon: Icons.queue_rounded,
                              title: AppLocalizations.of(
                                context,
                              )!
                                  .addToJukeboxQueue,
                              onTap: () {
                                Navigator.pop(context);
                                jukebox.addToQueue(subsonic, [widget.song]);
                              },
                            ),
                          ],
                        );
                      },
                    ),
                    _OptionTile(
                      icon: Icons.playlist_add_rounded,
                      title: AppLocalizations.of(context)!.addToPlaylist,
                      onTap: () {
                        Navigator.pop(context);
                        _showPlaylistPicker(context, widget.song);
                      },
                    ),
                    _OptionTile(
                      icon: Icons.album_rounded,
                      title: 'Go to Album',
                      onTap: () {
                        Navigator.pop(context);
                        if (widget.song.albumId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AlbumScreen(albumId: widget.song.albumId!),
                            ),
                          );
                        }
                      },
                    ),
                    _OptionTile(
                      icon: Icons.person_rounded,
                      title: 'Go to Artist',
                      onTap: () {
                        final nav = Navigator.of(context);
                        nav.pop();
                        _navigateToArtist(nav);
                      },
                    ),
                    _buildRatingTile(context),
                    _buildDownloadTile(context),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadTile(BuildContext context) {
    final isOffline = Provider.of<AuthProvider>(context, listen: false).state ==
        AuthState.offlineMode;

    if (_isDownloading) {
      return ListTile(
        leading: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            value: _downloadProgress > 0 ? _downloadProgress : null,
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          AppLocalizations.of(
            context,
          )!
              .downloading((_downloadProgress * 100).toInt()),
        ),
      );
    }

    if (_isDownloaded) {
      return _OptionTile(
        icon: Icons.download_done_rounded,
        title: AppLocalizations.of(context)!.downloaded,
        iconColor: Colors.green,
        onTap: () async {
          final l10n = AppLocalizations.of(context)!;
          final messenger = ScaffoldMessenger.of(context);
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(AppLocalizations.of(context)!.removeDownload),
              content: Text(
                AppLocalizations.of(context)!.removeDownloadConfirm,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(AppLocalizations.of(context)!.remove),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await _offlineService.deleteSong(widget.song.id);
            if (mounted) {
              setState(() {
                _isDownloaded = false;
              });
              messenger.showSnackBar(
                SnackBar(
                  content: Text(l10n.downloadRemoved),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        },
      );
    }

    if (isOffline) return const SizedBox.shrink();

    return _OptionTile(
      icon: Icons.download_rounded,
      title: 'Download',
      onTap: () => _downloadSong(context),
    );
  }

  Future<void> _downloadSong(BuildContext context) async {
    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final success = await _offlineService.downloadSong(
        widget.song,
        subsonicService,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress = progress;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _isDownloaded = success;
        });

        if (success) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(l10n.downloadedTitle(widget.song.title)),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          messenger.showSnackBar(
            SnackBar(
              content: Text(l10n.downloadFailed),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.downloadError(e)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildRatingTile(BuildContext context) {
    final rating = widget.song.userRating ?? 0;
    return _OptionTile(
      icon: Icons.star_rounded,
      title: rating > 0
          ? 'Rate Song ($rating ${rating == 1 ? "star" : "stars"})'
          : 'Rate Song',
      iconColor: rating > 0 ? Colors.amber : null,
      onTap: () => _showRatingDialog(context),
    );
  }

  Future<void> _showRatingDialog(BuildContext context) async {
    final currentRating = widget.song.userRating ?? 0;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.rateSong),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.song.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starValue = index + 1;
                return Flexible(
                  child: IconButton(
                    icon: Icon(
                      starValue <= currentRating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _setRating(context, starValue);
                    },
                  ),
                );
              }),
            ),
            if (currentRating > 0) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _setRating(context, 0);
                },
                child: Text(AppLocalizations.of(ctx)!.removeRating),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx)!.cancel),
          ),
        ],
      ),
    );
  }

  Future<void> _setRating(BuildContext context, int rating) async {
    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    try {
      await subsonicService.setRating(widget.song.id, rating);

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              rating > 0
                  ? 'Rated $rating ${rating == 1 ? "star" : "stars"}'
                  : 'Rating removed',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.failedToSetRating(e)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _toggleFavorite(BuildContext context) async {
    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    try {
      if (_isStarred) {
        await subsonicService.unstar(id: widget.song.id);
        setState(() {
          _isStarred = false;
        });
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(l10n.removedFromLikedSongs),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        await subsonicService.star(id: widget.song.id);
        setState(() {
          _isStarred = true;
        });
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(l10n.addedToLikedSongs),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _navigateToArtist(NavigatorState nav) {
    final participants = ArtistRef.fromListOrFallback(
      widget.song.artistParticipants,
      fallbackName: widget.song.artist,
      fallbackId: widget.song.artistId,
    );

    if (participants.length > 1) {
      final ctx = NavigationHelper.navigatorKey.currentContext;
      if (ctx == null) return;
      showModalBottomSheet(
        context: ctx,
        backgroundColor: Colors.transparent,
        builder: (sheetCtx) => ArtistsBottomSheet(
          artists: participants,
          onArtistTap: (artist) {
            Navigator.pop(sheetCtx);
            _pushArtist(nav, artist);
          },
        ),
      );
      return;
    }

    final single = participants.firstOrNull;
    if (single != null) {
      _pushArtist(nav, single);
      return;
    }

    final artistId = widget.song.artistId;
    if (artistId != null && artistId.isNotEmpty) {
      nav.push(
        MaterialPageRoute(builder: (_) => ArtistScreen(artistId: artistId)),
      );
    }
  }

  void _pushArtist(NavigatorState nav, ArtistRef artist) {
    if (artist.id.isNotEmpty) {
      nav.push(
        MaterialPageRoute(builder: (_) => ArtistScreen(artistId: artist.id)),
      );
    } else if (artist.name.isNotEmpty) {
      final ctx = NavigationHelper.navigatorKey.currentContext;
      if (ctx != null) {
        final subsonic = Provider.of<SubsonicService>(ctx, listen: false);
        subsonic
            .search(artist.name, artistCount: 3, albumCount: 0, songCount: 0)
            .then((res) {
          if (res.artists.isNotEmpty) {
            final matched = res.artists.firstWhere(
              (a) => a.name.toLowerCase() == artist.name.toLowerCase(),
              orElse: () => res.artists.first,
            );
            nav.push(MaterialPageRoute(
                builder: (_) => ArtistScreen(artistId: matched.id)));
          }
        }).catchError((_) {});
      }
    }
  }

  void _showPlaylistPicker(BuildContext context, Song song) {
    final libraryProvider = Provider.of<LibraryProvider>(
      context,
      listen: false,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text(
                    AppLocalizations.of(context)!.addToPlaylist,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (libraryProvider.playlists.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(AppLocalizations.of(context)!.noPlaylists),
              )
            else
              ...libraryProvider.playlists.map(
                (playlist) => ListTile(
                  leading: const Icon(Icons.queue_music_rounded),
                  title: Text(playlist.name),
                  subtitle: Text(AppLocalizations.of(context)!
                      .songsCount(playlist.songCount ?? 0)),
                  onTap: () async {
                    Navigator.pop(context);

                    final subsonicService = Provider.of<SubsonicService>(
                      context,
                      listen: false,
                    );
                    final l10n = AppLocalizations.of(context)!;
                    final messenger = ScaffoldMessenger.of(context);

                    bool isDuplicate = false;
                    try {
                      final fullPlaylist =
                          await subsonicService.getPlaylist(playlist.id);
                      final existingSongs =
                          fullPlaylist.songs ?? playlist.songs ?? [];
                      isDuplicate = existingSongs.any(
                        (s) =>
                            s.id == song.id ||
                            (s.title.trim().toLowerCase() ==
                                    song.title.trim().toLowerCase() &&
                                (s.artist ?? '').trim().toLowerCase() ==
                                    (song.artist ?? '').trim().toLowerCase()),
                      );
                    } catch (_) {
                      if (playlist.songs != null) {
                        isDuplicate =
                            playlist.songs!.any((s) => s.id == song.id);
                      }
                    }

                    if (isDuplicate) {
                      if (!context.mounted) return;
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(l10n.alreadyInPlaylist),
                          content: Text(
                            l10n.alreadyInPlaylistConfirm(
                                song.title, playlist.name),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(l10n.cancel),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(l10n.addAnyway),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true) return;
                    }

                    try {
                      debugPrint(
                        'Attempting to add song ${song.id} (${song.title}) to playlist ${playlist.id} (${playlist.name})',
                      );

                      await subsonicService.updatePlaylist(
                        playlistId: playlist.id,
                        songIdsToAdd: [song.id],
                      );

                      debugPrint('Successfully added song to playlist via API');

                      await libraryProvider.loadPlaylists();

                      debugPrint('Playlists refreshed');

                      messenger.showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Added "${song.title}" to ${playlist.name}',
                                ),
                              ),
                            ],
                          ),
                          duration: const Duration(seconds: 2),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      debugPrint('Error adding song to playlist: $e');
                      messenger.showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.error, color: Colors.white),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(l10n.errorAddingToPlaylist(e)),
                              ),
                            ],
                          ),
                          duration: const Duration(seconds: 3),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? Theme.of(context).colorScheme.primary,
      ),
      title: Text(title),
      onTap: onTap,
    );
  }
}
