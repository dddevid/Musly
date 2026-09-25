import 'package:flutter_test/flutter_test.dart';
import 'package:musly/services/audio_handler.dart';

import '../bootstrap.dart';

/// Android answers a hardware volume key by setting MediaSessionRecord's
/// mOptimisticVolume to currentVolume ± 1 and displaying that for a second
/// before the real value lands. Publishing the VolumeProvider on a 0-100 scale
/// while adjusting by 5 meant the optimistic value moved by 1 and ours by 5, so
/// the system volume overlay visibly jumped a second after every press.
///
/// The provider is therefore published on a coarser scale of one unit per step,
/// while everything the handler hands to callers stays in UPnP percent. These
/// tests pin that relationship, because getting the two scales out of step is
/// the whole bug and it is invisible in `dumpsys`.
///
/// The adjust/set entry points themselves are gated on `Platform.isAndroid`, so
/// they cannot run on a host VM; the conversion they depend on is what is
/// exercised here.
void main() {
  initializeTestEnvironment();

  test('one provider unit is exactly one adjustment step', () {
    // The invariant the fix exists to create: Android's ±1 must land on the
    // same value our own step would produce, or the overlay corrects itself a
    // second later and the user sees a jump.
    expect(MuslyAudioHandler.percentFromProviderUnits(1), 5);
    expect(
      MuslyAudioHandler.providerUnitsFromPercent(5) -
          MuslyAudioHandler.providerUnitsFromPercent(0),
      1,
    );
  });

  test('the provider scale spans the full percent range', () {
    expect(MuslyAudioHandler.percentFromProviderUnits(0), 0);
    expect(
      MuslyAudioHandler.percentFromProviderUnits(
        MuslyAudioHandler.remoteProviderMax,
      ),
      100,
      reason: 'max provider units must mean full volume, not 95% or 105%',
    );
  });

  test('percent and provider units round-trip on step boundaries', () {
    for (var percent = 0; percent <= 100; percent += 5) {
      final units = MuslyAudioHandler.providerUnitsFromPercent(percent);
      expect(MuslyAudioHandler.percentFromProviderUnits(units), percent,
          reason: '$percent% should survive the round trip');
    }
  });

  test('off-step percentages snap to the nearest unit', () {
    // Renderers report whatever they like — 46%, 73% — and that has to map onto
    // the provider scale without drifting a whole step.
    expect(MuslyAudioHandler.providerUnitsFromPercent(46), 9); // 45%
    expect(MuslyAudioHandler.providerUnitsFromPercent(73), 15); // 75%
    expect(MuslyAudioHandler.providerUnitsFromPercent(2), 0);
    expect(MuslyAudioHandler.providerUnitsFromPercent(3), 1);
  });

  test('conversions clamp instead of overshooting', () {
    expect(MuslyAudioHandler.providerUnitsFromPercent(150),
        MuslyAudioHandler.remoteProviderMax);
    expect(MuslyAudioHandler.providerUnitsFromPercent(-10), 0);
    expect(MuslyAudioHandler.percentFromProviderUnits(99), 100);
    expect(MuslyAudioHandler.percentFromProviderUnits(-1), 0);
  });

  test('a key press from an off-step volume lands on the provider scale', () {
    // Measured on upmpdcli: the renderer reported 33%, the slider showed 7
    // (35%), and adding 5 per press sent 28, 23, 28, 33 — always 2% off what
    // the slider displayed.
    expect(MuslyAudioHandler.adjustedPercent(33, -1), 30);
    expect(MuslyAudioHandler.adjustedPercent(33, 1), 40);
    expect(MuslyAudioHandler.adjustedPercent(35, -1), 30);
    expect(MuslyAudioHandler.adjustedPercent(35, 1), 40);
  });

  test('key presses clamp at the ends of the range', () {
    expect(MuslyAudioHandler.adjustedPercent(0, -1), 0);
    expect(MuslyAudioHandler.adjustedPercent(2, -1), 0);
    expect(MuslyAudioHandler.adjustedPercent(100, 1), 100);
    expect(MuslyAudioHandler.adjustedPercent(98, 1), 100);
  });

  test('the provider scale is coarser than percent', () {
    // A 0-100 provider scale is exactly what caused the jump; if someone
    // widens it back, this fails.
    expect(MuslyAudioHandler.remoteProviderMax, lessThan(100));
    expect(MuslyAudioHandler.remoteProviderMax, greaterThan(1));
  });
}
