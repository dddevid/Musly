import '../models/lyric_line.dart';

class LrcParser {
  /// Parses standard LRC content: [mm:ss.xx]Text
  static List<LyricLine> parseLrc(String content) {
    final lines = content.split('\n');
    final List<LyricLine> parsedLines = [];
    
    final RegExp lrcRegex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');

    for (var line in lines) {
      final match = lrcRegex.firstMatch(line.trim());
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final millisecondsStr = match.group(3)!;
        final milliseconds = millisecondsStr.length == 2 
            ? int.parse(millisecondsStr) * 10
            : int.parse(millisecondsStr);
            
        final text = match.group(4)!.trim();
        
        final duration = Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: milliseconds,
        );

        if (text.isNotEmpty) {
           parsedLines.add(LyricLine(
            text: text,
            startTime: duration,
          ));
        }
      } else if (line.trim().isNotEmpty) {
        // If no timestamps are found at all, we'll collect them as plain text.
        // We'll process them below if no valid LRC lines were parsed.
      }
    }

    if (parsedLines.isEmpty && content.trim().isNotEmpty) {
      // Treat as plain text, unsynced lyrics
      final plainLines = content.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty);
      for (var text in plainLines) {
        parsedLines.add(LyricLine(
          text: text,
          startTime: Duration.zero,
        ));
      }
      return parsedLines;
    }

    // Sort by start time just in case
    parsedLines.sort((a, b) => a.startTime.compareTo(b.startTime));

    // Calculate approximate end times for lines
    for (var i = 0; i < parsedLines.length - 1; i++) {
      final current = parsedLines[i];
      final next = parsedLines[i + 1];
      // End time is start time of next line minus a tiny gap
      parsedLines[i] = LyricLine(
        text: current.text,
        startTime: current.startTime,
        endTime: next.startTime - const Duration(milliseconds: 1),
        words: current.words,
      );
    }
    
    return parsedLines;
  }
}
