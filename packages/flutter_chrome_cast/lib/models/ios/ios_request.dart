import 'package:flutter_chrome_cast/entities/request.dart';

class GoogleCastIosRequest extends GoogleCastRequest {
  GoogleCastIosRequest({
    required super.inProgress,
    required super.isExternal,
    required super.requestID,
    super.error,
  });

  factory GoogleCastIosRequest.fromMap(Map<String, dynamic> map) {
    return GoogleCastIosRequest(
      inProgress: map['inProgress'] as bool,
      isExternal: map['isExternal'] as bool,
      requestID: map['requestID'] as int,
      error: map['error'] as String?,
    );
  }
}
