import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Call this at the top of `main()` in any test that instantiates
/// StorageService, PlayerProvider, AuthProvider, or any class that
/// accesses SharedPreferences / native MethodChannels.
void initializeTestEnvironment() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
}
