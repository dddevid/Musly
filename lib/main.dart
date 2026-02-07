import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:dotlottie_loader/dotlottie_loader.dart';
import 'dart:io';
import 'package:window_manager/window_manager.dart';

import 'services/services.dart';
import 'services/bpm_analyzer_service.dart';
import 'services/offline_service.dart';
import 'services/transcoding_service.dart';
import 'services/local_music_service.dart';
import 'services/cast_service.dart';
import 'providers/providers.dart';
import 'screens/screens.dart';
import 'theme/theme.dart';
import 'utils/image_cache.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions();
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  ImageCacheConfig.configure();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  final storageService = StorageService();
  final subsonicService = SubsonicService();
  final bpmAnalyzer = BpmAnalyzerService();
  final offlineService = OfflineService();
  final recommendationService = RecommendationService();
  final localMusicService = LocalMusicService();
  final castService = CastService();

  bpmAnalyzer.initialize().catchError((e) {
    debugPrint('Failed to initialize BPM analyzer: $e');
  });
  offlineService.initialize().catchError((e) {
    debugPrint('Failed to initialize offline service: $e');
  });
  recommendationService.initialize().catchError((e) {
    debugPrint('Failed to initialize recommendation service: $e');
  });
  localMusicService.initialize().catchError((e) {
    debugPrint('Failed to initialize local music service: $e');
  });

  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storageService),
        Provider<SubsonicService>.value(value: subsonicService),
        ChangeNotifierProvider<RecommendationService>.value(
          value: recommendationService,
        ),
        ChangeNotifierProvider<TranscodingService>(
          create: (_) => TranscodingService(),
        ),
        ChangeNotifierProvider<LocalMusicService>.value(
          value: localMusicService,
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(subsonicService, storageService),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(subsonicService, storageService),
        ),
        ChangeNotifierProvider<CastService>.value(value: castService),
        ChangeNotifierProvider(
          create: (_) =>
              PlayerProvider(subsonicService, storageService, castService),
        ),
        ChangeNotifierProvider(create: (_) => LibraryProvider(subsonicService)),
      ],
      child: const MuslyApp(),
    ),
  );
}

class MuslyApp extends StatelessWidget {
  const MuslyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Musly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  AuthState? _previousAuthState;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AuthProvider>(context);
    final currentState = authProvider.state;

    _previousAuthState = currentState;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    switch (authProvider.state) {
      case AuthState.unknown:
      case AuthState.authenticating:
        return Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: DotLottieLoader.fromNetwork(
              'https://lottie.host/6e9f4052-df21-4dc1-be37-88b062099640/TMV5YZRCbo.lottie',
              frameBuilder: (BuildContext context, DotLottie? dotlottie) {
                if (dotlottie != null) {
                  return Lottie.memory(
                    dotlottie.animations.values.single,
                    width: 250,
                    height: 250,
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          ),
        );
      case AuthState.authenticated:
        return const MainScreen();
      case AuthState.offlineMode:
        // Show MainScreen but with a banner indicating offline mode
        return const MainScreen(isOfflineMode: true);
      case AuthState.unauthenticated:
      case AuthState.error:
        return const LoginScreen();
    }
  }
}
