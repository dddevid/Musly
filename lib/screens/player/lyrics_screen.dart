import 'package:flutter/material.dart';
import 'package:musly/models/lyric_line.dart';
import 'package:musly/widgets/lyrics/lyrics_list_view.dart';
import '../../l10n/app_localizations.dart';

class LyricsScreen extends StatelessWidget {
  final List<LyricLine> lyrics;
  final Duration currentTime;
  final Function(Duration) onSeek;
  final VoidCallback? onToggleTranslation;
  final bool isTranslating;

  const LyricsScreen({
    super.key,
    required this.lyrics,
    required this.currentTime,
    required this.onSeek,
    this.onToggleTranslation,
    this.isTranslating = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasTranslation = lyrics.any((l) => l.hasTranslation);
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
        child: Stack(
          children: [
            Column(
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
            if (onToggleTranslation != null)
              Positioned(
                top: topPadding > 0 ? topPadding + 8 : 16,
                right: 16,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: isTranslating ? null : onToggleTranslation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: hasTranslation
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.85)
                            : Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isTranslating)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          else
                            const Icon(
                              Icons.translate_rounded,
                              size: 15,
                              color: Colors.white,
                            ),
                          const SizedBox(width: 5),
                          Text(
                            l10n?.lyricsTranslation ?? 'Translate',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
