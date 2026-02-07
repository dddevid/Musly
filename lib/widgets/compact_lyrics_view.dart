import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lyric/flutter_lyric.dart';
import '../models/lyrics.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../services/subsonic_service.dart';

/// Compact lyrics widget for landscape mode - shows only lyrics without background
class CompactLyricsView extends StatefulWidget {
  final Song song;
  final VoidCallback? onClose;

  const CompactLyricsView({super.key, required this.song, this.onClose});

  @override
  State<CompactLyricsView> createState() => _CompactLyricsViewState();
}

class _CompactLyricsViewState extends State<CompactLyricsView> {
  LyricController? _lyricController;
  StreamSubscription? _positionSubscription;

  bool _isLoading = true;
  String? _error;
  SyncedLyrics? _lyrics;
  bool _showReturnButton = false;
  bool _canShowReturnButton = false;

  // Throttle position updates for performance
  Duration _lastUpdatePosition = Duration.zero;

  // Track song internally to handle updates independent of parent
  late Song _song;

  @override
  void initState() {
    super.initState();
    _song = widget.song;
    _loadLyrics();
    _setupPositionListener();

    // Listen to Song changes from provider directly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PlayerProvider>(
        context,
        listen: false,
      ).addListener(_onPlayerStateChanged);
    });
  }

  @override
  void dispose() {
    // Try/catch in case provider is already disposed
    try {
      Provider.of<PlayerProvider>(
        context,
        listen: false,
      ).removeListener(_onPlayerStateChanged);
    } catch (_) {}

    _positionSubscription?.cancel();
    _lyricController?.dispose();
    super.dispose();
  }

  void _onPlayerStateChanged() {
    if (!mounted) return;
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final currentSong = playerProvider.currentSong;

    if (currentSong != null && currentSong.id != _song.id) {
      setState(() {
        _song = currentSong;
      });
      _loadLyrics();
    }
  }

  @override
  void didUpdateWidget(CompactLyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.id != widget.song.id) {
      // If parent *does* update correctly, sync our internal state
      if (widget.song.id != _song.id) {
        setState(() {
          _song = widget.song;
        });
        _loadLyrics();
      }
    }
  }

  void _initializeLyricController() {
    _lyricController?.dispose();
    _lyricController = LyricController();

    _lyricController!.setOnTapLineCallback((Duration position) {
      final playerProvider = Provider.of<PlayerProvider>(
        context,
        listen: false,
      );
      playerProvider.seek(position);
    });

    // Ignore initial stopSelection events that might fire during layout/build
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _canShowReturnButton = true;
    });

    _lyricController!.registerEvent(LyricEvent.stopSelection, (_) {
      if (mounted && _canShowReturnButton) {
        setState(() => _showReturnButton = true);
      }
    });

    _lyricController!.registerEvent(LyricEvent.resumeActiveLine, (_) {
      if (mounted) setState(() => _showReturnButton = false);
    });
  }

  void _setupPositionListener() {
    _positionSubscription?.cancel();
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);

    _positionSubscription = playerProvider.positionStream.listen((position) {
      if (_lyricController != null && mounted) {
        // Throttle updates to every 100ms for performance
        final diff = (position - _lastUpdatePosition).abs();
        final wentBackwards = position < _lastUpdatePosition;

        if (diff.inMilliseconds >= 100 || wentBackwards) {
          _lastUpdatePosition = position;
          _lyricController!.setProgress(position);
        }
      }
    });
  }

  Future<void> _loadLyrics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final subsonicService = Provider.of<SubsonicService>(
        context,
        listen: false,
      );

      // Try structured getLyricsBySongId first
      final syncedData = await subsonicService.getLyricsBySongId(_song.id);

      if (!mounted) return;

      if (syncedData != null) {
        final structuredLyrics = syncedData['structuredLyrics'];
        if (structuredLyrics is List && structuredLyrics.isNotEmpty) {
          final lyrics = structuredLyrics.first;
          final lines = lyrics['line'] as List?;
          if (lines != null && lines.isNotEmpty) {
            final parsedLines = lines
                .map<LyricLine>((line) {
                  final start = line['start'] as int? ?? 0;
                  return LyricLine(
                    timestamp: Duration(milliseconds: start),
                    text: line['value']?.toString() ?? '',
                  );
                })
                .where((line) => line.text.isNotEmpty)
                .toList();

            if (parsedLines.isNotEmpty) {
              setState(() {
                _lyrics = SyncedLyrics(lines: parsedLines);
                _isLoading = false;
              });
              _initializeLyricController();
              _lyricController!.loadLyric(_convertToLrc(_lyrics!));
              return;
            }
          }
        }
      }

      // Fallback to plain lyrics
      final plainData = await subsonicService.getLyrics(
        artist: _song.artist,
        title: _song.title,
      );

      if (plainData != null) {
        final value = plainData['value']?.toString();
        if (value != null && value.isNotEmpty) {
          if (value.contains('[') && value.contains(':')) {
            setState(() {
              _lyrics = SyncedLyrics.fromLrc(value);
              _isLoading = false;
            });
            _initializeLyricController();
            _lyricController!.loadLyric(value);
          } else {
            setState(() {
              _lyrics = SyncedLyrics.fromPlainText(value);
              _isLoading = false;
            });
            _initializeLyricController();
            _lyricController!.loadLyric(_convertToLrc(_lyrics!));
          }
          return;
        }
      }

      setState(() {
        _error = 'No lyrics available';
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load lyrics';
          _isLoading = false;
        });
      }
    }
  }

  String _convertToLrc(SyncedLyrics lyrics) {
    final buffer = StringBuffer();
    for (final line in lyrics.lines) {
      final minutes = line.timestamp.inMinutes;
      final seconds = line.timestamp.inSeconds % 60;
      final milliseconds = line.timestamp.inMilliseconds % 1000;
      final centiseconds = (milliseconds / 10).floor();
      buffer.writeln(
        '[${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${centiseconds.toString().padLeft(2, '0')}]${line.text}',
      );
    }
    return buffer.toString();
  }

  void _returnToSyncedPosition() {
    setState(() => _showReturnButton = false);
  }

  LyricStyle _buildCompactStyle() {
    return LyricStyle(
      textStyle: TextStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.w600,
        color: Colors.white.withOpacity(0.5),
        height: 1.3,
      ),
      activeStyle: const TextStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        height: 1.3,
      ),
      translationStyle: TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.w500,
        color: Colors.white.withOpacity(0.4),
        height: 1.3,
      ),
      lineGap: 16.0,
      translationLineGap: 6.0,
      lineTextAlign: TextAlign.center,
      contentAlignment: CrossAxisAlignment.center,
      fadeRange: FadeRange(top: 40.0, bottom: 40.0),
      scrollDuration: const Duration(milliseconds: 300),
      scrollCurve: Curves.easeOutCubic,
      activeHighlightColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      selectionAnchorPosition: 0.4,
      selectionAlignment: MainAxisAlignment.center,
      selectedColor: Colors.white.withOpacity(0.8),
      selectedTranslationColor: Colors.white.withOpacity(0.5),
      selectionAutoResumeDuration: const Duration(milliseconds: 500),
      activeAutoResumeDuration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white70),
      );
    }

    if (_error != null || _lyrics == null || _lyrics!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_off_rounded, size: 48, color: Colors.white38),
            const SizedBox(height: 16),
            Text(
              _error ?? 'No lyrics',
              style: const TextStyle(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_lyricController == null) {
      return const Center(
        child: Text('No lyrics', style: TextStyle(color: Colors.white54)),
      );
    }

    return Stack(
      children: [
        // Lyrics content
        LyricView(
          controller: _lyricController!,
          style: _buildCompactStyle(),
          width: double.infinity,
          height: double.infinity,
        ),

        // Return button when scrolled away
        if (_showReturnButton)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _returnToSyncedPosition,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Back to current',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
