import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/providers.dart';
import '../providers/auth_provider.dart';
import '../services/local_music_service.dart';
import '../services/recommendation_service.dart';
import '../services/update_service.dart';
import '../utils/navigation_helper.dart';
import '../widgets/widgets.dart';
import '../l10n/app_localizations.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'search_screen.dart';
import 'now_playing_screen.dart';

class MainScreen extends StatefulWidget {
  final bool isOfflineMode;

  const MainScreen({super.key, this.isOfflineMode = false});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    LibraryScreen(),
    SearchScreen(),
  ];

  @override
  void initState() {
    super.initState();

    NavigationHelper.registerTabChangeCallback((index) {
      setState(() => _currentIndex = index);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final libraryProvider = Provider.of<LibraryProvider>(
        context,
        listen: false,
      );
      final playerProvider = Provider.of<PlayerProvider>(
        context,
        listen: false,
      );
      final recommendationService = Provider.of<RecommendationService>(
        context,
        listen: false,
      );

      playerProvider.setLibraryProvider(libraryProvider);
      playerProvider.setRecommendationService(recommendationService);

      if (authProvider.isLocalOnlyMode) {
        final localMusicService = Provider.of<LocalMusicService>(
          context,
          listen: false,
        );
        // Wire service first (sets up listener + resets _isInitialized)
        libraryProvider.setLocalMusicService(localMusicService);

        if (localMusicService.isEmpty && !localMusicService.isScanning) {
          // No songs yet – trigger a fresh scan (listener will reload library)
          localMusicService.scanForMusic();
        } else if (!localMusicService.isScanning) {
          // Songs already loaded from the login screen scan – initialize immediately
          libraryProvider.initialize();
        }
        // If scanning is in progress, the listener on LocalMusicService
        // (_onLocalMusicServiceChanged) will fire when done and populate the library.
      } else {
        libraryProvider.initialize();
      }

      // Check for updates after a short delay so the UI is fully settled
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _checkForUpdate();
      });
    });
  }

  Future<void> _checkForUpdate() async {
    final release = await UpdateService.checkForUpdate();
    if (release == null || !mounted) return;
    _showUpdateDialog(release);
  }

  void _showUpdateDialog(ReleaseInfo release) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final changelog = UpdateService.stripMarkdown(release.body);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C5CE7), Color(0xFF00B4D8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      CupertinoIcons.arrow_up_circle_fill,
                      color: Colors.white,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.updateAvailable,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.updateAvailableSubtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _VersionBadge(
                          label: l10n.updateCurrentVersion(
                            UpdateService.currentVersion,
                          ),
                          color: Colors.white24,
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          CupertinoIcons.arrow_right,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        _VersionBadge(
                          label: l10n.updateLatestVersion(release.version),
                          color: Colors.white.withValues(alpha: 0.3),
                          bold: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Changelog
              if (changelog.isNotEmpty)
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.whatsNew,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white54 : Colors.black45,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Flexible(
                          child: Scrollbar(
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              child: Text(
                                changelog,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(l10n.remindLater),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          final uri = Uri.parse(release.htmlUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        icon: const Icon(
                          CupertinoIcons.cloud_download,
                          size: 18,
                        ),
                        label: Text(l10n.downloadUpdate),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: const Color(0xFF6C5CE7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openNowPlaying() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder: (context, animation, secondaryAnimation) {
          return const NowPlayingScreen();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  bool get _isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isLocalMode = authProvider.isLocalOnlyMode;

    if (_isDesktop) {
      return Scaffold(
        body: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  DesktopNavigationSidebar(
                    selectedIndex: _currentIndex,
                    onDestinationSelected: (index) {
                      setState(() => _currentIndex = index);
                      NavigationHelper.desktopNavigatorKey.currentState
                          ?.popUntil((route) => route.isFirst);
                    },
                    navigatorKey: NavigationHelper.desktopNavigatorKey,
                  ),
                  const VerticalDivider(width: 1, thickness: 1),
                  Expanded(
                    child: Navigator(
                      key: NavigationHelper.desktopNavigatorKey,
                      onGenerateRoute: (settings) {
                        return PageRouteBuilder(
                          pageBuilder: (_, __, ___) => IndexedStack(
                            index: _currentIndex,
                            children: _screens,
                          ),
                          transitionsBuilder: (_, animation, __, child) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Selector<PlayerProvider, bool>(
              selector: (_, p) => p.currentSong != null || p.isPlayingRadio,
              builder: (context, hasCurrentSong, _) {
                return hasCurrentSong
                    ? DesktopPlayerBar(
                        navigatorKey: NavigationHelper.desktopNavigatorKey,
                      )
                    : const SizedBox.shrink();
              },
            ),
          ],
        ),
      );
    }

    // Mobile layout with nested navigator for persistent bottom bar
    return Selector<PlayerProvider, bool>(
      selector: (_, p) => p.currentSong != null || p.isPlayingRadio,
      builder: (context, hasCurrentSong, _) {
        final bottomBarHeight = hasCurrentSong ? 64.0 + 83.0 : 83.0;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _handleBackButton();
          },
          child: Scaffold(
            resizeToAvoidBottomInset:
                false, // Prevent miniplayer from moving with keyboard
            body: Column(
              children: [
                // Offline mode banner
                if (widget.isOfflineMode || isLocalMode)
                  Container(
                    width: double.infinity,
                    color: isLocalMode ? Colors.indigo : Colors.orange,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Row(
                        children: [
                          Icon(
                            isLocalMode
                                ? CupertinoIcons.folder_fill
                                : CupertinoIcons.wifi_slash,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isLocalMode
                                  ? AppLocalizations.of(
                                      context,
                                    )!.localFilesModeBanner
                                  : AppLocalizations.of(
                                      context,
                                    )!.offlineModeBanner,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // LocalMusicService scan progress indicator
                if (isLocalMode)
                  Selector<LocalMusicService, (bool, double, String)>(
                    selector: (_, s) =>
                        (s.isScanning, s.scanProgress, s.scanStatus),
                    builder: (context, data, _) {
                      final (isScanning, progress, status) = data;
                      if (!isScanning) return const SizedBox.shrink();
                      return Container(
                        color: Colors.indigo.shade700,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              status,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.indigo.shade900,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                Expanded(
                  child: Navigator(
                    key: NavigationHelper.mobileNavigatorKey,
                    onGenerateRoute: (settings) {
                      return MaterialPageRoute(
                        builder: (_) => IndexedStack(
                          index: _currentIndex,
                          children: _screens,
                        ),
                      );
                    },
                  ),
                ),
                // Persistent bottom bar
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasCurrentSong) MiniPlayer(onTap: _openNowPlaying),
                    _buildBottomNav(context),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleBackButton() {
    // First, try to pop the nested navigator
    final navigatorState = NavigationHelper.mobileNavigatorKey.currentState;
    if (navigatorState != null && navigatorState.canPop()) {
      navigatorState.pop();
      return;
    }

    // If we're not on the home tab, go to home
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return;
    }

    // We're on home tab and can't pop - exit the app
    SystemNavigator.pop();
  }

  Widget _buildBottomNav(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            // Pop nested navigator to root when switching tabs
            final navigatorState =
                NavigationHelper.mobileNavigatorKey.currentState;
            navigatorState?.popUntil((route) => route.isFirst);
            setState(() => _currentIndex = index);
          },
          items: [
            BottomNavigationBarItem(
              icon: const Icon(CupertinoIcons.music_house),
              activeIcon: const Icon(CupertinoIcons.music_house_fill),
              label: l10n.home,
            ),
            BottomNavigationBarItem(
              icon: const Icon(CupertinoIcons.collections),
              activeIcon: const Icon(CupertinoIcons.collections_solid),
              label: l10n.library,
            ),
            BottomNavigationBarItem(
              icon: const Icon(CupertinoIcons.search),
              activeIcon: const Icon(CupertinoIcons.search),
              label: l10n.search,
            ),
          ],
        ),
      ),
    );
  }
}

class _VersionBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool bold;

  const _VersionBadge({
    required this.label,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}
