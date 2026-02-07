import 'package:flutter_chrome_cast/entities/cast_media_status.dart';
import 'package:flutter_chrome_cast/entities/load_options.dart';
import 'package:flutter_chrome_cast/entities/media_information.dart';
import 'package:flutter_chrome_cast/entities/media_seek_option.dart';
import 'package:flutter_chrome_cast/entities/queue_item.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class GoogleCastRemoteMediaClientPlatformInterface
    implements PlatformInterface {
  GoggleCastMediaStatus? get mediaStatus;

  Stream<GoggleCastMediaStatus?> get mediaStatusStream;

  Duration get playerPosition;

  Stream<Duration> get playerPositionStream;

  Stream<List<GoogleCastQueueItem>> get queueItemsStream;

  List<GoogleCastQueueItem> get queueItems;

  bool get queueHasNextItem;

  bool get queueHasPreviousItem;

  Future<void> loadMedia(
    GoogleCastMediaInformation mediaInfo, {
    bool autoPlay = true,
    Duration playPosition = Duration.zero,
    double playbackRate = 1.0,
    List<int>? activeTrackIds,
    String? credentials,
    String? credentialsType,
  });

  Future<void> queueLoadItems(
    List<GoogleCastQueueItem> queueItems, {
    GoogleCastQueueLoadOptions? options,
  });

  Future<void> setPlaybackRate(double rate);

  Future<void> setActiveTrackIDs(List<int> activeTrackIDs);

  Future<void> setTextTrackStyle(TextTrackStyle textTrackStyle);

  Future<void> pause();

  Future<void> play();

  Future<void> stop();

  Future<void> queueNextItem();

  Future<void> queuePrevItem();

  Future<void> seek(GoogleCastMediaSeekOption option);

  Future<void> queueInsertItems(
    List<GoogleCastQueueItem> items, {
    int? beforeItemWithId,
  });
  Future<void> queueInsertItemAndPlay(
    GoogleCastQueueItem item, {
    required int beforeItemWithId,
  });

  Future<void> queueRemoveItemsWithIds(
    List<int> itemIds,
  );

  Future<void> queueJumpToItemWithId(int itemId);

  Future<void> queueReorderItems({
    required List<int> itemsIds,
    required int? beforeItemWithId,
  });
}
