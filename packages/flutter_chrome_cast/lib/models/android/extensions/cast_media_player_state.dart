import 'package:flutter_chrome_cast/enums/player_state.dart';

extension CastMediaPlayerStateAndroid on CastMediaPlayerState {
  static CastMediaPlayerState fromMap(String value) {
    return CastMediaPlayerState.values.firstWhere(
      (element) => element.name.toUpperCase() == value.toUpperCase(),
      orElse: () => CastMediaPlayerState.idle,
    );
  }
}
