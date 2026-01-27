import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImageCacheConfig {
  static void configure() {

    // Reduced cache size to prevent OOM on low-end devices.
    // 100 images or 50MB, whichever comes first.
    PaintingBinding.instance.imageCache.maximumSize = 100;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20;
  }
}

class ImagePreloader {

  static Future<void> preloadImages(
    BuildContext context,
    List<String> imageUrls,
  ) async {
    for (final url in imageUrls) {
      if (url.isNotEmpty) {
        try {
          await precacheImage(CachedNetworkImageProvider(url), context);
        } catch (e) {

        }
      }
    }
  }

  static Future<void> preloadImage(
    BuildContext context,
    String imageUrl,
  ) async {
    if (imageUrl.isEmpty) return;

    try {
      await precacheImage(CachedNetworkImageProvider(imageUrl), context);
    } catch (e) {

    }
  }
}