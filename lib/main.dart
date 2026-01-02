import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:dotlottie_loader/dotlottie_loader.dart';

import 'services/services.dart';
import 'services/bpm_analyzer_service.dart';
import 'services/offline_service.dart';
import 'providers/providers.dart';
import 'screens/screens.dart';
import 'theme/theme.dart';
import 'utils/image_cache.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  bpmAnalyzer.initialize().catchError((e) {
    debugPrint('Failed to initialize BPM analyzer: $e');
  });
  offlineService.initialize().catchError((e) {
    debugPrint('Failed to initialize offline service: $e');
  });

  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storageService),
        Provider<SubsonicService>.value(value: subsonicService),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(subsonicService, storageService),
        ),
        ChangeNotifierProvider(create: (_) => PlayerProvider(subsonicService)),
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

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

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
      case AuthState.unauthenticated:
      case AuthState.error:
        return const LoginScreen();
    }
  }
}
