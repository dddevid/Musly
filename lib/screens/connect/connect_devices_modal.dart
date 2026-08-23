// ── Musly Connect & BeatSync [BETA] Device Modal ──────────────────────────────
// BeatSync multiroom party concept inspired by:
// https://github.com/freeman-jiang/beatsync
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
import '../../services/beatsync_service.dart';
import '../../services/musly_connect_service.dart';
import '../../services/cast_service.dart';
import '../../services/upnp_service.dart';
import '../../theme/app_theme.dart';
import 'beatsync_party_screen.dart';

class ConnectDevicesModal extends StatefulWidget {
  final bool isDesktopDialog;

  const ConnectDevicesModal({
    super.key,
    this.isDesktopDialog = false,
  });

  static Future<void> show(BuildContext context) {
    HapticFeedback.mediumImpact();
    final isDesktop = !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

    if (isDesktop) {
      return showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460, maxHeight: 640),
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
      // Trigger UPnP discovery
      final upnp = Provider.of<UpnpService>(context, listen: false);
      upnp.discover();

      // Trigger Cast discovery on supported mobile platforms only
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
    final surfaceColor = isDark ? const Color(0xFF14151E) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1C1D29) : const Color(0xFFF4F5F9);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);

    return Consumer4<MuslyConnectService, BeatSyncService, CastService, UpnpService>(
      builder: (context, connectService, beatSync, castService, upnpService, _) {
        final compatibleDevices = connectService.getCompatibleDevices();
        final partyRooms = connectService.getAvailablePartyRooms();
        final player = Provider.of<PlayerProvider>(context, listen: false);
        final isControlling = connectService.isControllingRemoteDevice;
        final isInParty = beatSync.isInParty;

        return Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: widget.isDesktopDialog
                ? BorderRadius.circular(20)
                : const BorderRadius.vertical(top: Radius.circular(24)),
            border: widget.isDesktopDialog
                ? Border.all(color: borderColor, width: 1.5)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          constraints: BoxConstraints(
            maxHeight: widget.isDesktopDialog
                ? 640
                : MediaQuery.of(context).size.height * 0.85,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag Handle for Mobile
                if (!widget.isDesktopDialog) ...[
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Connect & Devices',
                      style: TextStyle(
                        fontSize: widget.isDesktopDialog ? 18 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.xmark_circle_fill, size: 20),
                      color: isDark ? Colors.white54 : Colors.black45,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Controlling Remote Device Banner ───────────────────
                        if (isControlling) ...[
                          _buildActiveRemoteControlBanner(context, connectService, isDark),
                          const SizedBox(height: 12),
                        ],

                        // ── Active BeatSync Party Banner ───────────────────────
                        if (isInParty) ...[
                          _buildActiveBeatSyncBanner(context, beatSync, isDark),
                          const SizedBox(height: 12),
                        ],

                        // Current Device Card
                        _buildCurrentDeviceCard(connectService, player, isDark),
                        const SizedBox(height: 16),

                        // ── Musly BeatSync [BETA] Card ─────────────────────────
                        _buildBeatSyncSection(context, beatSync, partyRooms, isDark, cardBg, borderColor),
                        const SizedBox(height: 20),

                        // ── Musly Connect Devices (Spotify Connect style) ──────
                        _buildSectionHeader('Musly Connect Devices', compatibleDevices.isNotEmpty),
                        const SizedBox(height: 8),

                        if (compatibleDevices.isEmpty)
                          _buildEmptyDeviceHint('No other Musly devices found on this Wi-Fi.')
                        else
                          ...compatibleDevices.map(
                            (d) => _buildMuslyConnectDeviceTile(
                              context,
                              d,
                              connectService,
                              player,
                              isDark,
                              cardBg,
                              borderColor,
                            ),
                          ),

                        const SizedBox(height: 16),

                        // ── Cast & DLNA Devices ───────────────────────────────
                        StreamBuilder<List<GoogleCastDevice>>(
                          stream: _discoveryManager.devicesStream,
                          builder: (context, snapshot) {
                            final castDevices = snapshot.data ?? [];
                            final upnpDevices = upnpService.devices;
                            final hasWireless = castDevices.isNotEmpty || upnpDevices.isNotEmpty;

                            if (!hasWireless) return const SizedBox.shrink();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader('Speakers & Displays (Cast / DLNA)', true),
                                const SizedBox(height: 8),

                                // Cast Devices
                                ...castDevices.map((cd) => _buildCastDeviceTile(context, cd, castService, cardBg, borderColor)),

                                // UPnP Devices
                                ...upnpDevices.map((ud) => _buildUpnpDeviceTile(context, ud, upnpService, cardBg, borderColor)),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),
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

  Widget _buildActiveRemoteControlBanner(
    BuildContext context,
    MuslyConnectService connectService,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.brandRed.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.brandRed.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.antenna_radiowaves_left_right, color: AppTheme.brandRed, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CONTROLLING REMOTE DEVICE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.brandRed, letterSpacing: 0.5),
                ),
                const SizedBox(height: 1),
                Text(
                  connectService.activeRemoteDevice?.name ?? 'Remote Device',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              connectService.disconnectRemote();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Disconnected from remote device')),
              );
            },
            icon: const Icon(CupertinoIcons.xmark, size: 12),
            label: const Text('Disconnect', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandRed,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveBeatSyncBanner(
    BuildContext context,
    BeatSyncService beatSync,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.music_mic, color: Color(0xFF8B5CF6), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  beatSync.isHost ? 'HOSTING PARTY ROOM' : 'CONNECTED TO PARTY',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF8B5CF6), letterSpacing: 0.5),
                ),
                const SizedBox(height: 1),
                Text(
                  beatSync.partyRoomName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                CupertinoPageRoute(builder: (_) => const BeatSyncPartyScreen()),
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Open Room', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(CupertinoIcons.xmark_circle, size: 18, color: Colors.redAccent),
            tooltip: beatSync.isHost ? 'Close Room' : 'Leave Room',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              beatSync.leaveParty();
              MuslyConnectService().disconnectRemote();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(beatSync.isHost ? 'Party room closed' : 'Left party room')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentDeviceCard(MuslyConnectService connect, PlayerProvider player, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1DB954).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1DB954).withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFF1DB954),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.speaker_2_fill, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CURRENT DEVICE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF1DB954), letterSpacing: 0.5),
                ),
                const SizedBox(height: 2),
                Text(
                  connect.localDeviceName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(CupertinoIcons.waveform, color: Color(0xFF1DB954), size: 16),
        ],
      ),
    );
  }

  Widget _buildBeatSyncSection(
    BuildContext context,
    BeatSyncService beatSync,
    List<ConnectDevice> availableRooms,
    bool isDark,
    Color cardBg,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(CupertinoIcons.sparkles, color: Color(0xFF8B5CF6), size: 16),
                  SizedBox(width: 8),
                  Text(
                    'BeatSync Multi-Speaker',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'BETA',
                  style: TextStyle(
                    color: Color(0xFF8B5CF6),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Sync audio across phones and PCs over Wi-Fi with NTP precision.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.black54,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (!beatSync.isHost) {
                      beatSync.startHostingParty();
                    }
                    Navigator.of(context).push(
                      CupertinoPageRoute(builder: (_) => const BeatSyncPartyScreen()),
                    );
                  },
                  icon: const Icon(CupertinoIcons.music_mic, size: 14),
                  label: Text(beatSync.isHost ? 'Open Party' : 'Host Party', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF8B5CF6),
                    side: const BorderSide(color: Color(0xFF8B5CF6)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              if (availableRooms.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final host = availableRooms.first;
                      final ok = await MuslyConnectService().connectToRemoteDevice(host);
                      if (ok && context.mounted) {
                        beatSync.joinPartyAsGuest(host);
                        MuslyConnectService().sendCommand(
                          ConnectCommandType.joinParty,
                          {'guestName': MuslyConnectService().localDeviceName},
                        );
                        Navigator.of(context).push(
                          CupertinoPageRoute(builder: (_) => const BeatSyncPartyScreen()),
                        );
                      }
                    },
                    icon: const Icon(CupertinoIcons.person_badge_plus, size: 14),
                    label: Text('Join (${availableRooms.first.name})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool hasDevices) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey, letterSpacing: 0.6),
    );
  }

  Widget _buildMuslyConnectDeviceTile(
    BuildContext context,
    ConnectDevice device,
    MuslyConnectService connectService,
    PlayerProvider player,
    bool isDark,
    Color cardBg,
    Color borderColor,
  ) {
    final isControlling = connectService.activeRemoteDevice?.id == device.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isControlling
            ? const Color(0xFF1DB954).withValues(alpha: 0.08)
            : cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isControlling ? const Color(0xFF1DB954).withValues(alpha: 0.4) : borderColor,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Icon(
          _getPlatformIcon(device.platform),
          size: 22,
          color: isControlling ? const Color(0xFF1DB954) : (isDark ? Colors.white70 : Colors.black87),
        ),
        title: Text(
          device.name,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          device.isPlaying && device.currentSongTitle != null
              ? 'Playing: ${device.currentSongTitle}'
              : 'Musly (${device.platform.toUpperCase()})',
          style: TextStyle(
            fontSize: 12,
            color: isControlling ? const Color(0xFF1DB954) : Colors.grey,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Transfer Playback Button
            IconButton(
              icon: const Icon(CupertinoIcons.arrow_right_arrow_left_circle, size: 22),
              tooltip: 'Transfer playback here',
              color: isDark ? Colors.white70 : Colors.black87,
              onPressed: () async {
                final queueToTransfer = player.queue.isNotEmpty
                    ? player.queue
                    : (player.currentSong != null ? [player.currentSong!] : <Song>[]);

                if (queueToTransfer.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No active playback to transfer')),
                  );
                  return;
                }

                final currentPos = player.position.inSeconds;
                final currentIndex = player.currentIndex.clamp(0, queueToTransfer.length - 1);

                // Connect to remote device
                await connectService.connectToRemoteDevice(device);

                // Transfer playback with dual WebSocket + HTTP delivery
                final delivered = await connectService.transferPlaybackToRemote(
                  queueToTransfer,
                  currentIndex,
                  currentPos,
                  targetDevice: device,
                );

                if (delivered) {
                  // Pause local playback since it migrated to target device
                  await player.pause();

                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Playback transferred to ${device.name}'),
                        backgroundColor: const Color(0xFF1DB954),
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to transfer playback to ${device.name}')),
                    );
                  }
                }
              },
            ),

            // Disconnect or Control toggle
            if (isControlling)
              IconButton(
                icon: const Icon(CupertinoIcons.xmark_circle, size: 20, color: Colors.redAccent),
                tooltip: 'Disconnect controller',
                onPressed: () {
                  connectService.disconnectRemote();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Disconnected from ${device.name}')),
                  );
                },
              )
            else
              IconButton(
                icon: const Icon(CupertinoIcons.slider_horizontal_3, size: 20),
                tooltip: 'Remote Control',
                color: isDark ? Colors.white54 : Colors.black45,
                onPressed: () async {
                  final ok = await connectService.connectToRemoteDevice(device);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok ? 'Connected to ${device.name}' : 'Could not connect'),
                      ),
                    );
                  }
                },
              ),
          ],
        ),
          onTap: () async {
            if (isControlling) {
              connectService.disconnectRemote();
            } else {
              await connectService.connectToRemoteDevice(device);
            }
          },
        ),
      ),
    );
  }

  Widget _buildCastDeviceTile(
    BuildContext context,
    GoogleCastDevice castDevice,
    CastService cast,
    Color cardBg,
    Color borderColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          leading: const Icon(Icons.cast, size: 22, color: Colors.white70),
          title: Text(castDevice.friendlyName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: Text(castDevice.modelName ?? 'Google Cast', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          onTap: () async {
            final ok = await cast.connectToDevice(castDevice);
            if (context.mounted) {
              Navigator.of(context).pop();
              if (!ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to connect to ${castDevice.friendlyName}')),
                );
              }
            }
          },
        ),
      ),
    );
  }

  Widget _buildUpnpDeviceTile(
    BuildContext context,
    UpnpDevice upnpDevice,
    UpnpService upnp,
    Color cardBg,
    Color borderColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          leading: const Icon(Icons.speaker_group, size: 22, color: Colors.white70),
          title: Text(upnpDevice.friendlyName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: Text(
            [upnpDevice.manufacturer, upnpDevice.modelName].where((s) => s.isNotEmpty).join(' • '),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          onTap: () async {
            final ok = await upnp.connect(upnpDevice);
            if (context.mounted) {
              Navigator.of(context).pop();
              if (!ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to connect to ${upnpDevice.friendlyName}')),
                );
              }
            }
          },
        ),
      ),
    );
  }

  Widget _buildEmptyDeviceHint(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        message,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'windows':
        return Icons.desktop_windows_rounded;
      case 'macos':
        return Icons.laptop_mac_rounded;
      case 'linux':
        return Icons.computer_rounded;
      case 'ios':
        return CupertinoIcons.device_phone_portrait;
      case 'android':
      default:
        return Icons.phone_android_rounded;
    }
  }
}
