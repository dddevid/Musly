import 'package:flutter/material.dart';
import 'package:musly/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:musly/providers/providers.dart';
import 'package:musly/services/services.dart';
import 'package:musly/services/audio_handler.dart';
import 'package:musly/services/transcoding_service.dart';

class FakeCastService extends CastService {
  bool _mockConnected = false;
  CastMediaState _mockMediaState = CastMediaState();

  @override
  bool get isConnected => _mockConnected;

  void setMockConnected(bool value) {
    _mockConnected = value;
    notifyListeners();
  }

  void setMockMediaState(CastMediaState state) {
    _mockMediaState = state;
    notifyListeners();
  }

  @override
  CastMediaState get mediaState => _mockMediaState;

  @override
  Future<bool> loadMedia({
    required String url,
    required String title,
    required String artist,
    required String imageUrl,
    String? albumName,
    int? trackNumber,
    Duration? duration,
    Duration playPosition = Duration.zero,
    String? contentType,
    bool autoPlay = true,
  }) async {
    _mockMediaState = _mockMediaState.copyWith(
      title: title,
      artist: artist,
      imageUrl: imageUrl,
      duration: duration ?? Duration.zero,
      isPlaying: autoPlay,
      position: playPosition,
    );
    notifyListeners();
    return true;
  }

  @override
  Future<void> play() async {
    _mockMediaState = _mockMediaState.copyWith(isPlaying: true);
    notifyListeners();
  }

  @override
  Future<void> pause() async {
    _mockMediaState = _mockMediaState.copyWith(isPlaying: false);
    notifyListeners();
  }

  @override
  Future<void> stop() async {
    _mockMediaState = CastMediaState();
    notifyListeners();
  }

  @override
  Future<void> seek(Duration position) async {
    _mockMediaState = _mockMediaState.copyWith(position: position);
    notifyListeners();
  }
}

Widget createTestApp({
  required Widget child,
  SubsonicService? subsonicService,
  StorageService? storageService,
  PlayerProvider? playerProvider,
  LibraryProvider? libraryProvider,
  AuthProvider? authProvider,
}) {
  final service = subsonicService ?? SubsonicService();
  final storage = storageService ?? StorageService();

  final cast = FakeCastService();

  return MultiProvider(
    providers: [
      Provider<SubsonicService>.value(value: service),
      Provider<StorageService>.value(value: storage),
      ChangeNotifierProvider<CastService>.value(value: cast),
      ChangeNotifierProvider<UpnpService>.value(value: UpnpService()),
      ChangeNotifierProvider<JukeboxService>.value(value: JukeboxService()),
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => authProvider ?? AuthProvider(service, storage),
      ),
      ChangeNotifierProvider<PlayerProvider>(
        create: (_) =>
            playerProvider ??
            PlayerProvider(service, storage, cast, UpnpService(),
                MuslyAudioHandler(), JukeboxService(), TranscodingService()),
      ),
      ChangeNotifierProvider<LibraryProvider>(
        create: (_) => libraryProvider ?? LibraryProvider(service, MuslyAudioHandler()),
      ),
      ChangeNotifierProvider<TranscodingService>(
          create: (_) => TranscodingService()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

List<dynamic> createTestSongJsonList(int count) {
  return List.generate(
    count,
    (index) => {
      'id': 'song_${index + 1}',
      'title': 'Song ${index + 1}',
      'artist': 'Artist ${(index % 3) + 1}',
      'album': 'Album ${(index % 5) + 1}',
      'duration': 180 + (index * 10),
      'track': index + 1,
    },
  );
}

List<dynamic> createTestAlbumJsonList(int count) {
  return List.generate(
    count,
    (index) => {
      'id': 'album_${index + 1}',
      'name': 'Album ${index + 1}',
      'artist': 'Artist ${(index % 3) + 1}',
      'songCount': 10 + (index % 5),
      'duration': 3600 + (index * 100),
      'year': 2020 + (index % 4),
    },
  );
}

List<dynamic> createTestArtistJsonList(int count) {
  return List.generate(
    count,
    (index) => {
      'id': 'artist_${index + 1}',
      'name': 'Artist ${index + 1}',
      'albumCount': 5 + (index % 10),
    },
  );
}
