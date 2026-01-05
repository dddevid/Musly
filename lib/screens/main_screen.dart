import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../services/recommendation_service.dart';
import '../widgets/widgets.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'search_screen.dart';
import 'now_playing_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
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

      libraryProvider.initialize();
    });
  }

  void _openNowPlaying() {
    Navigator.of(context).push(
      PageRouteBuilder(
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

  final GlobalKey<NavigatorState> _desktopNavigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
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
                      _desktopNavigatorKey.currentState?.popUntil(
                        (route) => route.isFirst,
                      );
                    },
                    navigatorKey: _desktopNavigatorKey,
                  ),
                  const VerticalDivider(width: 1, thickness: 1),
                  Expanded(
                    child: Navigator(
                      key: _desktopNavigatorKey,
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
              selector: (_, p) => p.currentSong != null,
              builder: (context, hasCurrentSong, _) {
                return hasCurrentSong
                    ? DesktopPlayerBar(navigatorKey: _desktopNavigatorKey)
                    : const SizedBox.shrink();
              },
            ),
          ],
        ),
      );
    }

    return Selector<PlayerProvider, bool>(
      selector: (_, p) => p.currentSong != null,
      builder: (context, hasCurrentSong, _) {
        return Scaffold(
          body: Stack(
            children: [
              IndexedStack(index: _currentIndex, children: _screens),
              if (hasCurrentSong)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MiniPlayer(onTap: _openNowPlaying),
                      _buildBottomNav(context),
                    ],
                  ),
                ),
            ],
          ),
          bottomNavigationBar: hasCurrentSong ? null : _buildBottomNav(context),
        );
      },
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.music_house),
              activeIcon: Icon(CupertinoIcons.music_house_fill),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.collections),
              activeIcon: Icon(CupertinoIcons.collections_solid),
              label: 'Library',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.search),
              activeIcon: Icon(CupertinoIcons.search),
              label: 'Search',
            ),
          ],
        ),
      ),
    );
  }
}
