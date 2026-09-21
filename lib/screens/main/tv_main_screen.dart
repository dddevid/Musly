import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musly/widgets/navigation/tv_navigation_sidebar.dart';
import 'package:musly/screens/main/home_screen.dart';
import 'package:musly/screens/main/library_screen.dart';
import 'package:musly/screens/main/search_screen.dart';
import 'package:musly/screens/settings/settings_screen.dart';
import 'package:musly/utils/navigation_helper.dart';
import 'package:musly/widgets/widgets.dart';
import 'package:provider/provider.dart';
import 'package:musly/providers/player_provider.dart';
import 'package:musly/theme/app_theme.dart';
import 'package:musly/widgets/navigation/tv_remote_scope.dart';

class TvMainScreen extends StatefulWidget {
  final bool isOfflineMode;

  const TvMainScreen({super.key, this.isOfflineMode = false});

  @override
  State<TvMainScreen> createState() => _TvMainScreenState();
}

class _TvMainScreenState extends State<TvMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    SearchScreen(),
    LibraryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppTheme.darkBackground,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _handleBackButton();
        },
        child: TvRemoteScope(
          child: Scaffold(
            backgroundColor: AppTheme.darkBackground,
            body: Stack(
              children: [
                Positioned.fill(
                  left: 70, // Keep space for collapsed sidebar
                  child: Column(
                    children: [
                      Expanded(
                        child: Navigator(
                          key: NavigationHelper.appNavigatorKey,
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
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: TvNavigationSidebar(
                    selectedIndex: _currentIndex,
                    onDestinationSelected: (index) {
                      setState(() => _currentIndex = index);
                      NavigationHelper.appNavigatorKey.currentState
                          ?.popUntil((route) => route.isFirst);
                    },
                  ),
                ),
              ],
            ),
          ),
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
}
