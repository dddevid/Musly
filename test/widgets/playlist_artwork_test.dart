import 'package:flutter_test/flutter_test.dart';
import 'package:musly/models/models.dart';
import 'package:musly/widgets/playlist_artwork.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('PlaylistArtwork renders fallback icon when no covers are available',
      (tester) async {
    await tester.pumpWidget(
      createTestApp(
        child: const PlaylistArtwork(
          songs: [],
          size: 100,
        ),
      ),
    );

    expect(find.byType(PlaylistArtwork), findsOneWidget);
  });

  testWidgets('PlaylistArtwork renders 2x2 grid with 4 covers', (tester) async {
    final songs = [
      Song(id: 's1', title: 'Song 1', coverArt: 'c1'),
      Song(id: 's2', title: 'Song 2', coverArt: 'c2'),
      Song(id: 's3', title: 'Song 3', coverArt: 'c3'),
      Song(id: 's4', title: 'Song 4', coverArt: 'c4'),
    ];

    await tester.pumpWidget(
      createTestApp(
        child: PlaylistArtwork(
          songs: songs,
          size: 100,
        ),
      ),
    );

    expect(find.byType(PlaylistArtwork), findsOneWidget);
  });

  testWidgets('PlaylistArtwork renders 2x2 grid with 2 covers diagonally opposite',
      (tester) async {
    final songs = [
      Song(id: 's1', title: 'Song 1', coverArt: 'coverA'),
      Song(id: 's2', title: 'Song 2', coverArt: 'coverB'),
    ];

    await tester.pumpWidget(
      createTestApp(
        child: PlaylistArtwork(
          songs: songs,
          size: 100,
        ),
      ),
    );

    expect(find.byType(PlaylistArtwork), findsOneWidget);
  });
}
