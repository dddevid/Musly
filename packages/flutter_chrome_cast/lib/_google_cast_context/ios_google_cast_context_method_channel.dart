import 'package:flutter/services.dart';
import 'package:flutter_chrome_cast/entities/cast_options.dart';
import 'google_cast_context_plataform_interface.dart';

class FlutterIOSGoogleCastContextMethodChannel
    extends GoogleCastContextPlatformInterface {
  static const _methodChannel = MethodChannel('google_cast.context');

  @override
  Future<bool> setSharedInstanceWithOptions(
      GoogleCastOptions castOptions) async {
    return await _methodChannel.invokeMethod(
      'setSharedInstanceWithOptions',
      castOptions.toMap(),
    );
  }
}
