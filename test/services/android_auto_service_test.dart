import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musly/models/models.dart';
import 'package:musly/services/android_auto_service.dart';
import 'package:musly/services/offline_service.dart';
import 'package:musly/services/subsonic_service.dart';
import 'package:audio_service/audio_service.dart';

class MockSubsonicService extends Mock implements SubsonicService {}
class MockOfflineService extends Mock implements OfflineService {}
class MockPlayerDelegate extends Mock implements AndroidAutoDelegate {}
class MockLibraryDelegate extends Mock implements AndroidAutoLibraryDelegate {}

void main() {
  late MockSubsonicService mockSubsonic;
  late MockOfflineService mockOffline;
  late MockPlayerDelegate mockPlayer;
  late MockLibraryDelegate mockLibrary;
  late AndroidAutoService service;

  setUp(() {
    mockSubsonic = MockSubsonicService();
    mockOffline = MockOfflineService();
    mockPlayer = MockPlayerDelegate();
    mockLibrary = MockLibraryDelegate();

    when(() => mockSubsonic.isYoutube).thenReturn(false);
    when(() => mockOffline.isOfflineMode).thenReturn(false);

    service = AndroidAutoService(
      subsonicService: mockSubsonic,
      offlineService: mockOffline,
    );
    service.setPlayerDelegate(mockPlayer);
    service.setLibraryDelegate(mockLibrary);
  });

  group('getChildren root', () {
    test('returns standard root items when not playing and no queue', () async {
      when(() => mockPlayer.currentSong).thenReturn(null);
      when(() => mockPlayer.queue).thenReturn([]);

      final items = await service.getChildren(AudioService.browsableRootId);
      
      expect(items.length, 9); // Recent, Favorites, Albums, Artists, Playlists, Genres, Radio, Downloads, Shuffle
      expect(items.map((e) => e.id), containsAll([
        'AUTO_RECENT', 'AUTO_FAVORITES', 'AUTO_ALBUMS', 'AUTO_ARTISTS',
        'AUTO_PLAYLISTS', 'AUTO_GENRES', 'AUTO_RADIO', 'AUTO_DOWNLOADS', 'AUTO_SHUFFLE'
      ]));
    });

    test('includes Now Playing and Queue when active', () async {
      final song = Song(id: '1', title: 'Test', artist: 'Artist');
      when(() => mockPlayer.currentSong).thenReturn(song);
      when(() => mockPlayer.queue).thenReturn([song]);

      final items = await service.getChildren(AudioService.browsableRootId);
      
      expect(items.length, 11);
      expect(items.map((e) => e.id), contains(AudioService.recentRootId)); // Now Playing
      expect(items.map((e) => e.id), contains('AUTO_QUEUE'));
    });
  });

  group('getChildren categories', () {
    test('recent items uses cachedAllSongs', () async {
      when(() => mockLibrary.isInitialized).thenReturn(true);
      when(() => mockLibrary.isServerOfflineMode).thenReturn(false);
      when(() => mockLibrary.cachedAllSongs).thenReturn([
        Song(id: '1', title: 'Song 1', artist: 'Artist A'),
        Song(id: '2', title: 'Song 2', artist: 'Artist B'),
      ]);

      final items = await service.getChildren('AUTO_RECENT');
      expect(items.length, 2);
      expect(items[0].title, 'Song 1');
      expect(items[0].id, 'auto_song_1');
    });

    test('albums items uses cachedAllAlbums', () async {
      when(() => mockLibrary.isInitialized).thenReturn(true);
      when(() => mockLibrary.isServerOfflineMode).thenReturn(false);
      when(() => mockLibrary.cachedAllAlbums).thenReturn([
        Album(id: 'a1', name: 'Album 1', artist: 'Artist A'),
      ]);
      when(() => mockSubsonic.getCoverArtUrl(any(), size: any(named: 'size'))).thenReturn('http://test.com/art');

      final items = await service.getChildren('AUTO_ALBUMS');
      expect(items.length, 1);
      expect(items[0].title, 'Album 1');
      expect(items[0].id, 'auto_album_a1');
    });
  });

  group('playback actions', () {
    test('playFromMediaId handles shuffle', () async {
      when(() => mockPlayer.shuffleLibrary()).thenAnswer((_) => Future.value());
      
      await service.playFromMediaId('AUTO_SHUFFLE');
      
      verify(() => mockPlayer.shuffleLibrary()).called(1);
    });

    test('playFromSearch plays found song', () async {
      when(() => mockLibrary.isInitialized).thenReturn(true);
      when(() => mockLibrary.isServerOfflineMode).thenReturn(false);
      
      final song = Song(id: 's1', title: 'Search Hit');
      when(() => mockLibrary.search('test query')).thenAnswer(
        (_) => Future.value(SearchResult(songs: [song], albums: [], artists: []))
      );
      when(() => mockLibrary.cachedAllSongs).thenReturn([song]);
      when(() => mockPlayer.playSong(song, playlist: [song], startIndex: 0)).thenAnswer((_) => Future.value());

      await service.playFromSearch('test query');

      verify(() => mockPlayer.playSong(song, playlist: [song], startIndex: 0)).called(1);
    });
  });
}
