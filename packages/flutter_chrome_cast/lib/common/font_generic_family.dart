enum TextTrackFontGenericFamily {
  SANS_SERIF,

  MONOSPACED_SANS_SERIF,

  SERIF,

  MONOSPACED_SERIF,

  CASUAL,

  CURSIVE,

  SMALL_CAPITALS;

  factory TextTrackFontGenericFamily.fromMap(String value) {
    return values.firstWhere((element) => element.name == value);
  }
}
