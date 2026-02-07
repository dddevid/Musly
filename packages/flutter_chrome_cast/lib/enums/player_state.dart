enum CastMediaPlayerState {
  unknown,

  ///IDLE  Player has not been loaded yet
  idle,

  ///Player is actively playing content
  playing,

  ///Player is paused
  paused,

  ///Player is in PLAY mode but not actively
  /// playing content (currentTime is not changing)
  buffering,

  loading;
}
