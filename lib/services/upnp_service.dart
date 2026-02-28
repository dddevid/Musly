/// UPnP / DLNA media renderer discovery and control service.
///
/// Uses SSDP (Simple Service Discovery Protocol) over UDP multicast to find
/// DLNA MediaRenderer devices on the local network, then controls them via
/// AVTransport SOAP actions over HTTP.
library;

import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class UpnpDevice {
  final String friendlyName;
  final String location; // base URL of the device description
  final String manufacturer;
  final String modelName;
  final String avTransportUrl; // absolute URL for AVTransport control

  const UpnpDevice({
    required this.friendlyName,
    required this.location,
    required this.manufacturer,
    required this.modelName,
    required this.avTransportUrl,
  });

  @override
  String toString() => 'UpnpDevice($friendlyName @ $avTransportUrl)';
}

class UpnpPlaybackState {
  final String transportState; // PLAYING, PAUSED_PLAYBACK, STOPPED, etc.
  final Duration position;
  final Duration duration;

  const UpnpPlaybackState({
    required this.transportState,
    required this.position,
    required this.duration,
  });
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class UpnpService extends ChangeNotifier {
  static final UpnpService _instance = UpnpService._internal();
  factory UpnpService() => _instance;
  UpnpService._internal();

  // --- State ---
  final List<UpnpDevice> _devices = [];
  UpnpDevice? _connectedDevice;
  bool _isDiscovering = false;
  Timer? _pollTimer;

  // Playback state from the renderer (updated by polling)
  Duration _rendererPosition = Duration.zero;
  Duration _rendererDuration = Duration.zero;
  String _rendererState = 'STOPPED';

  Duration get rendererPosition => _rendererPosition;
  Duration get rendererDuration => _rendererDuration;
  String get rendererState => _rendererState;
  bool get isRendererPlaying => _rendererState == 'PLAYING';

  List<UpnpDevice> get devices => List.unmodifiable(_devices);
  UpnpDevice? get connectedDevice => _connectedDevice;
  bool get isConnected => _connectedDevice != null;
  bool get isDiscovering => _isDiscovering;

  static const String _ssdpAddress = '239.255.255.250';
  static const int _ssdpPort = 1900;
  static const Duration _discoveryTimeout = Duration(seconds: 4);

  final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );

  // --- Discovery ---

  /// Performs an SSDP M-SEARCH and returns discovered DLNA media renderers.
  /// Results are also stored in [devices] and listeners are notified.
  Future<List<UpnpDevice>> discover() async {
    if (_isDiscovering) return _devices;
    _isDiscovering = true;
    _devices.clear();
    notifyListeners();

    try {
      final seen = <String>{};
      final socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0, // ephemeral port
        reuseAddress: true,
      );

      // Join multicast group
      socket.joinMulticast(InternetAddress(_ssdpAddress));
      socket.broadcastEnabled = true;

      const mSearch =
          'M-SEARCH * HTTP/1.1\r\n'
          'HOST: 239.255.255.250:1900\r\n'
          'MAN: "ssdp:discover"\r\n'
          'MX: 3\r\n'
          // urn:schemas-upnp-org:device:MediaRenderer:1 covers most DLNA
          // speakers, TVs, and AV receivers.
          'ST: urn:schemas-upnp-org:device:MediaRenderer:1\r\n'
          '\r\n';

      final packet = mSearch.codeUnits;
      socket.send(packet, InternetAddress(_ssdpAddress), _ssdpPort);

      final completer = Completer<void>();
      final timer = Timer(_discoveryTimeout, () {
        if (!completer.isCompleted) completer.complete();
      });

      socket.listen((event) async {
        if (event != RawSocketEvent.read) return;
        final dg = socket.receive();
        if (dg == null) return;

        final response = String.fromCharCodes(dg.data);
        final location = _headerValue(response, 'LOCATION');
        if (location == null || seen.contains(location)) return;
        seen.add(location);

        try {
          final device = await _fetchDeviceDescription(location);
          if (device != null) {
            _devices.add(device);
            notifyListeners();
            debugPrint('UPnP: Found ${device.friendlyName}');
          }
        } catch (e) {
          debugPrint('UPnP: Error fetching device at $location: $e');
        }
      });

      await completer.future;
      timer.cancel();
      socket.close();
    } catch (e) {
      debugPrint('UPnP: Discovery error: $e');
    } finally {
      _isDiscovering = false;
      notifyListeners();
    }

