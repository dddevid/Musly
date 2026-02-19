import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../l10n/app_localizations.dart';
import 'settings_playback_tab.dart';
import 'settings_storage_tab.dart';
import 'settings_server_tab.dart';
import 'settings_display_tab.dart';
import 'settings_about_tab.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _isDark
          ? AppTheme.darkBackground
          : AppTheme.lightBackground,
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        centerTitle: false,
        backgroundColor: _isDark
            ? AppTheme.darkBackground
            : AppTheme.lightBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppTheme.appleMusicRed,
          labelColor: AppTheme.appleMusicRed,
          unselectedLabelColor: _isDark
              ? AppTheme.darkSecondaryText
              : AppTheme.lightSecondaryText,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          tabs: [
            Tab(
              icon: const Icon(CupertinoIcons.play_circle, size: 20),
              text: l10n.tabPlayback,
            ),
            Tab(
              icon: const Icon(CupertinoIcons.folder, size: 20),
              text: l10n.tabStorage,
            ),
            Tab(
              icon: const Icon(CupertinoIcons.cloud, size: 20),
              text: l10n.tabServer,
            ),
            Tab(
              icon: const Icon(CupertinoIcons.paintbrush, size: 20),
              text: l10n.tabDisplay,
            ),
            Tab(
              icon: const Icon(CupertinoIcons.info, size: 20),
              text: l10n.tabAbout,
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          SettingsPlaybackTab(),
          SettingsStorageTab(),
          SettingsServerTab(),
          SettingsDisplayTab(),
          SettingsAboutTab(),
        ],
      ),
    );
  }
}
