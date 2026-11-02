import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Tunable look of a [GlassContainer].
///
/// Colours are intentionally not stored here: the tint is resolved from the
/// ambient [Theme] at build time, so glass always sits *on top of* the current
/// light/dark/accent/dynamic theme instead of replacing it.
///
/// Lengths are in logical pixels.
@immutable
class GlassStyle {
  const GlassStyle({
    this.refraction = 18,
    this.bevel = 20,
    this.dispersion = 0.1,
    this.frost = 0,
    this.saturation = 1.2,
    this.lightTintOpacity = 0.06,
    this.darkTintOpacity = 0.05,
    this.adaptiveTint = 0.45,
    this.highlight = 1.0,
    this.elevation = 1.0,
    this.rimWidth = 1.0,
    this.fallbackBlurSigma = 20,
  });

  /// How far, at the very rim, the glass pulls in content from outside its
  /// edge. `0` disables lensing.
  final double refraction;

  /// Width of the curved band along the edge that bends light. The centre
  /// inside it is flat and optically clear.
  final double bevel;

  /// Chromatic dispersion across the bevel, as a fraction of [refraction]
  /// (blue bends that much more than green, red that much less).
  final double dispersion;

  /// Radius of an optional soft frost over the whole surface. `0` keeps the
  /// centre perfectly clear.
  final double frost;

  /// Colour saturation applied to what is seen through the glass
  /// (1 = unchanged).
  final double saturation;

  /// Base opacity of the theme-surface tint in light mode.
  final double lightTintOpacity;

  /// Base opacity of the theme-surface tint in dark mode.
  final double darkTintOpacity;

  /// Extra tint added where content behind would fight foreground legibility
  /// (bright content under dark glass, dark content under light glass).
  final double adaptiveTint;

  /// Multiplier for specular light on the bevel and rim. `0` disables it.
  final double highlight;

  /// Multiplier for the drop shadow. `0` makes the surface sit flat.
  final double elevation;

  /// Stroke width of the crisp specular rim line.
  final double rimWidth;

  /// Where refraction shaders are unavailable (web, non-Impeller renderers),
  /// glass falls back to a Gaussian blur of this sigma plus a thicker tint.
  final double fallbackBlurSigma;

  /// Default: optically clear centre with lensing edges. Mini-player, tab
  /// bar, toolbars.
  static const GlassStyle regular = GlassStyle();

  /// Even more transparent, for controls floating over artwork.
  static const GlassStyle clear = GlassStyle(
    refraction: 12,
    lightTintOpacity: 0.03,
    darkTintOpacity: 0.03,
    adaptiveTint: 0.2,
    elevation: 0.6,
  );

  /// Softly frosted, for larger surfaces carrying dense text.
  static const GlassStyle frosted = GlassStyle(
    frost: 4,
    lightTintOpacity: 0.40,
    darkTintOpacity: 0.32,
    adaptiveTint: 0.3,
  );

