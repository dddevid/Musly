import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import 'package:provider/provider.dart';
import 'package:musly/l10n/app_localizations.dart';
import 'package:musly/services/cast_service.dart';
import 'package:musly/services/upnp_service.dart';
import 'package:musly/theme/app_theme.dart';
import 'airplay_button.dart';

import '../../screens/connect/connect_devices_modal.dart';

class CastButton extends StatelessWidget {
  final Color? iconColor;
  final double iconSize;

  const CastButton({super.key, this.iconColor, this.iconSize = 24});

  @override
  Widget build(BuildContext context) {
    
    if (Platform.isIOS) {
      return AirPlayButton(
        tintColor: iconColor ?? Colors.white,
        size: iconSize,
      );
    }

    final castState = context.select<CastService, CastState>((s) => s.state);
    final upnpConnected = context.select<UpnpService, bool>(
      (s) => s.isConnected,
    );

    final IconData icon;
    final Color color;
    final String tooltip;

    if (castState == CastState.connected) {
      icon = Icons.cast_connected;
      color = const Color(0xFF1DB954);
      tooltip = 'Cast: Connected';
    } else if (upnpConnected) {
      icon = Icons.speaker_group;
      color = const Color(0xFF1DB954);
      tooltip =
          'DLNA: ${context.read<UpnpService>().connectedDevice?.friendlyName ?? "device"}';
    } else {
      icon = Icons.cast;
      color = iconColor ?? Colors.white;
      tooltip = 'Connect to a Device (Musly Connect / BeatSync)';
    }

    return IconButton(
      icon: Icon(icon, size: iconSize),
      color: color,
      tooltip: tooltip,
      onPressed: () {
        final castService = context.read<CastService>();
        final upnpService = context.read<UpnpService>();

        if (castService.isConnected) {
          _showCastControlDialog(context, castService);
        } else if (upnpService.isConnected) {
          _showUpnpControlDialog(context, upnpService);
        } else {
          ConnectDevicesModal.show(context);
        }
      },
    );
  }

