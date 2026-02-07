import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dart_discord_rpc/dart_discord_rpc.dart';
import 'storage_service.dart';

class DiscordRpcService {
  static const String _applicationId = '1465763539246645252';
  DiscordRPC? _rpc;
  final StorageService _storageService;

  bool _initialized = false;
  bool _enabled = true;

  DiscordRpcService(this._storageService);

  Future<void> initialize() async {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      _enabled = await _storageService.getDiscordRpcEnabled();
      if (_enabled) {
        // Initialize the library properly before creating instance
        DiscordRPC.initialize();
        _rpc = DiscordRPC(applicationId: _applicationId);
        _startRpc();
      }
    }
  }

  void _startRpc() {
    if (_initialized || _rpc == null) return;
    try {
      _rpc!.start(autoRegister: true);
      _initialized = true;
      debugPrint('Discord RPC started');
    } catch (e) {
      debugPrint('Failed to start Discord RPC: $e');
    }
  }

  void shutdown() {
    if (_initialized) {
      _rpc?.clearPresence();
      // shutDown() is not exposed in all versions, usually clearing presence is enough or loop stops on app exit
      // But typically we just let it be or clear presence.
      // dart_discord_rpc doesn't have a stop() method that fully kills the process connection without disposing,
      // but we can just clear presence.
      _initialized = false;
    }
  }

  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    await _storageService.saveDiscordRpcEnabled(enabled);

    if (enabled) {
      // Create instance if it doesn't exist yet
      if (_rpc == null) {
        DiscordRPC.initialize();
        _rpc = DiscordRPC(applicationId: _applicationId);
      }
      _startRpc();
    } else {
      _rpc?.clearPresence();
      // We don't fully shut down the IPC connection usually, just clear presence so it stops showing.
    }
  }

  bool get enabled => _enabled;

  void updatePresence({
    required String state,
    required String details,
    String? largeImageKey,
    String? largeImageText,
    String? smallImageKey,
    String? smallImageText,
    int? startTime,
    int? endTime,
    String? button1Label,
    String? button1Url,
  }) {
    if (!_enabled) {
      debugPrint('Discord RPC is disabled, ignoring update.');
      return;
    }
    if (!_initialized || _rpc == null) {
      debugPrint('Discord RPC not initialized, try re-initializing.');
      _startRpc(); // Try to start if not ready
      if (_rpc == null) return;
    }

    debugPrint('Updating Discord Presence: $details - $state');

    try {
      _rpc!.updatePresence(
        DiscordPresence(
          state: state,
          details: details,
          startTimeStamp: startTime,
          endTimeStamp: endTime,
          largeImageKey:
              largeImageKey, // Pass null if not provided, don't force 'active' which might not exist
          largeImageText: largeImageText,
          smallImageKey: smallImageKey,
          smallImageText: smallImageText,
          //   button1Label: button1Label,
          //   button1Url: button1Url,
        ),
      );
      debugPrint('Discord Presence updated successfully request sent.');
    } catch (e) {
      debugPrint('Error updating Discord presence: $e');
    }
  }

  void clearPresence() {
    debugPrint('Clearing Discord Presence');
    if (_initialized) {
      try {
        _rpc?.clearPresence();
      } catch (e) {
        debugPrint('Error clearing presence: $e');
      }
    }
  }
}
