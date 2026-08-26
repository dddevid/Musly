import 'package:flutter_test/flutter_test.dart';
import 'package:musly/services/audio_handler.dart';

import '../bootstrap.dart';

/// The media session is what the notification, lock screen, Android Auto and a
/// car head unit all read. If the handler cannot publish remote playback state
/// into it, every one of those controls silently operates on the idle local
/// player instead of the Cast/DLNA renderer.
///
/// That is exactly what happened: the constructor used
/// `playbackEventStream.pipe(playbackState)`, and pipe() is addStream() on the
/// underlying rxdart Subject — so every other playbackState.add() in the class
/// threw "You cannot add items while items are being added from addStream".
void main() {
  initializeTestEnvironment();

  late MuslyAudioHandler handler;

  setUp(() => handler = MuslyAudioHandler());
  tearDown(() => handler.cancelLocalStateMirror());

  test('updateRemotePlaybackState publishes instead of throwing', () {
    expect(
      () => handler.updateRemotePlaybackState(
        playing: true,
        position: const Duration(seconds: 42),
      ),
      returnsNormally,
      reason: 'a pipe()d playbackState makes every add() throw',
    );

    expect(handler.playbackState.value.playing, isTrue);
    expect(handler.playbackState.value.updatePosition,
        const Duration(seconds: 42));
  });

  test('remote pause state reaches the session', () {
    handler.updateRemotePlaybackState(
      playing: false,
      position: const Duration(seconds: 10),
    );
    expect(handler.playbackState.value.playing, isFalse);
  });

  test('repeated remote updates keep working', () {
    // A 1 Hz poll drives this continuously; one throw would leave the session
    // frozen for the rest of the session.
    for (var i = 1; i <= 20; i++) {
      handler.updateRemotePlaybackState(
        playing: true,
        position: Duration(seconds: i),
      );
    }
    expect(handler.playbackState.value.updatePosition,
        const Duration(seconds: 20));
  });

  test('updateNowPlaying publishes media item metadata', () {
    handler.updateNowPlaying(
      id: 'song-1',
      title: 'Track',
      artist: 'Artist',
      duration: const Duration(minutes: 3),
    );
    expect(handler.mediaItem.value?.id, 'song-1');
    expect(handler.mediaItem.value?.title, 'Track');
  });
}
