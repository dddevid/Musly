import 'package:flutter_test/flutter_test.dart';
import 'package:musly/services/upnp_service.dart';

void main() {
  group('UpnpService.decodeXmlEntities', () {
    test('decodes a single layer of escaping', () {
      expect(
        UpnpService.decodeXmlEntities('a&amp;b'),
        'a&b',
      );
    });

    test('decodes exactly one layer', () {
      // Single-pass by design: '&amp;amp;' is one layer of escaping over the
      // text '&amp;', so one decode yields '&amp;'. Collapsing all the way is
      // canonicalUri's job, not this function's.
      expect(
        UpnpService.decodeXmlEntities('v=1.16.1&amp;amp;c=Musly'),
        'v=1.16.1&amp;c=Musly',
      );
    });

    test('decodes the other entities a DIDL document can carry', () {
      expect(UpnpService.decodeXmlEntities('&lt;tag&gt;'), '<tag>');
      expect(UpnpService.decodeXmlEntities('&quot;q&quot;'), '"q"');
      expect(UpnpService.decodeXmlEntities('&apos;a&apos;'), "'a'");
    });

    test('decodes &amp; last so escaped entities survive one round', () {
      // '&amp;lt;' means the sender wanted a literal '&lt;', not '<'.
      // Decoding '&amp;' before '&lt;' would wrongly collapse it to '<'.
      expect(UpnpService.decodeXmlEntities('&amp;lt;'), '&lt;');
    });

    test('is a fixed point for text with no entities', () {
      const plain = 'http://host/rest/stream?id=abc&v=1';
      expect(UpnpService.decodeXmlEntities(plain), plain);
    });

    test('terminates on pathologically nested escaping', () {
      // Must not spin. The bound means very deep nesting is left partly
      // encoded, which is fine — it just fails to match, and the caller
      // treats an unrecognised URI as "leave the queue alone".
      final deep = '&amp;' * 40;
      expect(() => UpnpService.canonicalUri(deep), returnsNormally);
    });

    test('handles empty input', () {
      expect(UpnpService.decodeXmlEntities(''), '');
    });

    test('decodes numeric character references, decimal and hex', () {
      expect(UpnpService.decodeXmlEntities('a&#38;b'), 'a&b');
      expect(UpnpService.decodeXmlEntities('a&#x26;b'), 'a&b');
      expect(UpnpService.decodeXmlEntities('a&#X26;b'), 'a&b');
      expect(UpnpService.decodeXmlEntities('a&#038;b'), 'a&b',
          reason: 'leading zeros are valid in a numeric reference');
      expect(UpnpService.decodeXmlEntities('&#60;tag&#62;'), '<tag>');
    });

    test('numeric ampersand refs are decoded last, like &amp;', () {
      // Same single-pass rule: '&#38;lt;' means a literal '&lt;', so decoding
      // the numeric reference early would wrongly collapse it to '<'.
      expect(UpnpService.decodeXmlEntities('&#38;lt;'), '&lt;');
      expect(UpnpService.decodeXmlEntities('&#x26;lt;'), '&lt;');
    });

    test('leaves malformed or out-of-range references alone', () {
      expect(UpnpService.decodeXmlEntities('&#;'), '&#;');
      expect(UpnpService.decodeXmlEntities('&#zz;'), '&#zz;');
      expect(UpnpService.decodeXmlEntities('&#999999999;'), '&#999999999;');
      expect(UpnpService.decodeXmlEntities('&#0;'), '&#0;');
    });
  });

  group('UpnpService.canonicalUri', () {
    test('a sent URI and the renderer echo of it compare equal', () {
      // This single assertion is the whole bug: these two strings are the same
      // track, and comparing them raw reported a track change on every poll,
      // which drove a blind _currentIndex++ and walked the UI up the queue.
      const sent =
          'http://192.168.1.5:4533/rest/stream?u=tim&v=1.16.1&c=Musly&id=xyz';
      const echoed =
          'http://192.168.1.5:4533/rest/stream?u=tim&amp;amp;v=1.16.1&amp;amp;c=Musly&amp;amp;id=xyz';

      expect(UpnpService.canonicalUri(sent),
          UpnpService.canonicalUri(echoed));
    });

    test('genuinely different tracks still differ', () {
      const a = 'http://h/rest/stream?id=AAA&v=1';
      const b = 'http://h/rest/stream?id=BBB&v=1';
      expect(UpnpService.canonicalUri(a) == UpnpService.canonicalUri(b),
          isFalse);
    });

    test('matches when the renderer uses numeric refs for &', () {
      // Renderers are inconsistent about which escaping form they emit; a
      // numeric one must still be recognised as the same track, or the gapless
      // auto-advance silently stops being followed.
      const sent = 'http://h/rest/stream?u=t&v=1.16.1&id=xyz';
      const echoedDecimal = 'http://h/rest/stream?u=t&#38;v=1.16.1&#38;id=xyz';
      const echoedHex = 'http://h/rest/stream?u=t&#x26;v=1.16.1&#x26;id=xyz';

      expect(UpnpService.canonicalUri(echoedDecimal),
          UpnpService.canonicalUri(sent));
      expect(UpnpService.canonicalUri(echoedHex),
          UpnpService.canonicalUri(sent));
    });

    test('trims renderer whitespace padding', () {
      expect(UpnpService.canonicalUri('  http://h/x?a=1&amp;b=2  '),
          'http://h/x?a=1&b=2');
    });
  });
}
