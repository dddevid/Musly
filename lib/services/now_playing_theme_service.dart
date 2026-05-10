import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/now_playing_theme.dart';

/// Result of a theme import operation
class ImportResult {
  final bool valid;
  final List<String> errors;
  final List<String> warnings;
  final bool hasCustomCode;
  final List<String> customWidgetNames;
  final List<String> dependencies;
  final NowPlayingTheme? theme;

  const ImportResult({
    required this.valid,
    this.errors = const [],
    this.warnings = const [],
    this.hasCustomCode = false,
    this.customWidgetNames = const [],
    this.dependencies = const [],
    this.theme,
  });
}

/// Service for managing Now Playing themes
class NowPlayingThemeService extends ChangeNotifier {
  static const String _keyActiveThemeId = 'active_now_playing_theme_id';

  List<NowPlayingTheme> _themes = [];
  String? _activeThemeId;
  String? _themesDir;

  List<NowPlayingTheme> get themes => List.unmodifiable(_themes);
  NowPlayingTheme? get activeTheme =>
      _themes.where((t) => t.id == _activeThemeId).firstOrNull;
  bool get hasActiveTheme => _activeThemeId != null && activeTheme != null;

  /// Initialize the service and load all themes
  Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    _themesDir = '${appDir.path}/now_playing_themes';
    final themesDirectory = Directory(_themesDir!);

    if (!themesDirectory.existsSync()) {
      themesDirectory.createSync(recursive: true);
    }

    // Load active theme ID from preferences
    final prefs = await SharedPreferences.getInstance();
    _activeThemeId = prefs.getString(_keyActiveThemeId);

    // Load all themes from disk
    await loadThemes();

    // If no active theme or active theme doesn't exist, use default
    if (_activeThemeId == null ||
        !_themes.any((t) => t.id == _activeThemeId)) {
      _activeThemeId = null;
      await prefs.remove(_keyActiveThemeId);
    }
  }

  /// Load all themes from disk
  Future<void> loadThemes() async {
    if (_themesDir == null) return;

    _themes.clear();
    final themesDirectory = Directory(_themesDir!);

    if (!themesDirectory.existsSync()) {
      return;
    }

    final files = themesDirectory
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'));

    for (final file in files) {
      try {
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        final theme = NowPlayingTheme.fromJson(json);
        _themes.add(theme);
      } catch (e) {
        debugPrint('Error loading theme from ${file.path}: $e');
      }
    }

    notifyListeners();
  }

  /// Save a theme to disk
  Future<void> saveTheme(NowPlayingTheme theme) async {
    if (_themesDir == null) return;

    final file = File('$_themesDir/${theme.id}.json');
    final json = theme.toJson();
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(json),
    );

    // Update in-memory list
    final index = _themes.indexWhere((t) => t.id == theme.id);
    if (index >= 0) {
      _themes[index] = theme;
    } else {
      _themes.add(theme);
    }

    notifyListeners();
  }

  /// Delete a theme
  Future<void> deleteTheme(String themeId) async {
    if (_themesDir == null || themeId == 'default') return;

    final file = File('$_themesDir/$themeId.json');
    if (file.existsSync()) {
      await file.delete();
    }

    _themes.removeWhere((t) => t.id == themeId);

    // If deleted theme was active, clear active theme
    if (_activeThemeId == themeId) {
      _activeThemeId = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyActiveThemeId);
    }

    notifyListeners();
  }

  /// Duplicate a theme with a new ID and name
  Future<NowPlayingTheme> duplicateTheme(
    String sourceThemeId,
    String newName,
  ) async {
    final source = _themes.firstWhere((t) => t.id == sourceThemeId);
    final newId = DateTime.now().millisecondsSinceEpoch.toString();

    final duplicated = NowPlayingTheme(
      id: newId,
      themeName: newName,
      author: source.author,
      version: source.version,
      createdAt: DateTime.now(),
      background: source.background,
      text: source.text,
      artwork: source.artwork,
      progressBar: source.progressBar,
      controls: source.controls,
      layout: source.layout,
      animations: source.animations,
      customFlutterCode: source.customFlutterCode,
      safeMode: source.safeMode,
    );

    await saveTheme(duplicated);
    return duplicated;
  }

  /// Set the active theme
  Future<void> setActiveTheme(String? themeId) async {
    _activeThemeId = themeId;
    final prefs = await SharedPreferences.getInstance();

    if (themeId == null) {
      await prefs.remove(_keyActiveThemeId);
    } else {
      await prefs.setString(_keyActiveThemeId, themeId);
    }

    notifyListeners();
  }

  /// Export a theme to a JSON string
  String exportTheme(String themeId) {
    final theme = _themes.firstWhere((t) => t.id == themeId);
    final json = theme.toJson();
    return const JsonEncoder.withIndent('  ').convert(json);
  }

  /// Import a theme from JSON string
  Future<ImportResult> importTheme(String jsonString) async {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final theme = NowPlayingTheme.fromJson(json);

      // Validate theme
      final errors = theme.validate();
      if (errors.isNotEmpty) {
        return ImportResult(
          valid: false,
          errors: errors,
        );
      }

      // Check for custom code
      final hasCustomCode = theme.customFlutterCode.enabled &&
          theme.customFlutterCode.widgets.isNotEmpty;
      final customWidgetNames = hasCustomCode
          ? theme.customFlutterCode.widgets.map((w) => w.name).toList()
          : <String>[];
      final dependencies = hasCustomCode
          ? theme.customFlutterCode.widgets
              .expand((w) => w.dependencies)
              .toSet()
              .toList()
          : <String>[];

      final warnings = <String>[];
      if (hasCustomCode) {
        warnings.add(
          'This theme contains custom Flutter code which may pose security risks.',
        );
      }

      // Generate new ID to avoid conflicts
      final newId = DateTime.now().millisecondsSinceEpoch.toString();
      final importedTheme = theme.copyWith(id: newId);

      return ImportResult(
        valid: true,
        warnings: warnings,
        hasCustomCode: hasCustomCode,
        customWidgetNames: customWidgetNames,
        dependencies: dependencies,
        theme: importedTheme,
      );
    } catch (e) {
      return ImportResult(
        valid: false,
        errors: ['Invalid JSON format: $e'],
      );
    }
  }

  /// Toggle safe mode for a theme
  Future<void> toggleSafeMode(String themeId) async {
    final index = _themes.indexWhere((t) => t.id == themeId);
    if (index < 0) return;

    final theme = _themes[index];
    final updated = theme.copyWith(safeMode: !theme.safeMode);
    await saveTheme(updated);
  }

  /// Get the default theme (always available, not persisted)
  NowPlayingTheme getDefaultTheme() {
    return NowPlayingTheme.createDefault();
  }

  /// Get the currently effective theme (active custom or default)
  NowPlayingTheme getEffectiveTheme() {
    return activeTheme ?? getDefaultTheme();
  }
}
