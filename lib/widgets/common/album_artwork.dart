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
      if (coverArt.contains('googleusercontent.com') ||
          coverArt.contains('ggpht.com')) {
        final effectiveSize = size > 0 ? size : 800;
        final base = coverArt.split('=')[0];
        return '$base=w$effectiveSize-h$effectiveSize-l90-rj';
      }
      if (coverArt.contains('i.ytimg.com') || coverArt.contains('img.youtube.com')) {
        final match = RegExp(r'/vi/([a-zA-Z0-9_-]{11})').firstMatch(coverArt);
        if (match != null) {
          final vid = match.group(1);
          return 'https://i.ytimg.com/vi/$vid/hq720.jpg';
        }
      }
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
    return ValueListenableBuilder<String>(
      valueListenable: svc.artworkResolutionNotifier,
      builder: (context, resolutionSetting, _) {
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
          resolutionSetting,
        );
      },
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
    String resolutionSetting,
  ) {
    final validSize = size.isFinite && !size.isNaN ? size : 150.0;

    final dpr = MediaQuery.devicePixelRatioOf(context);
    final baseSize = (validSize * dpr).toInt();

    final int cacheSize;
    if (resolutionSetting == 'high') {
      cacheSize = 0; // Use original or maximum available size
    } else if (resolutionSetting == 'low') {
      cacheSize = baseSize > 300 ? baseSize.clamp(300, 600) : 300;
    } else {
      cacheSize = baseSize > 600 ? baseSize.clamp(600, 1000) : 600; // normal (at least 600px)
    }

    // For small thumbnails (e.g. lists, mini player), decode in memory at device resolution
    // rather than decoding a full 600px+ raster, saving ~90% RAM during long list scrolling.
    // We scale by 1.8x to guarantee that even wide 16:9 images retain sufficient vertical resolution.
    final int? memCacheSize = cacheSize == 0
        ? null
        : (validSize <= 80 ? (baseSize * 1.8).round().clamp(120, 360) : cacheSize);

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
          child: _buildImageNatural(isDark, cacheSize, memCacheSize),
        ),
      );
    }

    return Container(
      width: validSize,
      height: validSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(resolvedRadius),
        boxShadow:
            resolvedShadow != null && validSize > 60 ? [resolvedShadow] : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(resolvedRadius),
        child: _buildImage(isDark, cacheSize, memCacheSize),
      ),
    );
  }

  Widget _buildImageNatural(bool isDark, int cacheSize, int? memCacheSize) {
    if (coverArt == null || coverArt!.isEmpty) return _buildPlaceholder(isDark);

    final int? diskCacheSize =
        cacheSize > 0 ? (cacheSize > 600 ? cacheSize : 600) : null;
    final String keySuffix = cacheSize == 0 ? 'orig' : '$cacheSize';
    final String artId =
        coverArt!.startsWith('http://') || coverArt!.startsWith('https://')
            ? coverArt!.hashCode.toString()
            : coverArt!;
    final String cacheKey = 'cover_natural_${artId}_$keySuffix';

    if (isLocalFilePath(coverArt)) {
      final artFile = File(coverArt!);
      return Image.file(
        artFile,
        key: ValueKey(coverArt),
        fit: BoxFit.contain,
        cacheWidth: memCacheSize,
        errorBuilder: (ctx, err, stack) => _buildPlaceholder(isDark),
      );
    }

    if (OfflineService().downloadedSongIds.value.isNotEmpty) {
      final offlinePath =
          OfflineService().getLocalCoverArtPathByCoverArtId(coverArt);
      if (offlinePath != null) {
        return Image.file(
          File(offlinePath),
          key: ValueKey('offline_natural_$coverArt'),
          fit: BoxFit.contain,
          cacheWidth: memCacheSize,
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
          cacheKey: cacheKey,
          key: ValueKey(cacheKey),
          fit: BoxFit.contain,
          memCacheWidth: memCacheSize,
          maxWidthDiskCache: diskCacheSize,
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

  Widget _buildImage(bool isDark, int cacheSize, int? memCacheSize) {
    if (coverArt == null || coverArt!.isEmpty) return _buildPlaceholder(isDark);

    final int? diskCacheSize =
        cacheSize > 0 ? (cacheSize > 600 ? cacheSize : 600) : null;
    final String keySuffix = cacheSize == 0 ? 'orig' : '$cacheSize';
    final String artId =
        coverArt!.startsWith('http://') || coverArt!.startsWith('https://')
            ? coverArt!.hashCode.toString()
            : coverArt!;
    final String cacheKey = 'cover_${artId}_$keySuffix';

    if (isLocalFilePath(coverArt)) {
      final artFile = File(coverArt!);
      return Image.file(
        artFile,
        key: ValueKey(coverArt),
        fit: BoxFit.cover,
        cacheWidth: memCacheSize,
        errorBuilder: (ctx, err, stack) => _buildPlaceholder(isDark),
      );
    }

    if (OfflineService().downloadedSongIds.value.isNotEmpty) {
      final offlinePath =
          OfflineService().getLocalCoverArtPathByCoverArtId(coverArt);
      if (offlinePath != null) {
        return Image.file(
          File(offlinePath),
          key: ValueKey('offline_$coverArt'),
          fit: BoxFit.cover,
          cacheWidth: memCacheSize,
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
          cacheKey: cacheKey,
          key: ValueKey(cacheKey),
          fit: BoxFit.cover,
          memCacheWidth: memCacheSize,
          maxWidthDiskCache: diskCacheSize,
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
