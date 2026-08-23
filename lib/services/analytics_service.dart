import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:countly_flutter/countly_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/analytics_config.dart';

/// Analytics service using Countly SDK
///
/// Features:
/// - Completely anonymous tracking (no personal data)
/// - Crash reporting
/// - Monthly Active Users (MAU)
/// - Geographic distribution (country level only)
/// - App ratings (user-triggered feedback)
///
/// Privacy: Countly is self-hosted and GDPR compliant.
/// No advertising IDs, no personal data, no third-party sharing.
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  // Load from environment variables (set during build with --dart-define)
  static String get _serverUrl => AnalyticsConfig.serverUrl;
  static String get _appKey => AnalyticsConfig.appKey;
  static const String _analyticsEnabledKey = 'analytics_enabled';
  static const String _analyticsAskedKey = 'analytics_asked';

  bool _initialized = false;
  bool _enabled = false;

  bool get isEnabled => _enabled;
  bool get isInitialized => _initialized;

  /// Initialize Countly SDK with anonymous configuration
  Future<void> initialize() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_analyticsEnabledKey) ?? false;

    // Only initialize if user has opted in or if analytics were asked
    // For anonymous analytics, we enable by default but can be disabled
    final hasAsked = prefs.getBool(_analyticsAskedKey) ?? false;

    if (!hasAsked) {
      // First time - enable anonymous analytics by default
      // (can be disabled in settings)
      _enabled = true;
      await prefs.setBool(_analyticsEnabledKey, true);
      await prefs.setBool(_analyticsAskedKey, true);
    }

    if (!_enabled || !AnalyticsConfig.isConfigured) {
      if (!AnalyticsConfig.isConfigured) {
        debugPrint(
          'Analytics disabled: not configured (missing env variables)',
        );
      }
      return;
    }

    try {
      // Configure Countly with privacy-first settings
      final config = CountlyConfig(_serverUrl, _appKey)
          .setLoggingEnabled(kDebugMode)
          // Enable automatic crash reporting
          .enableCrashReporting()
          // Set session duration update interval (10 minutes)
          .setUpdateSessionTimerDelay(10)
          // Consent-based tracking - require all consents for GDPR compliance
          .setRequiresConsent(true)
          // Enable required consents (as strings)
          .setConsentEnabled([
        'sessions',
        'crashes',
        'location', // Country level only, not precise location
        'events',
        'users', // Anonymous user profiles only
      ]);

      await Countly.initWithConfig(config);

      // Record app start event
      await recordEvent('app_start');

      // Track rating prompt if needed
      await _checkAndPromptRating();

      _initialized = true;
      debugPrint('Analytics initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize analytics: $e');
    }
  }

  /// Enable/disable analytics
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_analyticsEnabledKey, enabled);
    _enabled = enabled;

    if (enabled && !_initialized) {
      await initialize();
    } else if (!enabled && _initialized) {
      await Countly.removeConsent([
        'sessions',
        'crashes',
        'location',
        'events',
        'users',
      ]);
    }
  }

  /// Record a custom event
  Future<void> recordEvent(
    String eventKey, [
    Map<String, dynamic>? segmentation,
  ]) async {
    if (!_enabled || !_initialized) return;

    try {
      await Countly.instance.events.recordEvent(
        eventKey,
        segmentation: segmentation != null
            ? Map<String, Object>.from(segmentation)
            : {},
        count: 1,
      );
    } catch (e) {
      debugPrint('Failed to record event: $e');
    }
  }

  /// Record screen view
  Future<void> recordScreenView(String screenName) async {
    if (!_enabled || !_initialized) return;

    try {
      await Countly.instance.views.startView(screenName);
    } catch (e) {
      debugPrint('Failed to record view: $e');
    }
  }

  /// Record app rating given by user
  Future<void> recordRating(int rating, [String? feedback]) async {
    if (!_enabled || !_initialized) return;

    try {
      await recordEvent('app_rating', {
        'rating': rating.toString(),
        'platform': Platform.operatingSystem,
        'feedback': feedback ?? '',
      });

      // Send feedback if provided
      if (feedback != null && feedback.isNotEmpty) {
        await Countly.instance.events.recordEvent(
          'rating_feedback',
          segmentation: <String, Object>{'rating': rating.toString(), 'feedback': feedback},
          count: 1,
        );
      }
    } catch (e) {
      debugPrint('Failed to record rating: $e');
    }
  }

  /// Record feature usage
  Future<void> recordFeatureUsage(String featureName) async {
    await recordEvent('feature_used', {'feature': featureName});
  }

  /// Record playback started
  Future<void> recordPlaybackStarted(String source) async {
    await recordEvent('playback_started', {'source': source});
  }

  /// Record download event
  Future<void> recordDownload(String type, int count) async {
    await recordEvent('download', {'type': type, 'count': count.toString()});
  }

  /// Check if we should prompt for rating
  Future<void> _checkAndPromptRating() async {
    final prefs = await SharedPreferences.getInstance();
    final launches = prefs.getInt('app_launches') ?? 0;
    final hasRated = prefs.getBool('has_rated_app') ?? false;
    final lastPrompt = prefs.getInt('last_rating_prompt') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Increment launch counter
    await prefs.setInt('app_launches', launches + 1);

    // Prompt after 5 launches, then every 20 launches
    // Only if not already rated and not prompted in last 30 days
    if (!hasRated) {
      final daysSinceLastPrompt = (now - lastPrompt) / (1000 * 60 * 60 * 24);

      if ((launches >= 5 && launches % 20 == 0) && daysSinceLastPrompt > 30) {
        await prefs.setInt('last_rating_prompt', now);
        // The actual rating dialog is shown by the UI layer
        await recordEvent('rating_prompt_shown', {
          'launch_count': launches.toString(),
        });
      }
    }
  }

  /// Mark that user has rated the app
  Future<void> markAppAsRated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_rated_app', true);
  }

  /// Get whether rating dialog should be shown
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

  /// Change consent for specific feature
  Future<void> setConsent(String consent, bool enabled) async {
    if (!_initialized) return;

    try {
      if (enabled) {
        await Countly.giveConsent([consent]);
      } else {
        await Countly.removeConsent([consent]);
      }
    } catch (e) {
      debugPrint('Failed to change consent: $e');
    }
  }

  /// Record error (non-fatal)
  Future<void> recordError(String error, StackTrace? stackTrace) async {
    if (!_enabled || !_initialized) return;

    try {
      // Log to analytics as a custom event since recordException might not be available
      await recordEvent('error_logged', {
        'error': error.substring(0, error.length > 100 ? 100 : error.length),
        'has_stacktrace': stackTrace != null ? 'true' : 'false',
      });
    } catch (e) {
      debugPrint('Failed to record error: $e');
    }
  }

  /// Get the anonymous device ID used for analytics
  /// This is the actual device ID generated by Countly SDK
  Future<String?> getDeviceId() async {
    // If Countly is already initialized, get the ID using the new API
    if (_initialized) {
      try {
        return await Countly.instance.deviceId.getID();
      } catch (e) {
        debugPrint('Failed to get device ID from Countly: $e');
        return null;
      }
    }

    // If not initialized but configured, initialize just to get the device ID
    if (AnalyticsConfig.isConfigured) {
      try {
        // Minimal config to initialize and get device ID
        // No consents given = no tracking, just device ID generation
        final config = CountlyConfig(_serverUrl, _appKey)
            .setLoggingEnabled(kDebugMode)
            .setRequiresConsent(
                true); // Require consent but don't give any = no tracking

        await Countly.initWithConfig(config);

        // Get the device ID
        final deviceId = await Countly.instance.deviceId.getID();

        // Mark as initialized so we don't re-init
        _initialized = true;
        _enabled = false; // Tracking is disabled (no consent)

        return deviceId;
      } catch (e) {
        debugPrint('Failed to initialize Countly for device ID: $e');
        return null;
      }
    }

    return null;
  }

  /// Note about Countly SDK logging:
  /// The Countly SDK may log the app_key in debug logs when network requests
  /// are made. This is controlled by the SDK itself and only appears in:
  /// - Debug builds (setLoggingEnabled: kDebugMode handles this)
  /// - Android logcat (not visible to end users in production)
  /// - Not visible in release builds with kDebugMode = false
  ///
  /// The app_key is only a write-only token for event submission and
  /// cannot be used to access any data. It is safe even if visible in logs.
}

/// Navigator observer that automatically tracks screen views
class AnalyticsNavigatorObserver extends NavigatorObserver {
  final Set<String> _trackedRoutes = {};

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _trackRoute(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _trackRoute(newRoute);
    }
  }

  void _trackRoute(Route<dynamic> route) {
    if (route is ModalRoute && route.settings.name != null) {
      final screenName = route.settings.name!;
      // Avoid tracking the same route multiple times
      if (!_trackedRoutes.contains(screenName)) {
        _trackedRoutes.add(screenName);
        AnalyticsService().recordScreenView(screenName);
      }
    } else {
      // Try to get screen name from route runtime type
      final routeName = route.runtimeType.toString();
      if (routeName.contains('Screen') || routeName.contains('Page')) {
        AnalyticsService().recordScreenView(routeName);
      }
    }
  }
}
