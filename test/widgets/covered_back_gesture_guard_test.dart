import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musly/widgets/navigation/covered_back_gesture_guard.dart';

final _root = GlobalKey<NavigatorState>();
final _inner = GlobalKey<NavigatorState>();
final _wide = ValueNotifier(false);
late CoveredBackGestureGuard _guard;
int _shellBuilds = 0;

/// MainScreen's layout: a root navigator whose home blocks pops and hands
/// them to an inner navigator, which holds the tabs and the pages opened
/// from them. Now playing, dialogs and some sheets go on the root navigator.
/// [_wide] swaps in the other layout, which reuses the inner navigator.
class _Shell extends StatefulWidget {
  const _Shell({required this.guarded});
  final bool guarded;

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  @override
  Widget build(BuildContext context) =>
      CoveredBackGestureScope(guard: _guard, child: _buildShell());

  Widget _buildShell() {
    _shellBuilds++;
    final inner = Navigator(
      key: _inner,
      observers: [if (widget.guarded) _guard],
      onGenerateRoute: (_) =>
          MaterialPageRoute(builder: (_) => const Text('tabs')),
    );
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_inner.currentState!.canPop()) _inner.currentState!.pop();
      },
      child: ValueListenableBuilder<bool>(
        valueListenable: _wide,
        builder: (_, wide, __) => Scaffold(
          body: wide ? Row(children: [Expanded(child: inner)]) : inner,
        ),
      ),
    );
  }
}

Future<void> _pumpShell(WidgetTester tester, {bool guarded = true}) async {
  _wide.value = false;
  _guard = CoveredBackGestureGuard();
  addTearDown(_guard.dispose);
  await tester.pumpWidget(MaterialApp(
    navigatorKey: _root,
    home: _Shell(guarded: guarded),
  ));
}

Future<void> _openPage(WidgetTester tester, String name) async {
  _inner.currentState!
      .push(MaterialPageRoute<void>(builder: (_) => Text(name)));
  await tester.pumpAndSettle();
}

Future<void> _openNowPlaying(WidgetTester tester) async {
  // As MiniPlayer opens it.
  showModalBottomSheet<void>(
    context: _root.currentContext!,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (_) => const SizedBox.expand(child: Text('now playing')),
  );
  await tester.pumpAndSettle();
}

Future<void> _openDialog(WidgetTester tester, BuildContext context) async {
  // showDialog uses the root navigator by default.
  showDialog<void>(
    context: context,
    builder: (_) => const AlertDialog(content: Text('dialog')),
  );
  await tester.pumpAndSettle();
}

Future<void> _sendGesture(WidgetTester tester, String method,
    [Object? args]) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/backgesture',
    const StandardMethodCodec().encodeMethodCall(MethodCall(method, args)),
    (_) {},
  );
  await tester.pump();
}

Map<String, Object?> _event(double progress) => {
      'touchOffset': <double>[5, 300],
      'progress': progress,
      'swipeEdge': 0,
    };

/// An Android edge swipe, as the engine reports it on Android 14 and later.
Future<void> _swipeBack(WidgetTester tester, {bool commit = true}) async {
  await _sendGesture(tester, 'startBackGesture', _event(0));
  await _sendGesture(tester, 'updateBackGestureProgress', _event(0.6));
  await _sendGesture(
      tester, commit ? 'commitBackGesture' : 'cancelBackGesture');
  await tester.pumpAndSettle();
}

Future<void> _pressBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

List<String> _visible() => [
      for (final name in [
        'tabs',
        'playlist',
        'album',
        'settings',
        'now playing',
        'dialog'
      ])
        if (find.text(name).evaluate().isNotEmpty) name,
    ];

