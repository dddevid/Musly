// ── Musly Connect & Group Listening Modal ────────────────────────────────────
// Clean, human-crafted device selector inspired by Spotify Connect & Apple AirPlay.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import 'package:provider/provider.dart';
import '../../models/connect_device.dart';
import '../../models/song.dart';
import '../../providers/player_provider.dart';
// import '../../services/beatsync_service.dart';
import '../../services/musly_connect_service.dart';
import '../../services/cast_service.dart';
import '../../services/upnp_service.dart';
// import 'beatsync_party_screen.dart';

class ConnectDevicesModal extends StatefulWidget {
  final bool isDesktopDialog;

  const ConnectDevicesModal({
    super.key,
    this.isDesktopDialog = false,
  });

  static Future<void> show(BuildContext context) {
    HapticFeedback.mediumImpact();
    final isDesktop =
        !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

    if (isDesktop) {
      return showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440, maxHeight: 600),
            child: const ConnectDevicesModal(isDesktopDialog: true),
          ),
        ),
      );
    }

    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const ConnectDevicesModal(isDesktopDialog: false),
    );
  }

  @override
  State<ConnectDevicesModal> createState() => _ConnectDevicesModalState();
}

class _ConnectDevicesModalState extends State<ConnectDevicesModal> {
  final GoogleCastDiscoveryManagerPlatformInterface _discoveryManager =
      GoogleCastDiscoveryManager.instance;

  bool get _isCastSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final upnp = Provider.of<UpnpService>(context, listen: false);
      upnp.discover();

