import 'package:flutter_chrome_cast/lib.dart';

extension GoogleCastIdleReasonAndroid on GoogleCastMediaIdleReason {
  static GoogleCastMediaIdleReason fromMap(String value) {
    return GoogleCastMediaIdleReason.values.firstWhere(
      (element) => element.name.toUpperCase() == value.toUpperCase(),
      orElse: () => GoogleCastMediaIdleReason.none,
    );
  }
}
