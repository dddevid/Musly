// lib/services/performance_monitor.dart
//
// Runtime frame-time monitor that automatically adapts the animated background
// quality tier (HIGH → MEDIUM → LOW) based on the device's real GPU/CPU load.
//
// State machine:
//
//   STARTUP ──► [benchmark: first 30 frames] ──► avg < 12 ms ──► HIGH
//                                              ├─ avg < 25 ms ──► MEDIUM
//                                              └─ avg ≥ 25 ms ──► LOW
//
//   MEDIUM ──► frametime > 25 ms for 3 consecutive frames ──► LOW
//          └─ OR frametime > 33 ms (single critical frame)  ──► LOW
//
//   MEDIUM ──► rolling-window avg < 12 ms ──► HIGH
//
//   LOW ──► stable for 10 s + rolling avg < 10 ms ──► MEDIUM (recovery)

/// Visual quality tier for the animated mesh background.
enum BackgroundQuality {
  /// Full animated mesh: 5 blobs, ImageFiltered blur, noise grain, 60 fps.
  high,

  /// 3 animated blobs, natural soft-radial blur, 30 fps cap. Default tier.
  medium,

  /// Static 3-stop linear gradient — zero GPU animation cost.
  low,
}

/// Monitors per-frame render time and exposes the current [BackgroundQuality].
///
/// Feed frame-time samples via [recordFrameTime]; the monitor emits quality
/// changes through the [onQualityChanged] callback.
///
/// ```dart
/// final monitor = PerformanceMonitor(
///   onQualityChanged: (q) => setState(() => _quality = q),
/// );
/// // Inside a Ticker callback:
/// monitor.recordFrameTime(deltaMs);
/// ```
class PerformanceMonitor {
  PerformanceMonitor({this.onQualityChanged});

  /// Called whenever the quality tier changes.  Safe to call `setState` here.
  final void Function(BackgroundQuality quality)? onQualityChanged;

  BackgroundQuality _quality = BackgroundQuality.medium;

  /// The current quality tier (changes are notified via [onQualityChanged]).
  BackgroundQuality get quality => _quality;

  // ── Rolling evaluation window ─────────────────────────────────────────────
  final List<double> _window = [];

  /// Number of samples in the rolling window (≈ 2 s at a background 15 fps).
  static const int _windowSize = 30;

  // ── Consecutive-alarm detector ────────────────────────────────────────────
  int _consecutiveAlarmFrames = 0;

  /// Consecutive frames above [_alarmMs] required to trigger a downgrade.
  static const int _alarmCount = 3;

  // ── LOW-quality recovery ──────────────────────────────────────────────────
  DateTime? _lowStart;

  /// Minimum time the device must remain stable before attempting recovery.
  static const Duration _recoveryDelay = Duration(seconds: 10);

  // ── Benchmark (first [_benchmarkTarget] frames) ───────────────────────────
  bool _benchmarkDone = false;
  final List<double> _benchmarkSamples = [];
  static const int _benchmarkTarget = 30;

  // ── Thresholds (milliseconds) ─────────────────────────────────────────────
  /// Frame time below which the device is considered HIGH-end (≈ 83+ fps).
  static const double _highMs = 12.0;

  /// Frame time above which a frame is flagged as an "alarm" (< 40 fps).
  static const double _alarmMs = 25.0;

  /// Frame time above which a single frame triggers an immediate downgrade.
  static const double _criticalMs = 33.0;

  /// Rolling-window average below which the device may recover from LOW.
  static const double _recoveryMs = 10.0;

  // ─────────────────────────────────────────────────────────────────────────

  /// Record a new frame-time sample [ms] (milliseconds since the last frame).
  ///
  /// Typically called from a [Ticker] callback so it fires once per vsync.
  void recordFrameTime(double ms) {
    if (ms <= 0 || ms > 500) return; // discard bogus / first-frame values

    _window.add(ms);
    if (_window.length > _windowSize) _window.removeAt(0);

    if (!_benchmarkDone) {
      _benchmarkSamples.add(ms);
      if (_benchmarkSamples.length >= _benchmarkTarget) _runBenchmark();
      return;
    }

    _evaluate(ms);
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  void _runBenchmark() {
    _benchmarkDone = true;
    final avg = _mean(_benchmarkSamples);

    if (avg < _highMs) {
      _set(BackgroundQuality.high);
    } else if (avg < _alarmMs) {
      _set(BackgroundQuality.medium);
    } else {
      _set(BackgroundQuality.low);
      _lowStart = DateTime.now();
    }
  }

  void _evaluate(double ms) {
    if (_quality == BackgroundQuality.low) {
      // Once downgraded to low, we lock it for the remainder of the session 
      // to prevent flashing/bouncing on mid-range devices.
      return;
    }

    // A single critical frame triggers an immediate downgrade.
    if (ms > _criticalMs) {
      _consecutiveAlarmFrames = 0;
      _downgrade();
      return;
    }

    if (ms > _alarmMs) {
      if (++_consecutiveAlarmFrames >= _alarmCount) {
        _consecutiveAlarmFrames = 0;
        _downgrade();
      }
    } else {
      _consecutiveAlarmFrames = 0;
      // Intentionally removed: upgrade from MEDIUM → HIGH to prevent bouncing.
    }
  }

  void _downgrade() {
    if (_quality == BackgroundQuality.high) {
      _set(BackgroundQuality.medium);
    } else {
      _set(BackgroundQuality.low);
    }
    _lowStart = DateTime.now();
  }

  void _set(BackgroundQuality q) {
    if (q == _quality) return;
    _quality = q;
    onQualityChanged?.call(q);
  }

  static double _mean(List<double> list) =>
      list.reduce((a, b) => a + b) / list.length;
}
