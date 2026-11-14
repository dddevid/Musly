import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musly/widgets/now_playing/music_visualizer_view.dart';
import 'package:musly/services/player_ui_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../bootstrap.dart';

void main() {
  initializeTestEnvironment();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await PlayerUiSettingsService().initialize();
  });

  group('MusicVisualizer Tests', () {
    testWidgets('MusicVisualizerView renders bars style without error', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MusicVisualizerView(
              isPlaying: true,
              style: 'bars',
              colorMode: 'artwork',
              paletteColors: [Colors.purple, Colors.blue],
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(MusicVisualizerView), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('MusicVisualizerView renders wave style without error', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MusicVisualizerView(
              isPlaying: false,
              style: 'wave',
              colorMode: 'rainbow',
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(MusicVisualizerView), findsOneWidget);
    });

    testWidgets('MusicVisualizerView renders circle style without error', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MusicVisualizerView(
              isPlaying: true,
              style: 'circle',
              colorMode: 'accent',
              accentColor: Colors.teal,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(MusicVisualizerView), findsOneWidget);
    });

    test('PlayerUiSettingsService persists visualizer settings', () async {
      final settings = PlayerUiSettingsService();
      await settings.setVisualizerEnabled(true);
      expect(settings.getVisualizerEnabled(), true);

      await settings.setVisualizerStyle('wave');
      expect(settings.getVisualizerStyle(), 'wave');

      await settings.setVisualizerColorMode('rainbow');
      expect(settings.getVisualizerColorMode(), 'rainbow');

      // reset
      await settings.setVisualizerEnabled(false);
      await settings.setVisualizerStyle('bars');
      await settings.setVisualizerColorMode('artwork');
    });
  });
}
