import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:musly/services/upnp_service.dart';

import '../fake_upnp_renderer.dart';

/// UpnpService reads GetVolume on every fifth poll. A read that reaches the
/// renderer before a SetVolume but answers after it carries the old volume,
/// and caching it made the system volume slider snap back to where it was
/// before the user's key press, then correct itself up to five seconds later.
///
/// Drives the real service against a fake renderer on loopback that can hold
/// a GetVolume response open, the only way to get that interleaving reliably.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeUpnpRenderer renderer;
  late UpnpService upnp;
  late List<int> volumes;

  void recordVolume() => volumes.add(upnp.volume);

  setUp(() async {
    HttpOverrides.global = null;
    renderer = FakeUpnpRenderer();
    await renderer.start();
    upnp = UpnpService();
    expect(await upnp.connect(renderer.device), isTrue);
    expect(upnp.volume, 15);
    volumes = [];
    upnp.addListener(recordVolume);
  });

  tearDown(() async {
    upnp.removeListener(recordVolume);
    upnp.disconnect();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await renderer.close();
  });

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 200));

  test('a poll read sent before a SetVolume cannot undo it', () async {
    renderer.holdNextRead = true;
    await renderer.readHeld.future.timeout(const Duration(seconds: 8));

    await upnp.setVolume(5);
    expect(renderer.volume, 5);
    expect(upnp.volume, 5);
    volumes.clear();

    renderer.releaseRead.complete();
    await settle();

    expect(upnp.volume, 5);
    expect(volumes, isNot(contains(15)),
        reason: 'a stale 15 here snaps the system slider back');
  });

  test('a change made by another controller still gets through', () async {
    renderer.volume = 30;
    final deadline = DateTime.now().add(const Duration(seconds: 8));
    while (upnp.volume != 30 && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    expect(upnp.volume, 30);
  });

  test('a SetVolume answered after a disconnect does not come back', () async {
    renderer.gateSetVolume = Completer<void>();
    final write = upnp.setVolume(40);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    upnp.disconnect();
    expect(upnp.volume, -1);
    renderer.gateSetVolume!.complete();
    await write;

    expect(upnp.volume, -1,
        reason: 'the next renderer would start out showing this one\'s volume');
  });

  test('refreshVolume caches what the renderer reports', () async {
    renderer.apply = (v) => v - 1;
    await upnp.setVolume(40);
    expect(upnp.volume, 40, reason: 'the cache holds what was sent');

    expect(await upnp.refreshVolume(), 39);
    expect(upnp.volume, 39);
  });
}
