///Possible text track font style.
enum TextTrackFontStyle {
  NORMAL,

  BOLD,

  BOLD_ITALIC,

  ITALIC;

  factory TextTrackFontStyle.fromMap(String value) {
    return values.firstWhere((element) => element.name == value);
  }
}
