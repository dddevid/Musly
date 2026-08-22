import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/music_folder.dart';
import '../models/server_config.dart';
import '../providers/auth_provider.dart';
import '../providers/player_provider.dart';
import '../providers/library_provider.dart';
import '../services/jukebox_service.dart';
import '../services/subsonic_service.dart';
import '../theme/app_theme.dart';
import '../utils/navigation_helper.dart';
import 'jukebox_screen.dart';
import 'add_server_screen.dart';
import '../widgets/settings/settings_section_card.dart';
import '../widgets/settings/settings_icon_badge.dart';
import '../widgets/settings/server_switcher_sheet.dart';
import '../utils/context_extensions.dart';

class SettingsServerTab extends StatefulWidget {
  const SettingsServerTab({super.key});

  @override
  State<SettingsServerTab> createState() => _SettingsServerTabState();
}

class _SettingsServerTabState extends State<SettingsServerTab> {

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final currentConfig = authProvider.config;

    final isYoutube =
        currentConfig?.isYoutube == true ||
        Provider.of<SubsonicService>(context, listen: false).isYoutube;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        _buildActiveServerCard(context, authProvider, currentConfig, isYoutube),

        const SizedBox(height: 24),

        _buildSavedServersSection(context, authProvider, currentConfig),

        if (!isYoutube) ...[
          const SizedBox(height: 24),
          SettingsSectionCard(
            title: l10n.sectionMusicFolders,
            children: [_buildMusicFoldersButton()],
          ),
          const SizedBox(height: 24),
          SettingsSectionCard(
            title: l10n.sectionJukebox,
            children: [_buildJukeboxSection()],
          ),
        ],

        const SizedBox(height: 24),
        SettingsSectionCard(
          title: l10n.sectionAccount,
          children: [_buildLogoutButton()],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildActiveServerCard(
    BuildContext context,
    AuthProvider authProvider,
    ServerConfig? config,
    bool isYoutube,
  ) {
    final isDark = context.isDark;

    final (IconData icon, List<Color> gradient, String serviceLabel) = isYoutube
        ? (CupertinoIcons.play_rectangle_fill, const [Color(0xFFFF3B30), Color(0xFFFF453A)], 'YT Stream')
        : config?.isJellyfin == true
            ? (CupertinoIcons.tv_fill, const [Color(0xFF00A4DC), Color(0xFF0077A3)], 'Jellyfin')
            : (CupertinoIcons.music_note_2, const [Color(0xFF6366F1), Color(0xFF8B5CF6)], config?.serverType ?? 'Navidrome / Subsonic');

    final serverName = config?.displayServerName ?? serviceLabel;
    final displayUrl = config?.displayUrl ?? (isYoutube ? 'YT Stream' : 'Not Connected');

    final isConnected = authProvider.state == AuthState.authenticated;
    final isAuthenticating = authProvider.state == AuthState.authenticating;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
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
                              serverName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (isConnected ? const Color(0xFF34C759) : Colors.orange)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CupertinoIcons.circle_fill,
                                  size: 6,
                                  color: isConnected ? const Color(0xFF34C759) : Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isConnected
                                      ? 'CONNECTED'
                                      : isAuthenticating
                                          ? 'CONNECTING'
                                          : 'OFFLINE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: isConnected ? const Color(0xFF34C759) : Colors.orange,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              displayUrl,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                FilledButton.tonalIcon(
                  onPressed: () => ServerSwitcherSheet.show(context),
                  icon: const Icon(CupertinoIcons.arrow_2_squarepath, size: 14),
                  label: const Text('Switch'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),

          if (!isYoutube && config != null) ...[
            Divider(height: 1, color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(CupertinoIcons.person_fill, size: 14, color: isDark ? Colors.white54 : Colors.black45),
                  const SizedBox(width: 6),
                  Text(
                    config.username,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  if (config.serverVersion != null && config.serverVersion!.isNotEmpty) ...[
                    Icon(CupertinoIcons.info_circle, size: 14, color: isDark ? Colors.white54 : Colors.black45),
                    const SizedBox(width: 6),
                    Text(
                      'v${config.serverVersion}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSavedServersSection(
    BuildContext context,
    AuthProvider authProvider,
    ServerConfig? currentConfig,
  ) {
    final isDark = context.isDark;

    return FutureBuilder<List<ServerConfig>>(
      future: authProvider.getSavedProfiles(),
      builder: (context, snapshot) {
        var profiles = snapshot.data ?? [];
        if (currentConfig != null &&
            !profiles.any((p) =>
                (p.isYoutube && currentConfig.isYoutube) ||
                (p.serverUrl == currentConfig.serverUrl && p.username == currentConfig.username))) {
          profiles = [currentConfig, ...profiles];
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SAVED SERVERS & SERVICES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppTheme.darkSecondaryText
                          : AppTheme.lightSecondaryText,
                      letterSpacing: 0.5,
                    ),
                  ),
                  InkWell(
                    onTap: () => ServerSwitcherSheet.show(context),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Text(
                        'Manage',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Column(
                  children: [
                    ...profiles.map((profile) {
                      final isActive = (profile.isYoutube && currentConfig?.isYoutube == true) ||
                          (currentConfig?.serverUrl == profile.serverUrl &&
                              currentConfig?.username == profile.username);

                      final (IconData pIcon, List<Color> pGradient) = profile.isYoutube
                          ? (CupertinoIcons.play_rectangle_fill, const [Color(0xFFFF3B30), Color(0xFFFF453A)])
                          : profile.isJellyfin
                              ? (CupertinoIcons.tv_fill, const [Color(0xFF00A4DC), Color(0xFF0077A3)])
                              : (CupertinoIcons.music_note_2, const [Color(0xFF6366F1), Color(0xFF8B5CF6)]);

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                            leading: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: pGradient),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(pIcon, color: Colors.white, size: 18),
                            ),
                            title: Text(
                              profile.displayServerName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              profile.displayUrl,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
                              ),
                            ),
                            trailing: isActive
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF34C759).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'ACTIVE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF34C759),
                                      ),
                                    ),
                                  )
                                : Icon(
                                    CupertinoIcons.arrow_2_squarepath,
                                    size: 16,
                                    color: isDark ? Colors.white38 : Colors.black38,
                                  ),
                            onTap: isActive
                                ? null
                                : () async {
                                    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
                                    final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
                                    await playerProvider.stop();
                                    await authProvider.switchProfile(profile);
                                    await libraryProvider.refresh();
                                  },
                          ),
                          if (profile != profiles.last)
                            Divider(height: 1, color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
                        ],
                      );
                    }),
                    Divider(height: 1, color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      leading: Icon(
                        CupertinoIcons.plus_circle_fill,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      title: Text(
                        'Add Server / Service',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      trailing: const Icon(CupertinoIcons.chevron_right, size: 14),
                      onTap: () => NavigationHelper.push(context, const AddServerScreen()),
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
        color: context.isDark
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
            secondary: SettingsIconBadge(
              gradientColors: const [Color(0xFFFF9500), Color(0xFFFF6000)],
              icon: CupertinoIcons.speaker_2,
            ),
            title: Text(l10n.jukeboxMode, style: const TextStyle(fontSize: 16)),
            subtitle: Text(
              l10n.jukeboxModeSubtitle,
              style: TextStyle(
                fontSize: 13,
                color: context.isDark
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
                color: context.isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
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
                color: context.isDark
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
      leading: SettingsIconBadge(
        gradientColors: const [Color(0xFFFF3B30), Color(0xFFFF453A)],
        icon: CupertinoIcons.square_arrow_right,
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
