import 'package:flutter_chrome_cast/lib.dart';

class GoogleCastOptionsAndroid extends GoogleCastOptions {
  final String appId;
  GoogleCastOptionsAndroid({
    required this.appId,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'appId': appId,
    };
  }
}
