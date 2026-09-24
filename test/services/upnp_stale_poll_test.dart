import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:musly/services/upnp_service.dart';

/// UpnpService polls the renderer once a second. loadAndPlay sends Stop and
/// SetAVTransportURI before Play, so a poll whose request lands in that window
/// reads STOPPED — and if the response arrives after Play has succeeded, it
/// overwrites the PLAYING state loadAndPlay just set. PlayerProvider reads
/// "was playing, now STOPPED" as the end of the track and advances again, so
/// pressing next on a DLNA renderer intermittently skipped two tracks.
/// Observed on a Pixel 7 Pro against upmpdcli: the stale STOPPED arrived 1 ms
/// after "Playing ... (instant)".
///
/// These tests drive the real service against a fake renderer on loopback
/// that can hold a GetTransportInfo response open, which is the only way to
/// reproduce the interleaving deterministically.
class _FakeRenderer {
  late final HttpServer _server;
  String state = 'PLAYING';

  /// When set, the next poll's GetTransportInfo records the state at request
  /// time and then waits for [releasePoll] before answering with it.
  bool holdNextPoll = false;
  Completer<void> pollHeld = Completer<void>();
  final Completer<void> releasePoll = Completer<void>();

  /// When set, SetAVTransportURI waits for this before completing, so a test
  /// can land a poll in the middle of a load.
  Future<void>? gateSetUri;

  String get controlUrl =>
      'http://${_server.address.host}:${_server.port}/avt';

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen(_handle);
  }

  Future<void> close() => _server.close(force: true);

  Future<void> _handle(HttpRequest req) async {
    final action = (req.headers.value('SOAPAction') ?? '')
        .replaceAll('"', '')
        .split('#')
        .last;
    await req.drain<void>();

    var body = '';
    switch (action) {
      case 'GetTransportInfo':
        final seen = state;
        if (holdNextPoll) {
          holdNextPoll = false;
          pollHeld.complete();
          await releasePoll.future;
        }
        body = '<CurrentTransportState>$seen</CurrentTransportState>';
      case 'GetPositionInfo':
        body = '<RelTime>0:00:01</RelTime><TrackDuration>0:03:00</TrackDuration>';
      case 'Stop':
        state = 'STOPPED';
      case 'SetAVTransportURI':
        state = 'STOPPED';
        await gateSetUri;
      case 'Play':
        state = 'PLAYING';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeRenderer renderer;
  late UpnpService upnp;
  late List<String> states;

  void recordState() => states.add(upnp.rendererState);

  setUp(() async {
    // The test binding replaces HttpClient with one that answers every
    // request with 400; this test needs real loopback HTTP.
    HttpOverrides.global = null;
    renderer = _FakeRenderer();
    await renderer.start();
    upnp = UpnpService();
    final connected = await upnp.connect(UpnpDevice(
      friendlyName: 'Fake renderer',
      location: '${renderer.controlUrl}/desc.xml',
      manufacturer: 'test',
      modelName: 'test',
      avTransportUrl: renderer.controlUrl,
    ));
    expect(connected, isTrue);
    states = [];
    upnp.addListener(recordState);
  });

  tearDown(() async {
    upnp.removeListener(recordState);
    upnp.disconnect();
    // disconnect() sends a fire-and-forget Stop; let it land before closing.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!renderer.releasePoll.isCompleted) renderer.releasePoll.complete();
    await renderer.close();
  });

  Future<void> load() async {
    final ok = await upnp.loadAndPlay(
      url: '${renderer.controlUrl}/track.mp3',
      title: 'Next track',
      artist: 'Artist',
    );
    expect(ok, isTrue);
  }

  /// Lets a released poll run to completion and notify.
  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 200));

  test('a poll sent before a load cannot report STOPPED after it', () async {
    // The renderer is between tracks when the poll goes out...
    renderer.state = 'STOPPED';
    renderer.holdNextPoll = true;
    await renderer.pollHeld.future.timeout(const Duration(seconds: 3));

    // ...then a load completes while that response is still in flight.
    await load();
    expect(upnp.rendererState, 'PLAYING');
    states.clear();

    renderer.releasePoll.complete();
    await settle();

    expect(upnp.rendererState, 'PLAYING');
    expect(states, isNot(contains('STOPPED')),
        reason: 'a stale STOPPED here makes the player skip the new track');
  });

  test('a poll sent during a load cannot report STOPPED after it', () async {
    // Hold the load after Stop/SetAVTransportURI, the point at which the real
    // renderer reports STOPPED, until a poll has gone out.
    final pollSent = Completer<void>();
    renderer.gateSetUri = pollSent.future;
    renderer.holdNextPoll = true;
    renderer.pollHeld.future.then((_) => pollSent.complete());

    await load().timeout(const Duration(seconds: 3));
    expect(upnp.rendererState, 'PLAYING');
    states.clear();

    renderer.releasePoll.complete();
    await settle();

    expect(upnp.rendererState, 'PLAYING');
    expect(states, isNot(contains('STOPPED')));
  });

  test('a genuine STOPPED with no load in flight still gets through', () async {
    // The guard must not swallow real end-of-track: PlayerProvider relies on
    // this transition to advance when there is no gapless next track queued.
    // Observe PLAYING first, or STOPPED would just be the initial state.
    while (upnp.rendererState != 'PLAYING') {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    renderer.state = 'STOPPED';
    renderer.holdNextPoll = true;
    await renderer.pollHeld.future.timeout(const Duration(seconds: 3));

    renderer.releasePoll.complete();
    await settle();

    expect(upnp.rendererState, 'STOPPED');
  });
}
