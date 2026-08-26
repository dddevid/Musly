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
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final view = View.of(context);
    final viewPadding = MediaQueryData.fromView(view).padding;
    final mediaQueryPadding = MediaQuery.of(context).padding;
    final topPadding = viewPadding.top > 0 ? viewPadding.top : mediaQueryPadding.top;
    final headerClearance = topPadding > 0
        ? topPadding + (isLandscape ? 44.0 : 64.0)
        : (isLandscape ? 48.0 : 56.0);

    // The background is provided by the parent (NowPlayingScreen)
    // Here we just need to provide the transparent scaffold and the list view
    return Scaffold(
      backgroundColor: Colors.transparent, // Let the animated background show through
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Header is handled by NowPlayingScreen in a Stack so it persists across page views,
            SizedBox(height: headerClearance), // Space for header
            
            Expanded(
              child: LyricsListView(
                lyrics: lyrics,
                currentTime: currentTime,
                onSeek: onSeek,
              ),
            ),
            
            // Optional: Mini controls at the bottom could go here, 
            // but for simplicity we rely on the main Now Playing controls when swiping back,
            // or we can add a mini player row specifically for lyrics view.
          ],
        ),
      ),
    );
  }
}
