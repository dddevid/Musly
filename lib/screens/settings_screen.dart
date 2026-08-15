import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../l10n/app_localizations.dart';
import 'settings_playback_tab.dart';
import 'settings_storage_tab.dart';
import 'settings_server_tab.dart';
import 'settings_display_tab.dart';
import 'settings_about_tab.dart';
import 'settings_support_tab.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  bool get _isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    final tabs = [
      (icon: CupertinoIcons.play_circle, text: l10n.tabPlayback),
      (icon: CupertinoIcons.folder, text: l10n.tabStorage),
      (icon: CupertinoIcons.cloud, text: l10n.tabServer),
      (icon: CupertinoIcons.paintbrush, text: l10n.tabDisplay),
      (icon: CupertinoIcons.heart_fill, text: l10n.tabSupport),
      (icon: CupertinoIcons.info, text: l10n.tabAbout),
    ];
    
    final tabViews = const [
      SettingsPlaybackTab(),
      SettingsStorageTab(),
      SettingsServerTab(),
      SettingsDisplayTab(),
      SettingsSupportTab(),
      SettingsAboutTab(),
    ];

    if (_isDesktop) {
      return Scaffold(
        backgroundColor: _isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        appBar: AppBar(
          title: Text(l10n.settingsTitle),
          centerTitle: false,
          backgroundColor: _isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        body: Row(
          children: [
            Container(
              width: 250,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: tabs.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedIndex == index;
                  return ListTile(
                    leading: Icon(
                      tabs[index].icon,
                      color: isSelected ? Theme.of(context).colorScheme.primary : (_isDark ? Colors.white70 : Colors.black87),
                    ),
                    title: Text(
                      tabs[index].text,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Theme.of(context).colorScheme.primary : (_isDark ? Colors.white : Colors.black),
                      ),
                    ),
                    selected: isSelected,
                    selectedTileColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    onTap: () {
                      setState(() => _selectedIndex = index);
                      _tabController.animateTo(index);
                    },
                  );
                },
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: tabViews.map((v) => Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 800), child: v))).toList(),
              ),
            ),
          ],
        ),
      );
    }

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
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
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
          tabs: tabs.map((t) => Tab(icon: Icon(t.icon, size: 20), text: t.text)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: tabViews,
      ),
    );
  }
}
