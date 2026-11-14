import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/update_service.dart';

class UpdateDialog extends StatefulWidget {
  final ReleaseInfo release;

  const UpdateDialog({
    super.key,
    required this.release,
  });

  static Future<void> show(BuildContext context, ReleaseInfo release) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => UpdateDialog(release: release),
    );
  }

  static Future<void> checkAndShow(BuildContext context, {bool manual = false}) async {
    if (!manual) {
      if (UpdateService.hasCheckedStartup) return;
      UpdateService.markStartupChecked();
    }
    if (manual && context.mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.checkingForUpdates ?? 'Checking for updates...'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    try {
      final release = await UpdateService.checkForUpdate(force: manual);
      if (!context.mounted) return;
      if (release != null) {
        await show(context, release);
      } else if (manual) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.appUpToDate ?? 'App is up to date'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('UpdateDialog: check error – $e');
      if (manual && context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to check for updates: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _downloadStatusText = '';
  CancelToken? _cancelToken;
  String? _errorMessage;
  late final String _changelog;
  DateTime? _lastProgressUpdateTime;
  double _lastProgressFraction = 0.0;

  @override
  void initState() {
    super.initState();
    _changelog = UpdateService.stripMarkdown(widget.release.body);
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  void _onDownloadProgress(int received, int total) {
    if (!mounted) return;
    if (total > 0) {
      final fraction = (received / total).clamp(0.0, 1.0);
      final now = DateTime.now();
      final isDone = received >= total;
      final timePassed = _lastProgressUpdateTime == null ||
          now.difference(_lastProgressUpdateTime!).inMilliseconds >= 80;
      final progressChanged =
          (fraction - _lastProgressFraction).abs() >= 0.01;

      if (isDone || (timePassed && progressChanged)) {
        _lastProgressUpdateTime = now;
        _lastProgressFraction = fraction;
        final recMb = (received / (1024 * 1024)).toStringAsFixed(1);
        final totMb = (total / (1024 * 1024)).toStringAsFixed(1);
        final percent = (fraction * 100).toInt();
        setState(() {
          _downloadProgress = fraction;
          _downloadStatusText = '$percent% ($recMb / $totMb MB)';
        });
      }
    }
  }

  Future<void> _startDownloadAndInstall() async {
    final asset = widget.release.targetAsset;
    if (asset == null) {
      await UpdateService.openReleasePage(widget.release);
      if (mounted) Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _downloadStatusText = '0%';
      _errorMessage = null;
      _cancelToken = CancelToken();
      _lastProgressUpdateTime = null;
      _lastProgressFraction = 0.0;
    });

    try {
      final downloadedPath = await UpdateService.downloadAsset(
        asset,
        cancelToken: _cancelToken,
        onProgress: _onDownloadProgress,
      );

      if (!mounted) return;
      setState(() {
        _downloadProgress = 1.0;
        _downloadStatusText = 'Download completato!';
      });

      await UpdateService.launchInstallerOrFile(
        downloadedPath,
        release: widget.release,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      if (e is DioException && e.type == DioExceptionType.cancel) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0.0;
          _downloadStatusText = '';
        });
        return;
      }
      setState(() {
        _isDownloading = false;
        _errorMessage = 'Download non riuscito: $e';
      });
    }
  }

  void _cancelDownload() {
    _cancelToken?.cancel();
    setState(() {
      _isDownloading = false;
      _downloadProgress = 0.0;
      _downloadStatusText = '';
      _lastProgressUpdateTime = null;
      _lastProgressFraction = 0.0;
    });
  }

  Future<void> _skipVersion() async {
    await UpdateService.skipVersion(widget.release.version);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final l10n = AppLocalizations.of(context)!;
    final asset = widget.release.targetAsset;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E1E22) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.system_update_rounded,
                      color: primaryColor,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.updateAvailable,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              'v${UpdateService.currentVersion}',
                              style: TextStyle(
                                fontSize: 13,
                                color:
                                    isDark ? Colors.white54 : Colors.black45,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'v${widget.release.version}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!_isDownloading)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Chiudi',
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (asset != null && asset.formattedSize.isNotEmpty) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.download_rounded,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          asset.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                      Text(
                        asset.formattedSize,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                'Novità e Changelog:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.black.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _changelog.isNotEmpty
                          ? _changelog
                          : 'Nuovi miglioramenti e correzioni di bug.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
              if (_isDownloading) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _downloadProgress > 0 ? _downloadProgress : null,
                    minHeight: 8,
                    backgroundColor:
                        isDark ? Colors.white12 : Colors.black12,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _downloadStatusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    TextButton(
                      onPressed: _cancelDownload,
                      child: const Text('Annulla', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
              ],
              const SizedBox(height: 16),
              if (!_isDownloading) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            UpdateService.openReleasePage(widget.release),
                        icon: const Icon(Icons.open_in_new_rounded, size: 16),
                        label: Text(l10n.openOnGitHub),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _startDownloadAndInstall,
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: Text(l10n.updateNow),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _skipVersion,
                      child: Text(
                        l10n.skipThisVersion,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Più tardi',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
