import 'dart:async';
import 'dart:io';

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
import '../fake_upnp_renderer.dart';
import '../test_helpers.dart';

/// Stands in for Android's remote VolumeProvider, which MuslyAudioHandler only
/// drives on Android. [shown] is what the system volume slider displays, and
/// [pressKey] delivers a hardware key the way Android does: one step from
/// whatever the slider currently shows.
class _SystemSlider extends MuslyAudioHandler {
  int? shown;

  @override
  void setRemotePlayback({required bool isRemote, int volume = 50}) {
    shown = isRemote ? volume : null;
  }

  @override
  void updateRemoteVolume(int volume) => shown = volume;

  void pressKey(int direction) {
    final next = MuslyAudioHandler.adjustedPercent(shown!, direction);
    shown = next;
    onSetRemoteVolume!(next);
  }
}

/// Every way of changing a UPnP renderer's volume (hardware keys, the in-app
/// sliders, the system slider) goes through one writer in PlayerProvider.
/// These drive the real provider and UpnpService against a loopback renderer
/// and check what the renderer receives, in what order, and what the player
/// and system slider end up showing.
void main() {
  initializeTestEnvironment();

  late FakeUpnpRenderer renderer;
  late UpnpService upnp;
  late _SystemSlider slider;
  late PlayerProvider player;

  setUp(() async {
    HttpOverrides.global = null;
    SharedPreferences.setMockInitialValues({});
    renderer = FakeUpnpRenderer(volume: 15);
    await renderer.start();
    upnp = UpnpService();
    slider = _SystemSlider();
    player = PlayerProvider(
      SubsonicService(),
      StorageService(),
      FakeCastService(),
      upnp,
      slider,
      JukeboxService(),
      TranscodingService(),
    );
    expect(await upnp.connect(renderer.device), isTrue);
    await pumpEventQueue();
    expect(slider.shown, 15);
  });

  tearDown(() async {
    upnp.disconnect();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    player.dispose();
    await renderer.close();
  });

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 300));

  test('a key press straight after a slider tap steps from the tap', () async {
    // Not awaited: setVolume saves to disk before returning, and a key press
    // landing during that save is exactly what used to undo the tap.
    unawaited(player.setVolume(0.28));
    expect(slider.shown, 28, reason: 'the system slider must move at once');
    slider.pressKey(1);
    await settle();

    expect(renderer.setVolumes, [28, 35]);
    expect(renderer.volume, 35);
    expect(player.volume, closeTo(0.35, 1e-9));
    expect(slider.shown, 35);
  });

  test('presses during a slow write are coalesced, not dropped', () async {
    renderer.gateSetVolume = Completer<void>();
    slider.pressKey(-1); // 10, in flight
    await Future<void>.delayed(const Duration(milliseconds: 50));
    slider.pressKey(-1); // 5, pending
    slider.pressKey(-1); // 0, replaces 5
    renderer.gateSetVolume!.complete();
    await settle();

    expect(renderer.setVolumes, [10, 0]);
    expect(renderer.volume, 0);
    expect(player.volume, 0);
    expect(slider.shown, 0);
  });

  test('a renderer that rounds is believed, and stays believed', () async {
    renderer.apply = (v) => v - 1;
    unawaited(player.setVolume(0.40));
    await settle();
    expect(player.volume, closeTo(0.39, 1e-9));

    // Poll ticks notify every second while playing. If the service still
    // cached the 40 that was sent, the player would flip back to it.
    final seen = <double>{};
    void record() => seen.add(player.volume);
    player.addListener(record);
    await Future<void>.delayed(const Duration(milliseconds: 2500));
    player.removeListener(record);

    expect(seen, isNotEmpty, reason: 'the poll should have notified');
    expect(seen, {closeTo(0.39, 1e-9)});
    expect(upnp.volume, 39);
  });

  test('switching renderer mid-burst sends nothing to the new one', () async {
    final other = FakeUpnpRenderer(volume: 20, name: 'Other renderer');
    await other.start();
    addTearDown(other.close);

    renderer.gateSetVolume = Completer<void>();
    slider.pressKey(-1); // 10, in flight to the first renderer
    await Future<void>.delayed(const Duration(milliseconds: 50));
    slider.pressKey(-1); // 5, pending

    expect(await upnp.connect(other.device), isTrue);
    renderer.gateSetVolume!.complete();
    await settle();

    expect(renderer.setVolumes, [10]);
    expect(other.setVolumes, isEmpty,
        reason: 'a value meant for one speaker must not land on another');
    expect(player.volume, closeTo(0.20, 1e-9),
        reason: 'resync to the new renderer, not the old one\'s level');
    expect(slider.shown, 20);
  });

  test('the next key press after a disconnect and reconnect starts fresh',
      () async {
    renderer.gateSetVolume = Completer<void>();
    slider.pressKey(1); // 20, in flight
    await Future<void>.delayed(const Duration(milliseconds: 50));
    upnp.disconnect();
    await pumpEventQueue();
    renderer.gateSetVolume!.complete();
    await settle();
    expect(upnp.volume, -1);
    expect(slider.shown, isNull);

    expect(await upnp.connect(renderer.device), isTrue);
    await pumpEventQueue();
    expect(slider.shown, renderer.volume);
  });
}
