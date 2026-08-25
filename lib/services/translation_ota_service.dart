import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TranslationOtaService {
  static final TranslationOtaService _instance = TranslationOtaService._internal();
  factory TranslationOtaService() => _instance;
  TranslationOtaService._internal();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      headers: {'Accept': 'application/json'},
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  static const String _otaPrefix = 'ota_l10n_';
  static const String _otaTimestampPrefix = 'ota_l10n_ts_';
  static const String _discoveredLocalesKey = 'ota_discovered_locales';

  final Map<String, String> _activeTranslations = {};
  final Set<String> _discoveredLocales = {};

  Set<String> get discoveredLocales => Set.unmodifiable(_discoveredLocales);
  Map<String, String> get activeTranslations => Map.unmodifiable(_activeTranslations);

  /// Load cached OTA translations and discovered locales from SharedPreferences
  Future<void> init(String? currentLocaleCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load discovered locales
      final savedLocales = prefs.getStringList(_discoveredLocalesKey);
      if (savedLocales != null) {
        _discoveredLocales.addAll(savedLocales);
      }

      // Load active translations for current locale if available
      if (currentLocaleCode != null) {
        await loadCachedLocale(currentLocaleCode);
      }
    } catch (e) {
      debugPrint('TranslationOtaService init error: $e');
    }
  }

  /// Load cached translations for a specific locale from local storage
  Future<void> loadCachedLocale(String localeCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_otaPrefix$localeCode');
      if (raw != null) {
        final decoded = json.decode(raw);
        if (decoded is Map<String, dynamic>) {
          _activeTranslations.clear();
          for (final entry in decoded.entries) {
            if (!entry.key.startsWith('@') && entry.value is String) {
              _activeTranslations[entry.key] = entry.value as String;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('TranslationOtaService loadCachedLocale error: $e');
    }
  }

  /// Check and fetch live translations from GitHub raw / Crowdin for the given locale
  Future<bool> syncTranslations({String? localeCode, bool force = false}) async {
    final targetLocale = localeCode ?? 'en';
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastTs = prefs.getInt('$_otaTimestampPrefix$targetLocale') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Throttle automatic checks to at most once every 30 minutes unless forced
      if (!force && (now - lastTs < 30 * 60 * 1000)) {
        return false;
      }

      // 1. Fetch latest .arb file for target locale from GitHub master
      final url = 'https://raw.githubusercontent.com/dddevid/Musly/master/lib/l10n/app_$targetLocale.arb';
      final response = await _dio.get<String>(
        url,
        options: Options(responseType: ResponseType.plain),
      );

      if (response.statusCode == 200 && response.data != null) {
        final decoded = json.decode(response.data!);
        if (decoded is Map<String, dynamic>) {
          final Map<String, String> stringsOnly = {};
          for (final entry in decoded.entries) {
            if (!entry.key.startsWith('@') && entry.value is String) {
              stringsOnly[entry.key] = entry.value as String;
            }
          }

          // Save to prefs
          await prefs.setString('$_otaPrefix$targetLocale', json.encode(stringsOnly));
          await prefs.setInt('$_otaTimestampPrefix$targetLocale', now);

          _activeTranslations.clear();
          _activeTranslations.addAll(stringsOnly);
          debugPrint('TranslationOtaService: Synced ${stringsOnly.length} strings for $targetLocale');
        }
      }

      // 2. Discover any newly added languages in lib/l10n
      await _discoverRemoteLanguages(prefs);
      return true;
    } catch (e) {
      debugPrint('TranslationOtaService: Sync error for $targetLocale: $e');
      return false;
    }
  }

  /// Discover newly added language files from GitHub repository
  Future<void> _discoverRemoteLanguages(SharedPreferences prefs) async {
    try {
      final res = await _dio.get<dynamic>(
        'https://api.github.com/repos/dddevid/Musly/contents/lib/l10n',
      );

      if (res.statusCode == 200 && res.data is List) {
        final List items = res.data as List;
        final Set<String> found = {};
        for (final item in items) {
          if (item is Map && item['name'] is String) {
            final name = item['name'] as String;
            if (name.startsWith('app_') && name.endsWith('.arb') && name != 'app_en.arb') {
              final code = name.substring(4, name.length - 4);
              if (code.isNotEmpty) {
                found.add(code);
              }
            }
          }
        }

        if (found.isNotEmpty) {
          _discoveredLocales.addAll(found);
          await prefs.setStringList(_discoveredLocalesKey, _discoveredLocales.toList());
        }
      }
    } catch (_) {
      // Ignore discovery errors (e.g. offline or rate limited)
    }
  }

  /// Get live translation for a key if available
  String? get(String key) {
    return _activeTranslations[key];
  }
}
