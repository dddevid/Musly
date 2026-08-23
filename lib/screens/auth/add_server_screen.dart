import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:musly/providers/auth_provider.dart';
import 'package:musly/providers/player_provider.dart';
import 'package:musly/providers/library_provider.dart';
import 'package:musly/services/local_music_service.dart';
import 'package:musly/theme/app_theme.dart';

class AddServerScreen extends StatefulWidget {
  final String? initialFamily;

  const AddServerScreen({super.key, this.initialFamily});

  @override
  State<AddServerScreen> createState() => _AddServerScreenState();
}

class _AddServerScreenState extends State<AddServerScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedFamily; // 'subsonic' | 'jellyfin' | 'youtube'

  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _lanUrlController = TextEditingController();
  final _userController = TextEditingController();
  final _passController = TextEditingController();

  bool _obscurePassword = true;
  bool _allowSelfSigned = false;
  bool _useLegacyAuth = false;
  bool _showAdvanced = false;
  String? _customCertPath;
  String? _customCertName;
  String? _clientCertPath;
  String? _clientCertName;
  final _clientCertPassController = TextEditingController();
  bool _obscureClientCertPass = true;

  bool _isConnecting = false;
  String? _errorMessage;
  late Future<bool> _hasYoutubeFuture;

  @override
  void initState() {
    super.initState();
    final isIos = !kIsWeb && Platform.isIOS;
    _selectedFamily = (isIos && widget.initialFamily == 'youtube')
        ? 'subsonic'
        : (widget.initialFamily ?? 'subsonic');
    _hasYoutubeFuture = Provider.of<AuthProvider>(context, listen: false).hasYoutubeProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _lanUrlController.dispose();
    _userController.dispose();
    _passController.dispose();
    _clientCertPassController.dispose();
    super.dispose();
  }

  Future<void> _pickCustomCertificate() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['crt', 'cer', 'pem', 'der'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _customCertPath = result.files.single.path;
          _customCertName = result.files.single.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking certificate: $e');
    }
  }

  Future<void> _pickClientCertificate() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['p12', 'pfx'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _clientCertPath = result.files.single.path;
          _clientCertName = result.files.single.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking client certificate: $e');
    }
  }

  bool _isRemoteInsecureHttp(String url) {
    final trimmed = url.trim().toLowerCase();
    if (!trimmed.startsWith('http://')) return false;
    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.host.isEmpty) return false;
    final host = uri.host.toLowerCase();
    if (host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '::1' ||
        host.endsWith('.local') ||
        host.startsWith('192.168.') ||
        host.startsWith('10.') ||
        RegExp(r'^172\.(1[6-9]|2[0-9]|3[0-1])\.').hasMatch(host)) {
      return false;
    }
    return true;
  }

  Future<void> _connectYtStream() async {
    if (!kIsWeb && Platform.isIOS) {
      setState(() {
        _errorMessage = 'Web Stream is not available on iOS.';
      });
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);

    final hasYt = await authProvider.hasYoutubeProfile();
    if (hasYt) {
      setState(() {
        _errorMessage = 'Web Stream is already configured in your music sources.';
      });
      return;
    }

    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      await playerProvider.stop();
      final success = await authProvider.connectYtStream();
      if (success) {
        await libraryProvider.refresh();
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(CupertinoIcons.checkmark_circle_fill, color: Color(0xFF34C759), size: 18),
                SizedBox(width: 10),
                Text('Connected to Web Stream', style: TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        setState(() {
          _isConnecting = false;
          _errorMessage = authProvider.error ?? 'Failed to connect to Web Stream';
        });
      }
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _connectServer() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);

    var rawUrl = _urlController.text.trim();
    if (!rawUrl.startsWith('http://') && !rawUrl.startsWith('https://')) {
      rawUrl = 'https://$rawUrl';
    }

    final user = _userController.text.trim();
    final pass = _passController.text;
    final profileName = _nameController.text.trim();

    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      await playerProvider.stop();
      final success = await authProvider.login(
        serverUrl: rawUrl,
        username: user,
        password: pass,
        serverFamily: _selectedFamily,
        profileName: profileName.isNotEmpty ? profileName : null,
        lanUrl: _lanUrlController.text.trim().isNotEmpty
            ? _lanUrlController.text.trim()
            : null,
        allowSelfSignedCertificates: _allowSelfSigned,
        useLegacyAuth: _useLegacyAuth,
        customCertificatePath: _customCertPath,
        clientCertificatePath: _clientCertPath,
        clientCertificatePassword: _clientCertPassController.text.isNotEmpty
            ? _clientCertPassController.text
            : null,
      );

      if (success) {
        await libraryProvider.refresh();
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(CupertinoIcons.checkmark_circle_fill, color: Color(0xFF34C759), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Connected to ${profileName.isNotEmpty ? profileName : user}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        setState(() {
          _isConnecting = false;
          _errorMessage = authProvider.error ?? 'Connection failed. Check URL and credentials.';
        });
      }
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            CupertinoIcons.chevron_back,
            color: isDark ? Colors.white : Colors.black87,
            size: 26,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Add Music Source',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<bool>(
        future: _hasYoutubeFuture,
        builder: (context, snapshot) {
          final hasYtStream = snapshot.data ?? false;

          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Music Provider',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),

                // Provider selection cards
                _buildProviderCard(
                  family: 'subsonic',
                  title: 'Navidrome / Subsonic',
                  subtitle: 'Connect to your self-hosted music library',
                  icon: CupertinoIcons.music_note_2,
                  gradient: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  badge: 'Self-Hosted',
                  isSelected: _selectedFamily == 'subsonic',
                  isDisabled: false,
                ),
                const SizedBox(height: 10),

                _buildProviderCard(
                  family: 'jellyfin',
                  title: 'Jellyfin / Emby',
                  subtitle: 'Connect to your Jellyfin or Emby media server',
                  icon: CupertinoIcons.tv_fill,
                  gradient: const [Color(0xFF00A4DC), Color(0xFF006699)],
                  badge: 'Media Server',
                  isSelected: _selectedFamily == 'jellyfin',
                  isDisabled: false,
                ),
                if (!kIsWeb && !Platform.isIOS) ...[
                  const SizedBox(height: 10),
                  _buildProviderCard(
                    family: 'youtube',
                    title: 'Web Stream',
                    subtitle: hasYtStream
                        ? 'Already configured in your music sources'
                        : 'Stream music online without account setup',
                    icon: CupertinoIcons.play_rectangle_fill,
                    gradient: const [Color(0xFFFF3B30), Color(0xFFFF453A)],
                    badge: hasYtStream ? 'ALREADY ADDED' : 'No Account Needed',
                    isSelected: _selectedFamily == 'youtube',
                    isDisabled: hasYtStream,
                  ),
                ],
                const SizedBox(height: 10),
                _buildProviderCard(
                  family: 'local',
                  title: 'Local Files',
                  subtitle: 'Play audio files stored directly on this device',
                  icon: CupertinoIcons.folder_fill,
                  gradient: const [Color(0xFF34C759), Color(0xFF30B0C7)],
                  badge: 'Offline',
                  isSelected: _selectedFamily == 'local',
                  isDisabled: false,
                ),

                const SizedBox(height: 24),

                // Error Message banner if any
                if (_errorMessage != null) ...[
                  _buildErrorBanner(isDark),
                  const SizedBox(height: 16),
                ],

                // Dynamic Form Content
                if (_selectedFamily == 'youtube') ...[
                  _buildYtStreamInfoCard(isDark, hasYtStream),
                ] else if (_selectedFamily == 'local') ...[
                  _buildLocalFilesCard(isDark),
                ] else ...[
                  _buildServerForm(isDark),
                ],

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProviderCard({
    required String family,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required String badge,
    required bool isSelected,
    required bool isDisabled,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedFamily = family;
          _errorMessage = null;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? (isSelected ? const Color(0xFF282828) : AppTheme.darkSurface)
              : (isSelected ? Colors.white : const Color(0xFFF9FAFB)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDisabled
                              ? const Color(0xFF34C759).withValues(alpha: 0.15)
                              : (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isDisabled
                                ? const Color(0xFF34C759)
                                : (isDark ? Colors.white70 : Colors.black54),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? primaryColor : (isDark ? Colors.white24 : Colors.black26),
                  width: 2,
                ),
                color: isSelected ? primaryColor : Colors.transparent,
              ),
              child: isSelected
                  ? const Center(child: Icon(Icons.check, size: 14, color: Colors.white))
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Connection Error',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: isDark ? Colors.red[200] : Colors.red[900],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYtStreamInfoCard(bool isDark, bool hasYtStream) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(CupertinoIcons.sparkles, color: Color(0xFFFF3B30), size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Zero-Config Streaming',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'No server setup or account credentials required',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          _buildFeatureBullet(
            icon: CupertinoIcons.music_albums,
            title: 'Global Music Search',
            subtitle: 'Search and stream millions of tracks, albums, and playlists seamlessly.',
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildFeatureBullet(
            icon: CupertinoIcons.antenna_radiowaves_left_right,
            title: 'Dynamic Radio',
            subtitle: 'Auto-generates seamless radio stations tailored to any song or artist.',
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildFeatureBullet(
            icon: CupertinoIcons.lock_shield,
            title: 'Private & Direct',
            subtitle: 'Audio streams directly to your device with local smart caching.',
            isDark: isDark,
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: hasYtStream || _isConnecting ? null : _connectYtStream,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF3B30),
                disabledBackgroundColor: hasYtStream
                    ? const Color(0xFF34C759).withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isConnecting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(
                      hasYtStream ? 'Web Stream is Already Added' : 'Connect Web Stream',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBullet({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFFFF3B30)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocalFilesCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF34C759), Color(0xFF30B0C7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(CupertinoIcons.folder_fill, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Local Music Library',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Play local audio files stored on device',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isConnecting ? null : _connectLocalFiles,
              icon: const Icon(CupertinoIcons.folder_open, size: 18),
              label: const Text(
                'Scan & Use Local Files',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF34C759),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _connectLocalFiles() async {
    final localService = Provider.of<LocalMusicService>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);

    final granted = await localService.requestPermission();
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission is required to access local music.')),
        );
      }
      return;
    }

    setState(() => _isConnecting = true);
    try {
      await playerProvider.stop();
      if (Platform.isIOS) {
        await localService.pickAndAddFiles();
      } else {
        await localService.scanForMusic();
      }
      if (localService.songs.isNotEmpty) {
        await authProvider.setLocalOnlyMode(true);
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  Widget _buildServerForm(bool isDark) {
    final isJellyfin = _selectedFamily == 'jellyfin';
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isJellyfin ? 'Jellyfin Connection Details' : 'Subsonic / Navidrome Details',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Profile Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Profile Name (Optional)',
                hintText: isJellyfin ? 'e.g. Home Jellyfin' : 'e.g. Navidrome Cloud',
                prefixIcon: const Icon(CupertinoIcons.tag),
                filled: true,
                fillColor: isDark ? const Color(0xFF222222) : const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Server URL
            TextFormField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Server URL is required';
                return null;
              },
              decoration: InputDecoration(
                labelText: 'Server URL *',
                hintText: isJellyfin ? 'https://jellyfin.example.com' : 'https://music.example.com',
                prefixIcon: const Icon(CupertinoIcons.link),
                filled: true,
                fillColor: isDark ? const Color(0xFF222222) : const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (_isRemoteInsecureHttp(_urlController.text)) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.exclamationmark_shield_fill, size: 16, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Insecure HTTP: Passwords and streaming traffic are not encrypted over public networks. HTTPS is recommended.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.amber[200] : Colors.amber[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),

            // LAN URL (Optional)
            TextFormField(
              controller: _lanUrlController,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: 'LAN Server URL (Optional)',
                hintText: 'e.g. http://192.168.1.5:4533',
                prefixIcon: const Icon(CupertinoIcons.wifi),
                filled: true,
                fillColor: isDark ? const Color(0xFF222222) : const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Username
            TextFormField(
              controller: _userController,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Username is required';
                return null;
              },
              decoration: InputDecoration(
                labelText: 'Username *',
                prefixIcon: const Icon(CupertinoIcons.person),
                filled: true,
                fillColor: isDark ? const Color(0xFF222222) : const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Password
            TextFormField(
              controller: _passController,
              obscureText: _obscurePassword,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                return null;
              },
              decoration: InputDecoration(
                labelText: 'Password *',
                prefixIcon: const Icon(CupertinoIcons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF222222) : const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Advanced Options Toggle
            InkWell(
              onTap: () => setState(() => _showAdvanced = !_showAdvanced),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      _showAdvanced ? CupertinoIcons.chevron_down : CupertinoIcons.chevron_right,
                      size: 16,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Advanced Security & TLS Settings',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_showAdvanced) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF222222) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Allow Self-Signed Certificates', style: TextStyle(fontSize: 13)),
                      subtitle: const Text('Useful for internal LAN or custom self-signed SSL', style: TextStyle(fontSize: 11)),
                      value: _allowSelfSigned,
                      onChanged: (v) => setState(() => _allowSelfSigned = v),
                    ),
                    if (!isJellyfin) ...[
                      const Divider(height: 12),
                      SwitchListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Legacy Authentication', style: TextStyle(fontSize: 13)),
                        subtitle: const Text('Required for older Subsonic API implementations', style: TextStyle(fontSize: 11)),
                        value: _useLegacyAuth,
                        onChanged: (v) => setState(() => _useLegacyAuth = v),
                      ),
                    ],
                    const Divider(height: 12),
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _customCertName ?? 'Custom CA Certificate (Optional)',
                        style: const TextStyle(fontSize: 13),
                      ),
                      subtitle: const Text('.crt, .pem or .cer file', style: TextStyle(fontSize: 11)),
                      trailing: IconButton(
                        icon: const Icon(CupertinoIcons.folder, size: 18),
                        onPressed: _pickCustomCertificate,
                      ),
                    ),
                    const Divider(height: 12),
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _clientCertName ?? 'Client Certificate (mTLS)',
                        style: const TextStyle(fontSize: 13),
                      ),
                      subtitle: const Text('.p12 or .pfx client identity file', style: TextStyle(fontSize: 11)),
                      trailing: IconButton(
                        icon: const Icon(CupertinoIcons.folder, size: 18),
                        onPressed: _pickClientCertificate,
                      ),
                    ),
                    if (_clientCertPath != null) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _clientCertPassController,
                        obscureText: _obscureClientCertPass,
                        decoration: InputDecoration(
                          labelText: 'Certificate Password',
                          prefixIcon: const Icon(CupertinoIcons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureClientCertPass ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                              size: 18,
                            ),
                            onPressed: () => setState(() => _obscureClientCertPass = !_obscureClientCertPass),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _isConnecting ? null : _connectServer,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isConnecting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        'Connect & Save Server',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
