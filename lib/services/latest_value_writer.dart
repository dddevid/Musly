import 'package:flutter/foundation.dart';

/// Sends values one at a time, always finishing on the newest one requested.
///
/// A request that arrives while a write is in flight replaces any earlier one
/// that hasn't been sent yet, instead of being dropped. The actual value is
/// read back once, after the last write, so a burst of key presses can't make
/// the caller show a stale intermediate value.
///
/// A [write] that throws is treated like one that went through; a [readBack]
/// that throws is treated as a failed read. Neither stops later requests.
class LatestValueWriter {
  LatestValueWriter({
    required this.write,
    required this.readBack,
    required this.onSettled,
  });

  final Future<void> Function(int value) write;

  /// The value actually in effect, or a negative number if it is unknown.
  final Future<int> Function() readBack;

  final void Function(int actual) onSettled;

  int? _pending;
  bool _busy = false;

  /// True from the first write until the read-back has been handled.
  bool get busy => _busy;

  void request(int value) {
    _pending = value;
    if (!_busy) _drain();
  }

  Future<void> _drain() async {
    _busy = true;
    try {
      while (true) {
        while (_pending != null) {
          final value = _pending!;
          _pending = null;
          try {
            await write(value);
          } catch (e) {
            debugPrint('LatestValueWriter: write($value) failed: $e');
          }
        }
        int actual;
        try {
          actual = await readBack();
        } catch (e) {
          debugPrint('LatestValueWriter: read-back failed: $e');
          actual = -1;
        }
        // Pressed again during the read-back: send that before reporting.
        if (_pending != null) continue;
        if (actual >= 0) {
          try {
            onSettled(actual);
          } catch (e) {
            debugPrint('LatestValueWriter: onSettled($actual) failed: $e');
          }
        }
        break;
      }
    } finally {
      _busy = false;
    }
    // onSettled can notify listeners that request again; don't strand that.
    if (_pending != null) _drain();
  }
}
