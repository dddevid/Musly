import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:musly/providers/providers.dart';
import 'package:musly/services/local_music_service.dart';
import '../../widgets/navigation/tv_remote_scope.dart';
import '../../services/tv_detection_service.dart';
import 'package:musly/services/recommendation_service.dart';
import 'package:musly/services/theme_service.dart';
import 'package:musly/services/usage_time_service.dart';
import 'package:musly/theme/app_theme.dart';
import 'package:musly/utils/navigation_helper.dart';
import 'package:musly/widgets/widgets.dart';
import 'package:musly/l10n/app_localizations.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'search_screen.dart';
import 'tv_main_screen.dart';
import 'package:musly/screens/media/fantasy_screen.dart';

class PlayPauseIntent extends Intent {
  const PlayPauseIntent();
}

class _PlayPauseAction extends Action<PlayPauseIntent> {
  final BuildContext context;
  _PlayPauseAction(this.context);

  @override
  bool isEnabled(PlayPauseIntent intent) {
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus != null) {
      final focusedContext = primaryFocus.context;
      if (focusedContext != null &&
          focusedContext.findAncestorWidgetOfExactType<EditableText>() !=
              null) {
        return false;
      }
    }
    return true;
  }

  @override
  Object? invoke(PlayPauseIntent intent) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    playerProvider.togglePlayPause();
    return null;
  }
}

/// Breathing room between a page's last item and the floating glass chrome.
const double _kScrollEndGap = 16;

class MainScreen extends StatefulWidget {
  final bool isOfflineMode;

  const MainScreen({super.key, this.isOfflineMode = false});

  /// How much of the bottom of the page at [context] is covered by the
  /// floating Liquid Glass mini-player + tab bar, measured from the bottom of
  /// the screen.
  ///
  /// `0` in the classic layout, and for anything shown full-screen above
  /// [MainScreen] (root-navigator routes).
  static double floatingChromeOverlap(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_FloatingChromeScope>()
          ?.overlap ??
      0;

  /// Padding to leave after the last item of a page's scrollable content.
  ///
  /// Returns [base] unchanged unless glass chrome floats over the page, in
  /// which case it is enough to scroll the last item fully clear of the
  /// chrome (and never less than [base]).
  static double scrollEndPadding(BuildContext context, double base) {
    final overlap = floatingChromeOverlap(context);
    return overlap > 0 ? math.max(base, overlap + _kScrollEndGap) : base;
  }

  /// For widgets that size themselves from the bottom [MediaQuery] padding,
  /// such as a [ListView] without explicit padding or a [SafeArea]: extends
  /// that padding to cover the floating glass chrome. Returns [child]
  /// untouched when no chrome floats over the page.
  static Widget clearFloatingChrome(BuildContext context, Widget child) {
    final overlap = floatingChromeOverlap(context);
    if (overlap <= 0) return child;
    final mq = MediaQuery.of(context);
    if (mq.padding.bottom >= overlap) return child;
    return MediaQuery(
      data: mq.copyWith(padding: mq.padding.copyWith(bottom: overlap)),
      child: child,
    );
  }

  @override
  State<MainScreen> createState() => _MainScreenState();
}

/// Publishes how far the floating glass chrome overlaps the pages of the
/// inner navigator. Read through [MainScreen.floatingChromeOverlap].
class _FloatingChromeScope extends InheritedWidget {
  const _FloatingChromeScope({required this.overlap, required super.child});

  final double overlap;

  @override
  bool updateShouldNotify(_FloatingChromeScope oldWidget) =>
      oldWidget.overlap != overlap;
}

/// Tracks whether a bottom sheet is the topmost route of the inner navigator.
///
/// Sheets opened from a page land on the inner navigator, which now runs
/// underneath the floating glass chrome. While one is on top, the chrome
/// steps aside so the sheet isn't covered (as on iOS, where a sheet covers
/// the tab bar).
class _SheetOnTopObserver extends NavigatorObserver {
  final ValueNotifier<bool> sheetOnTop = ValueNotifier<bool>(false);
  Route<dynamic>? _top;

  static bool _isSheet(Route<dynamic>? route) =>
      route is ModalBottomSheetRoute || route is CupertinoModalPopupRoute;

