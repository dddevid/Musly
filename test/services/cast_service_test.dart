import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musly/services/cast_service.dart';
import '../bootstrap.dart';

void main() {
  initializeTestEnvironment();

  group('CastMediaState', () {
    test('initializes with default values', () {
      final state = CastMediaState();
      expect(state.isPlaying, false);
      expect(state.position, Duration.zero);
      expect(state.duration, Duration.zero);
      expect(state.title, isNull);
      expect(state.artist, isNull);
      expect(state.imageUrl, isNull);
      expect(state.volume, 1.0);
      expect(state.playerState, isNull);
      expect(state.idleReason, isNull);
    });

    test('copyWith updates specified fields correctly', () {
      final state = CastMediaState();
      final updated = state.copyWith(
        isPlaying: true,
        position: const Duration(seconds: 42),
        duration: const Duration(seconds: 200),
        title: 'Test Title',
        artist: 'Test Artist',
        imageUrl: 'https://example.com/art.jpg',
        volume: 0.8,
        playerState: CastMediaPlayerState.playing,
        idleReason: GoogleCastMediaIdleReason.none,
      );

      expect(updated.isPlaying, true);
      expect(updated.position, const Duration(seconds: 42));
      expect(updated.duration, const Duration(seconds: 200));
      expect(updated.title, 'Test Title');
      expect(updated.artist, 'Test Artist');
      expect(updated.imageUrl, 'https://example.com/art.jpg');
      expect(updated.volume, 0.8);
      expect(updated.playerState, CastMediaPlayerState.playing);
      expect(updated.idleReason, GoogleCastMediaIdleReason.none);
    });
  });

  group('CastService MIME type resolution', () {
    test('resolves extensions from URLs correctly', () {
      expect(CastService.mimeTypeFromUrl('https://example.com/music.flac'), 'audio/flac');
      expect(CastService.mimeTypeFromUrl('https://example.com/music.ogg'), 'audio/ogg');
      expect(CastService.mimeTypeFromUrl('https://example.com/music.opus'), 'audio/ogg; codecs=opus');
      expect(CastService.mimeTypeFromUrl('https://example.com/music.wav'), 'audio/wav');
      expect(CastService.mimeTypeFromUrl('https://example.com/music.aac'), 'audio/aac');
      expect(CastService.mimeTypeFromUrl('https://example.com/music.m4a'), 'audio/mp4');
      expect(CastService.mimeTypeFromUrl('https://example.com/music.mp3'), 'audio/mpeg');
    });

    test('resolves format and suffix from query parameters', () {
      expect(
        CastService.mimeTypeFromUrl('https://example.com/rest/stream?id=123&format=flac&u=test'),
        'audio/flac',
      );
      expect(
        CastService.mimeTypeFromUrl('https://example.com/rest/stream?id=123&suffix=mp3&u=test'),
        'audio/mpeg',
      );
      expect(
        CastService.mimeTypeFromUrl('https://example.com/rest/stream?id=123&format=m4a'),
        'audio/mp4',
      );
    });

    test('falls back to audio/mpeg when format is unrecognized', () {
      expect(CastService.mimeTypeFromUrl('https://example.com/rest/stream?id=123'), 'audio/mpeg');
    });
  });
}
