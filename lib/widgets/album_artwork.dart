import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../services/subsonic_service.dart';
import '../theme/app_theme.dart';

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
  final double borderRadius;
  final BoxShadow? shadow;

  const AlbumArtwork({
    super.key,
    this.coverArt,
    this.size = 150,
    this.borderRadius = 8,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    final validSize = size.isFinite && !size.isNaN ? size : 150.0;
    final cacheSize = (validSize * 2).toInt().clamp(100, 600);

    final imageUrl = coverArt != null && coverArt!.isNotEmpty
        ? _ImageUrlCache.getUrl(
            Provider.of<SubsonicService>(context, listen: false),
            coverArt,
            cacheSize,
          )
        : '';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: Container(
        width: validSize,
        height: validSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: shadow != null
              ? [shadow!]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.15),
                    blurRadius: validSize / 10,
                    offset: Offset(0, validSize / 30),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  key: ValueKey(coverArt),
                  fit: BoxFit.cover,
                  memCacheWidth: cacheSize,
                  memCacheHeight: cacheSize,
                  fadeInDuration: const Duration(milliseconds: 100),
                  fadeOutDuration: Duration.zero,
                  useOldImageOnUrlChange: true,
                  placeholder: (_, __) => _buildPlaceholder(isDark),
                  errorWidget: (_, __, ___) => _buildPlaceholder(isDark),
                )
              : _buildPlaceholder(isDark),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      color: isDark ? AppTheme.darkCard : AppTheme.lightDivider,
      child: Icon(
        Icons.music_note_rounded,
        size: size / 3,
        color: isDark
            ? AppTheme.darkSecondaryText
            : AppTheme.lightSecondaryText,
      ),
    );
  }
}