      if (_isCastSupported) {
        try {
          _discoveryManager.startDiscovery();
        } catch (_) {}
      }
    });
  }

  @override
  void dispose() {
    if (_isCastSupported) {
      try {
        _discoveryManager.stopDiscovery();
      } catch (_) {}
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF14151B) : Colors.white;
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

    return Consumer3<MuslyConnectService, CastService, UpnpService>(
      builder: (context, connectService, castService, upnpService, _) {
        // final compatibleDevices = connectService.getCompatibleDevices();
        // final partyRooms = connectService.getAvailablePartyRooms();
        final player = Provider.of<PlayerProvider>(context, listen: false);
        final isControlling = connectService.isControllingRemoteDevice;
        // final isInParty = beatSync.isInParty;

        return Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: widget.isDesktopDialog
                ? BorderRadius.circular(16)
                : const BorderRadius.vertical(top: Radius.circular(20)),
            border: widget.isDesktopDialog
                ? Border.all(color: dividerColor, width: 1)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          constraints: BoxConstraints(
            maxHeight: widget.isDesktopDialog
                ? 600
                : MediaQuery.of(context).size.height * 0.82,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mobile Drag Handle
                if (!widget.isDesktopDialog) ...[
                  Center(
                    child: Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Modal Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Connect to a Device',
                          style: TextStyle(
                            fontSize: widget.isDesktopDialog ? 17 : 19,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Select where audio should play',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.xmark_circle_fill,
                          size: 22),
                      color: isDark ? Colors.white30 : Colors.black26,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Main Device List
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Active Remote Control Status Bar ──────────────────
                        if (isControlling) ...[
                          _buildActiveRemoteControlTile(
                              context, connectService, isDark),
                          const SizedBox(height: 14),
                        ],

                        // ── Active Party Banner (BeatSync Disabled) ───────────
                        // if (isInParty) ...[
                        //   _buildActivePartyTile(context, beatSync, isDark),
                        //   const SizedBox(height: 14),
                        // ],

                        // ── Current Device / Output ───────────────────────────
                        if (!isControlling) ...[
                          _buildCurrentDeviceTile(
                              connectService, player, isDark),
                          const SizedBox(height: 16),
                        ],

                        // ── Group Session / Party Mode (BeatSync Disabled) ────
                        // if (!isInParty) ...[
                        //   _buildGroupSessionCard(context, beatSync, partyRooms, isDark),
                        //   const SizedBox(height: 20),
                        // ],

                        // ── Available Musly Devices (Musly Connect disabled) ──
                        // _buildSectionLabel('MUSLY CONNECT DEVICES'),
                        // const SizedBox(height: 6),
                        //
                        // if (compatibleDevices.isEmpty)
                        //   _buildEmptyNotice('No other devices running Musly found on this Wi-Fi.')
                        // else
                        //   ...compatibleDevices.map(
                        //     (device) => _buildMuslyDeviceRow(
                        //       context: context,
                        //       device: device,
                        //       connectService: connectService,
                        //       player: player,
                        //       isDark: isDark,
                        //     ),
                        //   ),
                        //
                        // const SizedBox(height: 16),

                        // ── Cast & UPnP Wireless Speakers ──────────────────────
                        StreamBuilder<List<GoogleCastDevice>>(
                          stream: _discoveryManager.devicesStream,
                          builder: (context, snapshot) {
                            final castDevices = snapshot.data ?? [];
                            final upnpDevices = upnpService.devices;
                            final hasWireless = castDevices.isNotEmpty ||
                                upnpDevices.isNotEmpty;

                            if (!hasWireless) return const SizedBox.shrink();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionLabel('SPEAKERS & TVS'),
                                const SizedBox(height: 6),
                                ...castDevices.map((cd) => _buildCastRow(
                                    context, cd, castService, isDark)),
                                ...upnpDevices.map((ud) => _buildUpnpRow(
                                    context, ud, upnpService, isDark)),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // Unused since Musly Connect device list is disabled (see build()).
  // Widget _buildEmptyNotice(String text) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
  //     child: Text(
  //       text,
  //       style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
  //     ),
  //   );
  // }

  Widget _buildCurrentDeviceTile(
      MuslyConnectService connect, PlayerProvider player, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1DB954).withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF1DB954).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.volume_up_rounded,
                color: Color(0xFF1DB954), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  connect.localDeviceName,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                const Text(
                  'Playing on this device',
                  style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1DB954),
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          // Subtle audio wave indicator
          const Icon(CupertinoIcons.waveform,
              color: Color(0xFF1DB954), size: 18),
        ],
      ),
    );
  }

  Widget _buildActiveRemoteControlTile(
    BuildContext context,
    MuslyConnectService connectService,
    bool isDark,
  ) {
    final remoteName =
        connectService.activeRemoteDevice?.name ?? 'Remote Device';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1DB954).withValues(alpha: isDark ? 0.14 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFF1DB954).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.devices_rounded, color: Color(0xFF1DB954), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  remoteName,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                const Text(
                  'Controlling remote playback',
                  style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1DB954),
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              connectService.disconnectRemote();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Switched back to this device')),
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              backgroundColor: isDark ? Colors.white12 : Colors.black12,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Disconnect',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /*
  // BeatSync code commented out temporarily
  Widget _buildActivePartyTile(BuildContext context, BeatSyncService beatSync, bool isDark) {
    ...
  }

  Widget _buildGroupSessionCard(...) {
    ...
  }
  */

  /*
  // Unused since Musly Connect device list is disabled (see build()).
  Future<void> _handleTransferToDevice(
    BuildContext context,
    ConnectDevice device,
    PlayerProvider player,
    MuslyConnectService connectService,
  ) async {
    final queue = player.queue.isNotEmpty
        ? player.queue
        : (player.currentSong != null ? [player.currentSong!] : <Song>[]);

    if (queue.isEmpty) {
      await connectService.connectToRemoteDevice(device);
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connected to ${device.name}')),
        );
      }
      return;
    }

    final pos = player.position.inSeconds;
    final idx = player.currentIndex.clamp(0, queue.length - 1);

    // 1. Immediately pause the local audio player engine on this device
    await player.pauseLocal();

    // 2. Connect to the target device as controller
    await connectService.connectToRemoteDevice(device);

    // 3. Send queue to target device
    final ok = await connectService.transferPlaybackToRemote(
      queue,
      idx,
      pos,
      targetDevice: device,
    );

    if (ok && context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Playback transferred to ${device.name}'),
          backgroundColor: const Color(0xFF1DB954),
        ),
      );
    }
  }
  */

  /*
  // Unused since Musly Connect device list is disabled (see build()).
  Widget _buildMuslyDeviceRow({
    required BuildContext context,
    required ConnectDevice device,
    required MuslyConnectService connectService,
    required PlayerProvider player,
    required bool isDark,
  }) {
    final isControlling = connectService.activeRemoteDevice?.id == device.id;
    final tileBg = isDark ? const Color(0xFF1A1B24) : const Color(0xFFF3F4F7);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isControlling ? const Color(0xFF1DB954).withValues(alpha: 0.1) : tileBg,
        borderRadius: BorderRadius.circular(12),
        border: isControlling
            ? Border.all(color: const Color(0xFF1DB954).withValues(alpha: 0.35))
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            if (isControlling) {
              connectService.disconnectRemote();
            } else {
              await _handleTransferToDevice(context, device, player, connectService);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Icon(
                  _getPlatformIcon(device.platform),
                  size: 22,
                  color: isControlling ? const Color(0xFF1DB954) : (isDark ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isControlling ? const Color(0xFF1DB954) : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        device.isPlaying && device.currentSongTitle != null
                            ? 'Playing: ${device.currentSongTitle}'
                            : 'Musly Connect • Ready',
                        style: TextStyle(
                          fontSize: 12,
                          color: isControlling ? const Color(0xFF1DB954) : Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Play Here transfer button
                IconButton(
                  icon: const Icon(CupertinoIcons.arrow_right_arrow_left, size: 18),
                  tooltip: 'Transfer audio here',
                  color: isDark ? Colors.white60 : Colors.black54,
                  onPressed: () => _handleTransferToDevice(context, device, player, connectService),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  */

  Widget _buildCastRow(BuildContext context, GoogleCastDevice castDevice,
      CastService cast, bool isDark) {
    final tileBg = isDark ? const Color(0xFF1A1B24) : const Color(0xFFF3F4F7);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          dense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          leading: const Icon(Icons.cast, size: 20, color: Colors.grey),
          title: Text(castDevice.friendlyName,
              style:
                  const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
          subtitle: Text(castDevice.modelName ?? 'Google Cast',
              style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
          onTap: () async {
            final ok = await cast.connectToDevice(castDevice);
            if (context.mounted) {
              Navigator.of(context).pop();
              if (!ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Failed to connect to ${castDevice.friendlyName}')),
                );
              }
            }
          },
        ),
      ),
    );
  }

  Widget _buildUpnpRow(BuildContext context, UpnpDevice upnpDevice,
      UpnpService upnp, bool isDark) {
    final tileBg = isDark ? const Color(0xFF1A1B24) : const Color(0xFFF3F4F7);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          dense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          leading:
              const Icon(Icons.speaker_group, size: 20, color: Colors.grey),
          title: Text(upnpDevice.friendlyName,
              style:
                  const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
          subtitle: Text(
            [upnpDevice.manufacturer, upnpDevice.modelName]
                .where((s) => s.isNotEmpty)
                .join(' • '),
            style: const TextStyle(fontSize: 11.5, color: Colors.grey),
          ),
          onTap: () async {
            final ok = await upnp.connect(upnpDevice);
            if (context.mounted) {
              Navigator.of(context).pop();
              if (!ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Failed to connect to ${upnpDevice.friendlyName}')),
                );
              }
            }
          },
        ),
      ),
    );
  }

  /*
  // Unused since Musly Connect device list is disabled (see build()).
  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'android':
        return Icons.phone_android_rounded;
      case 'ios':
        return Icons.phone_iphone_rounded;
      case 'windows':
        return Icons.desktop_windows_rounded;
      case 'macos':
        return Icons.laptop_mac_rounded;
      case 'linux':
        return Icons.computer_rounded;
      case 'tv':
        return Icons.tv_rounded;
      default:
        return Icons.speaker_rounded;
    }
  }
  */
}
