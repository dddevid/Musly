import 'package:flutter_chrome_cast/lib.dart';

extension GoogleCastAndroidStreamType on CastMediaStreamType {
  static CastMediaStreamType fromMap(String value) {
    return CastMediaStreamType.values.firstWhere(
      (element) => element.value == value,
      orElse: () => CastMediaStreamType.NONE,
    );
  }
}
