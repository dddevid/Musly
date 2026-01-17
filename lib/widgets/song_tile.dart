import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../providers/library_provider.dart';
import '../services/subsonic_service.dart';
import '../services/offline_service.dart';
import '../theme/app_theme.dart';
import 'album_artwork.dart';
import 'animated_equalizer.dart';
import '../screens/album_screen.dart';
import '../screens/artist_screen.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final List<Song>? playlist;
  final int? index;
  final bool showArtwork;
  final bool showArtist;
  final bool showAlbum;
  final bool showDuration;
  final bool showTrackNumber;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const SongTile({
    super.key,
    required this.song,
    this.playlist,
    this.index,
    this.showArtwork = true,
    this.showArtist = true,
    this.showAlbum = false,
    this.showDuration = true,
    this.showTrackNumber = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Use Selector to only rebuild when currentSong.id changes
    return Selector<PlayerProvider, String?>(
      selector: (_, provider) => provider.currentSong?.id,
      builder: (context, currentSongId, _) {
        final isCurrentSong = currentSongId == song.id;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: _buildLeading(context, isCurrentSong),
          title: Text(
            song.title,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isCurrentSong ? AppTheme.appleMusicRed : null,
              fontWeight: isCurrentSong ? FontWeight.w600 : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: showArtist || showAlbum
              ? Text(
                  _buildSubtitle(),
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: _buildTrailing(context),
          onTap: onTap ?? () => _playSong(context),
          onLongPress: onLongPress ?? () => _showOptions(context),
        );
      },
    );
  }

  Widget? _buildLeading(BuildContext context, bool isCurrentSong) {
    if (showTrackNumber && !showArtwork) {
      return SizedBox(
        width: 30,
        child: Center(
          child: isCurrentSong
              ? Selector<PlayerProvider, bool>(
                  selector: (_, p) => p.isPlaying,
                  builder: (_, isPlaying, __) => AnimatedEqualizer(
                    color: AppTheme.appleMusicRed,
                    isPlaying: isPlaying,
                  ),
                )
              : Text(
                  '${song.track ?? index ?? 1}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightSecondaryText,
                  ),
                ),
        ),
      );
    }

    if (showArtwork) {
      return Stack(
        children: [
          AlbumArtwork(coverArt: song.coverArt, size: 50, borderRadius: 6),
          if (isCurrentSong)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Selector<PlayerProvider, bool>(
                    selector: (_, p) => p.isPlaying,
                    builder: (_, isPlaying, __) => AnimatedEqualizer(
                      color: Colors.white,
                      isPlaying: isPlaying,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    return null;
  }

  String _buildSubtitle() {
    final parts = <String>[];
    if (showArtist && song.artist != null) {
      parts.add(song.artist!);
    }
    if (showAlbum && song.album != null) {
      parts.add(song.album!);
    }
    return parts.join(' • ');
  }

  Widget _buildTrailing(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (song.starred == true)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              CupertinoIcons.heart_fill,
              size: 14,
              color: AppTheme.appleMusicRed.withValues(alpha: 0.7),
            ),
          ),
        if (showDuration)
          Text(
            song.formattedDuration,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.more_horiz),
          iconSize: 20,
          color: Theme.of(context).textTheme.bodySmall?.color,
          onPressed: () => _showOptions(context),
        ),
      ],
    );
  }

  void _playSong(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    playerProvider.playSong(song, playlist: playlist, startIndex: index);
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _SongOptionsSheet(song: song),
    );
  }
}

class _SongOptionsSheet extends StatefulWidget {
  final Song song;

  const _SongOptionsSheet({required this.song});

  @override
  State<_SongOptionsSheet> createState() => _SongOptionsSheetState();
}

class _SongOptionsSheetState extends State<_SongOptionsSheet> {
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
                  AlbumArtwork(
                    coverArt: widget.song.coverArt,
                    size: 60,
                    borderRadius: 8,
                  ),
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
                      iconColor: _isStarred ? AppTheme.appleMusicRed : null,
                      onTap: () async {
                        await _toggleFavorite(context);
                        if (mounted) {
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
                    _OptionTile(
                      icon: Icons.playlist_add_rounded,
                      title: 'Add to Playlist',
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
                        Navigator.pop(context);
                        if (widget.song.artistId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ArtistScreen(artistId: widget.song.artistId!),
                            ),
                          );
                        }
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
    if (_isDownloading) {
      return ListTile(
        leading: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            value: _downloadProgress > 0 ? _downloadProgress : null,
            strokeWidth: 2,
            color: AppTheme.appleMusicRed,
          ),
        ),
        title: Text('Downloading... ${(_downloadProgress * 100).toInt()}%'),
      );
    }

    if (_isDownloaded) {
      return _OptionTile(
        icon: Icons.download_done_rounded,
        title: 'Downloaded',
        iconColor: Colors.green,
        onTap: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Remove Download'),
              content: const Text('Remove this song from offline storage?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Remove'),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Download removed'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        },
      );
    }

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Downloaded "${widget.song.title}"'),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Download failed'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download error: $e'),
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
        title: const Text('Rate Song'),
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
                child: const Text('Remove Rating'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
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

    try {
      await subsonicService.setRating(widget.song.id, rating);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              rating > 0
                  ? 'Rated ${rating} ${rating == 1 ? "star" : "stars"}'
                  : 'Rating removed',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to set rating: $e'),
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

    try {
      if (_isStarred) {
        await subsonicService.unstar(id: widget.song.id);
        setState(() {
          _isStarred = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removed from Liked Songs'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        await subsonicService.star(id: widget.song.id);
        setState(() {
          _isStarred = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Added to Liked Songs'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
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
                    'Add to Playlist',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (libraryProvider.playlists.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text('No playlists available'),
              )
            else
              ...libraryProvider.playlists.map(
                (playlist) => ListTile(
                  leading: const Icon(Icons.queue_music_rounded),
                  title: Text(playlist.name),
                  subtitle: Text('${playlist.songCount ?? 0} songs'),
                  onTap: () async {
                    Navigator.pop(context);

                    try {
                      print(
                        'Attempting to add song ${song.id} (${song.title}) to playlist ${playlist.id} (${playlist.name})',
                      );

                      final subsonicService = Provider.of<SubsonicService>(
                        context,
                        listen: false,
                      );

                      await subsonicService.updatePlaylist(
                        playlistId: playlist.id,
                        songIdsToAdd: [song.id],
                      );

                      print('Successfully added song to playlist via API');

                      await libraryProvider.loadPlaylists();

                      print('Playlists refreshed');

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
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
                      }
                    } catch (e) {
                      print('Error adding song to playlist: $e');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.error, color: Colors.white),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text('Error adding to playlist: $e'),
                                ),
                              ],
                            ),
                            duration: const Duration(seconds: 3),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
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
      leading: Icon(icon, color: iconColor ?? AppTheme.appleMusicRed),
      title: Text(title),
      onTap: onTap,
    );
  }
}
