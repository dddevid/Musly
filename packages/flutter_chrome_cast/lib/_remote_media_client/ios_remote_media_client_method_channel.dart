import 'package:flutter/services.dart';
import 'package:flutter_chrome_cast/_remote_media_client/remote_media_client_platform.dart';
import 'package:flutter_chrome_cast/entities/cast_media_status.dart';
import 'package:flutter_chrome_cast/entities/load_options.dart';
import 'package:flutter_chrome_cast/entities/media_seek_option.dart';
import 'package:flutter_chrome_cast/entities/queue_item.dart';
import 'package:flutter_chrome_cast/entities/media_information.dart';
import 'package:flutter_chrome_cast/models/ios/ios_cast_queue_item.dart';
import 'package:flutter_chrome_cast/models/ios/ios_media_status.dart';
import 'package:rxdart/rxdart.dart';

class GoogleCastRemoteMediaClientIOSMethodChannel
    implements GoogleCastRemoteMediaClientPlatformInterface {
  GoogleCastRemoteMediaClientIOSMethodChannel() {
    _channel.setMethodCallHandler(_methodCallHandler);
  }

  final _channel = const MethodChannel('google_cast.remote_media_client');
  bool _queueHasNextItem = false;

  final _mediaStatusStreamController = BehaviorSubject<GoggleCastMediaStatus?>()
    ..add(null);

  final _playerPositionStreamController = BehaviorSubject<Duration>()
    ..add(Duration.zero);

  final _queueItemsStreamController =
      BehaviorSubject<List<GoogleCastQueueItem>>()..add([]);

  @override
  GoggleCastMediaStatus? get mediaStatus => _mediaStatusStreamController.value;

  @override
  Stream<GoggleCastMediaStatus?> get mediaStatusStream =>
      _mediaStatusStreamController.stream;

  @override
  Duration get playerPosition => _playerPositionStreamController.value;

  @override
  Stream<Duration> get playerPositionStream =>
      _playerPositionStreamController.stream;

  @override
  List<GoogleCastQueueItem> get queueItems => _queueItemsStreamController.value;

  @override
  Stream<List<GoogleCastQueueItem>> get queueItemsStream =>
      _queueItemsStreamController.stream;

  @override
  bool get queueHasNextItem => _queueHasNextItem;

  @override
  bool get queueHasPreviousItem {
    final index = queueItems
        .map((e) => e.itemId)
        .toList()
        .lastIndexOf(mediaStatus?.currentItemId);
    return index > 0;
  }

  @override
  Future<void> loadMedia(
    GoogleCastMediaInformation mediaInfo, {
    bool autoPlay = true,
    Duration playPosition = Duration.zero,
    double playbackRate = 1.0,
    List<int>? activeTrackIds,
    String? credentials,
    String? credentialsType,
  }) async {
    _channel.invokeMethod(
        'loadMedia',
        mediaInfo.toMap()
          ..addAll(
            {
              'autoPlay': autoPlay,
              'playPosition': playPosition.inSeconds,
              'playbackRate': playbackRate,
              'activeTrackIds': activeTrackIds,
              'credentials': credentials,
              'credentialsType': credentialsType,
            }..removeWhere((key, value) => value == null),
          ));
  }

  @override
  Future<void> pause() async {
    await _channel.invokeMethod('pause');
  }

  @override
  Future<void> play() async {
    await _channel.invokeMethod('play');
  }

  @override
  Future<void> setActiveTrackIDs(List<int> activeTrackIDs) async {
    await _channel.invokeMethod('setActiveTrackIDs', activeTrackIDs.toList());
  }

  @override
  Future<void> setPlaybackRate(double rate) async {
    await _channel.invokeMethod('setPlaybackRate', rate);
  }

  @override
  Future<void> setTextTrackStyle(TextTrackStyle textTrackStyle) async {
    await _channel.invokeMethod('setTextTrackStyle', textTrackStyle.toMap());
  }

  @override
  Future<void> stop() async {
    await _channel.invokeMethod('stop');
  }

  @override
  Future<void> seek(GoogleCastMediaSeekOption option) async {
    await _channel.invokeMethod('seek', option.toMap());
  }

  @override
  Future<void> queueNextItem() async {
    await _channel.invokeMethod('queueNextItem');
  }

  @override
  Future<void> queuePrevItem() async {
    _channel.invokeMethod('queuePrevItem');
  }

// MARK: - MethodCallHandler
  Future _methodCallHandler(MethodCall call) async {
    switch (call.method) {
      case "onUpdateMediaStatus":
        return await _onUpdateMediaStatus(call.arguments);
      case "onUpdatePlayerPosition":
        return await _onUpdatePlayerPosition(call.arguments);
      case "updateQueueItems":
        return await _updateQueueItems(call.arguments);
      default:
    }
  }

  Future _onUpdatePlayerPosition(int seconds) async {
    final duration = Duration(seconds: seconds);
    _playerPositionStreamController.add(duration);
  }

  _onUpdateMediaStatus(arguments) {
    if (arguments != null) {
      try {
        arguments = Map<String, dynamic>.from(arguments);
        final mediaStatus = GoogleCastIOSMediaStatus.fromMap(arguments);
        _queueHasNextItem = arguments["queueHasNextItem"];
        _mediaStatusStreamController.add(mediaStatus);
        print('ios Media status successfully serialized to dart');
      } catch (e, s) {
        print(s);
        print(s);
      }
    }
  }

  @override
  Future<void> queueLoadItems(
    List<GoogleCastQueueItem> queueItems, {
    GoogleCastQueueLoadOptions? options,
  }) async {
    _channel.invokeMethod(
      'queueLoadItems',
      {
        'items': queueItems.map((item) => item.toMap()).toList(),
        if (options != null) 'options': options.toMap(),
      },
    );
  }

  @override
  Future<void> queueInsertItems(List<GoogleCastQueueItem> items,
      {int? beforeItemWithId}) async {
    _channel.invokeMethod('queueInsertItems', {
      'items': items.map((item) => item.toMap()).toList(),
      'beforeItemWithId': beforeItemWithId,
    });
  }

  @override
  Future<void> queueInsertItemAndPlay(
    GoogleCastQueueItem item, {
    required int beforeItemWithId,
  }) async {
    assert(beforeItemWithId >= 0, 'beforeItemWithId must be greater than 0');
    _channel.invokeMethod('queueInsertItemAndPlay', {
      'item': item.toMap(),
      'beforeItemWithId': beforeItemWithId,
    });
    return;
  }

  @override
  Future<void> queueJumpToItemWithId(int itemId) async {
    _channel.invokeMethod('queueJumpToItemWithId', itemId);
  }

  @override
  Future<void> queueRemoveItemsWithIds(List<int> itemIds) async {
    _channel.invokeMethod('queueRemoveItemsWithIds', itemIds);
  }

  _updateQueueItems(arguments) {
    final items = List.from(arguments ?? []);
    final queueItems = items
        .map((item) =>
            GoogleCastQueueItemIOS.fromMap(Map<String, dynamic>.from(item)))
        .toList();
    _queueItemsStreamController.add(queueItems);
  }

  @override
  Future<void> queueReorderItems(
      {required List<int> itemsIds, required int? beforeItemWithId}) async {
    _channel.invokeMethod(
      'queueReorderItems',
      {
        'itemsIds': itemsIds,
        'beforeItemWithId': beforeItemWithId,
      },
    );
  }
}
