import 'package:flutter/material.dart';
import 'package:musly/models/lyric_line.dart';
import 'package:musly/widgets/lyrics/lyrics_list_view.dart';

class LyricsScreen extends StatelessWidget {
  final List<LyricLine> lyrics;
  final Duration currentTime;
  final Function(Duration) onSeek;

  const LyricsScreen({
    super.key,
    required this.lyrics,
    required this.currentTime,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final view = View.of(context);
    final viewPadding = MediaQueryData.fromView(view).padding;
    final mediaQueryPadding = MediaQuery.of(context).padding;
    final topPadding =
        viewPadding.top > 0 ? viewPadding.top : mediaQueryPadding.top;
    final headerClearance = topPadding > 0
        ? topPadding + (isLandscape ? 44.0 : 64.0)
        : (isLandscape ? 48.0 : 56.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            SizedBox(height: headerClearance),
            Expanded(
              child: LyricsListView(
                lyrics: lyrics,
                currentTime: currentTime,
                onSeek: onSeek,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
