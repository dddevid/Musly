import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:musly/screens/detail/album_screen.dart';
import 'package:musly/screens/detail/playlist_screen.dart';
import 'package:musly/screens/detail/artist_screen.dart';
import 'package:musly/screens/detail/genre_screen.dart';
import 'package:musly/screens/media/song_collection_screen.dart';
import 'package:musly/screens/media/album_collection_screen.dart';

class NavigationHelper {
  static final GlobalKey<NavigatorState> mobileNavigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> desktopNavigatorKey =
      GlobalKey<NavigatorState>();

  /// Global toggle state for the Desktop Queue RightSidebar
  static final ValueNotifier<bool> isDesktopQueueOpen = ValueNotifier<bool>(false);

  static void toggleDesktopQueue() {
    isDesktopQueueOpen.value = !isDesktopQueueOpen.value;
  }

  static bool get isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  static GlobalKey<NavigatorState> get navigatorKey {
    return isDesktop ? desktopNavigatorKey : mobileNavigatorKey;
  }

  static Widget? _currentTopWidget;
  static int _lastPushTimestamp = 0;

  static bool _isSamePage(Widget a, Widget? b) {
    if (b == null) return false;
    if (a.runtimeType != b.runtimeType) return false;

    if (a is AlbumScreen && b is AlbumScreen) {
      return a.albumId == b.albumId;
    }
    if (a is PlaylistScreen && b is PlaylistScreen) {
      return a.playlistId == b.playlistId;
    }
    if (a is ArtistScreen && b is ArtistScreen) {
      return a.artistId == b.artistId;
    }
    if (a is GenreScreen && b is GenreScreen) {
      return a.genreName == b.genreName;
    }
    if (a is SongCollectionScreen && b is SongCollectionScreen) {
      return a.type == b.type && a.title == b.title;
    }
    if (a is AlbumCollectionScreen && b is AlbumCollectionScreen) {
      return a.type == b.type && a.title == b.title;
    }
    return true;
  }

  static Future<T?> push<T>(BuildContext context, Widget page) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_isSamePage(page, _currentTopWidget) ||
        (now - _lastPushTimestamp < 350 && page.runtimeType == _currentTopWidget?.runtimeType)) {
      debugPrint('[Navigation] Prevented duplicate push of ${page.runtimeType}');
      return Future.value(null);
    }

    _currentTopWidget = page;
    _lastPushTimestamp = now;

    final nav = navigatorKey.currentState;
    final route = MaterialPageRoute<T>(
      builder: (_) => page,
      settings: RouteSettings(name: page.runtimeType.toString(), arguments: page),
    );

    final future = nav != null
        ? nav.push<T>(route)
        : Navigator.of(context).push<T>(route);

    return future.then((res) {
      if (_currentTopWidget == page) {
        _currentTopWidget = null;
      }
      return res;
    });
  }

  static Future<T?> pushRoute<T>(BuildContext context, Route<T> route) {
    final nav = navigatorKey.currentState;
    if (nav != null) {
      return nav.push<T>(route);
    }
    return Navigator.of(context).push<T>(route);
  }

  static void pop<T>(BuildContext context, [T? result]) {
    _currentTopWidget = null;
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
    _currentTopWidget = null;
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
