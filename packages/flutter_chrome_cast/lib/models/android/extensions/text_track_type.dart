import 'package:flutter_chrome_cast/lib.dart';

extension GoogleCastTextTrackStyleAndroid on TextTrackType {
  static TextTrackType fromMap(String value) {
    return TextTrackType.values.firstWhere(
      (element) => element.name.toUpperCase() == value.toUpperCase(),
      orElse: () => TextTrackType.UNKNOWN,
    );
  }
}
