import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

class PaletteService {
  static final Map<String, List<Color>> _colorCache = {};

  static Future<List<Color>> extractColors(
      ImageProvider imageProvider, String imageId) async {
    if (_colorCache.containsKey(imageId)) {
      return _colorCache[imageId]!;
    }

    try {
      final palette = await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: 32,
        timeout: const Duration(seconds: 2),
      );

      final dominant = palette.dominantColor?.color;
      final vibrant = palette.vibrantColor?.color;
      final darkVibrant = palette.darkVibrantColor?.color;
      final lightVibrant = palette.lightVibrantColor?.color;
      final muted = palette.mutedColor?.color;
      final darkMuted = palette.darkMutedColor?.color;

      final extracted = <Color>[];

      if (dominant != null) extracted.add(dominant);
      if (vibrant != null &&
          !extracted.any((c) => _colorDistance(c, vibrant) < 900)) {
        extracted.add(vibrant);
      }
      if (darkVibrant != null &&
          !extracted.any((c) => _colorDistance(c, darkVibrant) < 900)) {
        extracted.add(darkVibrant);
      }
      if (lightVibrant != null &&
          !extracted.any((c) => _colorDistance(c, lightVibrant) < 900)) {
        extracted.add(lightVibrant);
      }
      if (muted != null &&
          !extracted.any((c) => _colorDistance(c, muted) < 900)) {
        extracted.add(muted);
      }
      if (darkMuted != null &&
          !extracted.any((c) => _colorDistance(c, darkMuted) < 900)) {
        extracted.add(darkMuted);
      }

      for (final p in palette.paletteColors) {
        if (extracted.length >= 3) break;
        if (!extracted.any((c) => _colorDistance(c, p.color) < 700)) {
          extracted.add(p.color);
        }
      }

      if (extracted.isEmpty) {
        extracted.add(const Color(0xFF1E1E2C));
      }
      while (extracted.length < 3) {
        final last = extracted.last;
        final hsl = HSLColor.fromColor(last);
        final factor = extracted.length == 1 ? 0.75 : 0.5;
        extracted.add(hsl
            .withLightness((hsl.lightness * factor).clamp(0.12, 0.85))
            .toColor());
      }

      _colorCache[imageId] = extracted;
      return extracted;
    } catch (e) {
      return [
        const Color(0xFF1A1A24),
        const Color(0xFF2A2A3C),
        const Color(0xFF121218),
      ];
    }
  }

  static double _colorDistance(Color a, Color b) {
    final rDiff = (a.r * 255.0).round() - (b.r * 255.0).round();
    final gDiff = (a.g * 255.0).round() - (b.g * 255.0).round();
    final bDiff = (a.b * 255.0).round() - (b.b * 255.0).round();
    return (rDiff * rDiff + gDiff * gDiff + bDiff * bDiff).toDouble();
  }
}
