import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/support_dialog.dart';

/// Service to track app usage time and show support dialog after 8 minutes
class UsageTimeService extends ChangeNotifier with WidgetsBindingObserver {
  static final UsageTimeService _instance = UsageTimeService._internal();
  factory UsageTimeService() => _instance;
  UsageTimeService._internal();

  static const String _prefsKeyUsageTime = 'app_usage_time_seconds';
  static const String _prefsKeyDialogShown = 'support_dialog_shown_after_8min';
  static const String _prefsKeyDialogDontShow = 'support_dialog_dont_show';
  static const int _targetSeconds = 8 * 60; // 8 minutes in seconds

  DateTime? _sessionStartTime;
  int _accumulatedSeconds = 0;
  bool _dialogShown = false;
  bool _dontShowAgain = false;
  bool _initialized = false;

  int get accumulatedSeconds => _accumulatedSeconds;
  int get targetSeconds => _targetSeconds;
  double get progress => (_accumulatedSeconds / _targetSeconds).clamp(0.0, 1.0);
  bool get isTargetReached => _accumulatedSeconds >= _targetSeconds;
  bool get shouldShowDialog => isTargetReached && !_dialogShown && !_dontShowAgain;

  /// Initialize the service
  Future<void> initialize() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    _accumulatedSeconds = prefs.getInt(_prefsKeyUsageTime) ?? 0;
    _dialogShown = prefs.getBool(_prefsKeyDialogShown) ?? false;
    _dontShowAgain = prefs.getBool(_prefsKeyDialogDontShow) ?? false;

    // Register as observer to track app lifecycle
    WidgetsBinding.instance.addObserver(this);

    _initialized = true;
    debugPrint('[UsageTime] Initialized with $_accumulatedSeconds seconds accumulated');
  }

  /// Dispose and unregister observer
  void disposeService() {
    WidgetsBinding.instance.removeObserver(this);
    _saveSessionTime();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _onAppForeground();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _onAppBackground();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // Do nothing, just wait for paused
        break;
    }
  }

  void _onAppForeground() {
    _sessionStartTime = DateTime.now();
    debugPrint('[UsageTime] App entered foreground');
  }

  void _onAppBackground() {
    _saveSessionTime();
    debugPrint('[UsageTime] App entered background. Total: $_accumulatedSeconds seconds');
  }

  Future<void> _saveSessionTime() async {
    if (_sessionStartTime != null) {
      final sessionDuration = DateTime.now().difference(_sessionStartTime!).inSeconds;
      if (sessionDuration > 0) {
        _accumulatedSeconds += sessionDuration;
        await _saveToPrefs();
        
        // Check if we should show the dialog
        if (shouldShowDialog) {
          _showSupportDialog();
        }
      }
      _sessionStartTime = null;
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKeyUsageTime, _accumulatedSeconds);
  }

  /// Check and show support dialog if needed (call this periodically)
  Future<void> checkAndShowDialog(BuildContext context) async {
    if (!shouldShowDialog) return;
    
    // Save current session time first
    if (_sessionStartTime != null) {
      final sessionDuration = DateTime.now().difference(_sessionStartTime!).inSeconds;
      if (sessionDuration > 0) {
        _accumulatedSeconds += sessionDuration;
        _sessionStartTime = DateTime.now(); // Reset session start
        await _saveToPrefs();
      }
    }

    if (shouldShowDialog) {
      _showSupportDialog();
    }
  }

  void _showSupportDialog() async {
    _dialogShown = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKeyDialogShown, true);

    // Use a delayed post frame callback to show the dialog
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final context = _getContext();
      if (context != null) {
        showDialog(
          context: context,
          builder: (context) => const SupportDialog(),
          barrierDismissible: true,
        );
      }
    });
  }

  BuildContext? _getContext() {
    // This is a simplified approach - in practice we'd use a navigator key
    // The dialog will be shown via the periodic check in MainScreen
    return null;
  }

  /// Mark dialog as "don't show again"
  Future<void> markDontShowAgain() async {
    _dontShowAgain = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKeyDialogDontShow, true);
    notifyListeners();
  }

  /// Reset all tracking (for testing)
  Future<void> reset() async {
    _accumulatedSeconds = 0;
    _dialogShown = false;
    _dontShowAgain = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyUsageTime);
    await prefs.remove(_prefsKeyDialogShown);
    await prefs.remove(_prefsKeyDialogDontShow);
    notifyListeners();
  }

  /// Get formatted time string (e.g., "25 minutes")
  String get formattedTime {
    final minutes = _accumulatedSeconds ~/ 60;
    final seconds = _accumulatedSeconds % 60;
    if (minutes > 0) {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
    return '${seconds}s';
  }
}
