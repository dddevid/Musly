import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/cast_service.dart';
import '../services/upnp_service.dart';
import '../theme/app_theme.dart';

class CastButton extends StatelessWidget {
  final Color? iconColor;
  final double iconSize;

  const CastButton({super.key, this.iconColor, this.iconSize = 24});

  @override
  Widget build(BuildContext context) {
    final castState = context.select<CastService, CastState>((s) => s.state);
    final upnpConnected = context.select<UpnpService, bool>(
      (s) => s.isConnected,
    );

    late IconData icon;
    late Color color;
    late String tooltip;

    if (castState == CastState.connected) {
      icon = Icons.cast_connected;
      color = AppTheme.appleMusicRed;
      tooltip =
          'Casting to ${context.read<CastService>().deviceName ?? "device"}';
    } else if (castState == CastState.connecting) {
      icon = Icons.cast_connected;
      color = Colors.orange;
      tooltip = AppLocalizations.of(context)!.connecting;
    } else if (upnpConnected) {
      icon = Icons.speaker_rounded;
      color = AppTheme.appleMusicRed;
      tooltip =
          'DLNA: ${context.read<UpnpService>().connectedDevice?.friendlyName ?? "device"}';
    } else {
      icon = Icons.cast;
      color = iconColor ?? Colors.white;
      tooltip = AppLocalizations.of(context)!.castDlnaBeta;
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
          _showDevicePickerDialog(context, castService, upnpService);
        }
      },
    );
  }

  //  Cast control dialog

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
            Icon(Icons.cast_connected, color: AppTheme.appleMusicRed, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.casting,
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
                    color: AppTheme.appleMusicRed,
                  ),
                  Expanded(
                    child: Slider(
                      value: cs.mediaState.volume.clamp(0.0, 1.0),
                      onChanged: (v) => cs.setVolume(v),
                      activeColor: AppTheme.appleMusicRed,
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
              AppLocalizations.of(context)!.disconnect,
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

  //  UPnP control dialog

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
              color: AppTheme.appleMusicRed,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.dlna,
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
            Text(
              'Playback is being sent to this DLNA device. '
              'Use Musly\'s player controls to manage playback.',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppTheme.darkSecondaryText
                    : AppTheme.lightSecondaryText,
              ),
              textAlign: TextAlign.center,
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

  //  Combined device picker (Chromecast + DLNA/UPnP)

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

//  Internal dialog widget

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
    // Poll UPnP service every 500 ms while dialog is open.
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
          Icon(Icons.cast, color: AppTheme.appleMusicRed, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.castDlnaBeta,
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
                      color: AppTheme.appleMusicRed,
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
                        color: AppTheme.appleMusicRed,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppLocalizations.of(context)!.searchingDevices,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.castWifiHint,
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
                    label: AppLocalizations.of(context)!.chromecast,
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
                                    ? AppLocalizations.of(
                                        context,
                                      )!.connectedToDevice(d.friendlyName)
                                    : AppLocalizations.of(
                                        context,
                                      )!.failedToConnectDevice(d.friendlyName),
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
                    label: AppLocalizations.of(context)!.dlnaUpnp,
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
                                    ? AppLocalizations.of(
                                        context,
                                      )!.connectedToDevice(d.friendlyName)
                                    : AppLocalizations.of(
                                        context,
                                      )!.failedToConnectDevice(d.friendlyName),
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
          color: AppTheme.appleMusicRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppTheme.appleMusicRed, size: 26),
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
