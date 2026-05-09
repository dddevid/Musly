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
      try {
        _enabled = await _storageService.getDiscordRpcEnabled();
        if (_enabled) {
          DiscordRPC.initialize();
          _rpc = DiscordRPC(applicationId: _applicationId);
          _startRpc();
        }
      } catch (e) {
        debugPrint('Discord RPC initialization failed: $e');
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
      try {
        _rpc?.clearPresence();
      } catch (_) {}
      _initialized = false;
    }
  }

  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    try {
      await _storageService.saveDiscordRpcEnabled(enabled);
    } catch (_) {}

    if (enabled) {
      try {
        if (_rpc == null) {
          DiscordRPC.initialize();
          _rpc = DiscordRPC(applicationId: _applicationId);
        }
        _startRpc();
      } catch (e) {
        debugPrint('Discord RPC setEnabled failed: $e');
      }
    } else {
      try {
        _rpc?.clearPresence();
      } catch (_) {}
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
    if (kIsWeb ||
        !(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      return;
    }
    if (!_enabled) return;
    if (!_initialized || _rpc == null) {
      _startRpc();
      if (_rpc == null) return;
    }

    try {
      _rpc!.updatePresence(
        DiscordPresence(
          state: state,
          details: details,
          startTimeStamp: startTime,
          endTimeStamp: endTime,
          largeImageKey: largeImageKey,
          largeImageText: largeImageText,
          smallImageKey: smallImageKey,
          smallImageText: smallImageText,
        ),
      );
      debugPrint('Discord Presence updated successfully request sent.');
    } catch (e) {
      debugPrint('Error updating Discord presence: $e');
    }
  }

  void clearPresence() {
    if (kIsWeb ||
        !(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      return;
    }
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
