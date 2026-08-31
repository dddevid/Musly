import 'package:flutter_test/flutter_test.dart';
import 'package:musly/providers/player_provider.dart';
import 'package:musly/services/audio_handler.dart';
import 'package:musly/services/jukebox_service.dart';
import 'package:musly/services/storage_service.dart';
import 'package:musly/services/subsonic_service.dart';
import 'package:musly/services/transcoding_service.dart';
import 'package:musly/services/upnp_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../bootstrap.dart';
import '../test_helpers.dart';

/// `isRemotePlayback` used to be a stored bool written from eight places. A
/// single missed write silently rerouted skipNext() to the local player (UI
/// advanced, renderer kept playing the old track) and suppressed the media
/// session update (frozen notification, pause doing nothing over DLNA).
///
/// It is now derived from the services that own the audio, so it cannot drift.
/// These tests exist to stop it being turned back into stored state.
void main() {
  initializeTestEnvironment();

  late FakeCastService cast;
  late PlayerProvider player;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    cast = FakeCastService();
    player = PlayerProvider(
      SubsonicService(),
      StorageService(),
      cast,
      UpnpService(),
      MuslyAudioHandler(),
      JukeboxService(),
      TranscodingService(),
    );
  });

  tearDown(() => player.dispose());

  test('tracks the renderer with no explicit assignment anywhere', () async {
    expect(player.isRemotePlayback, isFalse);

    cast.setMockConnected(true);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(player.isRemotePlayback, isTrue);

    cast.setMockConnected(false);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(player.isRemotePlayback, isFalse);
  });

  test('survives repeated connect/disconnect without drifting', () async {
    // The old stored flag drifted precisely because these transitions were
    // handled by separate hand-written assignments that could disagree.
    for (var i = 0; i < 5; i++) {
      cast.setMockConnected(true);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(player.isRemotePlayback, isTrue, reason: 'iteration $i connect');

      cast.setMockConnected(false);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(player.isRemotePlayback, isFalse,
          reason: 'iteration $i disconnect');
    }
  });

  test('reports remote immediately, with no round trip needed', () {
    // Derivation means there is no window where the services say "connected"
    // but the provider still says local — which is the window in which
    // skipNext() would have taken the wrong branch.
    cast.setMockConnected(true);
    expect(player.isRemotePlayback, isTrue);
  });
}
