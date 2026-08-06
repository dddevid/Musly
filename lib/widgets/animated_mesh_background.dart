// lib/widgets/animated_mesh_background.dart
//
// Adaptive animated mesh-gradient background for the Now Playing screen.
//
// Each quality tier renders a different visual:
//
//   HIGH   — 5 Lissajous-path blobs + ImageFiltered Gaussian blur (σ=70)
//            + pre-baked noise-grain overlay + dark scrim.
//            All blobs at 60 fps with individual AnimationControllers.
//
//   MEDIUM — 3 Lissajous-path blobs (no extra ImageFiltered blur, the large
//            RadialGradient circles are naturally soft) + dark scrim.
//            Blob repaint throttled to 30 fps.
//
//   LOW    — Static 3-stop LinearGradient, zero GPU animation cost.
//
// A PerformanceMonitor (fed by a Ticker) automatically switches tiers based
// on real frame-time measurements.
//
// Color extraction:
//   PaletteGenerator samples the album art at 112×112 px and picks up to 4
//   dominant/accent colors.  Results are cached globally (up to 20 entries).
//   A 900 ms TweenAnimationBuilder crossfade blends old → new colors on track
//   change.

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:palette_generator/palette_generator.dart';

import 'album_artwork.dart' show isLocalFilePath;
import 'themed_now_playing_elements.dart';
import '../services/performance_monitor.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Global constants & helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Fallback colors when no artwork is available (Apple Music dark aesthetic).
const _kDefaultColors = <Color>[
  Color(0xFF1A0A2E),
  Color(0xFF0D1B3E),
  Color(0xFF0A1628),
  Color(0xFF160A2A),
];

/// Global palette cache shared across rebuilds. Keyed by image URL / path.
/// Bounded to 20 entries to avoid unbounded memory growth.
final _meshPaletteCache = <String, List<Color>>{};

/// Extract 4 palette colors from [imageUrl] via [PaletteGenerator].
///
/// Priority: vibrant → darkVibrant → muted → darkMuted → lightVibrant → lightMuted.
/// Falls back to [_kDefaultColors] on any error.
Future<List<Color>> _extractMeshColors(String imageUrl) async {
  if (_meshPaletteCache.containsKey(imageUrl)) {
    return _meshPaletteCache[imageUrl]!;
  }

  try {
    final ImageProvider provider;
    if (isLocalFilePath(imageUrl)) {
      provider = FileImage(File(imageUrl));
    } else {
      provider = NetworkImage(imageUrl);
    }

    final generator = await PaletteGenerator.fromImageProvider(
      provider,
      size: const Size(112, 112), // small thumbnail → fast extraction
      maximumColorCount: 8,
    );

    // Pick the richest available swatches.
    final candidates = [
      generator.vibrantColor,
      generator.darkVibrantColor,
      generator.mutedColor,
      generator.darkMutedColor,
      generator.lightVibrantColor,
      generator.lightMutedColor,
    ].whereType<PaletteColor>().map((s) => s.color).toList();

    final base = candidates.isNotEmpty
        ? candidates
        : generator.colors.take(6).toList();

    // Ensure exactly 4 fully-opaque colors.
    final result = List<Color>.generate(4, (i) {
      final c = base.isNotEmpty ? base[i % base.length] : _kDefaultColors[i];
      return c.withValues(alpha: 1.0);
    });

    _meshPaletteCache[imageUrl] = result;
    if (_meshPaletteCache.length > 20) {
      _meshPaletteCache.remove(_meshPaletteCache.keys.first);
    }
    return result;
  } catch (_) {
    return List<Color>.from(_kDefaultColors);
  }
}

