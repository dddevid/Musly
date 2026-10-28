import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:musly/services/upnp_service.dart';

/// A UPnP renderer on loopback, so tests can drive the real UpnpService over
/// real HTTP and hold individual responses open to force an interleaving.
///
/// The test binding replaces HttpClient with one that answers 400; set
/// `HttpOverrides.global = null` before using this.
class FakeUpnpRenderer {
  FakeUpnpRenderer({this.volume = 15, this.name = 'Fake renderer'});

  final String name;
  late final HttpServer _server;

  int volume;

  /// Every DesiredVolume received, in arrival order.
  final setVolumes = <int>[];

  /// What the renderer applies when asked for a volume; defaults to exactly
  /// what was asked. Real hardware mixers often round.
  int Function(int requested) apply = (v) => v;

  /// When set, SetVolume requests wait for this before being applied.
  Completer<void>? gateSetVolume;

  /// When set, the next GetVolume records the volume at request time and then
  /// waits for [releaseRead] before answering with it.
  bool holdNextRead = false;
  final Completer<void> readHeld = Completer<void>();
  final Completer<void> releaseRead = Completer<void>();

  int _position = 0;

  String get base => 'http://${_server.address.host}:${_server.port}';

  UpnpDevice get device => UpnpDevice(
        friendlyName: name,
        location: '$base/desc.xml',
        manufacturer: 'test',
        modelName: 'test',
        avTransportUrl: '$base/avt',
        renderingControlUrl: '$base/rc',
      );

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen(_handle);
  }

  Future<void> close() async {
    if (!releaseRead.isCompleted) releaseRead.complete();
    if (gateSetVolume?.isCompleted == false) gateSetVolume!.complete();
    await _server.close(force: true);
  }

  Future<void> _handle(HttpRequest req) async {
    final action = (req.headers.value('SOAPAction') ?? '')
        .replaceAll('"', '')
        .split('#')
        .last;
    final request = await utf8.decodeStream(req);

    var body = '';
    switch (action) {
      case 'GetTransportInfo':
        body = '<CurrentTransportState>PLAYING</CurrentTransportState>';
      case 'GetPositionInfo':
        // Advancing position makes every poll notify, as it does while a real
        // renderer is playing.
        final s = _position++;
        body = '<RelTime>0:${(s ~/ 60).toString().padLeft(2, '0')}:'
            '${(s % 60).toString().padLeft(2, '0')}</RelTime>'
            '<TrackDuration>0:03:00</TrackDuration>';
      case 'GetVolume':
        final seen = volume;
        if (holdNextRead) {
          holdNextRead = false;
          readHeld.complete();
          await releaseRead.future;
        }
        body = '<CurrentVolume>$seen</CurrentVolume>';
      case 'SetVolume':
        final m = RegExp(r'<DesiredVolume>(\d+)<').firstMatch(request);
        final requested = int.parse(m!.group(1)!);
        setVolumes.add(requested);
        await gateSetVolume?.future;
        volume = apply(requested);
    }

    req.response
      ..headers.contentType = ContentType('text', 'xml', charset: 'utf-8')
      ..write('<?xml version="1.0"?><s:Envelope '
          'xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"><s:Body>'
          '<u:${action}Response>$body</u:${action}Response>'
          '</s:Body></s:Envelope>');
    await req.response.close();
  }
}