  GlassStyle copyWith({
    double? refraction,
    double? bevel,
    double? dispersion,
    double? frost,
    double? saturation,
    double? lightTintOpacity,
    double? darkTintOpacity,
    double? adaptiveTint,
    double? highlight,
    double? elevation,
    double? rimWidth,
    double? fallbackBlurSigma,
  }) {
    return GlassStyle(
      refraction: refraction ?? this.refraction,
      bevel: bevel ?? this.bevel,
      dispersion: dispersion ?? this.dispersion,
      frost: frost ?? this.frost,
      saturation: saturation ?? this.saturation,
      lightTintOpacity: lightTintOpacity ?? this.lightTintOpacity,
      darkTintOpacity: darkTintOpacity ?? this.darkTintOpacity,
      adaptiveTint: adaptiveTint ?? this.adaptiveTint,
      highlight: highlight ?? this.highlight,
      elevation: elevation ?? this.elevation,
      rimWidth: rimWidth ?? this.rimWidth,
      fallbackBlurSigma: fallbackBlurSigma ?? this.fallbackBlurSigma,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is GlassStyle &&
      other.refraction == refraction &&
      other.bevel == bevel &&
      other.dispersion == dispersion &&
      other.frost == frost &&
      other.saturation == saturation &&
      other.lightTintOpacity == lightTintOpacity &&
      other.darkTintOpacity == darkTintOpacity &&
      other.adaptiveTint == adaptiveTint &&
      other.highlight == highlight &&
      other.elevation == elevation &&
      other.rimWidth == rimWidth &&
      other.fallbackBlurSigma == fallbackBlurSigma;

  @override
  int get hashCode => Object.hash(
      refraction,
      bevel,
      dispersion,
      frost,
      saturation,
      lightTintOpacity,
      darkTintOpacity,
      adaptiveTint,
      highlight,
      elevation,
      rimWidth,
      fallbackBlurSigma);
}

/// An iOS 26 "Liquid Glass" surface.
///
/// On Impeller (iOS, modern Android) the backdrop goes through a refraction
/// shader: the centre is optically clear while a curved bevel along the edge
/// pulls in and squeezes the content around the glass, with slight chromatic
/// dispersion, specular light and an adaptive tint for legibility. Elsewhere
/// (web, Skia) it falls back to blur + tint with the same shape and lighting.
///
/// Layers, bottom to top:
///  1. Continuous-corner clip ([ClipRSuperellipse], SwiftUI's `.continuous`).
///  2. Refraction shader, or blur fallback, over the backdrop. Uses the
///     nearest [BackdropGroup], so several glass surfaces share one backdrop.
///  3. [child].
///  4. Crisp specular rim line.
///  5. Depth shadow, painted only *outside* the shape and after the glass, so
///     the glass never refracts or tints its own shadow.
///
/// When [onTap] or [onLongPress] is set the surface responds to touch like
/// interactive iOS glass: it swells slightly and its highlights brighten.
///
/// Note: the glass only shows something if content is actually painted
/// *behind* it (e.g. it floats in a [Stack] over a scroll view).
class GlassContainer extends StatefulWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.style = GlassStyle.regular,
    this.padding,
    this.width,
    this.height,
    this.onTap,
    this.onLongPress,
    this.pressScale = 1.015,
  }) : _capsule = false;

  /// A pill whose corner radius is always half its shortest side.
  const GlassContainer.capsule({
    super.key,
    required this.child,
    this.style = GlassStyle.regular,
    this.padding,
    this.width,
    this.height,
    this.onTap,
    this.onLongPress,
    this.pressScale = 1.015,
  })  : borderRadius = BorderRadius.zero,
        _capsule = true;

  final Widget child;

  /// Corner radii. Ignored by [GlassContainer.capsule]. The refraction field
  /// uses the top-left radius for all corners.
  final BorderRadius borderRadius;
  final GlassStyle style;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Scale applied while pressed (only when [onTap]/[onLongPress] is set).
  final double pressScale;

  final bool _capsule;

  /// Forces the blur fallback even where the refraction shader is available.
  /// For comparisons and tests.
  static bool debugForceBlurFallback = false;

  @override
  State<GlassContainer> createState() => _GlassContainerState();
}

/// Loads the refraction shader once per process.
abstract final class _LiquidGlassProgram {
  static const String asset = 'shaders/liquid_glass.frag';

  static ui.FragmentProgram? program;
  static Future<void>? _loading;

  static bool get supported => ui.ImageFilter.isShaderFilterSupported;

  static Future<void> load() {
    return _loading ??= ui.FragmentProgram.fromAsset(asset).then(
      (p) => program = p,
      onError: (Object error) {
        debugPrint('GlassContainer: refraction shader unavailable, '
            'using blur fallback ($error)');
      },
    );
  }
}

class _GlassContainerState extends State<GlassContainer> {
  bool _pressed = false;

  bool get _interactive =>
      widget.onTap != null || widget.onLongPress != null;

