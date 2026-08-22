import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../models/server_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/library_provider.dart';
import '../../screens/add_server_screen.dart';
import '../../screens/settings_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/navigation_helper.dart';
import '../../theme/app_theme.dart';

class ServerSwitcherSheet extends StatefulWidget {
  const ServerSwitcherSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ServerSwitcherSheet(),
    );
  }

  @override
  State<ServerSwitcherSheet> createState() => _ServerSwitcherSheetState();
}

class _ServerSwitcherSheetState extends State<ServerSwitcherSheet> {
  String? _switchingServerKey;

  bool _isSameServer(ServerConfig a, ServerConfig? b) {
    if (b == null) return false;
    if (a.isYoutube && b.isYoutube) return true;
    return a.serverFamily == b.serverFamily &&
        a.serverUrl == b.serverUrl &&
        a.username == b.username;
  }

  Future<void> _switchToProfile(ServerConfig profile) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);

    if (_isSameServer(profile, authProvider.config)) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _switchingServerKey = '${profile.serverFamily}_${profile.serverUrl}_${profile.username}';
    });

    try {
      await playerProvider.resetForServerSwitch();
      await authProvider.switchProfile(profile);
      await libraryProvider.refresh();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(CupertinoIcons.checkmark_circle_fill, color: Color(0xFF34C759), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Connected to ${profile.displayServerName}',
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
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _switchingServerKey = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error connecting to server: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openAddServerScreen({String? family}) {
    Navigator.of(context).pop();
    NavigationHelper.push(context, AddServerScreen(initialFamily: family));
  }

  void _showRenameDialog(ServerConfig profile) {
    final controller = TextEditingController(text: profile.name ?? profile.displayServerName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Server Profile'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Profile Name',
            hintText: 'Enter new name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                await auth.renameProfile(profile, newName);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (mounted) {
                  setState(() {});
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteProfile(ServerConfig profile) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Server'),
        content: Text('Are you sure you want to remove "${profile.displayServerName}" from your saved servers?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              await auth.deleteProfile(profile);
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              if (mounted) {
                setState(() {});
              }
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final currentConfig = authProvider.config;

    return FutureBuilder<List<ServerConfig>>(
      future: authProvider.getSavedProfiles(),
      builder: (context, snapshot) {
        var profiles = snapshot.data ?? [];

        // Ensure current active config is present in list if not already saved
        if (currentConfig != null &&
            !profiles.any((p) => _isSameServer(p, currentConfig))) {
          profiles = [currentConfig, ...profiles];
        }

        final hasYtStream = profiles.any((p) => p.isYoutube);

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Sheet Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Switch Server',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Select an active server or streaming source',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => _openAddServerScreen(),
                      icon: const Icon(CupertinoIcons.plus, size: 16),
                      label: const Text('Add Server'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Server List
              Flexible(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shrinkWrap: true,
                  children: [
                    if (profiles.isEmpty && !hasYtStream)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'No servers saved yet',
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ),
                      ),

                    ...profiles.map((profile) {
                      final isActive = _isSameServer(profile, currentConfig);
                      final isSwitchingThis = _switchingServerKey ==
                          '${profile.serverFamily}_${profile.serverUrl}_${profile.username}' ||
                          (profile.isYoutube && _switchingServerKey == 'youtube');

                      return _buildServerCard(
                        context,
                        profile: profile,
                        isActive: isActive,
                        isSwitching: isSwitchingThis,
                        onTap: () => _switchToProfile(profile),
                        onRename: () => _showRenameDialog(profile),
                        onDelete: () => _confirmDeleteProfile(profile),
                      );
                    }),

                    if (!hasYtStream) ...[
                      const SizedBox(height: 12),
                      _buildQuickAddYtStreamTile(context),
                    ],

                    const SizedBox(height: 12),
                    Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                    const SizedBox(height: 4),

                    ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: Icon(
                        CupertinoIcons.gear_alt,
                        color: isDark ? Colors.white70 : Colors.black87,
                        size: 20,
                      ),
                      title: Text(
                        AppLocalizations.of(context)?.settingsTitle ?? 'Settings',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      trailing: Icon(
                        CupertinoIcons.chevron_forward,
                        size: 16,
                        color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        NavigationHelper.push(context, const SettingsScreen());
                      },
                    ),

                    ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: const Icon(
                        CupertinoIcons.arrow_right_square,
                        color: Colors.red,
                        size: 20,
                      ),
                      title: Text(
                        AppLocalizations.of(context)?.logout ?? 'Logout',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.red),
                      ),
                      onTap: () async {
                        final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
                        Navigator.pop(context);
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(AppLocalizations.of(context)?.logout ?? 'Logout'),
                            content: Text(
                              AppLocalizations.of(context)?.logoutConfirmation ?? 'Are you sure you want to log out?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text(
                                  AppLocalizations.of(context)?.logout ?? 'Logout',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await playerProvider.stop();
                          await authProvider.logout();
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildServerCard(
    BuildContext context, {
    required ServerConfig profile,
    required bool isActive,
    required bool isSwitching,
    required VoidCallback onTap,
    required VoidCallback onRename,
    required VoidCallback onDelete,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Brand specific icons & colors
    final (IconData icon, List<Color> gradient) = switch (profile.serverFamily) {
      'youtube' => (
          CupertinoIcons.play_rectangle_fill,
          const [Color(0xFFFF3B30), Color(0xFFFF453A)],
        ),
      'jellyfin' => (
          CupertinoIcons.tv_fill,
          const [Color(0xFF00A4DC), Color(0xFF0077A3)],
        ),
      _ => (
          CupertinoIcons.music_note_2,
          const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark
            ? (isActive ? const Color(0xFF282828) : AppTheme.darkSurface)
            : (isActive ? Colors.white : const Color(0xFFF9FAFB)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? primaryColor.withValues(alpha: 0.6)
              : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06)),
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: InkWell(
        onTap: isSwitching ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Server icon badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),

              // Title and URL info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            profile.displayServerName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                              color: isActive ? (isDark ? Colors.white : Colors.black) : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF34C759).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(CupertinoIcons.circle_fill, size: 6, color: Color(0xFF34C759)),
                                SizedBox(width: 4),
                                Text(
                                  'ACTIVE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF34C759),
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      profile.isYoutube
                          ? 'Free Online Streaming'
                          : '${profile.username} • ${profile.displayUrl}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Trailing action / switch loader / menu
              if (isSwitching)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: 20,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (val) {
                    if (val == 'switch') onTap();
                    if (val == 'rename') onRename();
                    if (val == 'delete') onDelete();
                  },
                  itemBuilder: (ctx) => [
                    if (!isActive)
                      const PopupMenuItem(
                        value: 'switch',
                        child: Row(
                          children: [
                            Icon(CupertinoIcons.arrow_2_squarepath, size: 18),
                            SizedBox(width: 10),
                            Text('Connect to Server'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'rename',
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.pencil, size: 18),
                          SizedBox(width: 10),
                          Text('Rename Profile'),
                        ],
                      ),
                    ),
                    if (!profile.isYoutube)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(CupertinoIcons.trash, size: 18, color: Colors.red),
                            SizedBox(width: 10),
                            Text('Remove', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAddYtStreamTile(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFF3B30).withValues(alpha: 0.3),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFFF3B30).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(CupertinoIcons.play_rectangle_fill, color: Color(0xFFFF3B30), size: 18),
        ),
        title: const Text('Add YT Stream', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: const Text('Instant streaming with no login required', style: TextStyle(fontSize: 12)),
        trailing: FilledButton.tonal(
          onPressed: () => _openAddServerScreen(family: 'youtube'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFF3B30).withValues(alpha: 0.15),
            foregroundColor: const Color(0xFFFF3B30),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
