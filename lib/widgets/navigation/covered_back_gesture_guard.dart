import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Keeps pages in a nested navigator from taking Android's back swipe while
/// something on an outer navigator covers them.
///
/// Flutter hands a predictive back swipe to the newest page that is the top
/// page of its own navigator. A page in a nested navigator stays the top page
/// there when a dialog, bottom sheet or page is pushed on the root navigator
/// over it, so the swipe popped that hidden page and left the sheet up.
///
/// While the route holding the nested navigator isn't current, every page in
/// the nested navigator reports that it can't pop. Flutter then treats the
/// swipe like the back button, which the root navigator gives to its top
/// route. While covered, `maybePop` on the nested navigator also does nothing;
/// `pop` and `popUntil` are unaffected.
///
/// Add the guard to the nested navigator's observers. Navigators for
/// alternative layouts that share one key can share one guard, since only one
/// is mounted at a time. Put a [CoveredBackGestureScope] above them so the
/// guard knows which outer route to watch.
class CoveredBackGestureGuard extends NavigatorObserver {
  final _OuterRouteIsCurrent _canPop = _OuterRouteIsCurrent();
  final Map<Route<dynamic>, _GuardEntry> _entries = {};

  /// Pages currently guarded; for tests.
  @visibleForTesting
  int get guardedRouteCount => _entries.length;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _add(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _remove(oldRoute);
    _add(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _remove(route);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _remove(route);

  void _add(Route<dynamic>? route) {
    if (route is! ModalRoute || _entries.containsKey(route)) return;
    final entry = _GuardEntry(_canPop);
    _entries[route] = entry;
    route.registerPopEntry(entry);
  }

  void _remove(Route<dynamic>? route) {
    final entry = _entries.remove(route);
    if (entry != null && route is ModalRoute) route.unregisterPopEntry(entry);
  }

  void dispose() => _canPop.dispose();
}

/// Tells [guard] which outer route holds its navigator.
///
/// Only this widget depends on that route, so covering and uncovering it
/// doesn't rebuild [child].
class CoveredBackGestureScope extends StatefulWidget {
  const CoveredBackGestureScope({
    super.key,
    required this.guard,
    required this.child,
  });

  final CoveredBackGestureGuard guard;
  final Widget child;

  @override
  State<CoveredBackGestureScope> createState() =>
      _CoveredBackGestureScopeState();
}

class _CoveredBackGestureScopeState extends State<CoveredBackGestureScope> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.guard._canPop.route = ModalRoute.of(context);
  }

  @override
  void didUpdateWidget(CoveredBackGestureScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.guard != widget.guard) {
      widget.guard._canPop.route = ModalRoute.of(context);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Reads [ModalRoute.isCurrent] when asked rather than caching it, so a swipe
/// in the same frame a sheet opens is already handled. Notifies when the
/// scope sees the route change.
class _OuterRouteIsCurrent extends ChangeNotifier
    implements ValueListenable<bool> {
  ModalRoute<dynamic>? _route;

  set route(ModalRoute<dynamic>? route) {
    _route = route;
    notifyListeners();
  }

  @override
  bool get value => _route?.isCurrent ?? true;
}

class _GuardEntry extends PopEntry<Object?> {
  _GuardEntry(this.canPopNotifier);

  @override
  final ValueListenable<bool> canPopNotifier;
}