  @override
  void initState() {
    super.initState();
    if (_LiquidGlassProgram.supported && _LiquidGlassProgram.program == null) {
      _LiquidGlassProgram.load().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  void didUpdateWidget(GlassContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_interactive) _pressed = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final highContrast = MediaQuery.highContrastOf(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final style = widget.style;

    final ui.FragmentProgram? program = _LiquidGlassProgram.supported &&
            !GlassContainer.debugForceBlurFallback
        ? _LiquidGlassProgram.program
        : null;

    // Tint follows the active theme surface (incl. dynamic colour). Dark glass
    // gets a small white lift so it still reads as a surface over pure black.
    final tintColor = Color.alphaBlend(
      Colors.white.withValues(alpha: isDark ? 0.10 : 0.0),
      theme.colorScheme.surface,
    ).withValues(alpha: 1.0);
    final baseTint = isDark ? style.darkTintOpacity : style.lightTintOpacity;
    final adaptive = style.adaptiveTint;

    final shadows = style.elevation <= 0
        ? const <BoxShadow>[]
        : <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(
                  alpha: (isDark ? 0.40 : 0.14) * style.elevation),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withValues(
                  alpha: (isDark ? 0.30 : 0.08) * style.elevation),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ];

    // A hairline just outside the edge keeps light glass defined against
    // light content, and dark glass defined against bright artwork.
    final outline = Colors.black.withValues(
        alpha: highContrast ? 0.35 : (isDark ? 0.22 : 0.07));

    final shape = _GlassShape(
      borderRadius: widget.borderRadius,
      capsule: widget._capsule,
    );

    Widget content = widget.child;
    if (widget.padding != null) {
      content = Padding(padding: widget.padding!, child: content);
    }

    final BackdropKey? backdropKey = BackdropGroup.of(context)?.backdropKey;

    Widget glass = TweenAnimationBuilder<double>(
      tween: Tween<double>(end: _pressed ? 1.0 : 0.0),
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: content,
      builder: (context, press, child) {
        final highlight =
            style.highlight * (highContrast ? 1.3 : 1.0) * (1 + 0.8 * press);

        final Widget filtered;
        if (program != null) {
          // Refraction path: the shader handles tint and bevel light.
          filtered = _LiquidGlassFilter(
            program: program,
            backdropKey: backdropKey,
            optics: _GlassOptics(
              shape: shape,
              refraction: style.refraction,
              bevel: style.bevel,
              dispersion: style.dispersion,
              frost: style.frost,
              saturation: style.saturation,
              highlight: highlight,
              tint: tintColor,
              tintOpacity: highContrast
                  ? math.max(baseTint, 0.7)
                  : baseTint + 0.06 * press,
              adaptiveTint: adaptive,
            ),
            child: CustomPaint(
              foregroundPainter: _GlassRimPainter(
                shape: shape,
                width: style.rimWidth,
                highlight: highlight,
                isDark: isDark,
              ),
              child: child,
            ),
          );
        } else {
          // Blur fallback: no lensing, so lean on blur + a thicker tint.
          final fallbackOpacity = highContrast
              ? 0.86
              : math.min(baseTint + 0.25 + adaptive * 0.3, 0.9);
          final surface = CustomPaint(
            painter: _GlassSurfacePainter(
              tint: Color.alphaBlend(
                Colors.white.withValues(alpha: (isDark ? 0.06 : 0.10) * press),
                tintColor.withValues(alpha: fallbackOpacity),
              ),
              highlight: highlight,
              isDark: isDark,
            ),
            foregroundPainter: _GlassRimPainter(
              shape: shape,
              width: style.rimWidth,
              highlight: highlight,
              isDark: isDark,
            ),
            child: child,
          );
          filtered = style.fallbackBlurSigma > 0
              ? BackdropFilter.grouped(
                  filter: _blurFilter(
                      style.fallbackBlurSigma, style.saturation + 0.4),
                  child: surface,
                )
              : surface;
        }

        final Widget body = CustomPaint(
          foregroundPainter: _GlassShadowPainter(
            shape: shape,
            shadows: shadows,
            outline: outline,
          ),
          child: ClipRSuperellipse(
            clipper: _GlassClipper(shape),
            child: filtered,
          ),
        );

        if (press == 0 || widget.pressScale == 1.0) return body;
        return Transform.scale(
          scale: 1 + (widget.pressScale - 1) * press,
          child: body,
        );
      },
    );

    if (widget.width != null || widget.height != null) {
      glass = SizedBox(width: widget.width, height: widget.height, child: glass);
    }

    if (!_interactive) return glass;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: glass,
    );
  }
}

ui.ImageFilter _blurFilter(double sigma, double saturation) {
  final blur = ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);
  if (saturation == 1.0) return blur;
  return ui.ImageFilter.compose(
    outer: ColorFilter.matrix(_saturationMatrix(saturation)),
    inner: blur,
  );
}

/// Standard luminance-preserving saturation matrix (Rec. 709 weights).
List<double> _saturationMatrix(double s) {
  const lr = 0.2126, lg = 0.7152, lb = 0.0722;
  final sr = (1 - s) * lr, sg = (1 - s) * lg, sb = (1 - s) * lb;
  return <double>[
    sr + s, sg, sb, 0, 0, //
    sr, sg + s, sb, 0, 0, //
    sr, sg, sb + s, 0, 0, //
    0, 0, 0, 1, 0, //
  ];
}

