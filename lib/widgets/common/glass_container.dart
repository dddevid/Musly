import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Tunable look of a [GlassContainer].
///
/// Colours are intentionally not stored here: the tint is resolved from the
/// ambient [Theme] at build time, so glass always sits *on top of* the current
/// light/dark/accent/dynamic theme instead of replacing it.
@immutable
class GlassStyle {
  const GlassStyle({
    this.blurSigma = 20,
    this.saturation = 1.7,
    this.lightTintOpacity = 0.60,
    this.darkTintOpacity = 0.46,
    this.highlight = 1.0,
    this.elevation = 1.0,
    this.rimWidth = 1.0,
  });

  /// Gaussian blur applied to whatever is painted behind the surface.
  /// `0` skips the [BackdropFilter] entirely (cheap, tint-only glass).
  final double blurSigma;

  /// Saturation boost applied to the blurred backdrop (1 = unchanged). Gives
  /// the vivid look of iOS materials instead of a washed-out frost.
  final double saturation;

  /// Opacity of the theme-surface tint laid over the blur in light mode.
  final double lightTintOpacity;

  /// Opacity of the theme-surface tint laid over the blur in dark mode.
  final double darkTintOpacity;

  /// Multiplier for the specular sheen and rim light. `0` disables them.
  final double highlight;

  /// Multiplier for the drop shadow. `0` makes the surface sit flat.
  final double elevation;

  /// Stroke width of the specular rim, in logical pixels.
  final double rimWidth;

  /// Default for floating chrome: mini-player, tab bar, toolbars.
  static const GlassStyle regular = GlassStyle();

  /// Thinner, more see-through variant for controls that float over artwork.
  static const GlassStyle clear = GlassStyle(
    blurSigma: 12,
    saturation: 1.4,
    lightTintOpacity: 0.28,
    darkTintOpacity: 0.22,
    elevation: 0.6,
  );

  GlassStyle copyWith({
    double? blurSigma,
    double? saturation,
    double? lightTintOpacity,
    double? darkTintOpacity,
    double? highlight,
    double? elevation,
    double? rimWidth,
  }) {
    return GlassStyle(
      blurSigma: blurSigma ?? this.blurSigma,
      saturation: saturation ?? this.saturation,
      lightTintOpacity: lightTintOpacity ?? this.lightTintOpacity,
      darkTintOpacity: darkTintOpacity ?? this.darkTintOpacity,
      highlight: highlight ?? this.highlight,
      elevation: elevation ?? this.elevation,
      rimWidth: rimWidth ?? this.rimWidth,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is GlassStyle &&
      other.blurSigma == blurSigma &&
      other.saturation == saturation &&
      other.lightTintOpacity == lightTintOpacity &&
      other.darkTintOpacity == darkTintOpacity &&
      other.highlight == highlight &&
      other.elevation == elevation &&
      other.rimWidth == rimWidth;

  @override
  int get hashCode => Object.hash(blurSigma, saturation, lightTintOpacity,
      darkTintOpacity, highlight, elevation, rimWidth);
}

/// An iOS 26 "Liquid Glass" surface.
///
/// Layers, bottom to top:
///  1. Depth shadow, painted only *outside* the shape so it never muddies the
///     translucent interior.
///  2. Continuous-corner clip ([ClipRSuperellipse], the equivalent of SwiftUI's
///     `.continuous` rounded rectangle).
///  3. Backdrop blur + saturation boost ([BackdropFilter.grouped], so several
///     glass surfaces under one [BackdropGroup] share a single backdrop read).
///  4. Theme-derived tint + vertical specular sheen.
///  5. [child].
///  6. Specular rim light (bright top-leading / bottom-trailing edges).
///
/// When [onTap] or [onLongPress] is set the surface responds to touch like
/// interactive iOS glass: it swells slightly and its highlights brighten.
///
/// Note: blur only shows something if content is actually painted *behind*
/// this widget (e.g. it sits in a [Stack] over a scroll view).
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

  /// Corner radii. Ignored by [GlassContainer.capsule].
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

  @override
  State<GlassContainer> createState() => _GlassContainerState();
}

class _GlassContainerState extends State<GlassContainer> {
  bool _pressed = false;

  bool get _interactive =>
      widget.onTap != null || widget.onLongPress != null;

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

    // Tint follows the active theme surface (incl. dynamic colour). Dark glass
    // gets a small white lift so it still reads as a surface over pure black.
    final baseTintOpacity =
        isDark ? style.darkTintOpacity : style.lightTintOpacity;
    final tintOpacity = highContrast
        ? math.max(baseTintOpacity, 0.86)
        : baseTintOpacity;
    final tint = Color.alphaBlend(
      Colors.white.withValues(alpha: isDark ? 0.07 : 0.0),
      theme.colorScheme.surface.withValues(alpha: tintOpacity),
    );

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

    Widget glass = TweenAnimationBuilder<double>(
      tween: Tween<double>(end: _pressed ? 1.0 : 0.0),
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: content,
      builder: (context, press, child) {
        final highlight =
            style.highlight * (highContrast ? 1.3 : 1.0) * (1 + 0.8 * press);
        final surface = CustomPaint(
          painter: _GlassSurfacePainter(
            tint: Color.alphaBlend(
              Colors.white.withValues(alpha: (isDark ? 0.06 : 0.10) * press),
              tint,
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

        final Widget blurred = style.blurSigma > 0
            ? BackdropFilter.grouped(
                filter: _backdropFilter(style.blurSigma, style.saturation),
                child: surface,
              )
            : surface;

        final Widget body = CustomPaint(
          painter: _GlassShadowPainter(
            shape: shape,
            shadows: shadows,
            outline: outline,
          ),
          child: ClipRSuperellipse(
            clipper: _GlassClipper(shape),
            child: blurred,
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

ui.ImageFilter _backdropFilter(double sigma, double saturation) {
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
      !_listEquals(old.shadows, shadows);
}

/// Fills the (already clipped) interior with the tint and a specular sheen.
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

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
