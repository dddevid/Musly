import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/subsonic_service.dart';
import '../theme/app_theme.dart';

class SettingsServerTab extends StatefulWidget {
  const SettingsServerTab({super.key});

  @override
  State<SettingsServerTab> createState() => _SettingsServerTabState();
}

class _SettingsServerTabState extends State<SettingsServerTab> {
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
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
          title: 'SERVER CONNECTION',
          children: [
            _buildInfoTile(
              icon: CupertinoIcons.cloud,
              iconColor: AppTheme.appleMusicRed,
              title: 'Server Type',
              subtitle: serverSubtitle,
            ),
            _buildDivider(),
            _buildInfoTile(
              icon: CupertinoIcons.link,
              iconColor: const Color(0xFF007AFF),
              title: 'Server URL',
              subtitle: authProvider.config?.serverUrl ?? 'Not connected',
            ),
            _buildDivider(),
            _buildInfoTile(
              icon: CupertinoIcons.person,
              iconColor: const Color(0xFF34C759),
              title: 'Username',
              subtitle: authProvider.config?.username ?? 'Unknown',
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSection(
          title: 'MUSIC FOLDERS',
          children: [_buildMusicFoldersButton()],
        ),
        const SizedBox(height: 24),
        _buildSection(title: 'ACCOUNT', children: [_buildLogoutButton()]),
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
    final folders = await subsonicService.getMusicFolders();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.musicFolders),
        content: folders.isEmpty
            ? Text(AppLocalizations.of(context)!.noMusicFolders)
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: folders.map((folder) {
                  return ListTile(
                    leading: const Icon(CupertinoIcons.folder),
                    title: Text(folder.name),
                  );
                }).toList(),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close),
          ),
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
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.logout),
            content: Text(AppLocalizations.of(context)!.logoutConfirmation),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Provider.of<AuthProvider>(context, listen: false).logout();
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
