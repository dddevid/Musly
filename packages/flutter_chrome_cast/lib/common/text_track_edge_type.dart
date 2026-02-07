
enum TextTrackEdgeType {
  NONE,

  OUTLINE,

  DROP_SHADOW,

  RAISED,

  DEPRESSED;

  factory TextTrackEdgeType.fromMap(String value) {
    return values.firstWhere((element) => element.name == value);
  }
}
