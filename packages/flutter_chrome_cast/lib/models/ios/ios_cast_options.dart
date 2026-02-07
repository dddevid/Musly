import 'package:flutter_chrome_cast/entities/discovery_criteria.dart';
import 'package:flutter_chrome_cast/entities/cast_options.dart';

class IOSGoogleCastOptions extends GoogleCastOptions {
  final GoogleCastDiscoveryCriteriaInitialize _discoveryCriteria;

  IOSGoogleCastOptions(this._discoveryCriteria);

  @override
  Map<String, dynamic> toMap() {
    return super.toMap()
      ..addAll(
        {
          'discoveryCriteria': _discoveryCriteria.toMap(),
        },
      );
  }
}
