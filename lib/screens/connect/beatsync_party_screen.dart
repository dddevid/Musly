/*
// ── Musly Listening Party (BeatSync) Screen ───────────────────────────────────
// Handcrafted multi-speaker listening experience inspired by Apple SharePlay & Spotify Group Session.
// Temporarily disabled / commented out.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/player_provider.dart';
import '../../services/beatsync_service.dart';
import '../../services/musly_connect_service.dart';
import '../../widgets/common/album_artwork.dart';

class BeatSyncPartyScreen extends StatefulWidget {
  const BeatSyncPartyScreen({super.key});

  @override
  State<BeatSyncPartyScreen> createState() => _BeatSyncPartyScreenState();
}

class _BeatSyncPartyScreenState extends State<BeatSyncPartyScreen> {
  Timer? _ntpTimer;
  bool _showCalibration = false;

  @override
  void initState() {
    super.initState();
    final beatSync = BeatSyncService();
    if (beatSync.isGuest) {
      _ntpTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        MuslyConnectService().sendNtpProbeToHost();
      });
      MuslyConnectService().sendNtpProbeToHost();
    }
  }

  @override
  void dispose() {
    _ntpTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F1015) : const Color(0xFFF7F8FA);

    return Consumer2<BeatSyncService, PlayerProvider>(
      builder: (context, beatSync, playerProvider, _) {
        final currentSong = playerProvider.currentSong;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(CupertinoIcons.back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  beatSync.partyRoomName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      beatSync.isHost ? 'Host DJ • In Sync' : 'Synced with Host',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
            centerTitle: true,
            actions: [
              TextButton(
                onPressed: () {
                  if (beatSync.isHost) {
                    MuslyConnectService().endPartySession();
                  } else {
                    MuslyConnectService().leavePartySession();
                  }
                  Navigator.of(context).pop();
                },
                child: Text(
                  beatSync.isHost ? 'End' : 'Leave',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // ── Hero Album Artwork ──────────────────────────────────────
                  Center(
                    child: Container(
                      width: 210,
                      height: 210,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: currentSong != null
                            ? AlbumArtwork(
                                coverArt: currentSong.coverArt,
                                size: 210,
                                borderRadius: 16,
                              )
                            : Container(
                                color: isDark ? const Color(0xFF1F202B) : const Color(0xFFE4E5EB),
                                child: const Icon(Icons.music_note_rounded, size: 64, color: Colors.grey),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // ── Track Title & Artist ────────────────────────────────────
                  Text(
                    currentSong?.title ?? 'No Track Playing',
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentSong?.artist ?? (beatSync.isHost ? 'You are controlling playback' : 'Listening together'),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 20),

                  // ── Host Playback Controls ──────────────────────────────────
                  if (beatSync.isHost) ...[
                    _buildHostPlaybackControls(playerProvider, isDark),
                    const SizedBox(height: 24),
                  ],

                  // ── Connected Speakers & Devices ────────────────────────────
                  _buildSpeakersList(beatSync, isDark),
                  const SizedBox(height: 16),

                  // ── Subtle Delay Calibration Toggle (for Bluetooth) ─────────
                  if (beatSync.isGuest) ...[
                    _buildCalibrationSection(beatSync, isDark),
                    const SizedBox(height: 16),
                  ],

                  // ── Bottom Leave Button ─────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () {
                        if (beatSync.isHost) {
                          MuslyConnectService().endPartySession();
                        } else {
                          MuslyConnectService().leavePartySession();
                        }
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(CupertinoIcons.square_arrow_right, size: 15, color: Colors.redAccent),
                      label: Text(
                        beatSync.isHost ? 'End Session for Everyone' : 'Leave Listening Session',
                        style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.redAccent.withValues(alpha: 0.08),
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

  Widget _buildHostPlaybackControls(PlayerProvider player, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF191A23) : const Color(0xFFF1F2F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.skip_previous_rounded, size: 28),
            onPressed: () {
              player.skipPrevious();
              final currentSong = player.currentSong;
              if (currentSong != null) {
                final epoch = BeatSyncService().calculateScheduledPlayEpoch();
                MuslyConnectService().broadcastBeatSyncSchedulePlay(currentSong, epoch, 0);
              }
            },
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? Colors.white : Colors.black87,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: isDark ? Colors.black87 : Colors.white,
                size: 28,
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
                    MuslyConnectService().broadcastBeatSyncSchedulePlay(
                      currentSong,
                      epoch,
                      player.position.inMilliseconds,
                    );
                  }
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.skip_next_rounded, size: 28),
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

  Widget _buildSpeakersList(BeatSyncService beatSync, bool isDark) {
    final cardBg = isDark ? const Color(0xFF191A23) : const Color(0xFFF1F2F6);
    final totalCount = beatSync.connectedGuestNames.length + 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SPEAKERS IN SESSION ($totalCount)',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey,
                  letterSpacing: 0.6,
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.sync_rounded, size: 13, color: Color(0xFF10B981)),
                  SizedBox(width: 4),
                  Text(
                    'Synced',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Host Device
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFF8B5CF6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.speaker_group_rounded, color: Colors.white, size: 16),
            ),
            title: Text(
              beatSync.isHost ? 'This Device (DJ Host)' : (beatSync.hostDevice?.name ?? 'Host'),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
            ),
            subtitle: Text(
              beatSync.isHost ? 'Broadcast source' : 'Main playback host',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),

          // Guest Speakers
          ...beatSync.connectedGuestNames.map(
            (guest) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white12 : Colors.black12,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    guest.isNotEmpty ? guest[0].toUpperCase() : 'G',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              title: Text(guest, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
              subtitle: const Text('Playing in sync', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalibrationSection(BeatSyncService beatSync, bool isDark) {
    final nudge = beatSync.manualCalibrationNudgeMs;
    final cardBg = isDark ? const Color(0xFF191A23) : const Color(0xFFF1F2F6);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _showCalibration,
          onExpansionChanged: (val) => setState(() => _showCalibration = val),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          leading: const Icon(Icons.tune_rounded, size: 18, color: Colors.grey),
          title: const Text(
            'Bluetooth Speaker Delay',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          trailing: Text(
            '${nudge >= 0 ? '+' : ''}${nudge.toStringAsFixed(0)} ms',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fine-tune if your Bluetooth headphones or soundbar lag slightly behind.',
                    style: TextStyle(fontSize: 11.5, color: Colors.grey),
                  ),
                  Slider(
                    value: nudge,
                    min: -50.0,
                    max: 50.0,
                    divisions: 20,
                    activeColor: const Color(0xFF8B5CF6),
                    onChanged: (val) => beatSync.setManualCalibrationNudge(val),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
*/
