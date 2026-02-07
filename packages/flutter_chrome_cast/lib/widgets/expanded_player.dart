import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:flutter_chrome_cast/lib.dart';
import 'package:flutter_chrome_cast/widgets/cast_volume.dart';


class ExpandedGoogleCastPlayerController extends StatefulWidget {
  final void Function()? toggleExpand;
  const ExpandedGoogleCastPlayerController({
    Key? key,
    this.toggleExpand,
  }) : super(key: key);

  @override
  State<ExpandedGoogleCastPlayerController> createState() =>
      _ExpandedGoogleCastPlayerControllerState();
}

class _ExpandedGoogleCastPlayerControllerState
    extends State<ExpandedGoogleCastPlayerController> {
  bool _isSliding = false;
  double _sliderPercentage = 0;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GoggleCastMediaStatus?>(
        stream: GoogleCastRemoteMediaClient.instance.mediaStatusStream,
        builder: (context, snapshot) {
          final mediaStatus = GoogleCastRemoteMediaClient.instance.mediaStatus;
          final deviceName = GoogleCastSessionManager
              .instance.currentSession?.device?.friendlyName;
          if (mediaStatus == null) return const SizedBox.shrink();
          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              leading: IconButton(
                  onPressed: widget.toggleExpand,
                  icon: const Icon(CupertinoIcons.chevron_down)),
              title: Hero(
                tag: 'com.felnanuke.google_cast.controller.title',
                child: Text(
                  mediaStatus.mediaInformation?.metadata?.extractedTitle ?? '',
                ),
              ),
              actions: [
                IconButton(onPressed: _onCastPressed, icon: const Icon(Icons.cast))
              ],
            ),
            body: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: 'com.felnanuke.google_cast.controller.image',
                  child: Image.network(
                    fit: BoxFit.cover,
                    mediaStatus.mediaInformation?.metadata?.images?.first.url
                            .toString() ??
                        '',
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          tileMode: TileMode.clamp,
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                        Colors.black,
                        Colors.black.withOpacity(0.1),
                        ...List.generate(6, (index) => Colors.transparent),
                        Colors.black.withOpacity(0.5),
                        Colors.black.withOpacity(0.8),
                        Colors.black,
                      ])),
                ),
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Casting to $deviceName',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            StreamBuilder<Duration?>(
                                stream: GoogleCastRemoteMediaClient
                                    .instance.playerPositionStream,
                                builder: (context, snapshot) {
                                  return SizedBox(
                                    width: 48,
                                    child: Text(
                                      _isSliding
                                          ? _getDurationToSeek(
                                                  _sliderPercentage,
                                                  mediaStatus)
                                              .formatted
                                          : GoogleCastRemoteMediaClient.instance
                                              .playerPosition.formatted,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                }),
                            _buildSlider(mediaStatus),
                            SizedBox(
                              width: 48,
                              child: Text(
                                '${mediaStatus.mediaInformation?.duration?.formatted}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          PopupMenuButton(
                            itemBuilder: (context) => [],
                            icon: const Icon(Icons.closed_caption),
                            iconSize: 48,
                            color: Colors.white,
                          ),
                          IconButton(
                            onPressed: _previous,
                            icon: const Icon(Icons.skip_previous),
                            iconSize: 48,
                            color: Colors.white,
                          ),
                          IconButton(
                            color: Colors.white,
                            onPressed: () => _togglePlayAndPause
                                .call(mediaStatus.playerState),
                            icon: _getIconFromPlayerState(
                                mediaStatus.playerState),
                            iconSize: 68,
                          ),
                          IconButton(
                            color: Colors.white,
                            onPressed: GoogleCastRemoteMediaClient
                                    .instance.queueHasNextItem
                                ? _next
                                : null,
                            disabledColor: Colors.grey,
                            icon: const Icon(Icons.skip_next),
                            iconSize: 48,
                          ),
                          const GoogleCastVolume(),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        });
  }

  Expanded _buildSlider(GoggleCastMediaStatus? mediaStatus) {
    return Expanded(
      child: StreamBuilder<Duration>(
          stream: GoogleCastRemoteMediaClient.instance.playerPositionStream,
          builder: (context, snapshot) {
            return Slider(
              value: _isSliding
                  ? _sliderPercentage
                  : _getProgressPercentage(
                      mediaStatus,
                      GoogleCastRemoteMediaClient.instance.playerPosition,
                    ),
              onChanged: _onSliderChanged,
              onChangeStart: _onSliderStarts,
              onChangeEnd: (value) => _onSliderEnd.call(value, mediaStatus!),
            );
          }),
    );
  }

  void _onCastPressed() {}

  void _previous() => GoogleCastRemoteMediaClient.instance.queuePrevItem();

  void _togglePlayAndPause(CastMediaPlayerState playerState) {
    switch (playerState) {
      case CastMediaPlayerState.playing:
        GoogleCastRemoteMediaClient.instance.pause();
        break;
      case CastMediaPlayerState.paused:
        GoogleCastRemoteMediaClient.instance.play();
        break;
      default:
    }
  }

  void _next() => GoogleCastRemoteMediaClient.instance.queueNextItem();

  ThemeData get theme => Theme.of(context);

  Widget _getIconFromPlayerState(CastMediaPlayerState playerState) {
    IconData iconData;
    switch (playerState) {
      case CastMediaPlayerState.playing:
        iconData = Icons.pause_circle_filled_rounded;
        break;
      case CastMediaPlayerState.paused:
        iconData = Icons.play_circle_filled_rounded;
        break;
      case CastMediaPlayerState.loading:
        return const SizedBox(
          child: CircularProgressIndicator(),
        );
      default:
        return const SizedBox.shrink();
    }
    return Icon(
      iconData,
    );
  }

  double _getProgressPercentage(
      GoggleCastMediaStatus? mediaStatus, Duration playerPosition) {
    final mediaDuration =
        mediaStatus?.mediaInformation?.duration ?? Duration.zero;

    if (mediaDuration.inSeconds == 0) return 0;

    if (playerPosition.inSeconds == 0) return 0;

    return playerPosition.inSeconds / mediaDuration.inSeconds;
  }

  void _onSliderStarts(double value) {
    setState(() {
      _isSliding = true;
      _sliderPercentage = value;
    });
  }

  void _onSliderChanged(double value) {
    setState(() {
      _sliderPercentage = value;
    });
  }

  void _onSliderEnd(double value, GoggleCastMediaStatus mediaStatus) {
    setState(() {
      _isSliding = false;
    });
    final durationToSeek = _getDurationToSeek(value, mediaStatus);
    GoogleCastRemoteMediaClient.instance.seek(
      GoogleCastMediaSeekOption(position: durationToSeek),
    );
  }

  Duration _getDurationToSeek(double value, GoggleCastMediaStatus mediaStatus) {
    final duration = mediaStatus.mediaInformation?.duration ?? Duration.zero;
    final secondsToSeek = duration.inSeconds * value;
    final durationToSeek = Duration(seconds: secondsToSeek.round());
    return durationToSeek;
  }

}
