import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:musly/providers/providers.dart';
import 'package:musly/services/services.dart';

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

  return MultiProvider(
    providers: [
      Provider<SubsonicService>.value(value: service),
      Provider<StorageService>.value(value: storage),
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => authProvider ?? AuthProvider(service, storage),
      ),
      ChangeNotifierProvider<PlayerProvider>(
        create: (_) => playerProvider ?? PlayerProvider(service),
      ),
      ChangeNotifierProvider<LibraryProvider>(
        create: (_) => libraryProvider ?? LibraryProvider(service),
      ),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
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