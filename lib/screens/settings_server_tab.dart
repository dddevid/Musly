import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/music_folder.dart';
import '../models/server_config.dart';
import '../providers/auth_provider.dart';
import '../providers/player_provider.dart';
import '../services/jukebox_service.dart';
import '../services/subsonic_service.dart';
import '../theme/app_theme.dart';
import '../utils/navigation_helper.dart';
import 'jukebox_screen.dart';

class SettingsServerTab extends StatefulWidget {
  const SettingsServerTab({super.key});

  @override
  State<SettingsServerTab> createState() => _SettingsServerTabState();
}

class _SettingsServerTabState extends State<SettingsServerTab> {
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final serverType = authProvider.config?.serverType;
    final serverVersion = authProvider.config?.serverVersion;

    String serverSubtitle = 'Subsonic API';
    if (serverType != null && serverType.isNotEmpty) {
      serverSubtitle = serverType;
      if (serverVersion != null && serverVersion.isNotEmpty) {
        serverSubtitle += ' $serverVersion';
      }
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        _buildSection(
          title: l10n.sectionServerConnection,
          children: [
            _buildInfoTile(
              icon: CupertinoIcons.cloud,
              iconColor: Theme.of(context).colorScheme.primary,
              title: l10n.serverType,
              subtitle: serverSubtitle,
            ),
            _buildDivider(),
            _buildInfoTile(
              icon: CupertinoIcons.link,
              iconColor: const Color(0xFF007AFF),
              title: l10n.serverUrl,
              subtitle: authProvider.config?.serverUrl ?? l10n.notConnected,
            ),
            _buildDivider(),
            _buildInfoTile(
              icon: CupertinoIcons.person,
              iconColor: const Color(0xFF34C759),
              title: l10n.username,
              subtitle: authProvider.config?.username ?? l10n.unknown,
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSavedProfilesSection(),
        const SizedBox(height: 24),
        _buildSection(
          title: l10n.sectionMusicFolders,
          children: [_buildMusicFoldersButton()],
        ),
        const SizedBox(height: 24),
        _buildSection(
          title: l10n.sectionJukebox,
          children: [_buildJukeboxSection()],
        ),
        const SizedBox(height: 24),
        _buildSection(
          title: l10n.sectionAccount,
          children: [_buildLogoutButton()],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: _isDark
                  ? AppTheme.darkSecondaryText
                  : AppTheme.lightSecondaryText,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: _isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 56),
      child: Container(
        height: 0.5,
        color: _isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: _isDark
              ? AppTheme.darkSecondaryText
              : AppTheme.lightSecondaryText,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildMusicFoldersButton() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5856D6), Color(0xFF7B68EE)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(CupertinoIcons.folder, color: Colors.white, size: 18),
      ),
      title: Text(
        AppLocalizations.of(context)!.musicFolders,
        style: const TextStyle(fontSize: 16),
      ),
      trailing: Icon(
        CupertinoIcons.chevron_right,
        size: 16,
        color: _isDark
            ? AppTheme.darkSecondaryText
            : AppTheme.lightSecondaryText,
      ),
      onTap: _showMusicFoldersDialog,
    );
  }

  void _showMusicFoldersDialog() async {
    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final folders = await subsonicService.getMusicFolders();

    if (!mounted) return;

    final currentSelection = Set<String>.from(
      authProvider.config?.selectedMusicFolderIds ?? [],
    );

    await showDialog(
      context: context,
      builder: (context) => _MusicFoldersDialog(
        folders: folders,
        initialSelection: currentSelection,
        onSave: (selected) async {
          await authProvider.updateSelectedMusicFolderIds(selected.toList());
        },
      ),
    );
  }

  Widget _buildJukeboxSection() {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<JukeboxService>(
      builder: (context, jukebox, _) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            secondary: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9500), Color(0xFFFF6000)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                CupertinoIcons.speaker_2,
                color: Colors.white,
                size: 18,
              ),
            ),
            title: Text(l10n.jukeboxMode, style: const TextStyle(fontSize: 16)),
            subtitle: Text(
              l10n.jukeboxModeSubtitle,
              style: TextStyle(
                fontSize: 13,
                color: _isDark
                    ? AppTheme.darkSecondaryText
                    : AppTheme.lightSecondaryText,
              ),
            ),
            value: jukebox.enabled,
            activeThumbColor: Theme.of(context).colorScheme.primary,
            onChanged: (v) => jukebox.setEnabled(v),
          ),
          if (jukebox.enabled) ...[
            Padding(
              padding: const EdgeInsets.only(left: 56),
              child: Container(
                height: 0.5,
                color: _isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
              ),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              leading: const SizedBox(width: 32),
              title: Text(
                l10n.openJukeboxController,
                style: const TextStyle(fontSize: 16),
              ),
              trailing: Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: _isDark
                    ? AppTheme.darkSecondaryText
                    : AppTheme.lightSecondaryText,
              ),
              onTap: () =>
                  NavigationHelper.push(context, const JukeboxScreen()),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF3B30), Color(0xFFFF453A)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          CupertinoIcons.square_arrow_right,
          color: Colors.white,
          size: 18,
        ),
      ),
      title: Text(
        AppLocalizations.of(context)!.logout,
        style: const TextStyle(fontSize: 16, color: Color(0xFFFF3B30)),
      ),
      onTap: () {
        final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.logout),
            content: Text(AppLocalizations.of(context)!.logoutConfirmation),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  playerProvider.stop();
                  authProvider.logout();
                },
                child: Text(
                  AppLocalizations.of(context)!.logout,
                  style: const TextStyle(color: Color(0xFFFF3B30)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSavedProfilesSection() {
    return FutureBuilder<List<ServerConfig>>(
      future: Provider.of<AuthProvider>(context, listen: false).getSavedProfiles(),
      builder: (context, snapshot) {
        final profiles = snapshot.data ?? [];
        if (profiles.isEmpty) return const SizedBox.shrink();

        final l10n = AppLocalizations.of(context)!;
        final authProvider = Provider.of<AuthProvider>(context);
        final currentConfig = authProvider.config;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                l10n.sectionSavedProfiles,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: _isDark
                      ? AppTheme.darkSecondaryText
                      : AppTheme.lightSecondaryText,
                  letterSpacing: 0.2,
                ),
              ),
            ),
              Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  children: [
                    ...profiles.map((profile) {
                      final isActive = currentConfig?.serverUrl == profile.serverUrl &&
                          currentConfig?.username == profile.username;
                      final label = profile.name?.isNotEmpty == true
                          ? profile.name!
                          : '${profile.username}@${Uri.tryParse(profile.serverUrl)?.host ?? profile.serverUrl}';

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        leading: Icon(
                          isActive
                              ? CupertinoIcons.checkmark_circle_fill
                              : CupertinoIcons.person_crop_circle,
                          color: isActive
                              ? const Color(0xFF34C759)
                              : (_isDark
                                  ? AppTheme.darkSecondaryText
                                  : AppTheme.lightSecondaryText),
                        ),
                        title: Text(
                          label,
                          style: TextStyle(
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                            color: isActive
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                        ),
                        subtitle: Text(
                          profile.serverUrl,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: _isDark
                                ? AppTheme.darkSecondaryText
                                : AppTheme.lightSecondaryText,
                          ),
                        ),
                        trailing: isActive
                            ? const Icon(CupertinoIcons.checkmark,
                                color: Color(0xFF34C759), size: 18)
                            : null,
                        onTap: isActive
                            ? null
                            : () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text(l10n.switchProfile),
                                    content: Text(l10n.switchProfileConfirmation(label)),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: Text(l10n.cancel),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: Text(l10n.ok),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true) {
                                  if (!mounted) return;
                                  final playerProvider =
                                      Provider.of<PlayerProvider>(context, listen: false);
                                  await playerProvider.stop();
                                  await authProvider.switchProfile(profile);
                                }
                              },
                      );
                    }),
                    Divider(height: 1, color: _isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      leading: Icon(
                        CupertinoIcons.plus_circle,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        l10n.addProfile,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        // Navigate to login screen to add new profile
                        final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
                        playerProvider.stop();
                        authProvider.disconnect();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MusicFoldersDialog extends StatefulWidget {
  final List<MusicFolder> folders;
  final Set<String> initialSelection;
  final Future<void> Function(Set<String> selected) onSave;

  const _MusicFoldersDialog({
    required this.folders,
    required this.initialSelection,
    required this.onSave,
  });

  @override
  State<_MusicFoldersDialog> createState() => _MusicFoldersDialogState();
}

class _MusicFoldersDialogState extends State<_MusicFoldersDialog> {
  late Set<String> _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.initialSelection);
  }

  bool _isFolderEnabled(MusicFolder folder) {
    
    return _selected.isEmpty || _selected.contains(folder.id);
  }

  void _toggle(MusicFolder folder) {
    setState(() {
      if (_selected.isEmpty) {
        
        _selected = widget.folders
            .map((f) => f.id)
            .where((id) => id != folder.id)
            .toSet();
      } else if (_selected.contains(folder.id)) {
        _selected.remove(folder.id);
        
        if (_selected.isEmpty) _selected = {};
      } else {
        _selected.add(folder.id);
        
        if (_selected.length == widget.folders.length) _selected = {};
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.musicFolders),
      content: widget.folders.isEmpty
          ? Text(l10n.noMusicFolders)
          : SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.musicFoldersHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  ...widget.folders.map(
                    (folder) => CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(CupertinoIcons.folder),
                      title: Text(folder.name),
                      value: _isFolderEnabled(folder),
                      onChanged: (v) => _toggle(folder),
                    ),
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: _saving
              ? null
              : () async {
                  setState(() => _saving = true);
                  await widget.onSave(_selected);
                  if (context.mounted) Navigator.pop(context);
                },
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.save),
        ),
      ],
    );
  }
}
