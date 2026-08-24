import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:musly/services/subsonic_service.dart';
import 'package:musly/services/player_ui_settings_service.dart';
import 'package:musly/services/offline_service.dart';

bool isLocalFilePath(String? s) {
  if (s == null || s.isEmpty) return false;
  final isPath = s.startsWith('/') || (s.length > 2 && s[1] == ':');
  if (!isPath) return false;
  final lower = s.toLowerCase();
  final isImageExt = lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.png') ||
      lower.endsWith('.webp') ||
      lower.endsWith('.bmp') ||
      lower.endsWith('.gif');
  if (!isImageExt) return false;
  try {
    final f = File(s);
    return f.existsSync() && f.lengthSync() > 0;
  } catch (_) {
    return false;
  }
}

class ImageUrlCache {
  static final Map<String, String> _cache = {};

  static void clear() {
    _cache.clear();
  }

  static String getUrl(SubsonicService service, String? coverArt, int size) {
    if (coverArt == null || coverArt.isEmpty) return '';
    if (coverArt.startsWith('http://') || coverArt.startsWith('https://')) {
      return coverArt;
    }
    final serverKey = service.config?.serverUrl ?? '';
    final key = '${serverKey}_${coverArt}_$size';
    return _cache.putIfAbsent(
      key,
      () => service.getCoverArtUrl(coverArt, size: size),
    );
  }
}

typedef _ImageUrlCache = ImageUrlCache;

class AlbumArtwork extends StatelessWidget {
  final String? coverArt;
  final double size;

  final double? borderRadius;
  final BoxShadow? shadow;

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
    final shape = svc.getArtworkShape();
    final globalRadius = svc.getAlbumArtCornerRadius();
    final shadowLevel = svc.getArtworkShadow();
    final shadowColor = svc.getArtworkShadowColor();

    final resolvedRadius = borderRadius ??
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
  }

  BoxShadow? _resolvedShadow(
    BuildContext context,
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
        color = Theme.of(context).colorScheme.primary;
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
      default:
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

    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheSize = (validSize * dpr).toInt().clamp(100, 600);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedShadow = _resolvedShadow(
      context,
      resolvedRadius,
      shadowLevel,
      shadowColor,
      isDark,
    );

    if (preserveAspectRatio) {
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

    return Container(
      width: validSize,
      height: validSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(resolvedRadius),

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
        cacheWidth: cacheSize,
        cacheHeight: cacheSize,
        errorBuilder: (ctx, err, stack) => _buildPlaceholder(isDark),
      );
    }

    if (OfflineService().downloadedSongIds.value.isNotEmpty) {
      final offlinePath = OfflineService().getLocalCoverArtPathByCoverArtId(coverArt);
      if (offlinePath != null) {
        return Image.file(
          File(offlinePath),
          key: ValueKey('offline_natural_$coverArt'),
          fit: BoxFit.contain,
          cacheWidth: cacheSize,
          cacheHeight: cacheSize,
          errorBuilder: (ctx, err, stack) => _buildPlaceholder(isDark),
        );
      }
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
          cacheKey: 'cover_natural_$coverArt',
          key: ValueKey('cover_natural_$coverArt'),
          fit: BoxFit.contain,
          memCacheWidth: cacheSize,
          memCacheHeight: cacheSize,
          maxWidthDiskCache: cacheSize > 600 ? cacheSize : 600,
          maxHeightDiskCache: cacheSize > 600 ? cacheSize : 600,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          useOldImageOnUrlChange: true,
          placeholder: (ctx, url) => _buildPlaceholder(isDark),
          errorWidget: (ctx, err, stack) {
            return _buildPlaceholder(isDark);
          },
        );
      },
    );
  }

  Widget _buildImage(bool isDark, int cacheSize) {
    if (coverArt == null || coverArt!.isEmpty) return _buildPlaceholder(isDark);

    if (isLocalFilePath(coverArt)) {
      final artFile = File(coverArt!);
      return Image.file(
        artFile,
        key: ValueKey(coverArt),
        fit: BoxFit.cover,
        cacheWidth: cacheSize,
        cacheHeight: cacheSize,
        errorBuilder: (ctx, err, stack) => _buildPlaceholder(isDark),
      );
    }

    if (OfflineService().downloadedSongIds.value.isNotEmpty) {
      final offlinePath = OfflineService().getLocalCoverArtPathByCoverArtId(coverArt);
      if (offlinePath != null) {
        return Image.file(
          File(offlinePath),
          key: ValueKey('offline_$coverArt'),
          fit: BoxFit.cover,
          cacheWidth: cacheSize,
          cacheHeight: cacheSize,
          errorBuilder: (ctx, err, stack) => _buildPlaceholder(isDark),
        );
      }
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
          cacheKey: 'cover_$coverArt',
          key: ValueKey('cover_$coverArt'),
          fit: BoxFit.cover,
          memCacheWidth: cacheSize,
          memCacheHeight: cacheSize,
          maxWidthDiskCache: cacheSize > 600 ? cacheSize : 600,
          maxHeightDiskCache: cacheSize > 600 ? cacheSize : 600,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          useOldImageOnUrlChange: true,
          placeholder: (ctx, url) => _buildPlaceholder(isDark),
          errorWidget: (ctx, err, stack) {
            return _buildPlaceholder(isDark);
          },
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
