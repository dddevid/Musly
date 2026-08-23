// ── BeatSync Party Experience [BETA] ─────────────────────────────────────────
// Multi-device synchronized audio broadcast inspired by:
// https://github.com/freeman-jiang/beatsync
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/player_provider.dart';
import '../../services/beatsync_service.dart';
import '../../services/musly_connect_service.dart';
import '../../widgets/common/album_artwork.dart';

/// Immersive BeatSync [BETA] Party Room Dashboard screen.
class BeatSyncPartyScreen extends StatefulWidget {
  const BeatSyncPartyScreen({super.key});

  @override
  State<BeatSyncPartyScreen> createState() => _BeatSyncPartyScreenState();
}

class _BeatSyncPartyScreenState extends State<BeatSyncPartyScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  Timer? _ntpTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    // If guest, run periodic NTP probe to maintain precise offset
    final beatSync = BeatSyncService();
    if (beatSync.isGuest) {
      _ntpTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        MuslyConnectService().sendNtpProbeToHost();
      });
      MuslyConnectService().sendNtpProbeToHost();
    }
  }

  @override
  void dispose() {
    _ntpTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer2<BeatSyncService, PlayerProvider>(
      builder: (context, beatSync, playerProvider, _) {
        final currentSong = playerProvider.currentSong;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0D0E15) : const Color(0xFFF7F8FC),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Row(
              children: [
                const Icon(CupertinoIcons.sparkles, color: Color(0xFF8B5CF6), size: 18),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    beatSync.partyRoomName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.5)),
                  ),
                  child: const Text(
                    'BETA',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF8B5CF6),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton.icon(
                icon: const Icon(CupertinoIcons.square_arrow_right, size: 15, color: Colors.redAccent),
                label: Text(
                  beatSync.isHost ? 'End' : 'Leave',
                  style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () {
                  if (beatSync.isHost) {
                    MuslyConnectService().endPartySession();
                  } else {
                    MuslyConnectService().leavePartySession();
                  }
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // 1. Sync Wave Pulsing Visualizer
                  _buildSyncPulsingHero(beatSync, playerProvider),
                  const SizedBox(height: 24),

                  // 2. Real-time NTP & Sync Diagnostics Card
                  _buildSyncDiagnosticsCard(beatSync),
                  const SizedBox(height: 20),

                  // 3. Manual Calibration Nudge Slider (Bluetooth/Hardware Delay)
                  if (beatSync.isGuest) ...[
                    _buildManualCalibrationNudge(beatSync),
                    const SizedBox(height: 20),
                  ],

                  // 4. Connected Party Members List
                  _buildPartyMembersList(beatSync),
                  const SizedBox(height: 24),

                  // 5. Host Controls or Leave Button
                  if (beatSync.isHost && currentSong != null) ...[
                    _buildHostBroadcastControls(playerProvider, isDark),
                    const SizedBox(height: 20),
                  ],

                  // 6. Bottom Leave / Close Party Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (beatSync.isHost) {
                          MuslyConnectService().endPartySession();
                        } else {
                          MuslyConnectService().leavePartySession();
                        }
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(CupertinoIcons.square_arrow_right, size: 16, color: Colors.redAccent),
                      label: Text(
                        beatSync.isHost ? 'End Party Room for Everyone' : 'Leave Party Room',
                        style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSyncPulsingHero(BeatSyncService beatSync, PlayerProvider player) {
    final song = player.currentSong;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final scale = 1.0 + (_pulseController.value * 0.06);
        final glowAlpha = 0.2 + (_pulseController.value * 0.25);

        return Column(
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: glowAlpha),
                    blurRadius: 36 * scale,
                    spreadRadius: 8 * scale,
                  ),
                ],
              ),
              child: Transform.scale(
                scale: scale,
                child: song != null
                    ? ClipOval(
                        child: AlbumArtwork(
                          coverArt: song.coverArt,
                          size: 140,
                        ),
                      )
                    : Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF06B6D4)],
                          ),
                        ),
                        child: const Icon(
                          CupertinoIcons.music_note_2,
                          color: Colors.white,
                          size: 54,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              song?.title ?? 'No Track Playing',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              song?.artist ?? (beatSync.isHost ? 'You are the DJ' : 'Listening with Host'),
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSyncDiagnosticsCard(BeatSyncService beatSync) {
    final offset = beatSync.clockOffsetMs;
    final rtt = beatSync.averageRttMs;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildDiagItem(
            'Role',
            beatSync.isHost ? '👑 Host / DJ' : '🎧 Guest',
            const Color(0xFF8B5CF6),
          ),
          Container(width: 1, height: 32, color: Colors.white12),
          _buildDiagItem(
            'Clock Offset',
            beatSync.isHost ? '0.0 ms' : '${offset >= 0 ? '+' : ''}${offset.toStringAsFixed(1)} ms',
            offset.abs() < 10 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
          ),
          Container(width: 1, height: 32, color: Colors.white12),
          _buildDiagItem(
            'Network RTT',
            beatSync.isHost ? '< 1 ms' : '${rtt.toStringAsFixed(0)} ms',
            const Color(0xFF06B6D4),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildManualCalibrationNudge(BeatSyncService beatSync) {
    final nudge = beatSync.manualCalibrationNudgeMs;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(CupertinoIcons.slider_horizontal_3, size: 16, color: Color(0xFF06B6D4)),
                  SizedBox(width: 8),
                  Text('Audio Phase Calibration', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
              Text(
                '${nudge >= 0 ? '+' : ''}${nudge.toStringAsFixed(0)} ms',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF06B6D4)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Adjust if using Bluetooth headphones or external speaker latency.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Slider(
            value: nudge,
            min: -50.0,
            max: 50.0,
            divisions: 20,
            activeColor: const Color(0xFF06B6D4),
            onChanged: (val) => beatSync.setManualCalibrationNudge(val),
          ),
        ],
      ),
    );
  }

  Widget _buildPartyMembersList(BeatSyncService beatSync) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.person_2_fill, size: 18, color: Color(0xFF8B5CF6)),
              const SizedBox(width: 8),
              Text(
                'Party Speakers (${beatSync.connectedGuestNames.length + 1})',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Host entry
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF8B5CF6),
              child: Icon(CupertinoIcons.music_mic, size: 16, color: Colors.white),
            ),
            title: Text(
              beatSync.isHost ? 'You (DJ / Host)' : (beatSync.hostDevice?.name ?? 'Host'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('SYNCED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
            ),
          ),
          // Guests
          ...beatSync.connectedGuestNames.map(
            (guest) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white12,
                child: Text(guest.isNotEmpty ? guest[0].toUpperCase() : 'G', style: const TextStyle(fontSize: 12, color: Colors.white)),
              ),
              title: Text(guest, style: const TextStyle(fontSize: 14)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('SYNCED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHostBroadcastControls(PlayerProvider player, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1C28) : const Color(0xFFEBECEF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(CupertinoIcons.backward_fill, color: isDark ? Colors.white : Colors.black87),
            onPressed: () {
              player.skipPrevious();
              final currentSong = player.currentSong;
              if (currentSong != null) {
                final epoch = BeatSyncService().calculateScheduledPlayEpoch();
                MuslyConnectService().broadcastBeatSyncSchedulePlay(currentSong, epoch, 0);
              }
            },
          ),
          IconButton(
            icon: Icon(
              player.isPlaying ? CupertinoIcons.pause_circle_fill : CupertinoIcons.play_circle_fill,
              color: const Color(0xFF8B5CF6),
              size: 38,
            ),
            onPressed: () {
              if (player.isPlaying) {
                player.pause();
                MuslyConnectService().broadcastBeatSyncSchedulePause();
              } else {
                player.play();
                final currentSong = player.currentSong;
                if (currentSong != null) {
                  final epoch = BeatSyncService().calculateScheduledPlayEpoch();
                  MuslyConnectService().broadcastBeatSyncSchedulePlay(currentSong, epoch, player.position.inMilliseconds);
                }
              }
            },
          ),
          IconButton(
            icon: Icon(CupertinoIcons.forward_fill, color: isDark ? Colors.white : Colors.black87),
            onPressed: () {
              player.skipNext();
              final currentSong = player.currentSong;
              if (currentSong != null) {
                final epoch = BeatSyncService().calculateScheduledPlayEpoch();
                MuslyConnectService().broadcastBeatSyncSchedulePlay(currentSong, epoch, 0);
              }
            },
          ),
        ],
      ),
    );
  }
}
