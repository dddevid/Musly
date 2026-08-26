import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:async';
import 'package:window_manager/window_manager.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:safe_device/safe_device.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

import 'l10n/app_localizations.dart';
import 'models/server_config.dart';
import 'services/services.dart';
import 'services/audio_handler.dart';
import 'services/transcoding_service.dart';
import 'services/local_music_service.dart';
import 'services/analytics_service.dart';
import 'services/favorite_playlists_service.dart';

import 'services/tv_detection_service.dart';

import 'package:musly/widgets/dialogs/privacy_policy_dialog.dart';
import 'package:musly/widgets/dialogs/milestone_celebration_dialog.dart';
import 'widgets/navigation/tv_remote_scope.dart';
import 'providers/providers.dart';
import 'screens/screens.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'theme/theme.dart';
import 'utils/image_cache.dart';

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

Future<void> _showPrivacyPolicyIfNeeded() async {
  if (await PrivacyPolicyDialog.shouldShow()) {
    await Future.delayed(const Duration(milliseconds: 300));
    if (navigatorKey.currentContext != null) {
      final result = await showDialog<bool>(
        context: navigatorKey.currentContext!,
        builder: (context) => const PrivacyPolicyDialog(),
        barrierDismissible: false,
      );

      if (result == false) {
        exit(0);
      } else {
        await PrivacyPolicyDialog.markAccepted();
      }
    }
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<bool> _isRunningOnEmulator() async {
  if (kDebugMode) return false;
  if (kIsWeb) return false;
  if (!Platform.isAndroid && !Platform.isIOS) return false;

  return !(await SafeDevice.isRealDevice);
}

class _EmulatorWarningScreen extends StatelessWidget {
  const _EmulatorWarningScreen();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context)!;
          return Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.block_rounded,
                      size: 80,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      l10n.emulatorDetected,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.emulatorNotAllowed,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    FilledButton.icon(
                      onPressed: () {
                        exit(0);
                      },
                      icon: const Icon(Icons.exit_to_app),
                      label: Text(
                        AppLocalizations.of(context)?.exitApp ?? 'Exit App',
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(200, 50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final isEmulator = await _isRunningOnEmulator();
  if (isEmulator) {
    runApp(const _EmulatorWarningScreen());
    return;
  }

  if (!kIsWeb && Platform.isAndroid) {
    try {
      await FlutterDisplayMode.setHighRefreshRate();
    } catch (e) {
      debugPrint('Error enabling high refresh rate: $e');
    }
  }

  JustAudioMediaKit.ensureInitialized(linux: true, windows: false);

  final storageService = StorageService();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    final hideTitlebar = await storageService.getHideWindowTitlebar();
    const windowOptions = WindowOptions(
      size: Size(1100, 750),
      minimumSize: Size(800, 560),
      center: true,
      titleBarStyle: TitleBarStyle.normal,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setMinimumSize(const Size(800, 560));
      if (hideTitlebar) {
        await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
      }
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

  FavoritePlaylistsService().initialize().catchError((e) {
    debugPrint('Failed to initialize favorite playlists service: $e');
  });

  PlaylistCoverService().init().catchError((e) {
    debugPrint('Failed to initialize playlist cover service: $e');
  });

  final analyticsService = AnalyticsService();
  analyticsService.initialize().catchError((e) {
    debugPrint('Failed to initialize analytics: $e');
  });

  try {
    await PlayerUiSettingsService().initialize();
  } catch (e) {
    debugPrint('Failed to initialize player UI settings: $e');
  }

  final audioHandler = await initAudioService();

  final transcodingService = TranscodingService();

  final authProvider = AuthProvider(subsonicService, storageService);
  final playerProvider = PlayerProvider(
    subsonicService,
    storageService,
    castService,
    upnpService,
    audioHandler,
    jukeboxService,
    transcodingService,
  );
  final libraryProvider = LibraryProvider(subsonicService, audioHandler);
  playerProvider.setLibraryProvider(libraryProvider);

  playerProvider.onMilestone50Triggered = () {
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      MilestoneCelebrationDialog.show(
        ctx,
        onResume: () => playerProvider.play(),
      );
    }
  };

  final tvDetectionService = TvDetectionService();
  await tvDetectionService.initialize();

  final Widget appWithProviders = MultiProvider(
    providers: [
      Provider<StorageService>.value(value: storageService),
      Provider<SubsonicService>.value(value: subsonicService),
      ChangeNotifierProvider<RecommendationService>.value(
        value: recommendationService,
      ),
      ChangeNotifierProvider<TranscodingService>.value(
        value: transcodingService,
      ),
      ChangeNotifierProvider<LocalMusicService>.value(value: localMusicService),
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ChangeNotifierProvider<CastService>.value(value: castService),
      ChangeNotifierProvider<LocaleService>.value(value: localeService),
      ChangeNotifierProvider<ThemeService>.value(value: themeService),
      ChangeNotifierProvider<UpnpService>.value(value: upnpService),
      ChangeNotifierProvider<JukeboxService>.value(value: jukeboxService),
      ChangeNotifierProvider<TvDetectionService>.value(
          value: tvDetectionService),
      ChangeNotifierProvider<PlayerProvider>.value(value: playerProvider),
      ChangeNotifierProvider<LibraryProvider>.value(value: libraryProvider),
    ],
    child: const MuslyApp(),
  );

  runApp(appWithProviders);
}

class MuslyApp extends StatelessWidget {
  const MuslyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeService = Provider.of<LocaleService>(context);
    final themeService = Provider.of<ThemeService>(context);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final ThemeData light;
        final ThemeData dark;

        if (themeService.accentColor.isDynamic) {
          if (lightDynamic != null && darkDynamic != null) {
            light = AppTheme.lightThemeFromScheme(lightDynamic.harmonized());
            dark = AppTheme.darkThemeFromScheme(darkDynamic.harmonized());
          } else {
            final fallbackAccent = themeService.accentColor.color;
            light = AppTheme.lightThemeWith(fallbackAccent);
            dark = AppTheme.darkThemeWith(fallbackAccent);
          }
        } else {
          final accent = themeService.accentColor.color;
          if (lightDynamic != null && darkDynamic != null) {
            final harmonisedLight = lightDynamic.harmonized().copyWith(
                  primary: accent,
                  secondary: accent.withAlpha(200),
                );
            final harmonisedDark = darkDynamic.harmonized().copyWith(
                  primary: accent,
                  secondary: accent.withAlpha(200),
                );
            light = AppTheme.lightThemeFromScheme(harmonisedLight);
            dark = AppTheme.darkThemeFromScheme(harmonisedDark);
          } else {
            light = AppTheme.lightThemeWith(accent);
            dark = AppTheme.darkThemeWith(accent);
          }
        }

        return MaterialApp(
          title: 'Musly',
          debugShowCheckedModeBanner: false,
          theme: light,
          darkTheme: dark,
          themeMode: themeService.themeMode,
          scrollBehavior: AppScrollBehavior(),
          navigatorKey: navigatorKey,
          locale: localeService.currentLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) =>
              TvRemoteScope(child: child ?? const SizedBox.shrink()),
          home: const AuthWrapper(),
          navigatorObservers: [AnalyticsNavigatorObserver()],
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

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  bool _checkedOnboarding = false;
  bool _onboardingCompleted = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkOnboarding();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      try {
        Provider.of<PlayerProvider>(context, listen: false)
            .checkPending50Milestone();
      } catch (_) {}
    }
  }

  Future<void> _checkOnboarding() async {
    TvDetectionService? tvService;
    try {
      tvService = Provider.of<TvDetectionService>(context, listen: false);
    } catch (_) {}
    if (tvService?.isTvMode == true) {
      await StorageService().setOnboardingCompleted(true);
      if (mounted) {
        setState(() {
          _onboardingCompleted = true;
          _checkedOnboarding = true;
        });
      }
      return;
    }

    final completed = await StorageService().isOnboardingCompleted();
    if (mounted) {
      setState(() {
        _onboardingCompleted = completed;
        _checkedOnboarding = true;
      });
    }
  }

  void _finishOnboarding() {
    setState(() {
      _onboardingCompleted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    switch (authProvider.state) {
      case AuthState.unknown:
        return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthState.authenticated:
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await _showPrivacyPolicyIfNeeded();
        });
        return const MainScreen();
      case AuthState.offlineMode:
        return const MainScreen(isOfflineMode: true);
      case AuthState.serverUnreachable:
        return _ServerUnreachableScreen(
          hasOfflineContent: authProvider.hasOfflineContent,
          onEnterOfflineMode: () => authProvider.enterOfflineMode(),
          onDisconnect: () => authProvider.disconnect(),
        );
      case AuthState.authenticating:
        if (authProvider.config == null) {
          if (!_checkedOnboarding) {
            return const Scaffold(
              backgroundColor: Color(0xFF090A0E),
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (!_onboardingCompleted) {
            return OnboardingScreen(onFinished: _finishOnboarding);
          }
          return const LoginScreen();
        }
        return _AuthenticatingScreen(
          hasOfflineContent: authProvider.hasOfflineContent,
          onEnterOfflineMode: () => authProvider.enterOfflineMode(),
        );
      case AuthState.unauthenticated:
      case AuthState.error:
        if (!_checkedOnboarding) {
          return const Scaffold(
            backgroundColor: Color(0xFF090A0E),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!_onboardingCompleted) {
          return OnboardingScreen(onFinished: _finishOnboarding);
        }
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
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
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
                  label: Text(
                    AppLocalizations.of(context)?.retry ?? 'Retry',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildSwitchProfileButton(context),
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

  Widget _buildSwitchProfileButton(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<List<ServerConfig>>(
      future: authProvider.getSavedProfiles(),
      builder: (context, snapshot) {
        final profiles = snapshot.data ?? [];
        if (profiles.isEmpty) return const SizedBox.shrink();

        final currentConfig = authProvider.config;
        final otherProfiles = profiles
            .where(
              (p) =>
                  p.serverUrl != currentConfig?.serverUrl ||
                  p.username != currentConfig?.username,
            )
            .toList();

        if (otherProfiles.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showSwitchProfileDialog(context, otherProfiles),
            icon: const Icon(Icons.swap_horiz_rounded),
            label: Text(l10n.switchServer),
          ),
        );
      },
    );
  }

  void _showSwitchProfileDialog(
      BuildContext context, List<ServerConfig> profiles) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).brightness == Brightness.dark
                ? AppTheme.darkSurface
                : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).brightness == Brightness.dark
                        ? AppTheme.darkDivider
                        : AppTheme.lightDivider,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.switchServer,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...profiles.map((profile) {
                  final label = profile.name?.isNotEmpty == true
                      ? profile.name!
                      : '${profile.username}@${Uri.tryParse(profile.serverUrl)?.host ?? profile.serverUrl}';
                  return ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(label),
                    subtitle: Text(profile.serverUrl,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await authProvider.switchProfile(profile);
                    },
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthenticatingScreen extends StatefulWidget {
  final bool hasOfflineContent;
  final VoidCallback onEnterOfflineMode;

  const _AuthenticatingScreen({
    required this.hasOfflineContent,
    required this.onEnterOfflineMode,
  });

  @override
  State<_AuthenticatingScreen> createState() => _AuthenticatingScreenState();
}

class _AuthenticatingScreenState extends State<_AuthenticatingScreen> {
  bool _showSlowWarning = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showSlowWarning = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            if (_showSlowWarning) ...[
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  'La connessione ci sta mettendo un po\'...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (widget.hasOfflineContent) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: widget.onEnterOfflineMode,
                  icon: const Icon(Icons.offline_pin_rounded),
                  label: Text(
                    AppLocalizations.of(context)?.offlineModeQuestion ??
                        'Offline mode?',
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
