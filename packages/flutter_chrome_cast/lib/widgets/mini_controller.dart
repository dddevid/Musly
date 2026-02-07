import 'package:flutter/material.dart';
import 'package:flutter_chrome_cast/lib.dart';
import 'package:flutter_chrome_cast/widgets/expanded_player.dart';

class GoogleCastMiniController extends StatefulWidget {
  const GoogleCastMiniController({Key? key}) : super(key: key);

  @override
  State<GoogleCastMiniController> createState() =>
      _GoogleCastMiniControllerState();
}

class _GoogleCastMiniControllerState extends State<GoogleCastMiniController> {
  bool isExpanded = false;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GoogleCastSession?>(
        stream: GoogleCastSessionManager.instance.currentSessionStream,
        builder: (context, snapshot) {
          return StreamBuilder<GoggleCastMediaStatus?>(
            stream: GoogleCastRemoteMediaClient.instance.mediaStatusStream,
            builder: ((context, snapshot) {
              final mediaStatus = snapshot.data;
              final hasConnectedSession =
                  GoogleCastSessionManager.instance.hasConnectedSession;

              if (!hasConnectedSession) return const SizedBox.shrink();

              if (mediaStatus == null) return const SizedBox.shrink();

              return Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: isExpanded ? size.height : 84,
                  child: Material(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxHeight > 84) {
                          return ExpandedGoogleCastPlayerController(
                            toggleExpand: _toggleExpand,
                          );
                        }
                        return _miniPlayerController(mediaStatus);
                      },
                    ),
                  ),
                ),
              );
            }),
          );
        });
  }

  InkWell _miniPlayerController(GoggleCastMediaStatus mediaStatus) {
    return InkWell(
      onTap: _toggleExpand,
      child: Card(
        shape: const ContinuousRectangleBorder(),
        margin: EdgeInsets.zero,
        color: theme.scaffoldBackgroundColor,
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _image(mediaStatus),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTitle(mediaStatus),
                        const SizedBox(height: 8),
                        _buildDeviceName(
                          GoogleCastSessionManager
                              .instance.currentSession?.device?.friendlyName,
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      _togglePlayAndPause.call(mediaStatus.playerState),
                  icon: _getIconFromPlayerState(mediaStatus.playerState),
                  iconSize: 48,
                )
              ],
            ),
            _buildProgressIndicator(mediaStatus),
          ],
        ),
      ),
    );
  }

  ThemeData get theme => Theme.of(context);

  Widget _image(GoggleCastMediaStatus mediaStatus) {
    final metadata = mediaStatus.mediaInformation?.metadata;
    if (metadata?.images != null && metadata!.images!.isNotEmpty) {
      return SizedBox(
        width: 80,
        height: 80,
        child: Hero(
          tag: 'com.felnanuke.google_cast.controller.image',
          child: Image.network(
            metadata.images!.first.url.toString(),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return Container();
  }

  Widget _buildTitle(GoggleCastMediaStatus mediaStatus) {
    final title = mediaStatus.mediaInformation?.metadata?.extractedTitle ?? '';

    return FittedBox(
      child: Hero(
        tag: 'com.felnanuke.google_cast.controller.title',
        child: Text(
          title,
          style: theme.textTheme.titleLarge,
          maxLines: 1,
        ),
      ),
    );
  }

  Widget _buildDeviceName(String? friendlyName) {
    final deviceName = friendlyName ?? '';
    return FittedBox(
      child: Text(
        'Casting to $deviceName',
        maxLines: 1,
        style: theme.textTheme.bodySmall,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

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

  Widget _getIconFromPlayerState(CastMediaPlayerState playerState) {
    IconData iconData;
    switch (playerState) {
      case CastMediaPlayerState.playing:
        iconData = Icons.pause_rounded;
        break;
      case CastMediaPlayerState.paused:
        iconData = Icons.play_arrow_rounded;
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

  Widget _buildProgressIndicator(GoggleCastMediaStatus mediaStatus) {
    return StreamBuilder<Duration?>(
      stream: GoogleCastRemoteMediaClient.instance.playerPositionStream,
      builder: (_, snapshot) => LinearProgressIndicator(
        value: getPlayerPercentage(mediaStatus, snapshot.data),
      ),
    );
  }

  void _toggleExpand() {
    setState(() {
      isExpanded = !isExpanded;
    });
  }

  Size get size => MediaQuery.of(context).size;
}
