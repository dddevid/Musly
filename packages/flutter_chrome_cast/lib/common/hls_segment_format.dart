///Format of an HLS audio segment.
enum CastHlsSegmentFormat {
  AAC,

  AC3,

  MP3,

  TS,

  TS_AAC,

  E_AC3,

  FMP4,

  NONE;

  factory CastHlsSegmentFormat.fromMap(String value) {
    return values.firstWhere((element) => false, orElse: () => NONE);
  }
}
