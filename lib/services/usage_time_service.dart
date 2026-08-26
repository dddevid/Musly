import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:musly/widgets/dialogs/support_dialog.dart';

class UsageTimeService extends ChangeNotifier with WidgetsBindingObserver {
  static final UsageTimeService _instance = UsageTimeService._internal();
  factory UsageTimeService() => _instance;
  UsageTimeService._internal();

  static const String _prefsKeyUsageTime = 'app_usage_time_seconds';
  static const String _prefsKeyDialogShown = 'support_dialog_shown_after_8min';
  static const String _prefsKeyDialogDontShow = 'support_dialog_dont_show';
  static const int _targetSeconds = 8 * 60;

  DateTime? _sessionStartTime;
  int _accumulatedSeconds = 0;
  bool _dialogShown = false;
  bool _dontShowAgain = false;
  bool _initialized = false;

  int get accumulatedSeconds => _accumulatedSeconds;
  int get targetSeconds => _targetSeconds;
  double get progress => (_accumulatedSeconds / _targetSeconds).clamp(0.0, 1.0);
  bool get isTargetReached => _accumulatedSeconds >= _targetSeconds;
  bool get shouldShowDialog =>
      isTargetReached && !_dialogShown && !_dontShowAgain;

  Future<void> initialize() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    _accumulatedSeconds = prefs.getInt(_prefsKeyUsageTime) ?? 0;
    _dialogShown = prefs.getBool(_prefsKeyDialogShown) ?? false;
    _dontShowAgain = prefs.getBool(_prefsKeyDialogDontShow) ?? false;

    WidgetsBinding.instance.addObserver(this);

    _initialized = true;
    debugPrint(
        '[UsageTime] Initialized with $_accumulatedSeconds seconds accumulated');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveSessionTime();
    super.dispose();
  }

  void disposeService() {
    dispose();
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
        break;
    }
  }

  void _onAppForeground() {
    _sessionStartTime = DateTime.now();
    debugPrint('[UsageTime] App entered foreground');
  }

  void _onAppBackground() {
    _saveSessionTime();
    debugPrint(
        '[UsageTime] App entered background. Total: $_accumulatedSeconds seconds');
  }

  Future<void> _saveSessionTime() async {
    if (_sessionStartTime != null) {
      final sessionDuration =
          DateTime.now().difference(_sessionStartTime!).inSeconds;
      if (sessionDuration > 0) {
        _accumulatedSeconds += sessionDuration;
        await _saveToPrefs();

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

  Future<void> checkAndShowDialog(BuildContext context) async {
    if (!shouldShowDialog) return;

    if (_sessionStartTime != null) {
      final sessionDuration =
          DateTime.now().difference(_sessionStartTime!).inSeconds;
      if (sessionDuration > 0) {
        _accumulatedSeconds += sessionDuration;
        _sessionStartTime = DateTime.now();
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
    return null;
  }

  Future<void> markDontShowAgain() async {
    _dontShowAgain = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKeyDialogDontShow, true);
    notifyListeners();
  }

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

  String get formattedTime {
    final minutes = _accumulatedSeconds ~/ 60;
    final seconds = _accumulatedSeconds % 60;
    if (minutes > 0) {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
    return '${seconds}s';
  }
}
