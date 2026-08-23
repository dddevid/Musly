import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight local service for app rating tracking and local diagnostics.
/// All Countly tracking and telemetry have been completely removed.
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  bool _initialized = false;
  bool _enabled = false;

  bool get isEnabled => _enabled;
  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
  }

  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
  }

  Future<void> recordEvent(
    String eventKey, [
    Map<String, dynamic>? segmentation,
  ]) async {}

  Future<void> recordScreenView(String screenName) async {}

  Future<void> recordRating(int rating, [String? feedback]) async {}

  Future<void> recordFeatureUsage(String featureName) async {}

  Future<void> recordPlaybackStarted(String source) async {}

  Future<void> recordDownload(String type, int count) async {}

  Future<void> markAppAsRated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_rated_app', true);
  }

  Future<bool> shouldShowRatingPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    final launches = prefs.getInt('app_launches') ?? 0;
    final hasRated = prefs.getBool('has_rated_app') ?? false;
    final lastPrompt = prefs.getInt('last_rating_prompt') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final daysSinceLastPrompt = (now - lastPrompt) / (1000 * 60 * 60 * 24);

    return !hasRated &&
        launches >= 5 &&
        launches % 20 == 0 &&
        daysSinceLastPrompt > 30;
  }

  Future<void> setConsent(String consent, bool enabled) async {}

  Future<void> recordError(String error, StackTrace? stackTrace) async {}

  Future<String?> getDeviceId() async => null;
}

class AnalyticsNavigatorObserver extends NavigatorObserver {}
