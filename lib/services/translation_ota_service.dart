import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TranslationOtaService {
  static final TranslationOtaService _instance =
      TranslationOtaService._internal();
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
  static const String _percentagesKey = 'ota_percentages_cache';

  final Map<String, String> _activeTranslations = {};
  final Set<String> _discoveredLocales = {};
  final Map<String, int> _percentages = {};

  Set<String> get discoveredLocales => Set.unmodifiable(_discoveredLocales);
  Map<String, String> get activeTranslations =>
      Map.unmodifiable(_activeTranslations);
  Map<String, int> get completionPercentages =>
      Map.unmodifiable(_percentages);

  Future<void> init(String? currentLocaleCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedLocales = prefs.getStringList(_discoveredLocalesKey);
      if (savedLocales != null) {
        _discoveredLocales.addAll(savedLocales);
      }

      final cachedPercentagesRaw = prefs.getString(_percentagesKey);
      if (cachedPercentagesRaw != null) {
        final decoded = json.decode(cachedPercentagesRaw);
        if (decoded is Map<String, dynamic>) {
          for (final entry in decoded.entries) {
            if (entry.value is num) {
              _percentages[entry.key] = (entry.value as num).toInt();
            }
          }
        }
      }

      if (currentLocaleCode != null) {
        await loadCachedLocale(currentLocaleCode);
      }
    } catch (e) {
      debugPrint('TranslationOtaService init error: $e');
    }
  }

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

  Future<bool> syncTranslations(
      {String? localeCode, bool force = false}) async {
    final targetLocale = localeCode ?? 'en';

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastTs = prefs.getInt('$_otaTimestampPrefix$targetLocale') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      if (!force && (now - lastTs < 30 * 60 * 1000)) {
        return false;
      }

      final url =
          'https://raw.githubusercontent.com/dddevid/Musly/master/lib/l10n/app_$targetLocale.arb';
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

          await prefs.setString(
              '$_otaPrefix$targetLocale', json.encode(stringsOnly));
          await prefs.setInt('$_otaTimestampPrefix$targetLocale', now);

          _activeTranslations.clear();
          _activeTranslations.addAll(stringsOnly);
          debugPrint(
              'TranslationOtaService: Synced ${stringsOnly.length} strings for $targetLocale');
        }
      }

      await _syncPercentages(prefs);
      await _discoverRemoteLanguages(prefs);
      return true;
    } catch (e) {
      debugPrint('TranslationOtaService: Sync error for $targetLocale: $e');
      return false;
    }
  }

  Future<void> _syncPercentages(SharedPreferences prefs) async {
    try {
      final url =
          'https://raw.githubusercontent.com/dddevid/Musly/master/lib/l10n/translation_percentages.json';
      final res = await _dio.get<String>(
        url,
        options: Options(responseType: ResponseType.plain),
      );

      if (res.statusCode == 200 && res.data != null) {
        final decoded = json.decode(res.data!);
        if (decoded is Map<String, dynamic>) {
          final Map<String, int> parsed = {};
          for (final entry in decoded.entries) {
            if (entry.value is num) {
              parsed[entry.key] = (entry.value as num).toInt();
            }
          }
          if (parsed.isNotEmpty) {
            _percentages.addAll(parsed);
            await prefs.setString(_percentagesKey, json.encode(_percentages));
            debugPrint(
              'TranslationOtaService: Synced ${parsed.length} translation percentages',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('TranslationOtaService: Percentage sync error: $e');
    }
  }

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
            if (name.startsWith('app_') &&
                name.endsWith('.arb') &&
                name != 'app_en.arb') {
              final code = name.substring(4, name.length - 4);
              if (code.isNotEmpty) {
                found.add(code);
              }
            }
          }
        }

        if (found.isNotEmpty) {
          _discoveredLocales.addAll(found);
          await prefs.setStringList(
              _discoveredLocalesKey, _discoveredLocales.toList());
        }
      }
    } catch (_) {}
  }

  int? getCompletionPercentage(String localeCode) {
    return _percentages[localeCode];
  }

  @visibleForTesting
  void setCompletionPercentages(Map<String, int> percentages) {
    _percentages.addAll(percentages);
  }

  String? get(String key) {
    return _activeTranslations[key];
  }
}
