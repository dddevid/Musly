import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:musly/providers/player_provider.dart';
import 'package:musly/models/song.dart';
import 'package:musly/widgets/common/blurred_gradient_background.dart';
import 'package:musly/widgets/now_playing/album_art_view.dart';
import 'package:musly/widgets/now_playing/playback_progress_slider.dart';
import 'package:musly/services/subsonic_service.dart';
import 'package:musly/widgets/navigation/tv_remote_scope.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TvNowPlayingScreen extends StatefulWidget {
  final ImageProvider image;
  final String title;
  final String artist;
  final Song? song;
  final List<Color> bgColors;

  const TvNowPlayingScreen({
    super.key,
    required this.image,
    required this.title,
    required this.artist,
    this.song,
    required this.bgColors,
  });

  @override
  State<TvNowPlayingScreen> createState() => _TvNowPlayingScreenState();
}

class _TvNowPlayingScreenState extends State<TvNowPlayingScreen> {
  final FocusNode _progressFocusNode = FocusNode();

  @override
  void dispose() {
    _progressFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlayerProvider>(context);
    final song = provider.currentSong ?? widget.song;
    
    ImageProvider? currentImageProvider = widget.image;
    if (song != null && song.coverArt != null) {
      final subsonic = Provider.of<SubsonicService>(context, listen: false);
      final coverUrl = subsonic.getCoverArtUrl(song.coverArt, size: 600);
      if (coverUrl.isNotEmpty) {
        currentImageProvider = CachedNetworkImageProvider(coverUrl);
      }
    }

    return TvRemoteScope(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            if (widget.bgColors.isNotEmpty)
              Positioned.fill(
                child: BlurredGradientBackground(
                  colors: widget.bgColors,
                  child: const SizedBox.shrink(),
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(64.0),
              child: Row(
                children: [
                  // Left side: Giant Album Art
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              blurRadius: 40,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        ),
                        child: AlbumArtView(
                          image: currentImageProvider,
                          tag: 'tv_hero_art',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 64),
                  // Right side: Info and Controls
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song?.title ?? widget.title,
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          song?.artist ?? widget.artist,
                          style: const TextStyle(
                            fontSize: 32,
                            color: Colors.white70,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 48),
                        
                        // Progress bar with scrubbing support
                        Focus(
                          focusNode: _progressFocusNode,
                          onKeyEvent: (node, event) {
                            if (event is KeyDownEvent) {
                              if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                                provider.seek(provider.position - const Duration(seconds: 5));
                                return KeyEventResult.handled;
                              } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                                provider.seek(provider.position + const Duration(seconds: 5));
                                return KeyEventResult.handled;
                              }
                            }
                            return KeyEventResult.ignored;
                          },
                          child: Builder(
                            builder: (context) {
                              final hasFocus = Focus.of(context).hasFocus;
                              return Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                decoration: BoxDecoration(
                                  border: hasFocus ? Border.all(color: Colors.white, width: 2) : Border.all(color: Colors.transparent, width: 2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: StreamBuilder<Duration>(
                                  stream: provider.positionStream,
                                  initialData: provider.position,
                                  builder: (context, snapshot) {
                                    return PlaybackProgressSlider(
                                      position: snapshot.data ?? Duration.zero,
                                      duration: provider.duration.inMilliseconds > 0 ? provider.duration : Duration(seconds: song?.duration ?? 0),
                                      onChanged: (val) => provider.seek(val),
                                      accentColor: widget.bgColors.isNotEmpty ? widget.bgColors.first : Colors.white,
                                    );
                                  },
                                ),
                              );
                            }
                          ),
                        ),
                        
                        const SizedBox(height: 64),
                        
                        // Playback Controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _TvControlButton(
                              icon: Icons.shuffle,
                              onPressed: provider.toggleShuffle,
                              isActive: provider.shuffleEnabled,
                            ),
                            _TvControlButton(
                              icon: Icons.skip_previous,
                              onPressed: provider.skipPrevious,
                            ),
                            _TvControlButton(
                              icon: provider.isPlaying ? Icons.pause : Icons.play_arrow,
                              onPressed: provider.togglePlayPause,
                              size: 80,
                              iconSize: 48,
                              autofocus: true,
                            ),
                            _TvControlButton(
                              icon: Icons.skip_next,
                              onPressed: provider.skipNext,
                            ),
                            _TvControlButton(
                              icon: provider.repeatMode == RepeatMode.one 
                                  ? Icons.repeat_one 
                                  : Icons.repeat,
                              onPressed: provider.toggleRepeat,
                              isActive: provider.repeatMode != RepeatMode.off,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TvControlButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isActive;
  final double size;
  final double iconSize;
  final bool autofocus;

  const _TvControlButton({
    required this.icon,
    required this.onPressed,
    this.isActive = false,
    this.size = 60,
    this.iconSize = 32,
    this.autofocus = false,
  });

  @override
  State<_TvControlButton> createState() => _TvControlButtonState();
}

class _TvControlButtonState extends State<_TvControlButton> {
  bool _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: (focused) => setState(() => _hasFocus = focused),
      child: Builder(
        builder: (context) {
          return GestureDetector(
            onTap: widget.onPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _hasFocus ? Colors.white : (widget.isActive ? Colors.white24 : Colors.transparent),
                border: _hasFocus ? Border.all(color: Colors.white, width: 3) : null,
              ),
              child: Icon(
                widget.icon,
                color: _hasFocus ? Colors.black : (widget.isActive ? Colors.white : Colors.white70),
                size: widget.iconSize,
              ),
            ),
          );
        }
      ),
    );
  }
}
