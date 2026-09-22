import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:musly/services/upnp_service.dart';

import '../bootstrap.dart';

/// SSDP discovery runs over UDP multicast, which is unreliable by design and
/// routinely dropped by access points and switches. The original implementation
/// sent one M-SEARCH, waited 4 seconds, closed the socket out from under any
/// description fetch still in flight, and cleared the device list up front.
///
/// Observed on a four-renderer network: the first scan listed one speaker, a
/// later sample listed three in a different order, and only a second full scan
/// found all four.
///
/// `discover()` itself binds a real multicast socket, so the parts worth
/// pinning are the list operations it now performs: merge-by-LOCATION (the
/// repeated sends make the same renderer answer more than once) and the
/// end-of-scan prune that replaced the up-front clear.
void main() {
  initializeTestEnvironment();

  late UpnpService service;

  UpnpDevice device(String name, String host) => UpnpDevice(
        friendlyName: name,
        location: 'http://$host/description.xml',
        manufacturer: 'Test',
        modelName: 'Test Renderer',
        avTransportUrl: 'http://$host/ctl/AVTransport',
      );

  setUp(() {
    // UpnpService is a singleton, so the device list carries over between
    // tests. Prune with the empty-ish sentinel first, then a real one.
    service = UpnpService();
    service.pruneDevicesNotIn({'__none__'});
  });

  group('merge by LOCATION', () {
    test('a renderer answering three times yields one entry', () {
      final d = device('Kitchen', '192.168.1.10:49152');

      service.mergeResolvedDevice(d);
      service.mergeResolvedDevice(d);
      service.mergeResolvedDevice(d);

      // The fix sends M-SEARCH three times, so every renderer replies up to
      // three times. Without dedupe the picker listed each speaker per reply.
      expect(service.devices.length, 1);
      expect(service.devices.single.friendlyName, 'Kitchen');
    });

    test('distinct renderers all survive', () {
      service.mergeResolvedDevice(device('Kitchen', '192.168.1.10:49152'));
      service.mergeResolvedDevice(device('Back-porch', '192.168.1.11:49152'));
      service.mergeResolvedDevice(device('Mel-room', '192.168.1.12:49152'));

      expect(service.devices.map((d) => d.friendlyName).toSet(),
          {'Kitchen', 'Back-porch', 'Mel-room'});
    });

    test('a re-resolved device replaces rather than duplicates', () {
      service.mergeResolvedDevice(device('Old name', '192.168.1.10:49152'));
      service.mergeResolvedDevice(device('Renamed', '192.168.1.10:49152'));

      expect(service.devices.length, 1);
      expect(service.devices.single.friendlyName, 'Renamed');
    });
  });

  group('end-of-scan prune', () {
    test('keeps renderers that answered', () {
      service.mergeResolvedDevice(device('Kitchen', '192.168.1.10:49152'));
      service.mergeResolvedDevice(device('Back-porch', '192.168.1.11:49152'));

      service.pruneDevicesNotIn({
        'http://192.168.1.10:49152/description.xml',
        'http://192.168.1.11:49152/description.xml',
      });

      expect(service.devices.length, 2);
    });

    test('drops a renderer that has gone away', () {
      service.mergeResolvedDevice(device('Kitchen', '192.168.1.10:49152'));
      service.mergeResolvedDevice(device('Unplugged', '192.168.1.99:49152'));

      service.pruneDevicesNotIn({'http://192.168.1.10:49152/description.xml'});

      expect(service.devices.map((d) => d.friendlyName), ['Kitchen']);
    });

    test('a scan that found nothing does not wipe the list', () {
      service.mergeResolvedDevice(device('Kitchen', '192.168.1.10:49152'));

      service.pruneDevicesNotIn({});

      // An empty result is far likelier to be a failed scan than every
      // renderer vanishing at once. The old code cleared up front, so a scan
      // that lost its reply to UDP dropped a speaker already on screen.
      expect(service.devices.length, 1);
    });

    test('never drops the renderer that is connected', () async {
      // A speaker busy streaming can miss every M-SEARCH in a scan. Pruning it
      // would hide the device the user is playing to; the poll's repeated
      // failures are what detect a connected renderer really going away.
      // connect() issues a real SOAP request, so answer it on loopback.
      HttpOverrides.global = null;
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((req) async {
        await req.drain<void>();
        req.response.write('<CurrentTransportState>PLAYING'
            '</CurrentTransportState>');
        await req.response.close();
      });
      addTearDown(() => server.close(force: true));

      final host = '${server.address.host}:${server.port}';
      final playing = device('Playing', host);
      service.mergeResolvedDevice(playing);
      service.mergeResolvedDevice(device('Kitchen', '192.168.1.10:49152'));
      expect(await service.connect(playing), isTrue);
      addTearDown(service.disconnect);

      service.pruneDevicesNotIn({'http://192.168.1.10:49152/description.xml'});

      expect(service.devices.map((d) => d.friendlyName),
          containsAll(['Playing', 'Kitchen']));
    });
  });

  group('headerValue', () {
    const response = 'HTTP/1.1 200 OK\r\n'
        'CACHE-CONTROL: max-age=1800\r\n'
        'LOCATION: http://192.168.1.50:49152/description.xml\r\n'
        'ST: urn:schemas-upnp-org:device:MediaRenderer:1\r\n'
        '\r\n';

    test('reads the LOCATION header', () {
      expect(UpnpService.headerValue(response, 'LOCATION'),
          'http://192.168.1.50:49152/description.xml');
    });

    test('is case-insensitive', () {
      // Renderers are inconsistent about header case. LOCATION is the dedupe
      // key, so failing to parse one spelling silently drops that renderer.
      expect(UpnpService.headerValue(response, 'location'),
          'http://192.168.1.50:49152/description.xml');
    });

    test('tolerates extra spacing after the colon', () {
      expect(
          UpnpService.headerValue(
              'LOCATION:    http://host/d.xml\r\n', 'LOCATION'),
          'http://host/d.xml');
    });

    test('returns null when the header is absent', () {
      expect(UpnpService.headerValue(response, 'USN'), isNull);
    });

    test('does not run past the end of the line', () {
      expect(
          UpnpService.headerValue(response, 'CACHE-CONTROL'), 'max-age=1800');
    });
  });

  test('devices is exposed unmodifiable', () {
    expect(
      () => service.devices.add(device('x', 'h')),
      throwsUnsupportedError,
      reason: 'callers must not mutate discovery state behind its back',
    );
  });
}
