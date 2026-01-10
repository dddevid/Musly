import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Navigation helper for nested navigation support.
/// This allows detail screens to navigate within the main shell,
/// keeping the bottom nav bar and miniplayer visible.
class NavigationHelper {
  /// Global navigator keys for nested navigation
  static final GlobalKey<NavigatorState> mobileNavigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> desktopNavigatorKey =
      GlobalKey<NavigatorState>();

  /// Check if we're on desktop platform
  static bool get isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  /// Get the appropriate navigator key for the current platform
  static GlobalKey<NavigatorState> get navigatorKey {
    return isDesktop ? desktopNavigatorKey : mobileNavigatorKey;
  }

  /// Push a route using the nested navigator if available,
  /// otherwise fall back to the root navigator
  static Future<T?> push<T>(BuildContext context, Widget page) {
    final nav = navigatorKey.currentState;
    if (nav != null) {
      return nav.push<T>(MaterialPageRoute(builder: (_) => page));
    }
    return Navigator.of(
      context,
    ).push<T>(MaterialPageRoute(builder: (_) => page));
  }

  /// Push a route with custom route builder
  static Future<T?> pushRoute<T>(BuildContext context, Route<T> route) {
    final nav = navigatorKey.currentState;
    if (nav != null) {
      return nav.push<T>(route);
    }
    return Navigator.of(context).push<T>(route);
  }

  /// Pop the current route
  static void pop<T>(BuildContext context, [T? result]) {
    final nav = navigatorKey.currentState;
    if (nav != null && nav.canPop()) {
      nav.pop<T>(result);
    } else {
      Navigator.of(context).pop<T>(result);
    }
  }

  /// Pop until a condition is met
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

  /// Callback for changing the main screen tab
  static void Function(int)? _onTabChanged;

  /// Register a callback for tab changes
  static void registerTabChangeCallback(void Function(int) callback) {
    _onTabChanged = callback;
  }

  /// Switch to a specific tab
  static void switchToTab(int index) {
    _onTabChanged?.call(index);
  }
}