/// Darken [c] by [factor] ∈ [0, 1]  (0 = unchanged, 1 = black).
Color _darken(Color c, double factor) {
  final f = 1.0 - factor.clamp(0.0, 1.0);
  return Color.fromRGBO(
    (c.r * 255.0 * f).round().clamp(0, 255),
    (c.g * 255.0 * f).round().clamp(0, 255),
    (c.b * 255.0 * f).round().clamp(0, 255),
    1.0,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Blob configuration
// ─────────────────────────────────────────────────────────────────────────────

/// Immutable descriptor for a single Lissajous-path blob.
///
/// The blob's centre follows:
///   x(t) = sin(freqX · t + phaseX) · ampX
///   y(t) = cos(freqY · t + phaseY) · ampY
/// where t ∈ [0, 2π] maps to one full [period] cycle.
class _BlobConfig {
  const _BlobConfig({
    required this.freqX,
    required this.freqY,
    required this.phaseX,
    required this.phaseY,
    required this.ampX,
    required this.ampY,
    required this.sizeFactor,
    required this.colorIndex,
    required this.period,
  });

  /// Lissajous frequency multipliers for X and Y axes.
  final double freqX, freqY;

  /// Phase offsets (radians) so blobs start at different positions.
  final double phaseX, phaseY;

  /// Maximum displacement along X and Y in Alignment units (≈ 0–1).
  final double ampX, ampY;

  /// Blob diameter as a fraction of the widget's shorter dimension.
  final double sizeFactor;

  /// Which extracted palette color index this blob uses.
  final int colorIndex;

  /// Duration of one complete oscillation cycle.
  final Duration period;
}

// ── MEDIUM preset: 3 blobs ────────────────────────────────────────────────

const _kMediumBlobs = <_BlobConfig>[
  _BlobConfig(
    freqX: 1.0, freqY: 1.3,
    phaseX: 0.0, phaseY: 0.5,
    ampX: 0.85, ampY: 0.90,
    sizeFactor: 1.85, colorIndex: 0,
    period: Duration(seconds: 35),
  ),
  _BlobConfig(
    freqX: 1.5, freqY: 1.0,
    phaseX: 1.2, phaseY: 0.0,
    ampX: 0.90, ampY: 0.85,
    sizeFactor: 1.75, colorIndex: 1,
    period: Duration(seconds: 42),
  ),
  _BlobConfig(
    freqX: 0.8, freqY: 1.7,
    phaseX: 2.5, phaseY: 1.8,
    ampX: 0.75, ampY: 0.80,
    sizeFactor: 1.90, colorIndex: 2,
    period: Duration(seconds: 30),
  ),
];

// ── HIGH preset: 5 blobs, richer coverage ────────────────────────────────

const _kHighBlobs = <_BlobConfig>[
  _BlobConfig(
    freqX: 1.0, freqY: 1.3,
    phaseX: 0.0, phaseY: 0.5,
    ampX: 0.90, ampY: 0.85,
    sizeFactor: 1.90, colorIndex: 0,
    period: Duration(seconds: 34),
  ),
  _BlobConfig(
    freqX: 1.5, freqY: 1.0,
    phaseX: 1.2, phaseY: 0.0,
    ampX: 0.85, ampY: 0.90,
    sizeFactor: 1.80, colorIndex: 1,
    period: Duration(seconds: 46),
  ),
  _BlobConfig(
    freqX: 0.8, freqY: 1.7,
    phaseX: 2.5, phaseY: 1.8,
    ampX: 0.80, ampY: 0.75,
    sizeFactor: 1.85, colorIndex: 2,
    period: Duration(seconds: 28),
  ),
  _BlobConfig(
    freqX: 2.0, freqY: 0.7,
    phaseX: 0.8, phaseY: 3.0,
    ampX: 0.75, ampY: 0.80,
    sizeFactor: 1.70, colorIndex: 3,
    period: Duration(seconds: 52),
  ),
  _BlobConfig(
    freqX: 1.3, freqY: 2.0,
    phaseX: 3.5, phaseY: 0.3,
    ampX: 0.70, ampY: 0.75,
    sizeFactor: 1.60, colorIndex: 0,
    period: Duration(seconds: 40),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// _AnimatedBlob — a single self-driven Lissajous blob
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedBlob extends StatefulWidget {
  const _AnimatedBlob({
    required this.config,
    required this.color,
    required this.throttleFps,
  });

  final _BlobConfig config;
  final Color color;

  /// Maximum target frame rate for repaints (60 = no cap, 30 = 30 fps cap).
  final int throttleFps;

  @override
  State<_AnimatedBlob> createState() => _AnimatedBlobState();
}

class _AnimatedBlobState extends State<_AnimatedBlob>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  int _lastRebuildMs = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.config.period)
      ..repeat();
    _ctrl.addListener(_onTick);
  }

  @override
  void didUpdateWidget(_AnimatedBlob old) {
    super.didUpdateWidget(old);
    // If quality changes the config (e.g., period differs), update the controller.
    if (old.config.period != widget.config.period) {
      _ctrl.duration = widget.config.period;
      if (_ctrl.isAnimating) _ctrl.repeat();
    }
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onTick);
    _ctrl.dispose();
    super.dispose();
  }

  void _onTick() {
    if (!mounted) return;
    final intervalMs = (1000 / widget.throttleFps).round();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs - _lastRebuildMs >= intervalMs) {
      _lastRebuildMs = nowMs;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = widget.config;
    final t = _ctrl.value * 2.0 * math.pi;
    final x = math.sin(cfg.freqX * t + cfg.phaseX) * cfg.ampX;
    final y = math.cos(cfg.freqY * t + cfg.phaseY) * cfg.ampY;

    return Align(
      alignment: Alignment(x, y),
      child: FractionallySizedBox(
        widthFactor: cfg.sizeFactor,
        heightFactor: cfg.sizeFactor,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                widget.color.withValues(alpha: 0.88),
                widget.color.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ColorListTween — smooth crossfade between two palette sets
// ─────────────────────────────────────────────────────────────────────────────

class _ColorListTween extends Tween<List<Color>> {
  _ColorListTween({required List<Color> begin, required List<Color> end})
      : super(begin: begin, end: end);

  @override
  List<Color> lerp(double t) {
    final b = begin!;
    final e = end!;
    return List.generate(b.length, (i) => Color.lerp(b[i], e[i], t)!);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NoisePainter — draws a pre-baked noise texture (no per-frame CPU cost)
// ─────────────────────────────────────────────────────────────────────────────

class _NoisePainter extends CustomPainter {
  const _NoisePainter(this._image);
  final ui.Image _image;

  @override
  void paint(Canvas canvas, Size size) {
    final src = Offset.zero &
        Size(_image.width.toDouble(), _image.height.toDouble());
    final dst = Offset.zero & size;
    // Scale the half-resolution noise tile to full screen — imperceptible.
    canvas.drawImageRect(
      _image,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  @override
  bool shouldRepaint(_NoisePainter old) => old._image != _image;
}

// ─────────────────────────────────────────────────────────────────────────────
// AnimatedMeshBackground — public widget
// ─────────────────────────────────────────────────────────────────────────────

/// Adaptive animated mesh-gradient background for the Now Playing screen.
///
/// Replaces the static `_DynamicBackground` with a self-regulating system
/// that auto-selects HIGH / MEDIUM / LOW visual quality based on runtime
/// frame-time measurements.
///
/// Integrates transparently with the existing [ThemeAwareBuilder] so that
/// custom user themes (solid / gradient / dynamic) still work as expected.
class AnimatedMeshBackground extends StatefulWidget {
  const AnimatedMeshBackground({super.key, required this.imageUrl});

  /// Network URL or local file path of the current album's cover art.
  final String imageUrl;

  @override
  State<AnimatedMeshBackground> createState() => _AnimatedMeshBackgroundState();
}

class _AnimatedMeshBackgroundState extends State<AnimatedMeshBackground>
    with SingleTickerProviderStateMixin {
  // ── Color state ────────────────────────────────────────────────────────────
  List<Color> _colors = List<Color>.from(_kDefaultColors);
  List<Color> _prevColors = List<Color>.from(_kDefaultColors);

  // ── Quality & performance ──────────────────────────────────────────────────
  BackgroundQuality _quality = BackgroundQuality.medium;
  late PerformanceMonitor _monitor;

  // ── Frame timing (Ticker-based, auto-disposed) ────────────────────────────
  late Ticker _frameTicker;
  Duration _lastTickElapsed = Duration.zero;

  // ── Noise grain (HIGH only; generated once, reused forever) ───────────────
  ui.Image? _noiseImage;
  bool _generatingNoise = false;

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _monitor = PerformanceMonitor(
      onQualityChanged: (q) {
        if (mounted) setState(() => _quality = q);
      },
    );

    // Use a Ticker so frame-time measurement automatically pauses/resumes
    // with TickerMode (e.g. when the screen is off-screen or paused).
    _frameTicker = createTicker(_onFrameTick)..start();

    _loadColors(widget.imageUrl);
  }

  @override
  void didUpdateWidget(AnimatedMeshBackground old) {
    super.didUpdateWidget(old);
    if (old.imageUrl != widget.imageUrl) _loadColors(widget.imageUrl);
  }

  @override
  void dispose() {
    _frameTicker.dispose();
    _noiseImage?.dispose();
    super.dispose();
  }

  // ── Frame timing ──────────────────────────────────────────────────────────

  void _onFrameTick(Duration elapsed) {
    final delta = elapsed - _lastTickElapsed;
    _lastTickElapsed = elapsed;
    final ms = delta.inMicroseconds / 1000.0;
    _monitor.recordFrameTime(ms);
  }

  // ── Color loading ─────────────────────────────────────────────────────────

  Future<void> _loadColors(String url) async {
    if (url.isEmpty) {
      if (mounted) {
        setState(() {
          _prevColors = _colors;
          _colors = List<Color>.from(_kDefaultColors);
        });
      }
      return;
    }

    // Serve from cache immediately to prevent a colour flash on track change.
    if (_meshPaletteCache.containsKey(url)) {
      if (mounted) {
        setState(() {
          _prevColors = _colors;
          _colors = _meshPaletteCache[url]!;
        });
      }
      return;
    }

    final result = await _extractMeshColors(url);
    if (mounted && url == widget.imageUrl) {
      setState(() {
        _prevColors = _colors;
        _colors = result;
      });
    }
  }

  // ── Noise texture (one-time async generation at half-resolution) ──────────

  Future<void> _generateNoise(Size size) async {
    if (_generatingNoise || _noiseImage != null) return;
    _generatingNoise = true;

    // Render at half the screen resolution → tiled to full size at display
    // time via drawImageRect.  Imperceptible for high-frequency noise.
    final w = (size.width / 2).ceil();
    final h = (size.height / 2).ceil();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Offset.zero & Size(w.toDouble(), h.toDouble()),
    );

    final paint = Paint();
    final rng = math.Random(42); // fixed seed → deterministic, reproducible
    final count = (w * h * 0.12).toInt(); // ~12 % pixel density

    for (var i = 0; i < count; i++) {
      final x = rng.nextDouble() * w;
      final y = rng.nextDouble() * h;
      final alpha = rng.nextDouble() * 0.07 + 0.005;
      // Mix bright-white and near-white for realistic analogue film grain.
      final lum = rng.nextBool() ? 255 : (180 + rng.nextInt(75));
      paint.color = Color.fromRGBO(lum, lum, lum, alpha);
      canvas.drawCircle(Offset(x, y), 0.65, paint);
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(w, h);

    if (mounted) setState(() => _noiseImage = img);
    _generatingNoise = false;
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ThemeAwareBuilder(
      builder: (ctx, theme, isCustom) {
        // ── Custom user-defined theme backgrounds ─────────────────────────
        if (isCustom) {
          final bgType = theme.background.type;
          if (bgType == 'solid') {
            return ColoredBox(color: theme.background.getColor(0));
          }
          if (bgType == 'gradient') {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.background.getColor(0),
                    theme.background.getColor(1),
                  ],
                ),
              ),
            );
          }
          // bgType == 'dynamic' falls through to the animated mesh below.
        }

        // ── Animated mesh (default) ───────────────────────────────────────
        return RepaintBoundary(
          child: TweenAnimationBuilder<List<Color>>(
            tween: _ColorListTween(begin: _prevColors, end: _colors),
            duration: const Duration(milliseconds: 900),
            builder: (ctx, colors, _) => _buildAdaptive(ctx, colors),
          ),
        );
      },
    );
  }

  // ── Quality-adaptive render ───────────────────────────────────────────────

  Widget _buildAdaptive(BuildContext context, List<Color> colors) {
    return AnimatedSwitcher(
      duration: const Duration(seconds: 1),
      child: _buildAdaptiveContent(context, colors, key: ValueKey(_quality)),
    );
  }

  Widget _buildAdaptiveContent(BuildContext context, List<Color> colors, {Key? key}) {
    if (_quality == BackgroundQuality.low) {
      return SizedBox.expand(
        key: key,
        child: _buildLow(colors),
      );
    }

    return LayoutBuilder(
      key: key,
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        // Kick off noise generation the first time we hit HIGH quality.
        if (_quality == BackgroundQuality.high &&
            _noiseImage == null &&
            !_generatingNoise) {
          _generateNoise(size);
        }

        final configs =
            _quality == BackgroundQuality.high ? _kHighBlobs : _kMediumBlobs;
        final throttleFps = _quality == BackgroundQuality.high ? 60 : 30;
        final applyBlur = _quality == BackgroundQuality.high;

        // Blob layer — optionally wrapped in a Gaussian ImageFiltered blur.
        Widget blobLayer = Stack(
          fit: StackFit.expand,
          children: [
            for (final cfg in configs)
              _AnimatedBlob(
                config: cfg,
                color: colors[cfg.colorIndex % colors.length],
                throttleFps: throttleFps,
              ),
          ],
        );

        if (applyBlur) {
          // ImageFiltered is cheaper than BackdropFilter because it only
          // processes its own subtree and is fully contained in a layer.
          blobLayer = ImageFiltered(
            imageFilter: ui.ImageFilter.blur(
              sigmaX: 70.0,
              sigmaY: 70.0,
              tileMode: TileMode.clamp,
            ),
            child: blobLayer,
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            // ① Solid dark base (prevents any transparent gaps).
            ColoredBox(color: _darken(colors.last, 0.45)),

            // ② Animated blob layer (with blur on HIGH quality).
            blobLayer,

            // ③ Noise grain overlay — HIGH quality only.
            //    isComplex/willChange hint the raster cache to bake this once.
            if (_quality == BackgroundQuality.high && _noiseImage != null)
              Opacity(
                opacity: 0.35,
                child: CustomPaint(
                  painter: _NoisePainter(_noiseImage!),
                  isComplex: true,
                  willChange: false,
                ),
              ),

            // ④ Dark scrim — ensures white text remains readable.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromRGBO(0, 0, 0, 0.42),
                    Color.fromRGBO(0, 0, 0, 0.70),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// LOW quality: a simple 3-stop linear gradient.  Zero animation cost.
  Widget _buildLow(List<Color> colors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.55, 1.0],
          colors: [
            _darken(colors[0], 0.30),
            _darken(colors[1 % colors.length], 0.45),
            _darken(colors[2 % colors.length], 0.60),
          ],
        ),
      ),
    );
  }
}
