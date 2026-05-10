import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/now_playing_theme.dart';
import '../services/now_playing_theme_service.dart';
import '../widgets/theme_preview_card.dart';
import '../theme/app_theme.dart';
import 'theme_editor_screen.dart';

class ThemeManagerScreen extends StatefulWidget {
  const ThemeManagerScreen({super.key});

  @override
  State<ThemeManagerScreen> createState() => _ThemeManagerScreenState();
}

class _ThemeManagerScreenState extends State<ThemeManagerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSurface,
        title: const Text(
          'Now Playing Themes',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.add, color: Colors.white),
            onPressed: () => _createNewTheme(context),
          ),
          IconButton(
            icon: const Icon(
              CupertinoIcons.square_arrow_down,
              color: Colors.white,
            ),
            onPressed: () => _importTheme(context),
          ),
        ],
      ),
      body: Consumer<NowPlayingThemeService>(
        builder: (context, service, _) {
          final themes = [...service.themes];
          final defaultTheme = service.getDefaultTheme();
          final hasDefaultInList = themes.any((t) => t.id == 'default');
          if (!hasDefaultInList) {
            themes.insert(0, defaultTheme);
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: themes.length,
            itemBuilder: (context, index) {
              final theme = themes[index];
              final isActive = service.activeTheme?.id == theme.id;
              final isDefault = theme.id == 'default';

              return ThemePreviewCard(
                theme: theme,
                isActive: isActive || (service.activeTheme == null && isDefault),
                onTap: () => _activateTheme(context, theme, service),
                onEdit: isDefault
                    ? null
                    : () => _editTheme(context, theme),
                onDuplicate: () => _duplicateTheme(context, theme, service),
                onExport: isDefault ? null : () => _exportTheme(context, theme, service),
                onDelete: isDefault
                    ? null
                    : () => _deleteTheme(context, theme, service),
                onToggleSafeMode: theme.customFlutterCode.enabled
                    ? () => _toggleSafeMode(context, theme, service)
                    : null,
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _createNewTheme(BuildContext context) async {
    final service = context.read<NowPlayingThemeService>();
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newTheme = NowPlayingTheme(
      id: newId,
      themeName: 'New Theme',
      author: 'Me',
      createdAt: DateTime.now(),
    );

    await service.saveTheme(newTheme);

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ThemeEditorScreen(themeId: newId),
        ),
      );
    }
  }

  Future<void> _activateTheme(
    BuildContext context,
    NowPlayingTheme theme,
    NowPlayingThemeService service,
  ) async {
    final isCurrentlyActive = service.activeTheme?.id == theme.id;
    final isDefault = theme.id == 'default';

    if (isCurrentlyActive && !isDefault) {
      // Deactivate
      await service.setActiveTheme(null);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Theme deactivated (using default)')),
        );
      }
    } else if (isDefault) {
      // Activate default explicitly (clear active)
      await service.setActiveTheme(null);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Default theme activated')),
        );
      }
    } else {
      // Activate this theme
      await service.setActiveTheme(theme.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${theme.themeName} activated')),
        );
      }
    }
  }

  Future<void> _editTheme(BuildContext context, NowPlayingTheme theme) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ThemeEditorScreen(themeId: theme.id),
      ),
    );
  }

  Future<void> _duplicateTheme(
    BuildContext context,
    NowPlayingTheme theme,
    NowPlayingThemeService service,
  ) async {
    final controller = TextEditingController(text: '${theme.themeName} Copy');

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: const Text(
          'Duplicate Theme',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'New theme name',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.appleMusicRed),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(ctx, controller.text.trim());
              }
            },
            child: const Text(
              'Duplicate',
              style: TextStyle(
                color: AppTheme.appleMusicRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    controller.dispose();

    if (result != null && result.isNotEmpty && context.mounted) {
      await service.duplicateTheme(theme.id, result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Duplicated as "$result"')),
        );
      }
    }
  }

  Future<void> _exportTheme(
    BuildContext context,
    NowPlayingTheme theme,
    NowPlayingThemeService service,
  ) async {
    try {
      final json = service.exportTheme(theme.id);
      final fileName = '${theme.themeName.replaceAll(' ', '_')}_theme.json';

      if (Platform.isAndroid || Platform.isIOS) {
        // Mobile: use file picker to save
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'Export Theme',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['json'],
        );

        if (result != null) {
          final file = File(result);
          await file.writeAsString(json);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Exported to $result')),
            );
          }
        }
      } else {
        // Desktop: use file picker to save
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'Export Theme',
          fileName: fileName,
        );

        if (result != null) {
          final file = File(result);
          await file.writeAsString(json);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Exported to $result')),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _importTheme(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.first.path!);
      final jsonString = await file.readAsString();

      final service = context.read<NowPlayingThemeService>();
      final importResult = await service.importTheme(jsonString);

      if (!context.mounted) return;

      if (!importResult.valid) {
        _showErrorDialog(context, importResult.errors);
        return;
      }

      if (importResult.hasCustomCode) {
        final approved = await _showSecurityDialog(context, importResult);
        if (approved != true || !context.mounted) return;

        final safeMode = approved == 'safe';
        final finalTheme = importResult.theme!.copyWith(safeMode: safeMode);
        await service.saveTheme(finalTheme);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Theme imported${safeMode ? ' (Safe Mode)' : ''}',
              ),
            ),
          );
        }
      } else {
        await service.saveTheme(importResult.theme!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Theme imported successfully')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  void _showErrorDialog(BuildContext context, List<String> errors) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: const Text(
          'Import Failed',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The theme file contains errors:',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            ...errors.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: Colors.red)),
                    Expanded(
                      child: Text(
                        e,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'OK',
              style: TextStyle(color: AppTheme.appleMusicRed),
            ),
          ),
        ],
      ),
    );
  }

  Future<dynamic> _showSecurityDialog(
    BuildContext context,
    ImportResult result,
  ) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Row(
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle_fill,
              color: Colors.orange,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Text(
              'Security Warning',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This theme contains custom Flutter code which may pose security risks.',
                style: TextStyle(color: Colors.white.withOpacity(0.9)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Theme Details:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildDetailRow('Name', result.theme!.themeName),
              _buildDetailRow('Author', result.theme!.author),
              _buildDetailRow('Version', result.theme!.version),
              const SizedBox(height: 12),
              const Text(
                'Custom Widgets:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...result.customWidgetNames.map(
                (name) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.function,
                        size: 14,
                        color: Colors.purple,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        name,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              if (result.dependencies.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Dependencies:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...result.dependencies.map(
                  (dep) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• $dep',
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'safe'),
            child: const Text(
              'Safe Mode',
              style: TextStyle(color: Colors.orange),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Enable Code',
              style: TextStyle(
                color: AppTheme.appleMusicRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTheme(
    BuildContext context,
    NowPlayingTheme theme,
    NowPlayingThemeService service,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: const Text(
          'Delete Theme',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${theme.themeName}"?',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: AppTheme.appleMusicRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await service.deleteTheme(theme.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${theme.themeName} deleted')),
        );
      }
    }
  }

  Future<void> _toggleSafeMode(
    BuildContext context,
    NowPlayingTheme theme,
    NowPlayingThemeService service,
  ) async {
    await service.toggleSafeMode(theme.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Safe Mode ${theme.safeMode ? 'disabled' : 'enabled'}',
          ),
        ),
      );
    }
  }
}