void main() {
  group('back swipe', () {
    testWidgets('closes now playing, not the hidden playlist under it',
        (tester) async {
      await _pumpShell(tester);
      await _openPage(tester, 'playlist');
      await _openNowPlaying(tester);

      await _swipeBack(tester);
      expect(_visible(), ['playlist'],
          reason: 'the sheet closes and the playlist it covered is still '
              'there');

      await _swipeBack(tester);
      expect(_visible(), ['tabs']);
    });

    testWidgets('without the guard it pops the hidden playlist (the bug)',
        (tester) async {
      await _pumpShell(tester, guarded: false);
      await _openPage(tester, 'playlist');
      await _openNowPlaying(tester);

      await _swipeBack(tester);
      expect(_visible(), ['tabs', 'now playing']);
    });

    testWidgets('closes a dialog, not the page under it', (tester) async {
      await _pumpShell(tester);
      await _openPage(tester, 'settings');
      await _openDialog(tester, tester.element(find.text('settings')));

      await _swipeBack(tester);
      expect(_visible(), ['settings']);
    });

    testWidgets('closes a dialog shown over now playing, then now playing',
        (tester) async {
      await _pumpShell(tester);
      await _openPage(tester, 'playlist');
      await _openNowPlaying(tester);
      // The cast device picker opens this way.
      await _openDialog(tester, tester.element(find.text('now playing')));

      await _swipeBack(tester);
      expect(_visible(), ['playlist', 'now playing']);
      await _swipeBack(tester);
      expect(_visible(), ['playlist']);
    });

    testWidgets('pops a page pushed on the root navigator', (tester) async {
      await _pumpShell(tester);
      await _openPage(tester, 'playlist');
      _root.currentState!
          .push(MaterialPageRoute<void>(builder: (_) => const Text('album')));
      await tester.pumpAndSettle();

      await _swipeBack(tester);
      expect(_visible(), ['playlist']);
    });

    testWidgets('closes now playing opened from a tab', (tester) async {
      await _pumpShell(tester);
      await _openNowPlaying(tester);

      await _swipeBack(tester);
      expect(_visible(), ['tabs']);
    });

    testWidgets('steps back through inner pages one at a time', (tester) async {
      await _pumpShell(tester);
      await _openPage(tester, 'playlist');
      await _openPage(tester, 'album');

      await _swipeBack(tester);
      expect(_visible(), ['playlist']);
      await _swipeBack(tester);
      expect(_visible(), ['tabs']);
    });

    testWidgets('inner pages keep the predictive animation when uncovered',
        (tester) async {
      await _pumpShell(tester);
      await _openPage(tester, 'playlist');
      final route = ModalRoute.of(tester.element(find.text('playlist')))!;
      expect(route.popGestureEnabled, isTrue);

      await _openNowPlaying(tester);
      expect(route.popGestureEnabled, isFalse);

      await _swipeBack(tester);
      expect(route.popGestureEnabled, isTrue,
          reason: 'uncovered again once now playing closes');

      // Mid-swipe, the page is being dragged rather than popped outright.
      await _sendGesture(tester, 'startBackGesture', _event(0));
      await _sendGesture(tester, 'updateBackGestureProgress', _event(0.5));
      expect(_inner.currentState!.userGestureInProgress, isTrue);
      await _sendGesture(tester, 'commitBackGesture');
      await tester.pumpAndSettle();
      expect(_visible(), ['tabs']);
    });

    testWidgets('a cancelled swipe leaves everything in place', (tester) async {
      await _pumpShell(tester);
      await _openPage(tester, 'playlist');
      await _openNowPlaying(tester);

      await _swipeBack(tester, commit: false);
      expect(_visible(), ['playlist', 'now playing']);
    });
  });

  group('back button', () {
    testWidgets('closes now playing, then the playlist', (tester) async {
      await _pumpShell(tester);
      await _openPage(tester, 'playlist');
      await _openNowPlaying(tester);

      await _pressBack(tester);
      expect(_visible(), ['playlist']);
      await _pressBack(tester);
      expect(_visible(), ['tabs']);
    });

    testWidgets('closes a dialog, then the page under it', (tester) async {
      await _pumpShell(tester);
      await _openPage(tester, 'settings');
      await _openDialog(tester, tester.element(find.text('settings')));

      await _pressBack(tester);
      expect(_visible(), ['settings']);
      await _pressBack(tester);
      expect(_visible(), ['tabs']);
    });
  });

  testWidgets('a swipe in the same frame now playing opens closes it',
      (tester) async {
    await _pumpShell(tester);
    await _openPage(tester, 'playlist');
    showModalBottomSheet<void>(
      context: _root.currentContext!,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (_) => const SizedBox.expand(child: Text('now playing')),
    );
    // No frame yet: the guard must not rely on a rebuild to know.
    await _swipeBack(tester);
    expect(_visible(), ['playlist']);
  });

  testWidgets('switching layout keeps guarding the same pages', (tester) async {
    await _pumpShell(tester);
    await _openPage(tester, 'playlist');
    _wide.value = true; // e.g. rotating a phone to landscape
    await tester.pumpAndSettle();

    await _openNowPlaying(tester);
    await _swipeBack(tester);
    expect(_visible(), ['playlist']);

    _wide.value = false;
    await tester.pumpAndSettle();
    _inner.currentState!.pop();
    await tester.pumpAndSettle();
    expect(_guard.guardedRouteCount, 1, reason: 'only the tabs page left');
  });

  testWidgets('covering the screen does not rebuild it', (tester) async {
    await _pumpShell(tester);
    await _openPage(tester, 'playlist');
    final builds = _shellBuilds;
    await _openNowPlaying(tester);
    await _swipeBack(tester);
    expect(_shellBuilds, builds);
  });

  testWidgets('a scope handed a new guard points it at the route at once',
      (tester) async {
    await _pumpShell(tester);
    _guard = CoveredBackGestureGuard();
    addTearDown(_guard.dispose);
    // ignore: prefer_const_constructors
    await tester.pumpWidget(MaterialApp(
      navigatorKey: _root,
      home: _Shell(guarded: true), // a new instance, so the scope updates
    ));
    await _openPage(tester, 'album');
    showModalBottomSheet<void>(
      context: _root.currentContext!,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (_) => const SizedBox.expand(child: Text('now playing')),
    );
    await _swipeBack(tester); // same frame: no dependency change yet
    expect(_visible(), ['album']);
  });

  testWidgets('lets go of pages once they are popped', (tester) async {
    await _pumpShell(tester);
    expect(_guard.guardedRouteCount, 1); // the tabs page
    for (var i = 0; i < 5; i++) {
      await _openPage(tester, 'playlist');
      _inner.currentState!.pop();
      await tester.pumpAndSettle();
    }
    expect(_guard.guardedRouteCount, 1);

    await _openPage(tester, 'playlist');
    _inner.currentState!.pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const Text('album')));
    await tester.pumpAndSettle();
    expect(_guard.guardedRouteCount, 2, reason: 'replaced page released');
  });
}
