enum GoogleCastMediaMetadataType {
  genericMediaMetadata(0),
  movieMediaMetadata(1),
  tvShowMediaMetadata(2),
  musicTrackMediaMetadata(3),
  photoMediaMetadata(4);

  final int value;
  const GoogleCastMediaMetadataType(this.value);

  factory GoogleCastMediaMetadataType.fromMap(int value) {
    return values.firstWhere(
      (element) => element.value == value,
      orElse: () => genericMediaMetadata,
    );
  }
}
