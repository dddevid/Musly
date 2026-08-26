import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../models/server_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/library_provider.dart';
import 'package:musly/screens/auth/add_server_screen.dart';
import 'package:musly/screens/settings/settings_screen.dart';
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
    if (a.name != null &&
        b.name != null &&
        a.name!.isNotEmpty &&
        b.name!.isNotEmpty) {
      return a.name == b.name &&
          a.serverFamily == b.serverFamily &&
          a.serverUrl == b.serverUrl &&
          a.username == b.username;
    }
    return a.serverFamily == b.serverFamily &&
        a.serverUrl == b.serverUrl &&
        a.username == b.username;
  }

  Future<void> _switchToProfile(ServerConfig profile) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final libraryProvider =
        Provider.of<LibraryProvider>(context, listen: false);

    if (_isSameServer(profile, authProvider.config)) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _switchingServerKey =
          '${profile.serverFamily}_${profile.serverUrl}_${profile.username}';
    });

    try {
      await playerProvider.resetForServerSwitch();
      await authProvider.switchProfile(profile);
      await libraryProvider.refresh();

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(CupertinoIcons.checkmark_circle_fill,
                    color: Color(0xFF34C759), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.connectedTo(profile.displayServerName),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _switchingServerKey = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorConnectingServer(e.toString())),
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
    final controller =
        TextEditingController(text: profile.name ?? profile.displayServerName);
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.renameServerProfile),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.profileNameLabel,
            hintText: l10n.enterNewNameHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
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
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteProfile(ServerConfig profile) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.removeServerTitle),
        content: Text(l10n.removeServerConfirm(profile.displayServerName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
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
            child: Text(l10n.remove, style: const TextStyle(color: Colors.red)),
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

    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<List<ServerConfig>>(
      future: authProvider.getSavedProfiles(),
      builder: (context, snapshot) {
        var profiles = snapshot.data ?? [];

        if (currentConfig != null &&
            !profiles.any((p) => _isSameServer(p, currentConfig))) {
          profiles = [currentConfig, ...profiles];
        }

        if (!kIsWeb && Platform.isIOS) {
          profiles = profiles.where((p) => !p.isYoutube).toList();
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
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.switchServerTitle,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.switchServerSubtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppTheme.darkSecondaryText
                                  : AppTheme.lightSecondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => _openAddServerScreen(),
                      icon: const Icon(CupertinoIcons.plus, size: 16),
                      label: Text(l10n.addServerButton),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shrinkWrap: true,
                  children: [
                    if (profiles.isEmpty && !hasYtStream)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            l10n.noServersSavedYet,
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
                          (profile.isYoutube &&
                              _switchingServerKey == 'youtube');

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
                    if (!kIsWeb && !Platform.isIOS && !hasYtStream) ...[
                      const SizedBox(height: 12),
                      _buildQuickAddYtStreamTile(context),
                    ],
                    const SizedBox(height: 12),
                    Divider(
                        height: 1,
                        color: isDark ? Colors.white10 : Colors.black12),
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
                        AppLocalizations.of(context)?.settingsTitle ??
                            'Settings',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      trailing: Icon(
                        CupertinoIcons.chevron_forward,
                        size: 16,
                        color: isDark
                            ? AppTheme.darkDivider
                            : AppTheme.lightDivider,
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
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.red),
                      ),
                      onTap: () async {
                        final playerProvider =
                            Provider.of<PlayerProvider>(context, listen: false);
                        Navigator.pop(context);
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(AppLocalizations.of(context)?.logout ??
                                'Logout'),
                            content: Text(
                              AppLocalizations.of(context)
                                      ?.logoutConfirmation ??
                                  'Are you sure you want to log out?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(
                                    AppLocalizations.of(context)?.cancel ??
                                        'Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text(
                                  AppLocalizations.of(context)?.logout ??
                                      'Logout',
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
    final l10n = AppLocalizations.of(context)!;

    final (IconData icon, List<Color> gradient) =
        switch (profile.serverFamily) {
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
              : (isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.06)),
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
                              fontWeight:
                                  isActive ? FontWeight.bold : FontWeight.w600,
                              color: isActive
                                  ? (isDark ? Colors.white : Colors.black)
                                  : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF34C759)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(CupertinoIcons.circle_fill,
                                    size: 6, color: Color(0xFF34C759)),
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
                        color: isDark
                            ? AppTheme.darkSecondaryText
                            : AppTheme.lightSecondaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onSelected: (val) {
                    if (val == 'switch') onTap();
                    if (val == 'rename') onRename();
                    if (val == 'delete') onDelete();
                  },
                  itemBuilder: (ctx) => [
                    if (!isActive)
                      PopupMenuItem(
                        value: 'switch',
                        child: Row(
                          children: [
                            const Icon(CupertinoIcons.arrow_2_squarepath,
                                size: 18),
                            const SizedBox(width: 10),
                            Text(l10n.connectToServer),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'rename',
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.pencil, size: 18),
                          const SizedBox(width: 10),
                          Text(l10n.renameProfile),
                        ],
                      ),
                    ),
                    if (!profile.isYoutube)
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(CupertinoIcons.trash,
                                size: 18, color: Colors.red),
                            const SizedBox(width: 10),
                            Text(l10n.remove,
                                style: const TextStyle(color: Colors.red)),
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
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: const Color(0xFFFF3B30).withValues(alpha: 0.3),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFFF3B30).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(CupertinoIcons.play_rectangle_fill,
              color: Color(0xFFFF3B30), size: 18),
        ),
        title: Text(l10n.addWebStream,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(l10n.addWebStreamSubtitle,
            style: const TextStyle(fontSize: 12)),
        trailing: FilledButton.tonal(
          onPressed: () => _openAddServerScreen(family: 'youtube'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFF3B30).withValues(alpha: 0.15),
            foregroundColor: const Color(0xFFFF3B30),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          child: Text(l10n.add,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