// ---------------------------------------------------------------------------
// Refraction shader plumbing
// ---------------------------------------------------------------------------

/// Everything the refraction shader needs, in logical pixels.
@immutable
class _GlassOptics {
  const _GlassOptics({
    required this.shape,
    required this.refraction,
    required this.bevel,
    required this.dispersion,
    required this.frost,
    required this.saturation,
    required this.highlight,
    required this.tint,
    required this.tintOpacity,
    required this.adaptiveTint,
  });

  final _GlassShape shape;
  final double refraction;
  final double bevel;
  final double dispersion;
  final double frost;
  final double saturation;
  final double highlight;
  final Color tint;
  final double tintOpacity;
  final double adaptiveTint;

  @override
  bool operator ==(Object other) =>
      other is _GlassOptics &&
      other.shape == shape &&
      other.refraction == refraction &&
      other.bevel == bevel &&
      other.dispersion == dispersion &&
      other.frost == frost &&
      other.saturation == saturation &&
      other.highlight == highlight &&
      other.tint == tint &&
      other.tintOpacity == tintOpacity &&
      other.adaptiveTint == adaptiveTint;

  @override
  int get hashCode => Object.hash(shape, refraction, bevel, dispersion, frost,
      saturation, highlight, tint, tintOpacity, adaptiveTint);
}

/// Applies the refraction shader to the backdrop behind [child].
class _LiquidGlassFilter extends SingleChildRenderObjectWidget {
  const _LiquidGlassFilter({
    required this.program,
    required this.optics,
    this.backdropKey,
    super.child,
  });

  final ui.FragmentProgram program;
  final _GlassOptics optics;
  final BackdropKey? backdropKey;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderLiquidGlass(program.fragmentShader(), optics, backdropKey);

  @override
  void updateRenderObject(
      BuildContext context, _RenderLiquidGlass renderObject) {
    renderObject
      ..optics = optics
      ..backdropKey = backdropKey;
  }
}

class _RenderLiquidGlass extends RenderProxyBox {
  _RenderLiquidGlass(this._shader, this._optics, this._backdropKey);

  final ui.FragmentShader _shader;

  _GlassOptics get optics => _optics;
  _GlassOptics _optics;
  set optics(_GlassOptics value) {
    if (value == _optics) return;
    _optics = value;
    markNeedsPaint();
  }

  BackdropKey? get backdropKey => _backdropKey;
  BackdropKey? _backdropKey;
  set backdropKey(BackdropKey? value) {
    if (value == _backdropKey) return;
    _backdropKey = value;
    markNeedsPaint();
  }

  @override
  bool get alwaysNeedsCompositing => child != null;

  @override
  _LiquidGlassLayer? get layer => super.layer as _LiquidGlassLayer?;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) {
      layer = null;
      return;
    }
    layer ??= _LiquidGlassLayer(_shader);
    layer!
      ..localRect = offset & size
      ..optics = _optics
      ..configure(backdropKey: _backdropKey);
    context.pushLayer(layer!, super.paint, offset);
  }

  @override
  void dispose() {
    super.dispose();
    _shader.dispose();
  }
}

/// A backdrop-filter layer that positions the refraction shader at
/// compositing time.
///
/// The shader works in screen (render-target) pixels, so it needs to know
/// where the glass actually is on screen. That changes whenever an ancestor
/// layer moves (scrolling, slide transitions, press scaling) — often without
/// this render object repainting. So, like [FollowerLayer], this layer opts
/// out of retained rendering and recomputes its on-screen bounds from the
/// ancestor layer transforms every time the scene is built.
class _LiquidGlassLayer extends BackdropFilterLayer {
  _LiquidGlassLayer(this._shader);

  final ui.FragmentShader _shader;

  /// Glass bounds in this layer's parent coordinate space.
  Rect localRect = Rect.zero;
  _GlassOptics? optics;

  ui.ImageFilter? _resolved;
  bool _configuring = false;

  /// Applies inherited settings whose setters mark the layer dirty, which a
  /// layer that always re-adds itself may otherwise not do.
  void configure({BackdropKey? backdropKey}) {
    _configuring = true;
    try {
      this.backdropKey = backdropKey;
    } finally {
      _configuring = false;
    }
  }

