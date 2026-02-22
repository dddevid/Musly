import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../services/subsonic_service.dart';
import '../services/player_ui_settings_service.dart';
import '../theme/app_theme.dart';

/// Returns true if [s] looks like an absolute file system path rather than a
/// Subsonic cover-art ID or network URL.
bool isLocalFilePath(String? s) {
  if (s == null || s.isEmpty) return false;
  if (s.startsWith('/')) return true; // Unix / Android / macOS
  if (s.length > 2 && s[1] == ':') return true; // Windows  C:\…
  return false;
}

class _ImageUrlCache {
  static final Map<String, String> _cache = {};

  static String getUrl(SubsonicService service, String? coverArt, int size) {
    if (coverArt == null || coverArt.isEmpty) return '';
    final key = '${coverArt}_$size';
    return _cache.putIfAbsent(
      key,
      () => service.getCoverArtUrl(coverArt, size: size),
    );
  }
}

class AlbumArtwork extends StatelessWidget {
  final String? coverArt;
  final double size;

  /// Explicit corner radius. When null (the default) the value from
  /// [PlayerUiSettingsService.albumArtCornerRadiusNotifier] is used so that
  /// all artwork respects the user's global preference.
  final double? borderRadius;
  final BoxShadow? shadow;

  /// When true the image is shown at its natural aspect ratio (no cropping).
  /// The [size] parameter is then used as the maximum width.
  final bool preserveAspectRatio;

  const AlbumArtwork({
    super.key,
    this.coverArt,
    this.size = 150,
    this.borderRadius,
    this.shadow,
    this.preserveAspectRatio = false,
  });

