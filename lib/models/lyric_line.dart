import 'lyric_word.dart';

class LyricLine {
  final String text;
  final Duration startTime;
  final Duration? endTime;
  final List<LyricWord>? words; // Only present if word-level sync is available

  LyricLine({
    required this.text,
    required this.startTime,
    this.endTime,
    this.words,
  });

  bool get hasWords => words != null && words!.isNotEmpty;
}
