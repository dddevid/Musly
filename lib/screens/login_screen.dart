import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/local_music_service.dart';
import '../theme/app_theme.dart';

enum _LoginErrorType {
  ssl,
  credentials,
  notFound,
  timeout,
  connection,
  format,
  generic,
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _useLegacyAuth = false;
  bool _allowSelfSignedCertificates = false;
  bool _obscurePassword = true;
  bool _showAdvancedOptions = false;
  String? _customCertificatePath;
  String? _customCertificateName;
  // mTLS client certificate
  String? _clientCertificatePath;
  String? _clientCertificateName;
  final _clientCertPasswordController = TextEditingController();
  bool _obscureClientCertPassword = true;
  bool _isScanning = false;
  double _scanProgress = 0.0;
  String _scanStatus = '';

  // Inline error state
  String? _loginError;

  @override
  void initState() {
    super.initState();
    // Clear the inline error whenever user edits any field
    _serverController.addListener(_clearError);
    _usernameController.addListener(_clearError);
    _passwordController.addListener(_clearError);
  }

  void _clearError() {
    if (_loginError != null && mounted) {
      setState(() => _loginError = null);
    }
  }

  /// Categorises a login error string for icon/colour selection.
  _LoginErrorType _categoriseError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('ssl') ||
        lower.contains('certificate') ||
        lower.contains('handshake') ||
        lower.contains('tls')) {
      return _LoginErrorType.ssl;
    }
    if (lower.contains('invalid username') ||
        lower.contains('wrong password') ||
        lower.contains('unauthorized') ||
        lower.contains('401')) {
      return _LoginErrorType.credentials;
    }
    if (lower.contains('not found') ||
        lower.contains('404') ||
        lower.contains('url path')) {
      return _LoginErrorType.notFound;
    }
    if (lower.contains('timed out') || lower.contains('timeout')) {
      return _LoginErrorType.timeout;
    }
    if (lower.contains('cannot connect') ||
        lower.contains('connection refused') ||
        lower.contains('network') ||
        lower.contains('socket')) {
      return _LoginErrorType.connection;
    }
    if (lower.contains('url format') || lower.contains('http')) {
      return _LoginErrorType.format;
    }
    return _LoginErrorType.generic;
  }

  Widget _buildErrorCard(ThemeData theme) {
    final error = _loginError;
    if (error == null) return const SizedBox.shrink();

    final type = _categoriseError(error);

    IconData icon;
    Color color;
    String? hint;

    switch (type) {
      case _LoginErrorType.ssl:
        icon = CupertinoIcons.lock_slash;
        color = const Color(0xFFFF9500); // orange
        if (!_allowSelfSignedCertificates) {
          hint = 'Try enabling "Allow Self-Signed Certificates" below.';
        }
      case _LoginErrorType.credentials:
        icon = CupertinoIcons.person_badge_minus;
        color = AppTheme.appleMusicRed;
        hint = 'Check your username and password and try again.';
      case _LoginErrorType.notFound:
        icon = CupertinoIcons.question_circle;
        color = const Color(0xFFFF9500);
        hint = 'Verify the server URL path (e.g. /navidrome, /airsonic).';
      case _LoginErrorType.timeout:
        icon = CupertinoIcons.timer;
        color = const Color(0xFFFF9500);
        hint = 'The server took too long to respond. Check your network.';
      case _LoginErrorType.connection:
        icon = CupertinoIcons.wifi_slash;
        color = const Color(0xFFFF9500);
        hint = null;
      case _LoginErrorType.format:
        icon = CupertinoIcons.link;
        color = const Color(0xFFFF9500);
        hint = 'URL must start with http:// or https://';
      case _LoginErrorType.generic:
        icon = CupertinoIcons.exclamationmark_triangle;
        color = AppTheme.appleMusicRed;
        hint = null;
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    error,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (hint != null) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 30),
                child: Text(
                  hint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
            // Quick action: enable self-signed certs
            if (type == _LoginErrorType.ssl &&
                !_allowSelfSignedCertificates) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 30),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _allowSelfSignedCertificates = true;
                      _loginError = null;
                    });
                  },
                  child: Text(
                    'Tap to enable self-signed certificates',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: color,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _serverController.removeListener(_clearError);
    _usernameController.removeListener(_clearError);
    _passwordController.removeListener(_clearError);
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _clientCertPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickClientCertificate() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['p12', 'pfx', 'pem'],
        dialogTitle: 'Select Client Certificate',
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _clientCertificatePath = result.files.single.path;
          _clientCertificateName = result.files.single.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!.failedToSelectClientCert(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickCertificateFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pem', 'crt', 'cer', 'p12', 'pfx', 'der'],
        dialogTitle: 'Select TLS/SSL Certificate',
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _customCertificatePath = result.files.single.path;
          _customCertificateName = result.files.single.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!.failedToSelectCertificate(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loginError = null);

    final serverUrl = _serverController.text.trim();

    // URL scheme check (redundant with validator, but kept as a safety net)
    if (!serverUrl.startsWith('http://') && !serverUrl.startsWith('https://')) {
      setState(
        () => _loginError = 'Server URL must start with http:// or https://',
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      serverUrl: serverUrl,
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      useLegacyAuth: _useLegacyAuth,
      allowSelfSignedCertificates: _allowSelfSignedCertificates,
      customCertificatePath: _customCertificatePath,
      clientCertificatePath: _clientCertificatePath,
      clientCertificatePassword: _clientCertPasswordController.text.isEmpty
          ? null
          : _clientCertPasswordController.text,
    );

    if (!success && mounted) {
      setState(
        () => _loginError = authProvider.error ?? 'Failed to connect to server',
      );
    }
    // Support dialog is now shown by AuthWrapper after successful login
  }

  Future<void> _useLocalFiles() async {
    final localService = Provider.of<LocalMusicService>(context, listen: false);

    final granted = await localService.requestPermission();
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.storagePermissionRequired,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isScanning = true;
      _scanProgress = 0.0;
      _scanStatus = 'Starting scan...';
    });

    // Listen to progress updates
    void updateProgress() {
      if (mounted) {
        setState(() {
          _scanProgress = localService.scanProgress;
          _scanStatus = localService.scanStatus;
        });
      }
    }

    localService.addListener(updateProgress);

    try {
      await localService.scanForMusic();

      if (mounted) {
        if (localService.songs.isNotEmpty) {
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );
          await authProvider.setLocalOnlyMode(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.noMusicFilesFound),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } finally {
      localService.removeListener(updateProgress);
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoading = authProvider.state == AuthState.authenticating;
    final theme = Theme.of(context);
    final isBusy = isLoading || _isScanning;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.appleMusicRed.withValues(
                              alpha: 0.4,
                            ),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Transform.translate(
                          offset: const Offset(0, 8),
                          child: Image.asset(
                            'assets/logobig.png',
                            width: 100,
                            height: 100,
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    AppLocalizations.of(context)!.appName,
                    style: theme.textTheme.displayLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.connectToServerSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightSecondaryText,
                    ),
                  ),
                  const SizedBox(height: 48),

                  TextFormField(
                    controller: _serverController,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: 'Server URL',
                      hintText: 'https://your-server.com',
                      prefixIcon: const Icon(CupertinoIcons.globe),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter server URL';
                      }
                      final url = value.trim();
                      if (!url.startsWith('http://') &&
                          !url.startsWith('https://')) {
                        return 'URL must start with http:// or https://';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _usernameController,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      prefixIcon: const Icon(CupertinoIcons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter username';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(CupertinoIcons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? CupertinoIcons.eye
                              : CupertinoIcons.eye_slash,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      CupertinoSwitch(
                        value: _useLegacyAuth,
                        activeTrackColor: AppTheme.appleMusicRed,
                        onChanged: (value) {
                          setState(() {
                            _useLegacyAuth = value;
                          });
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Legacy Authentication',
                              style: theme.textTheme.bodyMedium,
                            ),
                            Text(
                              'Use for older Subsonic servers',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      CupertinoSwitch(
                        value: _allowSelfSignedCertificates,
                        activeTrackColor: AppTheme.appleMusicRed,
                        onChanged: (value) {
                          setState(() {
                            _allowSelfSignedCertificates = value;
                          });
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Allow Self-Signed Certificates',
                              style: theme.textTheme.bodyMedium,
                            ),
                            Text(
                              'For servers with custom TLS/SSL certificates',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Advanced Options
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showAdvancedOptions = !_showAdvancedOptions;
                      });
                    },
                    child: Row(
                      children: [
                        Icon(
                          _showAdvancedOptions
                              ? CupertinoIcons.chevron_down
                              : CupertinoIcons.chevron_right,
                          size: 18,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Advanced Options',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_showAdvancedOptions) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.dark
                            ? const Color(0xFF2C2C2E)
                            : const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Custom TLS/SSL Certificate',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Upload a custom certificate for servers with non-standard CA',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          if (_customCertificateName != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.brightness == Brightness.dark
                                    ? const Color(0xFF3C3C3E)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    CupertinoIcons.doc_fill,
                                    size: 20,
                                    color: AppTheme.appleMusicRed,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _customCertificateName!,
                                      style: theme.textTheme.bodyMedium,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      CupertinoIcons.xmark_circle_fill,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _customCertificatePath = null;
                                        _customCertificateName = null;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            )
                          else
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _pickCertificateFile,
                                icon: const Icon(
                                  CupertinoIcons.doc_on_clipboard,
                                ),
                                label: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.selectCertificateFile,
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.appleMusicRed,
                                  side: BorderSide(
                                    color: AppTheme.appleMusicRed.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),

                          // ── mTLS Client Certificate ──────────────────────
                          const SizedBox(height: 20),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context)!.clientCertificate,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.clientCertificateSubtitle,
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          if (_clientCertificateName != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.brightness == Brightness.dark
                                    ? const Color(0xFF3C3C3E)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.security_rounded,
                                    size: 20,
                                    color: AppTheme.appleMusicRed,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _clientCertificateName!,
                                      style: theme.textTheme.bodyMedium,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      CupertinoIcons.xmark_circle_fill,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _clientCertificatePath = null;
                                        _clientCertificateName = null;
                                        _clientCertPasswordController.clear();
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _clientCertPasswordController,
                              obscureText: _obscureClientCertPassword,
                              decoration: InputDecoration(
                                hintText: AppLocalizations.of(
                                  context,
                                )!.clientCertPassword,
                                prefixIcon: const Icon(
                                  CupertinoIcons.lock,
                                  size: 20,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureClientCertPassword
                                        ? CupertinoIcons.eye
                                        : CupertinoIcons.eye_slash,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() {
                                    _obscureClientCertPassword =
                                        !_obscureClientCertPassword;
                                  }),
                                ),
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ] else
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _pickClientCertificate,
                                icon: const Icon(Icons.security_rounded),
                                label: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.selectClientCertificate,
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.appleMusicRed,
                                  side: BorderSide(
                                    color: AppTheme.appleMusicRed.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  _buildErrorCard(theme),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.appleMusicRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Connect',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Divider with "OR"
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.lightSecondaryText,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Use Local Files button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: isBusy ? null : _useLocalFiles,
                      icon: _isScanning
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.appleMusicRed,
                                ),
                              ),
                            )
                          : const Icon(CupertinoIcons.folder),
                      label: Text(
                        _isScanning ? _scanStatus : 'Use Local Files',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.appleMusicRed,
                        side: const BorderSide(color: AppTheme.appleMusicRed),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  // Scan progress bar
                  if (_isScanning) ...[
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: _scanProgress > 0 ? _scanProgress : null,
                      backgroundColor: AppTheme.appleMusicRed.withValues(
                        alpha: 0.2,
                      ),
                      color: AppTheme.appleMusicRed,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
