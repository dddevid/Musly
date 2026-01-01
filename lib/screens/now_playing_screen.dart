import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:volume_controller/volume_controller.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../services/subsonic_service.dart';
import '../theme/app_theme.dart';
import '../widgets/synced_lyrics_view.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen>
    with SingleTickerProviderStateMixin {

  String? _cachedImageUrl;
  String? _cachedCoverArtId;
  late AnimationController _bgAnimationController;
  bool _showLyrics = false;

  @override
  void initState() {
    super.initState();
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgAnimationController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Selector<PlayerProvider, Song?>(
      selector: (_, provider) => provider.currentSong,
      builder: (context, song, _) {
        if (song == null) {
          return const Scaffold(body: Center(child: Text('No song playing')));
        }

        if (_cachedCoverArtId != song.coverArt) {
          _cachedCoverArtId = song.coverArt;
          final subsonicService = Provider.of<SubsonicService>(
            context,
            listen: false,
          );
          _cachedImageUrl = subsonicService.getCoverArtUrl(
            song.coverArt,
            size: 600,
          );
        }

        return Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [

              _DynamicBackground(
                imageUrl: _cachedImageUrl ?? '',
                animation: _bgAnimationController,
              ),

              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final screenHeight = constraints.maxHeight;
                    final screenWidth = constraints.maxWidth;

                    final artworkSize = (screenWidth * 0.80).clamp(
                      200.0,
                      screenHeight * 0.38,
                    );

                    const controlsHeight = 250.0;
                    const headerHeight = 56.0;

                    final availableSpace =
                        screenHeight -
                        headerHeight -
                        artworkSize -
                        controlsHeight;

                    final topSpacing = (availableSpace * 0.35).clamp(8.0, 60.0);
                    final middleSpacing = (availableSpace * 0.45).clamp(
                      12.0,
                      50.0,
                    );
                    final bottomSpacing = (availableSpace * 0.20).clamp(
                      4.0,
                      30.0,
                    );

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: screenHeight),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [

                            _PlayerHeader(
                              albumName: song.album ?? 'Unknown Album',
                              showLyricsButton: true,
                              isLyricsActive: _showLyrics,
                              onLyricsPressed: () {
                                setState(() {
                                  _showLyrics = !_showLyrics;
                                });
                              },
                            ),

                            SizedBox(height: topSpacing),

                            _AlbumArtworkSection(
                              imageUrl: _cachedImageUrl ?? '',
                              size: artworkSize,
                            ),

                            SizedBox(height: middleSpacing),

                            _PlayerControls(formatDuration: _formatDuration),

                            SizedBox(height: bottomSpacing),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              if (_showLyrics)
                AnimatedOpacity(
                  opacity: _showLyrics ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: SyncedLyricsView(
                    song: song,
                    imageUrl: _cachedImageUrl,
                    onClose: () {
                      setState(() {
                        _showLyrics = false;
                      });
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DynamicBackground extends StatelessWidget {
  final String imageUrl;
  final Animation<double> animation;

  const _DynamicBackground({required this.imageUrl, required this.animation});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [

          if (imageUrl.isNotEmpty)
            AnimatedBuilder(
              animation: animation,
              builder: (context, child) {

                final scale = 1.1 + (animation.value * 0.2);

                final offsetX = (animation.value - 0.5) * 20;
                final offsetY = (animation.value - 0.5) * 15;

                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..translate(offsetX, offsetY)
                    ..scale(scale),
                  child: child,
                );
              },
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                memCacheWidth: 400,
                memCacheHeight: 400,
                useOldImageOnUrlChange: true,
                fadeInDuration: const Duration(milliseconds: 300),
                fadeOutDuration: Duration.zero,
                placeholder: (_, __) => Container(color: Colors.black),
                errorWidget: (_, __, ___) => Container(color: Colors.black),
              ),
            )
          else
            Container(color: Colors.black),

          AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              final opacity1 = 0.4 + (animation.value * 0.2);
              final opacity2 = 0.7 + (animation.value * 0.15);

              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.black.withOpacity(opacity1),
                      Colors.black.withOpacity(opacity2),
                    ],
                    stops: [0.0 + animation.value * 0.1, 1.0],
                  ),
                ),
              );
            },
          ),

          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(color: Colors.transparent),
          ),
        ],
      ),
    );
  }
}

