///Possible text track window types.
enum TextTrackWindowType {
  NONE,

  NORMAL,

  ROUNDED_CORNERS;

  factory TextTrackWindowType.fromMap(String value) {
    return values.firstWhere((element) => element.name == value);
  }
}
