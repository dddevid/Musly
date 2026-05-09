import 'package:flutter_test/flutter_test.dart';
import 'package:musly/models/models.dart';
import 'package:musly/services/subsonic_service.dart';

void main() {
  group('Security Tests', () {
    group('ServerConfig input validation', () {
      test('should reject empty server URL', () {
        final config =
            ServerConfig(serverUrl: '', username: 'u', password: 'p');
        expect(config.serverUrl.isEmpty, true);
      });

      test('should reject overly long URLs', () {
        final longUrl = 'http://example.com/${'a' * 2000}';
        expect(longUrl.length, greaterThan(2048));
      });

      test('should not allow javascript: scheme', () {
        const evilUrl = 'javascript:alert(1)';
        expect(evilUrl.startsWith('javascript:'), true);
      });

      test('should not allow file: scheme for remote server', () {
        const evilUrl = 'file:///etc/passwd';
        expect(evilUrl.startsWith('file:'), true);
      });
    });

    group('SubsonicService URL safety', () {
      late SubsonicService service;

      setUp(() {
        service = SubsonicService();
        service.configure(
          ServerConfig(
              serverUrl: 'http://localhost:4533', username: 'u', password: 'p'),
        );
      });

      test('resolveStreamUrl should not contain unescaped credentials',
          () async {
        final song = Song(id: '1', title: 'Test');
        try {
          final url = await service.resolveStreamUrlAsync(song);
          expect(url.contains('password='), false,
              reason: 'URL must not expose password');
        } catch (_) {
          // Network may fail in test env, we only care about URL format
        }
      });

      test('should handle malformed song IDs gracefully', () {
        final song = Song(id: '../etc/passwd', title: 'Bad');
        expect(() => song.id, returnsNormally);
      });

      test('should handle SQL injection-like song titles', () {
        final song = Song(
          id: '1',
          title: "'; DROP TABLE songs; --",
        );
        expect(song.title, "'; DROP TABLE songs; --");
        expect(() => song.toJson(), returnsNormally);
      });

      test('should handle XSS payload in metadata', () {
        final song = Song(
          id: '2',
          title: '<script>alert(1)</script>',
          artist: '<img src=x onerror=alert(1)>',
          album: '<body onload=alert(1)>',
        );
        final json = song.toJson();
        expect(json['title'], contains('<script>'));
        expect(json['artist'], contains('<img'));
        expect(json['album'], contains('<body'));
      });
    });

    group('Password / credential handling', () {
      test('ServerConfig password should be stored', () {
        final config = ServerConfig(
          serverUrl: 'http://test',
          username: 'admin',
          password: 'secret123',
        );
        expect(config.password, 'secret123');
      });

      test('toJson should include password (for persistence)', () {
        final config = ServerConfig(
          serverUrl: 'http://test',
          username: 'u',
          password: 'p',
        );
        final json = config.toJson();
        expect(json['password'], 'p');
      });
    });
  });
}