class _PlayerHeader extends StatelessWidget {
  final String albumName;
  final bool showLyricsButton;
  final bool isLyricsActive;
  final VoidCallback? onLyricsPressed;

  const _PlayerHeader({
    required this.albumName,
    this.showLyricsButton = false,
    this.isLyricsActive = false,
    this.onLyricsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              CupertinoIcons.chevron_down,
              color: Colors.white,
              size: 28,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'PLAYING FROM',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  albumName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showLyricsButton)
                IconButton(
                  onPressed: onLyricsPressed,
                  icon: Icon(
                    Icons.lyrics_rounded,
                    color: isLyricsActive
                        ? AppTheme.appleMusicRed
                        : Colors.white,
                    size: 24,
                  ),
                ),
              IconButton(
                onPressed: () => _showQueue(context),
                icon: const Icon(
                  CupertinoIcons.list_bullet,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showQueue(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _QueueSheet(),
    );
  }
}

class _AlbumArtworkSection extends StatelessWidget {
  final String imageUrl;
  final double size;

  const _AlbumArtworkSection({required this.imageUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: SizedBox(
        width: size,
        height: size,
        child: RepaintBoundary(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: 600,
                      memCacheHeight: 600,
                      useOldImageOnUrlChange: true,
                      fadeInDuration: const Duration(milliseconds: 100),
                      fadeOutDuration: Duration.zero,
                      placeholder: (_, __) => _buildPlaceholder(),
                      errorWidget: (_, __, ___) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Shimmer.fromColors(
      baseColor: AppTheme.darkCard,
      highlightColor: Colors.grey.shade700,
      child: Container(
        color: AppTheme.darkCard,
        child: const Center(
          child: Icon(
            Icons.music_note_rounded,
            size: 80,
            color: Colors.white24,
          ),
        ),
      ),
    );
  }
}

class _PlayerControls extends StatelessWidget {
  final String Function(Duration) formatDuration;

  const _PlayerControls({required this.formatDuration});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [

          Selector<PlayerProvider, Song?>(
            selector: (_, p) => p.currentSong,
            builder: (context, song, _) => _SongInfo(song: song),
          ),

          const SizedBox(height: 12),

          Selector<PlayerProvider, (double, Duration, Duration)>(
            selector: (_, p) => (p.progress, p.position, p.duration),
            builder: (context, data, _) {
              final (progress, position, duration) = data;
              return _ProgressBar(
                progress: progress,
                position: position,
                duration: duration,
                formatDuration: formatDuration,
              );
            },
          ),

          const SizedBox(height: 8),

          const _PlaybackControls(),

          const SizedBox(height: 12),

          const _VolumeSlider(),
        ],
      ),
    );
  }
}

class _SongInfo extends StatefulWidget {
  final Song? song;

  const _SongInfo({required this.song});

  @override
  State<_SongInfo> createState() => _SongInfoState();
}

class _SongInfoState extends State<_SongInfo> {
  bool _isStarred = false;

  @override
  void initState() {
    super.initState();
    _isStarred = widget.song?.starred ?? false;
  }

  @override
  void didUpdateWidget(_SongInfo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song?.id != widget.song?.id) {
      _isStarred = widget.song?.starred ?? false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.song == null) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.song!.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                (widget.song!.artist ?? 'Unknown Artist').replaceAll(
                  '/',
                  ' / ',
                ),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 18,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _showAddToPlaylistDialog(context),
          icon: const Icon(
            CupertinoIcons.plus_circle,
            color: Colors.white,
            size: 26,
          ),
        ),
        IconButton(
          onPressed: () => _toggleFavorite(context),
          icon: Icon(
            _isStarred ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
            color: _isStarred ? AppTheme.appleMusicRed : Colors.white,
            size: 26,
          ),
        ),
      ],
    );
  }

  Future<void> _toggleFavorite(BuildContext context) async {
    if (widget.song == null) return;
    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );
    try {
      if (_isStarred) {
        await subsonicService.unstar(id: widget.song!.id);
        setState(() => _isStarred = false);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removed from favorites'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        await subsonicService.star(id: widget.song!.id);
        setState(() => _isStarred = true);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Added to favorites'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _showAddToPlaylistDialog(BuildContext context) async {
    if (widget.song == null) return;

    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );

    try {
      final playlists = await subsonicService.getPlaylists();

      if (!context.mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          decoration: BoxDecoration(
            color: AppTheme.darkSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.darkDivider,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Add to Playlist',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Material(
                  color: AppTheme.appleMusicRed,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _showCreatePlaylistDialog(context);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.add_circled_solid,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Create New Playlist',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Your Playlists',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    final coverArtUrl = playlist.coverArt != null
                        ? subsonicService.getCoverArtUrl(
                            playlist.coverArt!,
                            size: 100,
                          )
                        : null;

                    return ListTile(
                      leading: coverArtUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: CachedNetworkImage(
                                imageUrl: coverArtUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  width: 50,
                                  height: 50,
                                  color: AppTheme.darkCard,
                                  child: const Icon(
                                    CupertinoIcons.music_note_list,
                                    color: Colors.white30,
                                    size: 24,
                                  ),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  width: 50,
                                  height: 50,
                                  color: AppTheme.darkCard,
                                  child: const Icon(
                                    CupertinoIcons.music_note_list,
                                    color: Colors.white30,
                                    size: 24,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppTheme.darkCard,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                CupertinoIcons.music_note_list,
                                color: Colors.white30,
                                size: 24,
                              ),
                            ),
                      title: Text(
                        playlist.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: playlist.songCount != null
                          ? Text(
                              '${playlist.songCount} songs',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                              ),
                            )
                          : null,
                      onTap: () async {
                        Navigator.pop(context);
                        await _addToPlaylist(
                          context,
                          playlist.id,
                          playlist.name,
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading playlists: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _showCreatePlaylistDialog(BuildContext context) async {
    if (widget.song == null) return;

    final nameController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: const Text(
          'Create Playlist',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Playlist name',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.appleMusicRed),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(context, nameController.text.trim());
              }
            },
            child: const Text(
              'Create',
              style: TextStyle(
                color: AppTheme.appleMusicRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && context.mounted) {
      await _createPlaylistAndAddSong(context, result);
    }

    nameController.dispose();
  }

  Future<void> _createPlaylistAndAddSong(
    BuildContext context,
    String playlistName,
  ) async {
    if (widget.song == null) return;

    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );

    try {

      await subsonicService.createPlaylist(
        name: playlistName,
        songIds: [widget.song!.id],
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Created playlist "$playlistName" with this song'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _addToPlaylist(
    BuildContext context,
    String playlistId,
    String playlistName,
  ) async {
    if (widget.song == null) return;

    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );

    try {
      await subsonicService.updatePlaylist(
        playlistId: playlistId,
        songIdsToAdd: [widget.song!.id],
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added to $playlistName'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

class _ProgressBar extends StatefulWidget {
  final double progress;
  final Duration position;
  final Duration duration;
  final String Function(Duration) formatDuration;

  const _ProgressBar({
    required this.progress,
    required this.position,
    required this.duration,
    required this.formatDuration,
  });

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar> {
  bool _isDragging = false;
  bool _waitingForSeek = false;
  double _dragValue = 0.0;

  @override
  void didUpdateWidget(_ProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.duration != widget.duration) {
      _isDragging = false;
      _waitingForSeek = false;
      _dragValue = 0.0;
      return;
    }

    if (_waitingForSeek && (widget.progress - _dragValue).abs() < 0.05) {
      setState(() => _waitingForSeek = false);
    }
  }

  void _updateProgressFromPosition(Offset localPosition, double width) {
    final newProgress = (localPosition.dx / width).clamp(0.0, 1.0);
    setState(() => _dragValue = newProgress);
  }

  @override
  Widget build(BuildContext context) {

    final showDragValue = _isDragging || _waitingForSeek;
    final displayProgress = showDragValue ? _dragValue : widget.progress;
    final displayPosition = showDragValue
        ? Duration(
            milliseconds: (_dragValue * widget.duration.inMilliseconds).round(),
          )
        : widget.position;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final trackWidth = constraints.maxWidth;

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: (details) {
                  setState(() {
                    _isDragging = true;
                    _waitingForSeek = false;
                    _dragValue = widget.progress;
                  });
                  _updateProgressFromPosition(
                    details.localPosition,
                    trackWidth,
                  );
                },
                onHorizontalDragUpdate: (details) {
                  _updateProgressFromPosition(
                    details.localPosition,
                    trackWidth,
                  );
                },
                onHorizontalDragEnd: (details) {
                  context.read<PlayerProvider>().seekToProgress(_dragValue);
                  setState(() {
                    _isDragging = false;
                    _waitingForSeek = true;
                  });
                },
                onTapDown: (details) {
                  final newProgress = (details.localPosition.dx / trackWidth)
                      .clamp(0.0, 1.0);
                  setState(() {
                    _dragValue = newProgress;
                    _waitingForSeek = true;
                  });
                  context.read<PlayerProvider>().seekToProgress(newProgress);
                },
                child: SizedBox(
                  height: 40,
                  child: Center(
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [

                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),

                        FractionallySizedBox(
                          widthFactor: displayProgress.clamp(0.0, 1.0),
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

                        Positioned(
                          left:
                              ((trackWidth * displayProgress.clamp(0.0, 1.0)) -
                                      6)
                                  .clamp(0.0, trackWidth - 12),
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.formatDuration(displayPosition),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
              Text(
                '-${widget.formatDuration(widget.duration - displayPosition)}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlaybackControls extends StatelessWidget {
  const _PlaybackControls();

  @override
  Widget build(BuildContext context) {
    return Selector<PlayerProvider, (bool, bool, bool, RepeatMode, bool)>(
      selector: (_, p) => (
        p.isPlaying,
        p.shuffleEnabled,
        p.hasNext,
        p.repeatMode,
        p.hasPrevious,
      ),
      builder: (context, data, _) {
        final (isPlaying, shuffleEnabled, hasNext, repeatMode, _) = data;
        final provider = context.read<PlayerProvider>();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: provider.toggleShuffle,
              icon: Icon(
                CupertinoIcons.shuffle,
                color: shuffleEnabled
                    ? AppTheme.appleMusicRed
                    : Colors.white.withOpacity(0.7),
                size: 22,
              ),
            ),
            IconButton(
              onPressed: provider.skipPrevious,
              icon: const Icon(
                CupertinoIcons.backward_fill,
                color: Colors.white,
                size: 36,
              ),
            ),
            Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: provider.togglePlayPause,
                icon: Icon(
                  isPlaying
                      ? CupertinoIcons.pause_fill
                      : CupertinoIcons.play_fill,
                  color: Colors.black,
                  size: 34,
                ),
              ),
            ),
            IconButton(
              onPressed: hasNext ? provider.skipNext : null,
              icon: Icon(
                CupertinoIcons.forward_fill,
                color: hasNext ? Colors.white : Colors.white.withOpacity(0.3),
                size: 36,
              ),
            ),
            IconButton(
              onPressed: provider.toggleRepeat,
              icon: Icon(
                repeatMode == RepeatMode.one
                    ? CupertinoIcons.repeat_1
                    : CupertinoIcons.repeat,
                color: repeatMode != RepeatMode.off
                    ? AppTheme.appleMusicRed
                    : Colors.white.withOpacity(0.7),
                size: 22,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _VolumeSlider extends StatefulWidget {
  const _VolumeSlider();

  @override
  State<_VolumeSlider> createState() => _VolumeSliderState();
}

class _VolumeSliderState extends State<_VolumeSlider> {
  bool _isDragging = false;
  double _dragValue = 0.0;
  double _systemVolume = 0.5;
  StreamSubscription<double>? _volumeSubscription;

  @override
  void initState() {
    super.initState();
    _initVolumeController();
  }

  Future<void> _initVolumeController() async {

    VolumeController.instance.showSystemUI = false;

    _systemVolume = await VolumeController.instance.getVolume();
    if (mounted) setState(() {});

    _volumeSubscription = VolumeController.instance.addListener((volume) {
      if (mounted && !_isDragging) {
        setState(() {
          _systemVolume = volume;
        });
      }
    });
  }

  @override
  void dispose() {
    _volumeSubscription?.cancel();
    super.dispose();
  }

  void _updateVolumeFromPosition(Offset localPosition, double width) {
    final newVolume = (localPosition.dx / width).clamp(0.0, 1.0);
    setState(() {
      _dragValue = newVolume;
      _systemVolume = newVolume;
    });
    VolumeController.instance.setVolume(newVolume);
  }

  @override
  Widget build(BuildContext context) {
    final displayVolume = _isDragging ? _dragValue : _systemVolume;

    return Row(
      children: [
        GestureDetector(
          onTap: () {
            setState(() => _systemVolume = 0.0);
            VolumeController.instance.setVolume(0.0);
          },
          child: Icon(
            displayVolume <= 0.01
                ? CupertinoIcons.speaker_slash_fill
                : CupertinoIcons.speaker_1_fill,
            color: Colors.white.withOpacity(0.7),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final trackWidth = constraints.maxWidth;

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: (details) {
                  setState(() {
                    _isDragging = true;
                    _dragValue = _systemVolume;
                  });
                  _updateVolumeFromPosition(details.localPosition, trackWidth);
                },
                onHorizontalDragUpdate: (details) {
                  _updateVolumeFromPosition(details.localPosition, trackWidth);
                },
                onHorizontalDragEnd: (details) {
                  setState(() => _isDragging = false);
                },
                onTapDown: (details) {
                  _updateVolumeFromPosition(details.localPosition, trackWidth);
                },
                child: SizedBox(
                  height: 40,
                  child: Center(
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [

                        AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          curve: Curves.easeOut,
                          height: _isDragging ? 6 : 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(
                              _isDragging ? 3 : 2,
                            ),
                          ),
                        ),

                        FractionallySizedBox(
                          widthFactor: displayVolume.clamp(0.0, 1.0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            curve: Curves.easeOut,
                            height: _isDragging ? 6 : 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(
                                _isDragging ? 3 : 2,
                              ),
                            ),
                          ),
                        ),

                        Positioned(
                          left:
                              ((trackWidth * displayVolume.clamp(0.0, 1.0)) -
                                      (_isDragging ? 10 : 6))
                                  .clamp(
                                    0.0,
                                    trackWidth - (_isDragging ? 20 : 12),
                                  ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            curve: Curves.easeOut,
                            width: _isDragging ? 20 : 12,
                            height: _isDragging ? 20 : 12,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: _isDragging
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.4),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 3,
                                      ),
                                    ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () {
            setState(() => _systemVolume = 1.0);
            VolumeController.instance.setVolume(1.0);
          },
          child: Icon(
            CupertinoIcons.speaker_3_fill,
            color: Colors.white.withOpacity(0.7),
            size: 20,
          ),
        ),
      ],
    );
  }
}

class _QueueSheet extends StatelessWidget {
  const _QueueSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkSurface
                : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.darkDivider,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Playing Next',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Selector<PlayerProvider, (List<Song>, int)>(
                  selector: (_, p) => (p.queue, p.currentIndex),
                  builder: (context, data, _) {
                    final (queue, currentIndex) = data;
                    final provider = context.read<PlayerProvider>();

                    return ReorderableListView.builder(
                      scrollController: scrollController,
                      itemCount: queue.length,
                      onReorder: provider.reorderQueue,
                      itemBuilder: (context, index) {
                        final song = queue[index];
                        final isPlaying = index == currentIndex;

                        return ListTile(
                          key: ValueKey(song.id),
                          leading: isPlaying
                              ? const Icon(
                                  Icons.equalizer_rounded,
                                  color: AppTheme.appleMusicRed,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: AppTheme.lightSecondaryText,
                                  ),
                                ),
                          title: Text(
                            song.title,
                            style: TextStyle(
                              color: isPlaying ? AppTheme.appleMusicRed : null,
                              fontWeight: isPlaying ? FontWeight.w600 : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            song.artist ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => provider.removeFromQueue(index),
                          ),
                          onTap: () => provider.skipToIndex(index),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}