  Future<void> _showCastControlDialog(
    BuildContext context,
    CastService castService,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.cast_connected, color: Theme.of(context).colorScheme.primary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Casting',
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(
                    castService.deviceName ?? 'Unknown Device',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: isDark
                          ? AppTheme.darkSecondaryText
                          : AppTheme.lightSecondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (castService.mediaState.title != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.05,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    if (castService.mediaState.imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          castService.mediaState.imageUrl!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, e, st) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[800],
                            child: const Icon(
                              Icons.music_note,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            castService.mediaState.title ?? '',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            castService.mediaState.artist ?? '',
                            style: TextStyle(
                              fontSize: 14,
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
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Consumer<CastService>(
              builder: (context, cs, _) => Row(
                children: [
                  Icon(
                    cs.mediaState.volume == 0
                        ? Icons.volume_off
                        : cs.mediaState.volume < 0.5
                        ? Icons.volume_down
                        : Icons.volume_up,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  Expanded(
                    child: Slider(
                      value: cs.mediaState.volume.clamp(0.0, 1.0),
                      onChanged: (v) => cs.setVolume(v),
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    '${(cs.mediaState.volume * 100).round()}%',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppTheme.darkSecondaryText
                          : AppTheme.lightSecondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              castService.disconnect();
            },
            icon: const Icon(
              Icons.stop_circle_outlined,
              color: Color(0xFFFF3B30),
            ),
            label: Text(
              AppLocalizations.of(context)!.close, // Use close instead of disconnect for simplicity since 'disconnect' is missing
              style: const TextStyle(color: Color(0xFFFF3B30)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    );
  }

  Future<void> _showUpnpControlDialog(
    BuildContext context,
    UpnpService upnpService,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final device = upnpService.connectedDevice;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.speaker_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DLNA',
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(
                    device?.friendlyName ?? 'Unknown Device',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: isDark
                          ? AppTheme.darkSecondaryText
                          : AppTheme.lightSecondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (device != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.05,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow(Icons.devices, device.manufacturer, isDark),
                    if (device.modelName.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _infoRow(Icons.info_outline, device.modelName, isDark),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Consumer<UpnpService>(
              builder: (context, us, _) {
                if (us.volume < 0) {
                  
                  return Text(
                    'Playback is being sent to this DLNA device. '
                    'Use Musly\'s player controls to manage playback.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppTheme.darkSecondaryText
                          : AppTheme.lightSecondaryText,
                    ),
                    textAlign: TextAlign.center,
                  );
                }
                return Row(
                  children: [
                    Icon(
                      us.volume == 0
                          ? Icons.volume_off
                          : us.volume < 50
                          ? Icons.volume_down
                          : Icons.volume_up,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    Expanded(
                      child: Slider(
                        value: (us.volume / 100.0).clamp(0.0, 1.0),
                        onChanged: (v) => us.setVolume((v * 100).round()),
                        activeColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      '${us.volume}%',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppTheme.darkSecondaryText
                            : AppTheme.lightSecondaryText,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              upnpService.disconnect();
            },
            icon: const Icon(
              Icons.stop_circle_outlined,
              color: Color(0xFFFF3B30),
            ),
            label: const Text(
              'Disconnect',
              style: TextStyle(color: Color(0xFFFF3B30)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark
              ? AppTheme.darkSecondaryText
              : AppTheme.lightSecondaryText,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppTheme.darkSecondaryText
                  : AppTheme.lightSecondaryText,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showDevicePickerDialog(
    BuildContext context,
    CastService castService,
    UpnpService upnpService,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final discoveryManager = GoogleCastDiscoveryManager.instance;

    discoveryManager.startDiscovery();
    upnpService.discover();

    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _DevicePickerDialog(
        isDark: isDark,
        discoveryManager: discoveryManager,
        castService: castService,
        upnpService: upnpService,
      ),
    );

    await discoveryManager.stopDiscovery();
  }
}

class _DevicePickerDialog extends StatefulWidget {
  final bool isDark;
  final GoogleCastDiscoveryManagerPlatformInterface discoveryManager;
  final CastService castService;
  final UpnpService upnpService;

  const _DevicePickerDialog({
    required this.isDark,
    required this.discoveryManager,
    required this.castService,
    required this.upnpService,
  });

  @override
  State<_DevicePickerDialog> createState() => _DevicePickerDialogState();
}

class _DevicePickerDialogState extends State<_DevicePickerDialog> {
  List<UpnpDevice> _upnpDevices = [];
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    
    _pollTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) {
        final devices = widget.upnpService.devices;
        if (devices.length != _upnpDevices.length) {
          setState(() => _upnpDevices = List.of(devices));
        }
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return AlertDialog(
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.cast, color: Theme.of(context).colorScheme.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Cast / DLNA (Beta)',
              style: const TextStyle(fontSize: 18),
            ),
          ),
          Consumer<UpnpService>(
            builder: (ctx, upnp, _) => upnp.isDiscovering
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 360,
        child: StreamBuilder<List<GoogleCastDevice>>(
          stream: widget.discoveryManager.devicesStream,
          builder: (context, snapshot) {
            final castDevices = snapshot.data ?? [];
            final hasCast = castDevices.isNotEmpty;
            final hasUpnp = _upnpDevices.isNotEmpty;

            if (!hasCast && !hasUpnp) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Searching devices...',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Make sure your device is connected to the same Wi-Fi network.',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppTheme.darkSecondaryText
                            : AppTheme.lightSecondaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView(
              children: [
                if (hasCast) ...[
                  _SectionHeader(
                    label: 'Chromecast',
                    isDark: isDark,
                  ),
                  ...castDevices.map(
                    (d) => _DeviceTile(
                      icon: Icons.cast,
                      name: d.friendlyName,
                      subtitle: d.modelName ?? 'Chromecast',
                      isDark: isDark,
                      onTap: () async {
                        Navigator.pop(context);
                        final ok = await widget.castService.connectToDevice(d);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? "Connected to ${d.friendlyName}"
                                    : "Failed to connect to ${d.friendlyName}",
                              ),
                              backgroundColor: ok ? null : Colors.red,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
                if (hasUpnp) ...[
                  _SectionHeader(
                    label: 'DLNA / UPnP',
                    isDark: isDark,
                  ),
                  ..._upnpDevices.map(
                    (d) => _DeviceTile(
                      icon: Icons.speaker_rounded,
                      name: d.friendlyName,
                      subtitle: [
                        d.manufacturer,
                        d.modelName,
                      ].where((s) => s.isNotEmpty).join('  '),
                      isDark: isDark,
                      onTap: () async {
                        Navigator.pop(context);
                        final ok = await widget.upnpService.connect(d);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? "Connected to ${d.friendlyName}"
                                    : "Failed to connect to ${d.friendlyName}",
                              ),
                              backgroundColor: ok ? null : Colors.red,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionHeader({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: isDark
              ? AppTheme.darkSecondaryText
              : AppTheme.lightSecondaryText,
        ),
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final IconData icon;
  final String name;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;

  const _DeviceTile({
    required this.icon,
    required this.name,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 26),
      ),
      title: Text(
        name,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppTheme.darkSecondaryText
                    : AppTheme.lightSecondaryText,
              ),
            )
          : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
