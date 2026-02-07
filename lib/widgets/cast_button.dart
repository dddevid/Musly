import 'package:flutter/material.dart';
import 'package:flutter_chrome_cast/lib.dart';
import 'package:provider/provider.dart';
import '../services/cast_service.dart';
import '../theme/app_theme.dart';

class CastButton extends StatelessWidget {
  final Color? iconColor;
  final double iconSize;

  const CastButton({
    super.key,
    this.iconColor,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CastService>(
      builder: (context, castService, _) {
        IconData icon;
        Color color;

        switch (castService.state) {
          case CastState.connecting:
            icon = Icons.cast_connected;
            color = Colors.orange;
            break;
          case CastState.connected:
            icon = Icons.cast_connected;
            color = AppTheme.appleMusicRed;
            break;
          case CastState.disconnecting:
            icon = Icons.cast;
            color = iconColor ?? Colors.white;
            break;
          case CastState.notConnected:
            icon = Icons.cast;
            color = iconColor ?? Colors.white;
            break;
        }

        return IconButton(
          icon: Icon(icon, size: iconSize),
          color: color,
          onPressed: () {
            if (castService.isConnected) {
              _showCastControlDialog(context, castService);
            } else {
              _showDevicePickerDialog(context, castService);
            }
          },
          tooltip: castService.isConnected
              ? 'Casting to ${castService.deviceName}'
              : 'Cast',
        );
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
            Icon(
              Icons.cast_connected,
              color: AppTheme.appleMusicRed,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Casting', style: TextStyle(fontSize: 18)),
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
            // Now playing info
            if (castService.mediaState.title != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
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
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[800],
                            child: const Icon(Icons.music_note, color: Colors.white),
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

            // Volume control
            Consumer<CastService>(
              builder: (context, castService, _) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          castService.mediaState.volume == 0
                              ? Icons.volume_off
                              : castService.mediaState.volume < 0.5
                                  ? Icons.volume_down
                                  : Icons.volume_up,
                          color: AppTheme.appleMusicRed,
                        ),
                        Expanded(
                          child: Slider(
                            value: castService.mediaState.volume,
                            onChanged: (value) {
                              castService.setVolume(value);
                            },
                            activeColor: AppTheme.appleMusicRed,
                          ),
                        ),
                        Text(
                          '${(castService.mediaState.volume * 100).round()}%',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? AppTheme.darkSecondaryText
                                : AppTheme.lightSecondaryText,
                          ),
                        ),
                      ],
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
              castService.disconnect();
            },
            icon: const Icon(Icons.stop_circle_outlined, color: Color(0xFFFF3B30)),
            label: const Text('Disconnect', style: TextStyle(color: Color(0xFFFF3B30))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDevicePickerDialog(
    BuildContext context,
    CastService castService,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final discoveryManager = GoogleCastDiscoveryManager.instance;

    // Start discovery
    await discoveryManager.startDiscovery();

    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.cast, color: AppTheme.appleMusicRed, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Cast to Device', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: StreamBuilder<List<GoogleCastDevice>>(
            stream: discoveryManager.devicesStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${snapshot.error}',
                        style: TextStyle(
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

              final devices = snapshot.data ?? [];

              if (devices.isEmpty) {
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
                      const Text(
                        'Searching for devices...',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Make sure your Cast device is on\nthe same WiFi network',
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

              return ListView.separated(
                itemCount: devices.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
                ),
                itemBuilder: (context, index) {
                  final device = devices[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.appleMusicRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.tv,
                        color: AppTheme.appleMusicRed,
                        size: 28,
                      ),
                    ),
                    title: Text(
                      device.friendlyName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      device.modelName ?? 'Cast Device',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppTheme.darkSecondaryText
                            : AppTheme.lightSecondaryText,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      Navigator.pop(context);
                      final success = await castService.connectToDevice(device);
                      if (context.mounted && success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Connected to ${device.friendlyName}'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Failed to connect to ${device.friendlyName}',
                            ),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    // Stop discovery when dialog closes
    await discoveryManager.stopDiscovery();
  }
}
