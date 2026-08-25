import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:musly/models/models.dart';
import 'package:musly/providers/player_provider.dart';
import 'package:musly/services/subsonic_service.dart';
import 'package:musly/theme/app_theme.dart';
import 'package:musly/l10n/app_localizations.dart';

class RadioScreen extends StatefulWidget {
  const RadioScreen({super.key});

  @override
  State<RadioScreen> createState() => _RadioScreenState();
}

class _RadioScreenState extends State<RadioScreen> {
  List<RadioStation> _stations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final subsonic = Provider.of<SubsonicService>(context, listen: false);
      final stations = await subsonic.getInternetRadioStations();

      if (mounted) {
        setState(() {
          _stations = stations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _playStation(RadioStation station) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    playerProvider.playRadioStation(station);
  }

  Future<void> _openHomePage(RadioStation station) async {
    if (station.homePageUrl == null || station.homePageUrl!.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noHomepageUrl)),
      );
      return;
    }

    final uri = Uri.tryParse(station.homePageUrl!);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showStationOptions(RadioStation station) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.play_circle),
                title: Text(
                  l10n.playAll,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _playStation(station);
                },
              ),
              if (station.homePageUrl != null && station.homePageUrl!.isNotEmpty)
                ListTile(
                  leading: const Icon(CupertinoIcons.globe),
                  title: Text(
                    'Homepage',
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _openHomePage(station);
                  },
                ),
              ListTile(
                leading: const Icon(CupertinoIcons.link),
                title: Text(
                  l10n.copyStreamUrl,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.streamUrlLabel(station.streamUrl))),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.radioStations),
        backgroundColor: isDark ? AppTheme.darkBackground : Colors.white,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.refresh),
            onPressed: _loadStations,
            tooltip: l10n.refresh,
          ),
        ],
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.exclamationmark_triangle,
                size: 64,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.failedToLoadRadioStations,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadStations,
                icon: const Icon(CupertinoIcons.refresh),
                label: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (_stations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.radiowaves_right,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                l10n.noRadioStations,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.addRadioStationsHint,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStations,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 100),
        itemExtent: 72.0,
        itemCount: _stations.length,
        itemBuilder: (context, index) {
          final station = _stations[index];
          return _RadioStationTile(
            station: station,
            onTap: () => _playStation(station),
            onLongPress: () => _showStationOptions(station),
          );
        },
      ),
    );
  }
}

class _RadioStationTile extends StatelessWidget {
  final RadioStation station;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _RadioStationTile({
    required this.station,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        final isPlaying =
            playerProvider.isPlayingRadio &&
            playerProvider.currentRadioStation?.id == station.id;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isPlaying
                    ? [
                        AppTheme.brandRed,
                        AppTheme.brandRed.withValues(alpha: 0.7),
                      ]
                    : [const Color(0xFF5856D6), const Color(0xFF007AFF)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPlaying
                  ? CupertinoIcons.waveform
                  : CupertinoIcons.radiowaves_right,
              color: Colors.white,
              size: 28,
            ),
          ),
          title: Text(
            station.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isPlaying
                  ? AppTheme.brandRed
                  : (isDark ? Colors.white : Colors.black),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            station.streamUrl,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: isPlaying
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.brandRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.waveform,
                        color: AppTheme.brandRed,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          color: AppTheme.brandRed,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              : Icon(
                  CupertinoIcons.play_circle_fill,
                  color: isDark ? Colors.white38 : Colors.black26,
                  size: 32,
                ),
          onTap: onTap,
          onLongPress: onLongPress,
        );
      },
    );
  }
}
