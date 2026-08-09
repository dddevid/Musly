import 'package:flutter/material.dart';

class PaletteService {
  static final Map<String, List<Color>> _colorCache = {};

  /// Extracts dominant colors from an ImageProvider using Material 3 Monet.
  /// Caches the result based on [imageId] to avoid recomputing for the same song.
  static Future<List<Color>> extractColors(
      ImageProvider imageProvider, String imageId) async {
    if (_colorCache.containsKey(imageId)) {
      return _colorCache[imageId]!;
    }

    try {
      final scheme = await ColorScheme.fromImageProvider(
        provider: imageProvider,
        brightness: Brightness.dark,
      );

      final List<Color> colors = [
        scheme.primary,
        scheme.tertiary,
        scheme.secondary,
        scheme.primaryContainer,
      ];

      _colorCache[imageId] = colors;
      return colors;
    } catch (e) {
      // Fallback colors on error
      return [
        const Color(0xFF202020),
        const Color(0xFF404040),
        const Color(0xFF606060),
      ];
    }
  }
}
