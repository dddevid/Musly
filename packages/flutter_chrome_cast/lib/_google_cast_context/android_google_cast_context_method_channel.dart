import 'package:flutter/services.dart';
import 'package:flutter_chrome_cast/entities/cast_options.dart';

import 'google_cast_context_plataform_interface.dart';

class GoogleCastContextAndroidMethodChannel
    implements GoogleCastContextPlatformInterface {
  final _channel = const MethodChannel('com.felnanuke.google_cast.context');

  @override
  Future<bool> setSharedInstanceWithOptions(
      GoogleCastOptions castOptions) async {
    try {
      final result =
          await _channel.invokeMethod('setSharedInstance', castOptions.toMap());
      print('setSharedInstanceWithOptions initialized with $result');
      return result == true;
    } catch (e, s) {
      print(e);
      print(s);
      rethrow;
    }
  }
}
