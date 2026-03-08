import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class NavigationHelper {
  
  static final GlobalKey<NavigatorState> mobileNavigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> desktopNavigatorKey =
      GlobalKey<NavigatorState>();

  static bool get isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  static GlobalKey<NavigatorState> get navigatorKey {
    return isDesktop ? desktopNavigatorKey : mobileNavigatorKey;
  }

  static Future<T?> push<T>(BuildContext context, Widget page) {
    final nav = navigatorKey.currentState;
    if (nav != null) {
      return nav.push<T>(MaterialPageRoute(builder: (_) => page));
    }
    return Navigator.of(
      context,
    ).push<T>(MaterialPageRoute(builder: (_) => page));
  }

  static Future<T?> pushRoute<T>(BuildContext context, Route<T> route) {
    final nav = navigatorKey.currentState;
    if (nav != null) {
      return nav.push<T>(route);
    }
    return Navigator.of(context).push<T>(route);
  }

  static void pop<T>(BuildContext context, [T? result]) {
    final nav = navigatorKey.currentState;
    if (nav != null && nav.canPop()) {
      nav.pop<T>(result);
    } else {
      Navigator.of(context).pop<T>(result);
    }
  }

  static void popUntil(
    BuildContext context,
    bool Function(Route<dynamic>) predicate,
  ) {
    final nav = navigatorKey.currentState;
    if (nav != null) {
      nav.popUntil(predicate);
    } else {
      Navigator.of(context).popUntil(predicate);
    }
  }

  static void Function(int)? _onTabChanged;

  static void registerTabChangeCallback(void Function(int) callback) {
    _onTabChanged = callback;
  }

  static void switchToTab(int index) {
    _onTabChanged?.call(index);
  }
}
