import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:musly/services/latest_value_writer.dart';

/// Hardware volume keys can fire a few milliseconds apart, faster than one
/// SetVolume + GetVolume round trip. The provider used to drop any press that
/// arrived mid-write, so the renderer stayed on the earlier value and the
/// system slider snapped back to it a second later. These tests drive the
/// writer against a renderer whose responses the test releases by hand.
class _FakeRenderer {
  int volume = 15;
  final writes = <int>[];
  final settled = <int>[];
  final _pendingWrites = <Completer<void>>[];
  final _pendingReads = <Completer<int>>[];
  int readResult = -2; // -2: report the current volume

  late final writer = LatestValueWriter(
    write: (v) {
      writes.add(v);
      final c = Completer<void>();
      _pendingWrites.add(c);
      return c.future.then((_) => volume = v);
    },
    readBack: () {
      final c = Completer<int>();
      _pendingReads.add(c);
      return c.future;
    },
    onSettled: settled.add,
  );

  Future<void> finishWrite() async {
    _pendingWrites.removeAt(0).complete();
    await pumpEventQueue();
  }

  Future<void> finishRead() async {
    _pendingReads.removeAt(0).complete(readResult == -2 ? volume : readResult);
    await pumpEventQueue();
  }

  bool get hasPendingWrite => _pendingWrites.isNotEmpty;
  bool get hasPendingRead => _pendingReads.isNotEmpty;
}

void main() {
  test('a request during a write is sent next, not dropped', () async {
    final r = _FakeRenderer();
    r.writer.request(10);
    r.writer.request(5);
    await pumpEventQueue();
    expect(r.writes, [10]);

    await r.finishWrite();
    expect(r.writes, [10, 5]);
    expect(r.hasPendingRead, isFalse, reason: 'no read-back mid-burst');

    await r.finishWrite();
    await r.finishRead();
    expect(r.volume, 5);
    expect(r.settled, [5]);
  });

  test('a burst during one write collapses to first and last', () async {
    final r = _FakeRenderer();
    for (final v in [20, 25, 30, 35, 40]) {
      r.writer.request(v);
    }
    await pumpEventQueue();
    await r.finishWrite();
    await r.finishWrite();
    await r.finishRead();
    expect(r.writes, [20, 40]);
    expect(r.settled, [40]);
  });

  test('a request during the read-back is written before reporting', () async {
    final r = _FakeRenderer();
    r.writer.request(10);
    await pumpEventQueue();
    await r.finishWrite();
    expect(r.hasPendingRead, isTrue);

    r.writer.request(5);
    await r.finishRead();
    expect(r.settled, isEmpty, reason: 'the read-back value is already stale');
    expect(r.writes, [10, 5]);

    await r.finishWrite();
    await r.finishRead();
    expect(r.settled, [5]);
  });

  test('a failed read-back reports nothing and the writer recovers', () async {
    final r = _FakeRenderer()..readResult = -1;
    r.writer.request(10);
    await pumpEventQueue();
    await r.finishWrite();
    await r.finishRead();
    expect(r.settled, isEmpty);
    expect(r.writer.busy, isFalse);

    r.readResult = -2;
    r.writer.request(5);
    await pumpEventQueue();
    await r.finishWrite();
    await r.finishRead();
    expect(r.settled, [5]);
  });

  test('busy covers the whole sequence', () async {
    final r = _FakeRenderer();
    expect(r.writer.busy, isFalse);
    r.writer.request(10);
    expect(r.writer.busy, isTrue);
    await pumpEventQueue();
    await r.finishWrite();
    expect(r.writer.busy, isTrue, reason: 'still reading back');
    await r.finishRead();
    expect(r.writer.busy, isFalse);
    expect(r.hasPendingWrite, isFalse);
  });

  test('a write that throws does not strand the next request', () async {
    final writes = <int>[];
    final settled = <int>[];
    final gate = Completer<void>();
    final writer = LatestValueWriter(
      write: (v) async {
        writes.add(v);
        if (v == 10) {
          await gate.future;
          throw Exception('renderer fault');
        }
      },
      readBack: () async => 5,
      onSettled: settled.add,
    );
    writer.request(10);
    writer.request(5);
    gate.complete();
    await pumpEventQueue();
    expect(writes, [10, 5]);
    expect(settled, [5]);
    expect(writer.busy, isFalse);
  });
}