    return _devices;
  }

  /// Parses the HTTP-style SSDP response to extract a named header value.
  static String? _headerValue(String response, String header) {
    final pattern = RegExp(
      '${RegExp.escape(header)}: *([^\r\n]+)',
      caseSensitive: false,
    );
    return pattern.firstMatch(response)?.group(1)?.trim();
  }

  /// Fetches the UPnP device description XML from [location] and extracts
  /// the friendly name, manufacturer, model, and AVTransport control URL.
  Future<UpnpDevice?> _fetchDeviceDescription(String location) async {
    final response = await _dio.get<String>(location);
    final xml = response.data ?? '';

    final friendlyName = _xmlText(xml, 'friendlyName') ?? 'Unknown Device';
    final manufacturer = _xmlText(xml, 'manufacturer') ?? '';
    final modelName = _xmlText(xml, 'modelName') ?? '';

    // Find the AVTransport service and its control URL
    final avTransportUrl = _extractAvTransportUrl(xml, location);
    if (avTransportUrl == null) {
      debugPrint('UPnP: No AVTransport service found at $location');
      return null;
    }

    return UpnpDevice(
      friendlyName: friendlyName,
      location: location,
      manufacturer: manufacturer,
      modelName: modelName,
      avTransportUrl: avTransportUrl,
    );
  }

  /// Extract the content of the first XML element matching [tag].
  static String? _xmlText(String xml, String tag) {
    final pattern = RegExp('<$tag>([^<]*)</$tag>', caseSensitive: false);
    return pattern.firstMatch(xml)?.group(1)?.trim();
  }

  /// Find the AVTransport service's controlURL within the device XML and
  /// build its absolute URL relative to [location].
  static String? _extractAvTransportUrl(String xml, String location) {
    // Services are listed as <service> blocks
    final servicePattern = RegExp(
      r'<service>(.*?)</service>',
      dotAll: true,
      caseSensitive: false,
    );
    for (final match in servicePattern.allMatches(xml)) {
      final serviceBlock = match.group(1) ?? '';
      final serviceType = _xmlText(serviceBlock, 'serviceType') ?? '';
      if (serviceType.toLowerCase().contains('avtransport')) {
        final controlPath = _xmlText(serviceBlock, 'controlURL');
        if (controlPath == null) continue;

        // Build absolute URL
        final base = Uri.parse(location);
        final absolute = base.resolve(controlPath).toString();
        return absolute;
      }
    }
    return null;
  }

  // --- Connection ---

  /// Connects to [device] after verifying reachability via a GetTransportInfo
  /// SOAP call. Returns `true` on success, `false` if the device is
  /// unreachable or returns a SOAP fault.
  Future<bool> connect(UpnpDevice device) async {
    try {
      // Use _soap (not _soapQuery) so HTTP errors and SOAP faults throw,
      // preventing connect() from succeeding against an unreachable/broken renderer.
      await _soap(device.avTransportUrl, 'GetTransportInfo', '');
      _connectedDevice = device;
      debugPrint('UPnP: Connected to ${device.friendlyName}');
      _startPolling();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('UPnP: Failed to connect to ${device.friendlyName}: $e');
      return false;
    }
  }

  void disconnect() {
    final device = _connectedDevice;
    debugPrint('UPnP: Disconnecting from ${device?.friendlyName}');
    _stopPolling();
    _connectedDevice = null;
    _rendererState = 'STOPPED';
    _rendererPosition = Duration.zero;
    _rendererDuration = Duration.zero;
    notifyListeners();

    // Fire-and-forget Stop so the renderer actually stops playback
    if (device != null) {
      _soap(device.avTransportUrl, 'Stop', '').then((_) {
        debugPrint('UPnP: Stop sent on disconnect');
      }).catchError((e) {
        debugPrint('UPnP: Stop on disconnect failed (ok): $e');
      });
    }
  }

  // --- Position / state polling ---

  void _startPolling() {
    _stopPolling();
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) => _poll());
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  bool _isPolling = false;

  Future<void> _poll() async {
    if (_isPolling) return; // prevent overlapping polls
    final device = _connectedDevice;
    if (device == null) return;
    _isPolling = true;

    try {
      final state = await getPlaybackState();
      if (state == null) return;

      bool changed = false;
      if (state.transportState != _rendererState) {
        _rendererState = state.transportState;
        changed = true;
      }
      if (state.position != _rendererPosition) {
        _rendererPosition = state.position;
        changed = true;
      }
      if (state.duration != _rendererDuration) {
        _rendererDuration = state.duration;
        changed = true;
      }
      if (changed) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('UPnP: poll error: $e');
    } finally {
      _isPolling = false;
    }
  }

  /// Query renderer for current transport state and position.
  Future<UpnpPlaybackState?> getPlaybackState() async {
    final device = _connectedDevice;
    if (device == null) return null;

    try {
      // GetTransportInfo for state
      final transportXml = await _soapQuery(
        device.avTransportUrl,
        'GetTransportInfo',
        '',
      );
      final state =
          _xmlText(transportXml, 'CurrentTransportState') ?? 'STOPPED';

      // GetPositionInfo for position + duration
      final posXml = await _soapQuery(
        device.avTransportUrl,
        'GetPositionInfo',
        '',
      );
      final relTime = _xmlText(posXml, 'RelTime') ?? '0:00:00';
      final trackDuration = _xmlText(posXml, 'TrackDuration') ?? '0:00:00';

      return UpnpPlaybackState(
        transportState: state,
        position: _parseTime(relTime),
        duration: _parseTime(trackDuration),
      );
    } catch (e) {
      debugPrint('UPnP: getPlaybackState error: $e');
      return null;
    }
  }

  // --- Playback control ---

  /// Load [url] on the connected renderer and start playback.
  /// Returns `true` on success. Throws on SOAP/network error so the caller
  /// can surface the failure to the user.
  Future<bool> loadAndPlay({
    required String url,
    required String title,
    required String artist,
    String? album,
    String? albumArtUrl,
    int? durationSecs,
  }) async {
    final device = _connectedDevice;
    if (device == null) {
      debugPrint('UPnP: loadAndPlay called but no device connected');
      return false;
    }

    debugPrint('UPnP: loadAndPlay → ${device.friendlyName}');
    debugPrint('UPnP:   URL: $url');
    debugPrint('UPnP:   AVTransport: ${device.avTransportUrl}');

    // Stop any current playback first — required by many Samsung TVs
    try {
      await _soap(device.avTransportUrl, 'Stop', '');
      debugPrint('UPnP: Stop OK');
    } catch (e) {
      debugPrint('UPnP: Stop failed (ignoring): $e');
    }

    // SetAVTransportURI — throws on fault or network error
    final didl = _didl(
      title: title,
      artist: artist,
      url: url,
      album: album,
      albumArtUrl: albumArtUrl,
      durationSecs: durationSecs,
    );
    debugPrint('UPnP: SetAVTransportURI…');
    await _soap(
      device.avTransportUrl,
      'SetAVTransportURI',
      '<CurrentURI>${_xmlEscapeAttr(url)}</CurrentURI>\n'
          '<CurrentURIMetaData>$didl</CurrentURIMetaData>',
    );
    debugPrint('UPnP: SetAVTransportURI OK');

    // Try Play immediately — many renderers accept it right away.
    // Only fall back to retry/backoff if the first attempt fails.
    try {
      await _soap(device.avTransportUrl, 'Play', '<Speed>1</Speed>');
      debugPrint('UPnP: Playing "$title" on ${device.friendlyName} (instant)');
      return true;
    } catch (e) {
      debugPrint('UPnP: Instant Play failed ($e), retrying with backoff…');
    }

    // Retry with backoff — renderer may need time for HTTPS pipeline setup.
    // Delays: 150 → 300 → 600 → 1200 → 2400 ms (total worst-case ~4.7s).
    const maxAttempts = 5;
    var delay = const Duration(milliseconds: 150);

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      await Future.delayed(delay);

      // Check transport state — wait if renderer reports TRANSITIONING.
      try {
        final xml = await _soapQuery(
          device.avTransportUrl,
          'GetTransportInfo',
          '',
        );
        final state = _xmlText(xml, 'CurrentTransportState') ?? '';
        if (state == 'TRANSITIONING') {
          debugPrint('UPnP: Renderer TRANSITIONING (attempt $attempt)');
          delay = delay * 2 < const Duration(milliseconds: 2400)
              ? delay * 2
              : const Duration(milliseconds: 2400);
          continue;
        }
      } catch (_) {
        // Can't query state — try Play anyway.
      }

      try {
        await _soap(device.avTransportUrl, 'Play', '<Speed>1</Speed>');
        debugPrint('UPnP: Playing "$title" on ${device.friendlyName} (attempt $attempt)');
        return true;
      } catch (e) {
        debugPrint('UPnP: Play attempt $attempt/$maxAttempts failed: $e');
        if (attempt == maxAttempts) return false;
        delay = delay * 2 < const Duration(milliseconds: 2400)
            ? delay * 2
            : const Duration(milliseconds: 2400);
      }
    }
    return false;
  }

  Future<void> pause() async {
    final device = _connectedDevice;
    if (device == null) return;
    try {
      await _soap(device.avTransportUrl, 'Pause', '');
    } catch (e) {
      debugPrint('UPnP: pause error: $e');
    }
  }

  Future<void> play() async {
    final device = _connectedDevice;
    if (device == null) return;
    try {
      await _soap(device.avTransportUrl, 'Play', '<Speed>1</Speed>');
    } catch (e) {
      debugPrint('UPnP: play error: $e');
    }
  }

  Future<void> stop() async {
    final device = _connectedDevice;
    if (device == null) return;
    try {
      await _soap(device.avTransportUrl, 'Stop', '');
    } catch (e) {
      debugPrint('UPnP: stop error: $e');
    }
  }

  Future<void> seek(Duration position) async {
    final device = _connectedDevice;
    if (device == null) return;
    try {
      final hms = _formatTime(position);
      await _soap(
        device.avTransportUrl,
        'Seek',
        '<Unit>REL_TIME</Unit><Target>$hms</Target>',
      );
    } catch (e) {
      debugPrint('UPnP: seek error: $e');
    }
  }

  // --- SOAP helpers ---

  /// Fire-and-forget SOAP action (throws on error).
  Future<void> _soap(String controlUrl, String action, String body) async {
    const serviceType = 'urn:schemas-upnp-org:service:AVTransport:1';
    final envelope =
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"'
        ' s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">\n'
        '  <s:Body>\n'
        '    <u:$action xmlns:u="$serviceType">\n'
        '      <InstanceID>0</InstanceID>\n'
        '      $body\n'
        '    </u:$action>\n'
        '  </s:Body>\n'
        '</s:Envelope>';

    debugPrint('UPnP SOAP → $action @ $controlUrl');

    final response = await _dio.post<String>(
      controlUrl,
      data: envelope,
      options: Options(
        headers: {
          'Content-Type': 'text/xml; charset="utf-8"',
          'SOAPAction': '"$serviceType#$action"',
        },
        validateStatus: (_) => true, // handle status manually
        responseType: ResponseType.plain,
      ),
    );

    final status = response.statusCode ?? 0;
    final responseBody = response.data ?? '';
    debugPrint(
      'UPnP SOAP ← $action HTTP $status | ${responseBody.length} bytes',
    );
    if (responseBody.isNotEmpty) {
      // Print up to 600 chars so we can see faults without flooding the log
      debugPrint(
        'UPnP SOAP body: ${responseBody.substring(0, responseBody.length.clamp(0, 600))}',
      );
    }

    // Detect HTTP errors
    if (status < 200 || status >= 300) {
      throw Exception('UPnP SOAP $action failed — HTTP $status: $responseBody');
    }

    // Detect SOAP faults (some TVs use 200 OK with a Fault in the body)
    final lowerBody = responseBody.toLowerCase();
    if (lowerBody.contains('<s:fault>') ||
        lowerBody.contains('<soap:fault>') ||
        lowerBody.contains('<fault>')) {
      // Try UPnP errorCode/errorDescription first, then generic faultString
      final code =
          RegExp(
            r'<errorCode>([^<]*)</errorCode>',
            caseSensitive: false,
          ).firstMatch(responseBody)?.group(1) ??
          RegExp(
            r'<faultcode>([^<]*)</faultcode>',
            caseSensitive: false,
          ).firstMatch(responseBody)?.group(1);
      final desc =
          RegExp(
            r'<errorDescription>([^<]*)</errorDescription>',
            caseSensitive: false,
          ).firstMatch(responseBody)?.group(1) ??
          RegExp(
            r'<faultstring>([^<]*)</faultstring>',
            caseSensitive: false,
          ).firstMatch(responseBody)?.group(1);
      throw Exception('UPnP SOAP fault for $action — code: $code, desc: $desc');
    }
  }

  /// SOAP query that returns the response body XML for parsing.
  Future<String> _soapQuery(
    String controlUrl,
    String action,
    String body,
  ) async {
    const serviceType = 'urn:schemas-upnp-org:service:AVTransport:1';
    final envelope =
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"'
        ' s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">\n'
        '  <s:Body>\n'
        '    <u:$action xmlns:u="$serviceType">\n'
        '      <InstanceID>0</InstanceID>\n'
        '      $body\n'
        '    </u:$action>\n'
        '  </s:Body>\n'
        '</s:Envelope>';

    final response = await _dio.post<String>(
      controlUrl,
      data: envelope,
      options: Options(
        headers: {
          'Content-Type': 'text/xml; charset="utf-8"',
          'SOAPAction': '"$serviceType#$action"',
        },
        validateStatus: (_) => true,
        responseType: ResponseType.plain,
      ),
    );

    final status = response.statusCode ?? 0;
    final responseBody = response.data ?? '';
    if (status < 200 || status >= 300) {
      throw Exception('UPnP SOAP $action failed — HTTP $status');
    }
    final lowerBody = responseBody.toLowerCase();
    if (lowerBody.contains('<s:fault>') ||
        lowerBody.contains('<soap:fault>') ||
        lowerBody.contains('<fault>')) {
      throw Exception('UPnP SOAP fault for $action');
    }
    return responseBody;
  }

  /// DIDL-Lite metadata for the renderer's Now Playing display.
  ///
  /// Returns an already-XML-escaped DIDL string, safe to embed as the text
  /// content of `<CurrentURIMetaData>` in the SOAP body.
  static String _didl({
    required String title,
    required String artist,
    required String url,
    String? album,
    String? albumArtUrl,
    int? durationSecs,
  }) {
    String esc(String s) => s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');

    // Wildcard protocolInfo — accepted by the broadest range of DLNA renderers
    // including Samsung TVs which are picky about MIME type matching.
    const protocol = 'http-get:*:*:*';

    // Format duration as HH:MM:SS for the <res> element
    final durationAttr = durationSecs != null
        ? ' duration="${_formatTimeSecs(durationSecs)}"'
        : '';

    final albumTag =
        album != null ? '<upnp:album>${esc(album)}</upnp:album>' : '';
    final artTag = albumArtUrl != null
        ? '<upnp:albumArtURI>${esc(albumArtUrl)}</upnp:albumArtURI>'
        : '';

    final didl =
        '<DIDL-Lite '
        'xmlns:dc="http://purl.org/dc/elements/1.1/" '
        'xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/" '
        'xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/">'
        '<item id="1" parentID="0" restricted="1">'
        '<dc:title>${esc(title)}</dc:title>'
        '<dc:creator>${esc(artist)}</dc:creator>'
        '<upnp:artist>${esc(artist)}</upnp:artist>'
        '$albumTag'
        '$artTag'
        '<upnp:class>object.item.audioItem.musicTrack</upnp:class>'
        '<res protocolInfo="${esc(protocol)}"$durationAttr>${esc(url)}</res>'
        '</item></DIDL-Lite>';

    // XML-escape the whole DIDL so it sits as text content of
    // <CurrentURIMetaData> in the outer SOAP envelope.
    return esc(didl);
  }

  /// XML-escapes a string for safe insertion inside an XML element or attribute.
  static String _xmlEscapeAttr(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  static String _formatTime(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  static String _formatTimeSecs(int totalSeconds) {
    final h = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  static Duration _parseTime(String hms) {
    if (hms == 'NOT_IMPLEMENTED' || hms.isEmpty) return Duration.zero;
    final parts = hms.split(':');
    if (parts.length != 3) return Duration.zero;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final s = int.tryParse(parts[2].split('.')[0]) ?? 0;
    return Duration(hours: h, minutes: m, seconds: s);
  }

  @override
  void dispose() {
    _stopPolling();
    _dio.close();
    super.dispose();
  }
}
