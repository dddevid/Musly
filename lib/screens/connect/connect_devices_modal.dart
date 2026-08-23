// ── Musly Connect & BeatSync [BETA] Device Modal ──────────────────────────────
// BeatSync multiroom party concept inspired by:
// https://github.com/freeman-jiang/beatsync
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import 'package:provider/provider.dart';
import '../../models/connect_device.dart';
import '../../providers/player_provider.dart';
import '../../services/beatsync_service.dart';
import '../../services/musly_connect_service.dart';
import '../../services/cast_service.dart';
import '../../services/upnp_service.dart';
import 'beatsync_party_screen.dart';

class ConnectDevicesModal extends StatefulWidget {
  const ConnectDevicesModal({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const ConnectDevicesModal(),
    );
  }

  @override
  State<ConnectDevicesModal> createState() => _ConnectDevicesModalState();
}

class _ConnectDevicesModalState extends State<ConnectDevicesModal> {
  final GoogleCastDiscoveryManagerPlatformInterface _discoveryManager =
      GoogleCastDiscoveryManager.instance;

  @override
  void initState() {
    super.initState();
    // Trigger UPnP discovery
    final upnp = Provider.of<UpnpService>(context, listen: false);
    upnp.discover();

    // Trigger Cast discovery
    try {
      _discoveryManager.startDiscovery();
    } catch (_) {}
  }

  @override
  void dispose() {
    try {
      _discoveryManager.stopDiscovery();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer4<MuslyConnectService, BeatSyncService, CastService, UpnpService>(
      builder: (context, connectService, beatSync, castService, upnpService, _) {
        final compatibleDevices = connectService.getCompatibleDevices();
        final partyRooms = connectService.getAvailablePartyRooms();
        final player = Provider.of<PlayerProvider>(context, listen: false);

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF13141E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Connect to a Device',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(CupertinoIcons.xmark_circle_fill, size: 22),
                        color: isDark ? Colors.white54 : Colors.black45,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Current Device Card
                  _buildCurrentDeviceCard(connectService, player),
                  const SizedBox(height: 20),

                  // ── BeatSync Party Room [BETA] Hero ───────────────────────
                  _buildBeatSyncHeroSection(context, beatSync, partyRooms),
                  const SizedBox(height: 24),

                  // ── Musly Connect Devices (Spotify Connect style) ──────────
                  _buildSectionHeader('Musly Connect Devices', compatibleDevices.isNotEmpty),
                  const SizedBox(height: 8),

                  if (compatibleDevices.isEmpty)
                    _buildEmptyDeviceHint('No other Musly devices found on your Wi-Fi network.')
                  else
                    ...compatibleDevices.map((d) => _buildMuslyConnectDeviceTile(context, d, connectService, player)),

                  const SizedBox(height: 20),

                  // ── Cast & DLNA Devices ───────────────────────────────────
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
                          ...castDevices.map((cd) => _buildCastDeviceTile(context, cd, castService)),

                          // UPnP Devices
                          ...upnpDevices.map((ud) => _buildUpnpDeviceTile(context, ud, upnpService)),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentDeviceCard(MuslyConnectService connect, PlayerProvider player) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1DB954).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1DB954).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF1DB954),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.speaker_2_fill, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Currently Playing On',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1DB954)),
                ),
                const SizedBox(height: 2),
                Text(
                  connect.localDeviceName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(CupertinoIcons.waveform, color: Color(0xFF1DB954), size: 18),
        ],
      ),
    );
  }

  Widget _buildBeatSyncHeroSection(
    BuildContext context,
    BeatSyncService beatSync,
    List<ConnectDevice> availableRooms,
  ) {
    final isInParty = beatSync.isInParty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(CupertinoIcons.sparkles, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Musly BeatSync',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'BETA',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Synchronize multiple phones & computers over Wi-Fi as surround party speakers with millisecond precision.',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 14),

          if (isInParty) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(builder: (_) => const BeatSyncPartyScreen()),
                  );
                },
                icon: const Icon(CupertinoIcons.music_mic, size: 16),
                label: Text('Open Active Room (${beatSync.partyRoomName})'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF8B5CF6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      beatSync.startHostingParty();
                      Navigator.of(context).push(
                        CupertinoPageRoute(builder: (_) => const BeatSyncPartyScreen()),
                      );
                    },
                    icon: const Icon(CupertinoIcons.play_circle_fill, size: 16),
                    label: const Text('Host Party'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF8B5CF6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                if (availableRooms.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
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
                      icon: const Icon(CupertinoIcons.person_badge_plus_fill, size: 16, color: Colors.white),
                      label: Text('Join (${availableRooms.first.name})', style: const TextStyle(color: Colors.white, fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool hasDevices) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.8),
        ),
      ],
    );
  }

  Widget _buildMuslyConnectDeviceTile(
    BuildContext context,
    ConnectDevice device,
    MuslyConnectService connectService,
    PlayerProvider player,
  ) {
    final isControlling = connectService.activeRemoteDevice?.id == device.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isControlling
            ? const Color(0xFF1DB954).withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isControlling ? const Color(0xFF1DB954) : Colors.white10,
        ),
      ),
      child: ListTile(
        leading: Icon(_getPlatformIcon(device.platform), size: 24, color: isControlling ? const Color(0xFF1DB954) : Colors.white70),
        title: Text(device.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        subtitle: Text(
          device.isPlaying && device.currentSongTitle != null
              ? 'Playing: ${device.currentSongTitle}'
              : 'Musly (${device.platform.toUpperCase()})',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(CupertinoIcons.arrow_right_arrow_left_circle, size: 20),
              tooltip: 'Transfer playback here',
              onPressed: () async {
                final ok = await connectService.connectToRemoteDevice(device);
                if (ok && player.queue.isNotEmpty) {
                  connectService.transferPlaybackToRemote(
                    player.queue,
                    player.currentIndex,
                    player.position.inSeconds,
                  );
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Playback transferred to ${device.name}')),
                    );
                  }
                }
              },
            ),
          ],
        ),
        onTap: () async {
          await connectService.connectToRemoteDevice(device);
        },
      ),
    );
  }

  Widget _buildCastDeviceTile(BuildContext context, GoogleCastDevice castDevice, CastService cast) {
    return ListTile(
      leading: const Icon(Icons.cast, color: Colors.white70),
      title: Text(castDevice.friendlyName, style: const TextStyle(fontSize: 14)),
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
    );
  }

  Widget _buildUpnpDeviceTile(BuildContext context, UpnpDevice upnpDevice, UpnpService upnp) {
    return ListTile(
      leading: const Icon(Icons.speaker_group, color: Colors.white70),
      title: Text(upnpDevice.friendlyName, style: const TextStyle(fontSize: 14)),
      subtitle: Text([upnpDevice.manufacturer, upnpDevice.modelName].where((s) => s.isNotEmpty).join(' • '), style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
    );
  }

  Widget _buildEmptyDeviceHint(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        message,
        style: const TextStyle(fontSize: 13, color: Colors.grey),
      ),
    );
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'windows':
        return Icons.desktop_windows;
      case 'macos':
        return Icons.laptop_mac;
      case 'linux':
        return Icons.computer;
      case 'ios':
        return CupertinoIcons.device_phone_portrait;
      case 'android':
      default:
        return Icons.phone_android;
    }
  }
}