  @override
  Widget build(BuildContext context) {
    final svc = PlayerUiSettingsService();
    return ValueListenableBuilder<String>(
      valueListenable: svc.artworkShapeNotifier,
      builder: (context, shape, _) {
        return ValueListenableBuilder<double>(
          valueListenable: svc.albumArtCornerRadiusNotifier,
          builder: (context, globalRadius, _) {
            return ValueListenableBuilder<String>(
              valueListenable: svc.artworkShadowNotifier,
              builder: (context, shadowLevel, _) {
                return ValueListenableBuilder<String>(
                  valueListenable: svc.artworkShadowColorNotifier,
                  builder: (context, shadowColor, _) {
                    final resolvedRadius =
                        borderRadius ??
                        (shape == 'circle'
                            ? 9999.0
                            : shape == 'square'
                            ? 0.0
                            : globalRadius);
                    return _buildContent(
                      context,
                      resolvedRadius,
                      shadowLevel,
                      shadowColor,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  /// Compute the shadow based on user settings. If [shadow] is provided
  /// explicitly it overrides the global preference.
  BoxShadow? _resolvedShadow(
    double resolvedRadius,
    String shadowLevel,
    String shadowColor,
    bool isDark,
  ) {
    if (shadow != null) return shadow;
    if (shadowLevel == 'none') return null;
    final Color color;
    switch (shadowColor) {
      case 'accent':
        color = AppTheme.appleMusicRed;
        break;
      default:
        color = Colors.black;
    }
    double opacity;
    double blur;
    Offset offset;
    switch (shadowLevel) {
      case 'medium':
        opacity = isDark ? 0.35 : 0.25;
        blur = size / 6;
        offset = Offset(0, size / 20);
        break;
      case 'strong':
        opacity = isDark ? 0.55 : 0.40;
        blur = size / 4;
        offset = Offset(0, size / 12);
        break;
      default: // 'soft'
        opacity = isDark ? 0.22 : 0.14;
        blur = size / 10;
        offset = Offset(0, size / 30);
    }
    return BoxShadow(
      color: color.withValues(alpha: opacity),
      blurRadius: blur,
      offset: offset,
    );
  }

  Widget _buildContent(
    BuildContext context,
    double resolvedRadius,
    String shadowLevel,
    String shadowColor,
  ) {
    final validSize = size.isFinite && !size.isNaN ? size : 150.0;

    // Optimized cache size calculation:
    // Reduced multiplier from 2 to 1.5 to save memory on low-end devices.
    // Reduced max cache size from 600 to 400.
    final cacheSize = (validSize * 1.5).toInt().clamp(100, 400);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedShadow = _resolvedShadow(
      resolvedRadius,
      shadowLevel,
      shadowColor,
      isDark,
    );

    if (preserveAspectRatio) {
      // Show image at its natural aspect ratio, constrained to [size] width.
      return Container(
        constraints: BoxConstraints(maxWidth: validSize),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(resolvedRadius),
          boxShadow: resolvedShadow != null ? [resolvedShadow] : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(resolvedRadius),
          child: _buildImageNatural(isDark, cacheSize),
        ),
      );
    }

    // Removed RepaintBoundary which creates a new layer for every image.
    // This significantly reduces GPU memory usage in long lists (e.g. SongTile).
    return Container(
      width: validSize,
      height: validSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(resolvedRadius),
        // Only show shadow if explicitly provided or if the image is large enough.
        // Rendering shadows for every small list item is expensive.
        boxShadow: resolvedShadow != null && validSize > 60
            ? [resolvedShadow]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(resolvedRadius),
        child: _buildImage(isDark, cacheSize),
      ),
    );
  }

  Widget _buildImageNatural(bool isDark, int cacheSize) {
    if (coverArt == null || coverArt!.isEmpty) return _buildPlaceholder(isDark);

    if (isLocalFilePath(coverArt)) {
      final artFile = File(coverArt!);
      return Image.file(
        artFile,
        key: ValueKey(coverArt),
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildPlaceholder(isDark),
      );
    }

    return Builder(
      builder: (context) {
        final imageUrl = _ImageUrlCache.getUrl(
          Provider.of<SubsonicService>(context, listen: false),
          coverArt,
          cacheSize,
        );
        if (imageUrl.isEmpty) return _buildPlaceholder(isDark);
        return CachedNetworkImage(
          imageUrl: imageUrl,
          cacheKey: '${coverArt}_natural_$cacheSize',
          key: ValueKey('${coverArt}_natural_$cacheSize'),
          fit: BoxFit.contain,
          fadeInDuration: const Duration(milliseconds: 100),
          fadeOutDuration: Duration.zero,
          useOldImageOnUrlChange: true,
          placeholder: (_, __) => _buildPlaceholder(isDark),
          errorWidget: (_, __, ___) => _buildPlaceholder(isDark),
        );
      },
    );
  }

  Widget _buildImage(bool isDark, int cacheSize) {
    if (coverArt == null || coverArt!.isEmpty) return _buildPlaceholder(isDark);

    // Local file (absolute path saved by LocalMusicService)
    if (isLocalFilePath(coverArt)) {
      final artFile = File(coverArt!);
      return Image.file(
        artFile,
        key: ValueKey(coverArt),
        fit: BoxFit.cover,
        cacheWidth: cacheSize,
        cacheHeight: cacheSize,
        errorBuilder: (_, __, ___) => _buildPlaceholder(isDark),
      );
    }

    // Network image via Subsonic cover-art ID
    // NOTE: _ImageUrlCache requires a BuildContext so this is called lazily.
    // We build an empty-URL guard here to avoid boilerplate at every call site.
    return Builder(
      builder: (context) {
        final imageUrl = _ImageUrlCache.getUrl(
          Provider.of<SubsonicService>(context, listen: false),
          coverArt,
          cacheSize,
        );
        if (imageUrl.isEmpty) return _buildPlaceholder(isDark);
        return CachedNetworkImage(
          imageUrl: imageUrl,
          cacheKey: '${coverArt}_$cacheSize',
          key: ValueKey('${coverArt}_$cacheSize'),
          fit: BoxFit.cover,
          memCacheWidth: cacheSize,
          memCacheHeight: cacheSize,
          maxWidthDiskCache: cacheSize,
          maxHeightDiskCache: cacheSize,
          fadeInDuration: const Duration(milliseconds: 100),
          fadeOutDuration: Duration.zero,
          useOldImageOnUrlChange: true,
          placeholder: (_, __) => _buildPlaceholder(isDark),
          errorWidget: (_, __, ___) => _buildPlaceholder(isDark),
        );
      },
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2A2A2A), const Color(0xFF1A1A1A)]
              : [Colors.grey.shade300, Colors.grey.shade200],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          size: (size / 3).clamp(16.0, 60.0),
          color: isDark ? Colors.white24 : Colors.black12,
        ),
      ),
    );
  }
}