  @override
  bool get alwaysNeedsAddToScene => !_configuring;

  @override
  ui.ImageFilter? get filter => _resolved;

  @override
  void addToScene(ui.SceneBuilder builder) {
    _resolved = _resolveFilter();
    super.addToScene(builder);
  }

  ui.ImageFilter _resolveFilter() {
    final o = optics!;
    final m = _screenTransform();
    final screenRect = MatrixUtils.transformRect(m, localRect);
    // Logical px -> screen px (device pixel ratio and any ancestor scale).
    final s = math.sqrt(m.storage[0] * m.storage[0] + m.storage[1] * m.storage[1]);

    final size = localRect.size;
    final half = size.shortestSide / 2;
    final radius = math.min(o.shape.radiusFor(size).topLeft.x, half);
    final bevel = math.min(o.bevel, half * 0.9);
    final normalRadius = math.min(math.max(radius, bevel), half);

    _shader
      // 0, 1: u_size, set by the engine.
      ..setFloat(2, screenRect.left)
      ..setFloat(3, screenRect.top)
      ..setFloat(4, screenRect.width)
      ..setFloat(5, screenRect.height)
      ..setFloat(6, radius * s)
      ..setFloat(7, bevel * s)
      ..setFloat(8, o.refraction * s)
      ..setFloat(9, normalRadius * s)
      ..setFloat(10, o.dispersion)
      ..setFloat(11, o.frost * s)
      ..setFloat(12, o.saturation)
      ..setFloat(13, o.highlight)
      ..setFloat(14, o.tint.r)
      ..setFloat(15, o.tint.g)
      ..setFloat(16, o.tint.b)
      ..setFloat(17, o.tintOpacity)
      ..setFloat(18, o.adaptiveTint);
    return ui.ImageFilter.shader(_shader);
  }

  /// Transform from this layer's coordinates to the root (screen pixels).
  Matrix4 _screenTransform() {
    final ancestors = <ContainerLayer>[];
    for (ContainerLayer? p = parent; p != null; p = p.parent) {
      ancestors.add(p);
    }
    final m = Matrix4.identity();
    for (var i = ancestors.length - 1; i >= 0; i--) {
      ancestors[i].applyTransform(i == 0 ? this : ancestors[i - 1], m);
    }
    return m;
  }
}

// ---------------------------------------------------------------------------
// Shape + painters
// ---------------------------------------------------------------------------

/// Resolves the continuous-corner geometry for a given size, so a capsule can
/// always use exactly half its shortest side as its radius.
@immutable
class _GlassShape {
  const _GlassShape({required this.borderRadius, required this.capsule});

  final BorderRadius borderRadius;
  final bool capsule;

  BorderRadius radiusFor(Size size, {double inset = 0}) {
    if (capsule) {
      final r = math.max(0.0, size.shortestSide / 2 - inset);
      return BorderRadius.all(Radius.circular(r));
    }
    if (inset == 0) return borderRadius;
    Radius shrink(Radius r) => Radius.elliptical(
        math.max(0.0, r.x - inset), math.max(0.0, r.y - inset));
    return BorderRadius.only(
      topLeft: shrink(borderRadius.topLeft),
      topRight: shrink(borderRadius.topRight),
      bottomLeft: shrink(borderRadius.bottomLeft),
      bottomRight: shrink(borderRadius.bottomRight),
    );
  }

  ui.RSuperellipse rsuperellipse(Rect rect, Size size, {double inset = 0}) =>
      radiusFor(size, inset: inset).toRSuperellipse(rect);

  Path path(Rect rect, Size size, {double inset = 0}) =>
      Path()..addRSuperellipse(rsuperellipse(rect, size, inset: inset));

  @override
  bool operator ==(Object other) =>
      other is _GlassShape &&
      other.capsule == capsule &&
      other.borderRadius == borderRadius;

  @override
  int get hashCode => Object.hash(borderRadius, capsule);
}

class _GlassClipper extends CustomClipper<ui.RSuperellipse> {
  const _GlassClipper(this.shape);

  final _GlassShape shape;

  @override
  ui.RSuperellipse getClip(Size size) =>
      shape.rsuperellipse(Offset.zero & size, size);

  @override
  bool shouldReclip(_GlassClipper oldClipper) => oldClipper.shape != shape;
}

