enum HlsVideoSegmentFormat {
  MPEG2_TS,

  FMP4,
  NONE;

  factory HlsVideoSegmentFormat.fromMap(String value) {
    return values.firstWhere((element) => element.name == value,
        orElse: () => NONE);
  }
}
