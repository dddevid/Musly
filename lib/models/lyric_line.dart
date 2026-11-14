import 'lyric_word.dart';

class LyricLine {
  final String text;
  final Duration startTime;
  final Duration? endTime;
  final List<LyricWord>? words;
  String? translation;

  LyricLine({
    required this.text,
    required this.startTime,
    this.endTime,
    this.words,
    this.translation,
  });

  bool get hasWords => words != null && words!.isNotEmpty;
  bool get hasTranslation =>
      translation != null && translation!.trim().isNotEmpty;
}