  void _setTop(Route<dynamic>? route) {
    _top = route;
    if (sheetOnTop.value == _isSheet(route)) return;
    // Route changes can be reported mid-build; never notify listeners then.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback(
          (_) => sheetOnTop.value = _isSheet(_top));
    } else {
      sheetOnTop.value = _isSheet(route);
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _setTop(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _setTop(previousRoute);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (identical(route, _top)) _setTop(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (identical(oldRoute, _top)) _setTop(newRoute);
  }

  void dispose() => sheetOnTop.dispose();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  int _searchTapCount = 0;
  DateTime _lastSearchTap = DateTime.fromMillisecondsSinceEpoch(0);

  final List<Widget> _screens = const [
    HomeScreen(),
    LibraryScreen(),
    SearchScreen(),
  ];

  // While a dialog, sheet or page on the root navigator (now playing, for one)
  // covers this screen, the back swipe goes to that instead of a hidden page
  // in the inner navigator. Shared by both layouts' inner navigators.
  final _backGuard = CoveredBackGestureGuard();

  // Phone layout only: hides the floating glass chrome under bottom sheets.
  final _sheetObserver = _SheetOnTopObserver();

  @override
  void dispose() {
    UsageTimeService().disposeService();
    _backGuard.dispose();
    _sheetObserver.dispose();
    super.dispose();
  }

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

      playerProvider.onAudioFocusDenied = () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.audioFocusDenied),
          ),
        );
      };

      if (authProvider.isLocalOnlyMode) {
        final localMusicService = Provider.of<LocalMusicService>(
          context,
          listen: false,
        );

        libraryProvider.setLocalMusicService(localMusicService);

        if (localMusicService.isEmpty && !localMusicService.isScanning) {
          localMusicService.scanForMusic();
        } else if (!localMusicService.isScanning) {
          libraryProvider.initialize();
        }
      } else {
        libraryProvider.setLocalOnlyMode(false);
        libraryProvider.setServerOfflineMode(widget.isOfflineMode);
        libraryProvider.initialize();
      }

      UsageTimeService().initialize();

      _startUsageTimeChecker();

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _checkForUpdate();
      });
    });
  }

  void _startUsageTimeChecker() {
    Future.delayed(const Duration(minutes: 2), () {
      if (!mounted) return;

      final usageService = UsageTimeService();
      if (usageService.shouldShowDialog) {
        _showSupportDialog();
      } else {
        _startUsageTimeChecker();
      }
    });
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => const SupportDialog(),
      barrierDismissible: true,
    );
  }

  Future<void> _checkForUpdate() async {
    if (!mounted) return;
    await UpdateDialog.checkAndShow(context);
  }

  bool _isLargeScreen(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width >= 650 || size.shortestSide >= 600;
  }

  @override
  Widget build(BuildContext context) =>
      CoveredBackGestureScope(guard: _backGuard, child: _buildScreen(context));

  Widget _buildScreen(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isLocalMode = authProvider.isLocalOnlyMode;
    final isTv = Provider.of<TvDetectionService>(context).isTvMode;

    if (isTv) {
      return TvMainScreen(isOfflineMode: widget.isOfflineMode);
    }

    if (_isLargeScreen(context)) {
      final content = Scaffold(
        body: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  DesktopNavigationSidebar(
                    selectedIndex: _currentIndex,
                    onDestinationSelected: (index) {
                      setState(() => _currentIndex = index);
                      NavigationHelper.appNavigatorKey.currentState
                          ?.popUntil((route) => route.isFirst);
                    },
                    navigatorKey: NavigationHelper.appNavigatorKey,
                  ),
                  Expanded(
                    child: Navigator(
                      key: NavigationHelper.appNavigatorKey,
                      observers: [_backGuard],
                      onGenerateRoute: (settings) {
                        return PageRouteBuilder(
                          pageBuilder: (ctx, anim, _) => LazyIndexedStack(
                            index: _currentIndex,
                            children: _screens,
                          ),
                          transitionsBuilder: (ctx, animation, _, child) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                        );
                      },
                    ),
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: NavigationHelper.isDesktopLyricsOpen,
                    builder: (context, isLyricsOpen, _) {
                      if (!isLyricsOpen) return const SizedBox.shrink();
                      return Selector<PlayerProvider, bool>(
                        selector: (_, p) =>
                            p.currentSong != null || p.isPlayingRadio,
                        builder: (context, hasCurrentSong, _) {
                          return hasCurrentSong
                              ? DesktopLyricsPanel(
                                  onClose: () => NavigationHelper
                                      .isDesktopLyricsOpen.value = false,
                                )
                              : const SizedBox.shrink();
                        },
                      );
                    },
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: NavigationHelper.isDesktopQueueOpen,
                    builder: (context, isQueueOpen, _) {
                      if (!isQueueOpen) return const SizedBox.shrink();
                      return Selector<PlayerProvider, bool>(
                        selector: (_, p) =>
                            p.currentSong != null || p.isPlayingRadio,
                        builder: (context, hasCurrentSong, _) {
                          return hasCurrentSong
                              ? RightSidebar(
                                  onClose: () => NavigationHelper
                                      .isDesktopQueueOpen.value = false,
                                )
                              : const SizedBox.shrink();
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            Selector<PlayerProvider, bool>(
              selector: (_, p) => p.currentSong != null || p.isPlayingRadio,
              builder: (context, hasCurrentSong, _) {
                return hasCurrentSong
                    ? SafeArea(
                        top: false,
                        child: DesktopPlayerBar(
                          navigatorKey: NavigationHelper.appNavigatorKey,
                        ),
                      )
                    : const SizedBox.shrink();
              },
            ),
          ],
        ),
      );

      return Shortcuts(
        shortcuts: <ShortcutActivator, Intent>{
          const SingleActivator(LogicalKeyboardKey.space):
              const PlayPauseIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            PlayPauseIntent: _PlayPauseAction(context),
          },
          child: TvRemoteScope(
            child: Focus(
              autofocus: true,
              child: content,
            ),
          ),
        ),
      );
    }

    final bool liquidGlass = Provider.of<ThemeService>(context).liquidGlass;
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final bool keyboardVisible = mediaQuery.viewInsets.bottom != 0;
    return Selector<PlayerProvider, bool>(
      selector: (_, p) => p.currentSong != null || p.isPlayingRadio,
      builder: (context, hasCurrentSong, _) {
        // Liquid Glass: the mini-player + tab bar float over the pages, which
        // run edge-to-edge underneath so the glass has real content to blur.
        // Classic: they sit below the pages, as before.
        final Widget? floatingChrome = liquidGlass && !keyboardVisible
            ? _buildFloatingGlassChrome(context, hasCurrentSong)
            : null;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _handleBackButton();
          },
          child: TvRemoteScope(
            child: Scaffold(
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkBackground
                : AppTheme.lightBackground,
            resizeToAvoidBottomInset: false,
            extendBody: floatingChrome != null,
            bottomNavigationBar: floatingChrome,
            body: Builder(builder: (bodyContext) {
              // With extendBody the Scaffold reports the chrome's height as
              // the body's bottom padding. Pages get it via
              // _FloatingChromeScope; the inner navigator itself keeps the
              // real system inset, so sheets, dialogs and SafeAreas pushed
              // there lay out exactly as before. (Classic: a no-op.)
              final bodyMediaQuery = MediaQuery.of(bodyContext);
              return MediaQuery(
                data: bodyMediaQuery.copyWith(
                  padding: bodyMediaQuery.padding
                      .copyWith(bottom: mediaQuery.padding.bottom),
                ),
                child: _FloatingChromeScope(
                  overlap: floatingChrome != null
                      ? bodyMediaQuery.padding.bottom
                      : 0,
                  child: _buildPhoneBody(
                    context,
                    isLocalMode: isLocalMode,
                    inlineChrome: !liquidGlass && !keyboardVisible,
                    hasCurrentSong: hasCurrentSong,
                  ),
                ),
              );
            }),
          ),
          ),
        );
      },
    );
  }

  /// The phone layout's page column: status banners, the inner navigator and,
  /// in the classic layout only, the inline mini-player + tab bar.
  Widget _buildPhoneBody(
    BuildContext context, {
    required bool isLocalMode,
    required bool inlineChrome,
    required bool hasCurrentSong,
  }) {
    return Column(
      children: [
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
                            )!
                              .localFilesModeBanner
                          : AppLocalizations.of(
                              context,
                            )!
                              .offlineModeBanner,
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
        if (isLocalMode)
          Selector<LocalMusicService, (bool, double, String)>(
            selector: (_, s) =>
                (s.isScanning, s.scanProgress, s.scanStatus),
            builder: (context, data, _) {
              final (isScanning, progress, status) = data;
              if (!isScanning) return const SizedBox.shrink();
              return Container(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.85),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (progress > 0)
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        Expanded(
          child: Navigator(
            key: NavigationHelper.appNavigatorKey,
            observers: [_backGuard, _sheetObserver],
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (_) => LazyIndexedStack(
                  index: _currentIndex,
                  children: _screens,
                ),
              );
            },
          ),
        ),
        if (inlineChrome)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasCurrentSong) const MiniPlayer(),
              _buildBottomNav(context),
            ],
          ),
      ],
    );
  }

  /// Liquid Glass chrome floating over the pages: mini-player + tab bar.
  Widget _buildFloatingGlassChrome(BuildContext context, bool hasCurrentSong) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return ValueListenableBuilder<bool>(
      valueListenable: _sheetObserver.sheetOnTop,
      builder: (context, sheetOnTop, child) {
        // Slide out of the way while a bottom sheet is open over the pages.
        // Layout size is kept, so pages don't reflow underneath the sheet.
        return IgnorePointer(
          ignoring: sheetOnTop,
          child: AnimatedSlide(
            offset: sheetOnTop ? const Offset(0, 1.4) : Offset.zero,
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 280),
            curve: sheetOnTop ? Curves.easeInCubic : Curves.easeOutCubic,
            child: child,
          ),
        );
      },
      // One shared backdrop for every glass surface in the chrome, so the
      // engine snapshots the content behind it once rather than per surface.
      child: BackdropGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasCurrentSong) const MiniPlayer(),
            _buildGlassBottomNav(context),
          ],
        ),
      ),
    );
  }

  void _handleBackButton() {
    final navigatorState = NavigationHelper.appNavigatorKey.currentState;
    if (navigatorState != null && navigatorState.canPop()) {
      navigatorState.pop();
      return;
    }

    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return;
    }

    SystemNavigator.pop();
  }

  Widget _buildGlassBottomNav(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final l10n = AppLocalizations.of(context)!;

    final items = [
      (
        icon: CupertinoIcons.music_house,
        activeIcon: CupertinoIcons.music_house_fill,
        label: l10n.home,
      ),
      (
        icon: CupertinoIcons.collections,
        activeIcon: CupertinoIcons.collections_solid,
        label: l10n.library,
      ),
      (
        icon: CupertinoIcons.search,
        activeIcon: CupertinoIcons.search,
        label: l10n.search,
      ),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 4, 12, safeBottom > 0 ? safeBottom : 12),
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xF018181A) : const Color(0xF5FFFFFF),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.08),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: List.generate(items.length, (idx) {
            final item = items[idx];
            final isSelected = _currentIndex == idx;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  final navigatorState =
                      NavigationHelper.appNavigatorKey.currentState;
                  navigatorState?.popUntil((route) => route.isFirst);

                  if (idx == 2) {
                    final now = DateTime.now();
                    if (now.difference(_lastSearchTap).inSeconds > 3) {
                      _searchTapCount = 0;
                    }
                    _searchTapCount++;
                    _lastSearchTap = now;
                    if (_searchTapCount >= 11) {
                      _searchTapCount = 0;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FantasyScreen(),
                        ),
                      );
                      return;
                    }
                  } else {
                    _searchTapCount = 0;
                  }

                  setState(() => _currentIndex = idx);
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: Icon(
                        isSelected ? item.activeIcon : item.icon,
                        key: ValueKey(isSelected),
                        color: isSelected
                            ? accent
                            : (isDark ? Colors.white54 : Colors.black38),
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? accent
                            : (isDark ? Colors.white54 : Colors.black38),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
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
            final navigatorState =
                NavigationHelper.appNavigatorKey.currentState;
            navigatorState?.popUntil((route) => route.isFirst);

            if (index == 2) {
              final now = DateTime.now();
              if (now.difference(_lastSearchTap).inSeconds > 3) {
                _searchTapCount = 0;
              }
              _searchTapCount++;
              _lastSearchTap = now;
              if (_searchTapCount >= 11) {
                _searchTapCount = 0;
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FantasyScreen()),
                );
                return;
              }
            } else {
              _searchTapCount = 0;
            }

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
