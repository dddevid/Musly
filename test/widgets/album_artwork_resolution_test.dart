import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:musly/models/server_config.dart';
import 'package:musly/services/player_ui_settings_service.dart';
import 'package:musly/services/subsonic_service.dart';
import 'package:musly/widgets/common/album_artwork.dart';
import 'package:musly/widgets/now_playing/album_art_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ImageUrlCache.clear();
  });

  group('AlbumArtwork Resolution and Caching', () {
    test('ImageUrlCache caches URLs by size and clears successfully', () async {
      final service = SubsonicService();
      await service.configure(ServerConfig(
        serverUrl: 'https://demo.navidrome.org',
        username: 'user',
        password: 'password',
      ));

      final url600 = ImageUrlCache.getUrl(service, 'al-1', 600);
      expect(url600, contains('size=600'));
      expect(url600, contains('id=al-1'));

      final url300 = ImageUrlCache.getUrl(service, 'al-1', 300);
      expect(url300, contains('size=300'));
      expect(url300, isNot(equals(url600)));

      ImageUrlCache.clear();
      final urlAfterClear = ImageUrlCache.getUrl(service, 'al-1', 600);
      expect(urlAfterClear, contains('size=600'));
    });

    testWidgets('AlbumArtwork builds without exception in normal, low, and high resolution',
        (tester) async {
      final settings = PlayerUiSettingsService();
      await settings.setArtworkResolution('normal');

      await tester.pumpWidget(
        createTestApp(
          child: const AlbumArtwork(
            coverArt: 'cover_test_1',
            size: 156,
          ),
        ),
      );

      expect(find.byType(AlbumArtwork), findsOneWidget);

      await settings.setArtworkResolution('low');
      await tester.pumpAndSettle();
      expect(find.byType(AlbumArtwork), findsOneWidget);

      await settings.setArtworkResolution('high');
      await tester.pumpAndSettle();
      expect(find.byType(AlbumArtwork), findsOneWidget);
    });

    testWidgets('AlbumArtwork omits memCacheHeight to preserve aspect ratio (#283, #277)',
        (tester) async {
      final settings = PlayerUiSettingsService();
      await settings.setArtworkResolution('normal');

      await tester.pumpWidget(
        createTestApp(
          child: const AlbumArtwork(
            coverArt: 'https://example.com/cover.jpg',
            size: 56,
          ),
        ),
      );

      final cachedImageFinder = find.byType(CachedNetworkImage);
      expect(cachedImageFinder, findsOneWidget);
      final CachedNetworkImage cachedImage = tester.widget(cachedImageFinder);
      expect(cachedImage.memCacheWidth, isNotNull);
      expect(cachedImage.memCacheHeight, isNull);
      expect(cachedImage.fit, BoxFit.cover);
    });

    test('SubsonicService getCoverArtUrl defaults to 600px', () async {
      final service = SubsonicService();
      await service.configure(ServerConfig(
        serverUrl: 'https://demo.navidrome.org',
        username: 'user',
        password: 'password',
      ));

      final defaultUrl = service.getCoverArtUrl('al-cover');
      expect(defaultUrl, contains('size=600'));
    });

    test('ImageUrlCache upscales Google CDN image URLs dynamically by size', () {
      final service = SubsonicService();
      const googleThumb =
          'https://yt3.googleusercontent.com/abc123xyz=w60-h60-l90-rj';

      final url60 = ImageUrlCache.getUrl(service, googleThumb, 60);
      expect(url60, contains('=w60-h60-l90-rj'));

      final url800 = ImageUrlCache.getUrl(service, googleThumb, 800);
      expect(url800, contains('=w800-h800-l90-rj'));
      expect(url800, isNot(contains('=w60-h60')));
    });

    test('ImageUrlCache upgrades legacy YouTube hqdefault.jpg to hq720.jpg', () {
      final service = SubsonicService();
      const legacyYtThumb =
          'https://i.ytimg.com/vi/b53QJYP-lqY/hqdefault.jpg';

      final upgraded = ImageUrlCache.getUrl(service, legacyYtThumb, 600);
      expect(upgraded, 'https://i.ytimg.com/vi/b53QJYP-lqY/hq720.jpg');
      expect(upgraded, isNot(contains('hqdefault.jpg')));
    });

    testWidgets('AlbumArtView enforces 1:1 square AspectRatio and BoxFit.cover',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const SizedBox(
            width: 400,
            height: 300,
            child: AlbumArtView(
              image: AssetImage('assets/logo.png'),
              tag: 'test_tag',
            ),
          ),
        ),
      );

      final aspectRatioFinder = find.byType(AspectRatio);
      expect(aspectRatioFinder, findsOneWidget);
      final AspectRatio aspectRatioWidget = tester.widget(aspectRatioFinder);
      expect(aspectRatioWidget.aspectRatio, 1.0);

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      final Image imageWidget = tester.widget(imageFinder);
      expect(imageWidget.fit, BoxFit.cover);
      expect(imageWidget.width, double.infinity);
      expect(imageWidget.height, double.infinity);
    });
  });
}

