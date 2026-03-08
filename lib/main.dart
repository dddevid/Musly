import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:window_manager/window_manager.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';

import 'l10n/app_localizations.dart';
import 'services/services.dart';
import 'services/transcoding_service.dart';
import 'services/local_music_service.dart';
import 'providers/providers.dart';
import 'screens/screens.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'theme/theme.dart';
import 'utils/image_cache.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  JustAudioMediaKit.ensureInitialized(linux: true, windows: false);

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
  final offlineService = OfflineService();
  final recommendationService = RecommendationService();
  final localMusicService = LocalMusicService();
  final castService = CastService();
  final localeService = LocaleService();
  final upnpService = UpnpService();
  final jukeboxService = JukeboxService();
  final themeService = ThemeService();

  BpmAnalyzerService().initialize().catchError((e) {
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
  localeService.loadSavedLocale().catchError((e) {
    debugPrint('Failed to load saved locale: $e');
  });
  await themeService.initialize().catchError((e) {
    debugPrint('Failed to initialize theme service: $e');
  });
  jukeboxService.initialize().catchError((e) {
    debugPrint('Failed to initialize jukebox service: $e');
  });
  
  try {
    await PlayerUiSettingsService().initialize();
  } catch (e) {
    debugPrint('Failed to initialize player UI settings: $e');
  }

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
        ChangeNotifierProvider<CastService>.value(value: castService),
        ChangeNotifierProvider<LocaleService>.value(value: localeService),
        ChangeNotifierProvider<ThemeService>.value(value: themeService),
        ChangeNotifierProvider<UpnpService>.value(value: upnpService),
        ChangeNotifierProvider<JukeboxService>.value(value: jukeboxService),
        ChangeNotifierProvider(
          create: (_) => PlayerProvider(
            subsonicService,
            storageService,
            castService,
            upnpService,
          ),
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
    final localeService = Provider.of<LocaleService>(context);
    final themeService = Provider.of<ThemeService>(context);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final accent = themeService.accentColor.color;

        final ThemeData light;
        final ThemeData dark;

        if (lightDynamic != null && darkDynamic != null) {
          
          final harmonisedLight = lightDynamic.harmonized();
          final harmonisedDark = darkDynamic.harmonized();
          light = AppTheme.lightThemeFromScheme(harmonisedLight);
          dark = AppTheme.darkThemeFromScheme(harmonisedDark);
        } else {
          light = AppTheme.lightThemeWith(accent);
          dark = AppTheme.darkThemeWith(accent);
        }

        return MaterialApp(
          title: 'Musly',
          debugShowCheckedModeBanner: false,
          theme: light,
          darkTheme: dark,
          themeMode: themeService.themeMode,

          locale: localeService.currentLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,

          home: const AuthWrapper(),
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    switch (authProvider.state) {
      case AuthState.unknown:
        return Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: const CircularProgressIndicator(),
          ),
        );
      case AuthState.authenticated:
        return const MainScreen();
      case AuthState.offlineMode:
        
        return const MainScreen(isOfflineMode: true);
      case AuthState.serverUnreachable:
        return _ServerUnreachableScreen(
          hasOfflineContent: authProvider.hasOfflineContent,
          onEnterOfflineMode: () => authProvider.enterOfflineMode(),
          onDisconnect: () => authProvider.disconnect(),
        );      case AuthState.authenticating:
        return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthState.unauthenticated:
      case AuthState.error:
        return const LoginScreen();
    }
  }
}

class _ServerUnreachableScreen extends StatelessWidget {
  final bool hasOfflineContent;
  final VoidCallback onEnterOfflineMode;
  final VoidCallback onDisconnect;

  const _ServerUnreachableScreen({
    required this.hasOfflineContent,
    required this.onEnterOfflineMode,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 72, color: Colors.grey),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)!.serverUnreachableTitle,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.serverUnreachableSubtitle,
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => authProvider.retryConnection(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ),
              const SizedBox(height: 12),
              if (hasOfflineContent) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onEnterOfflineMode,
                    icon: const Icon(Icons.offline_pin_rounded),
                    label: Text(AppLocalizations.of(context)!.openOfflineMode),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onDisconnect,
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(AppLocalizations.of(context)!.disconnect),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