/// Paints drop shadows + an outer hairline strictly outside the glass shape.
class _GlassShadowPainter extends CustomPainter {
  const _GlassShadowPainter({
    required this.shape,
    required this.shadows,
    required this.outline,
  });

  final _GlassShape shape;
  final List<BoxShadow> shadows;
  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    if (shadows.isEmpty && outline.a == 0) return;
    final rect = Offset.zero & size;

    var reach = 2.0;
    for (final s in shadows) {
      reach = math.max(
          reach, s.blurRadius * 2 + s.spreadRadius.abs() + s.offset.distance);
    }

    canvas.save();
    // Even-odd: big rect minus the shape = "everything outside the glass".
    canvas.clipPath(Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rect.inflate(reach))
      ..addPath(shape.path(rect, size), Offset.zero));

    for (final s in shadows) {
      final shadowRect = rect.shift(s.offset).inflate(s.spreadRadius);
      canvas.drawPath(shape.path(shadowRect, size), s.toPaint());
    }

    if (outline.a > 0) {
      // Centred on the edge; the clip keeps only the outer half.
      canvas.drawPath(
        shape.path(rect, size),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = outline,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GlassShadowPainter old) =>
      old.shape != shape ||
      old.outline != outline ||
      !listEquals(old.shadows, shadows);
}

/// Blur fallback only: fills the (already clipped) interior with the tint and
/// a specular sheen standing in for the shader's bevel light.
class _GlassSurfacePainter extends CustomPainter {
  const _GlassSurfacePainter({
    required this.tint,
    required this.highlight,
    required this.isDark,
  });

  final Color tint;
  final double highlight;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = tint);

    if (highlight <= 0) return;
    // Light from above: bright cap at the top, a faint caustic bounce at the
    // bottom edge, clear through the middle so content stays legible.
    final top = ((isDark ? 0.10 : 0.30) * highlight).clamp(0.0, 1.0);
    final bottom = ((isDark ? 0.035 : 0.14) * highlight).clamp(0.0, 1.0);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: top),
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: bottom),
          ],
          stops: const [0.0, 0.48, 0.78, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_GlassSurfacePainter old) =>
      old.tint != tint || old.highlight != highlight || old.isDark != isDark;
}

/// Thin specular rim: bright on the top-leading and bottom-trailing edges,
/// fading toward the other two corners, like light caught by a glass lens.
class _GlassRimPainter extends CustomPainter {
  const _GlassRimPainter({
    required this.shape,
    required this.width,
    required this.highlight,
    required this.isDark,
  });

  final _GlassShape shape;
  final double width;
  final double highlight;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (highlight <= 0 || width <= 0) return;
    final bounds = Offset.zero & size;
    final rect = bounds.deflate(width / 2);
    final peak = ((isDark ? 0.55 : 0.95) * highlight).clamp(0.0, 1.0);
    Color w(double f) => Colors.white.withValues(alpha: peak * f);

    // Angles: 0 = right, clockwise. The gradient is stretched to the rect so
    // "top-left" means the actual corner even on a wide capsule.
    final gradient = SweepGradient(
      colors: [
        w(0.30), // right
        w(0.80), // bottom-right
        w(0.28), // bottom
        w(0.06), // bottom-left
        w(0.30), // left
        w(1.00), // top-left
        w(0.50), // top
        w(0.08), // top-right
        w(0.30), // right (wrap)
      ],
      stops: const [0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875, 1],
      transform: const _StretchToBounds(),
    );

    canvas.drawPath(
      shape.path(rect, size, inset: width / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..shader = gradient.createShader(bounds),
    );
  }

  @override
  bool shouldRepaint(_GlassRimPainter old) =>
      old.shape != shape ||
      old.width != width ||
      old.highlight != highlight ||
      old.isDark != isDark;
}

/// Stretches a gradient horizontally so its angular stops map onto the
/// corners of non-square bounds.
class _StretchToBounds extends GradientTransform {
  const _StretchToBounds();

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    if (bounds.height <= 0 || bounds.width <= 0) return null;
    final sx = bounds.width / bounds.height;
    // Scale x by sx around the centre (column-major storage).
    return Matrix4(
      sx, 0, 0, 0, //
      0, 1, 0, 0, //
      0, 0, 1, 0, //
      bounds.center.dx * (1 - sx), 0, 0, 1, //
    );
  }
}
