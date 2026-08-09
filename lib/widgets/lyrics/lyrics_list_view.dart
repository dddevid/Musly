import 'dart:async';
import '../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/lyric_line.dart';
import 'lyrics_line.dart';
import 'interlude_dots_widget.dart';

enum ItemType { lyric, interlude }

class LyricsItem {
  final ItemType type;
  final LyricLine? line;
  final Duration startTime;
  final Duration endTime;
  final int? lyricIndex;

  LyricsItem({
    required this.type,
    this.line,
    required this.startTime,
    required this.endTime,
    this.lyricIndex,
  });
}

class LyricsListView extends StatefulWidget {
  final List<LyricLine> lyrics;
  final Duration currentTime;
  final Function(Duration) onSeek;

  const LyricsListView({
    super.key,
    required this.lyrics,
    required this.currentTime,
    required this.onSeek,
  });

  @override
  State<LyricsListView> createState() => _LyricsListViewState();
}

class _LyricsListViewState extends State<LyricsListView> {
  late ScrollController _scrollController;
  late List<GlobalKey> _keys;
  late List<LyricsItem> _items;
  int _currentIndex = -1;
  int _currentLyricIndex = -1;
  bool _isManualScrolling = false;
  Timer? _resumeAutoScrollTimer;

  // The approximate height of a lyric line to help with scrolling calculations
  static const double _estimatedLineHeight = 60.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _buildItems();
    _updateCurrentIndex();
  }

  @override
  void didUpdateWidget(LyricsListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.lyrics != widget.lyrics) {
      _buildItems();
    }
    
    // Only process update if we are playing and not manually scrolling
    if (oldWidget.currentTime != widget.currentTime) {
      _updateCurrentIndex();
    }
  }

  void _buildItems() {
    _items = [];
    if (widget.lyrics.isEmpty) {
      _keys = [];
      return;
    }

    // Start interlude
    if (widget.lyrics[0].startTime > const Duration(seconds: 10)) {
      _items.add(LyricsItem(
        type: ItemType.interlude,
        startTime: Duration.zero,
        endTime: widget.lyrics[0].startTime,
      ));
    }

    for (int i = 0; i < widget.lyrics.length; i++) {
      final line = widget.lyrics[i];
      final nextTime = i < widget.lyrics.length - 1 
          ? widget.lyrics[i+1].startTime 
          : const Duration(hours: 24);
      
      final lyricEndTime = line.endTime ?? 
          (nextTime - line.startTime > const Duration(seconds: 5) 
              ? line.startTime + const Duration(seconds: 5) 
              : nextTime);

      _items.add(LyricsItem(
        type: ItemType.lyric,
        line: line,
        startTime: line.startTime,
        endTime: lyricEndTime,
        lyricIndex: i,
      ));

      if (i < widget.lyrics.length - 1) {
        final gap = nextTime - lyricEndTime;
        if (gap > const Duration(seconds: 10)) {
          _items.add(LyricsItem(
            type: ItemType.interlude,
            startTime: lyricEndTime,
            endTime: nextTime,
          ));
        }
      }
    }
    _keys = List.generate(_items.length, (_) => GlobalKey());
  }

  void _updateCurrentIndex() {
    if (_items.isEmpty) return;

    int newIndex = -1;
    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (widget.currentTime >= item.startTime && widget.currentTime < item.endTime) {
        newIndex = i;
        break;
      }
    }

    // Check if it's unsynced (all start times are zero and we have multiple lines)
    final isUnsynced = _items.length > 1 && 
        _items.every((item) => item.startTime == Duration.zero);

    if (isUnsynced) {
      newIndex = -1; // No highlight
    } else if (newIndex == -1 && widget.currentTime >= _items.last.startTime) {
      newIndex = _items.length - 1;
    }
    
    // Before first item
    if (newIndex == -1 && !isUnsynced) {
      newIndex = 0;
    }

    if (newIndex != _currentIndex) {
      setState(() {
        _currentIndex = newIndex;
        if (newIndex >= 0) {
          _currentLyricIndex = _items[newIndex].lyricIndex ?? -1;
        } else {
          _currentLyricIndex = -1;
        }
      });
      _scrollToCurrentLine();
    }
  }

  void _scrollToCurrentLine() {
    if (_isManualScrolling || !_scrollController.hasClients || _currentIndex < 0 || _currentIndex >= _keys.length) return;

    final key = _keys[_currentIndex];
    if (key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        alignment: 0.5,
      );
    }
  }

  void _onUserScroll() {
    setState(() {
      _isManualScrolling = true;
    });

    _resumeAutoScrollTimer?.cancel();
    _resumeAutoScrollTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _isManualScrolling = false;
        });
        _scrollToCurrentLine();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _resumeAutoScrollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lyrics.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.noLyricsAvailable,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        if (scrollNotification is UserScrollNotification) {
          _onUserScroll();
        }
        return false;
      },
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(
          vertical: MediaQuery.of(context).size.height / 2, // Allow first/last item to center
        ),
        child: Column(
          children: List.generate(_items.length, (index) {
            final item = _items[index];
            
            if (item.type == ItemType.interlude) {
              return Container(
                key: _keys[index],
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: InterludeDotsWidget(
                  currentTime: widget.currentTime,
                  targetTime: item.endTime,
                ),
              );
            }

            final line = item.line!;
            final lyricIndex = item.lyricIndex!;
            
            LyricLineState state = LyricLineState.future;
            if (_currentLyricIndex != -1) {
              if (lyricIndex < _currentLyricIndex) {
                state = LyricLineState.past;
              } else if (lyricIndex == _currentLyricIndex) {
                state = LyricLineState.current;
              }
            } else {
              // During an interlude, we want all lyrics to look past or future
              // We can determine this by comparing startTime with currentTime
              if (item.endTime <= widget.currentTime) {
                state = LyricLineState.past;
              }
            }

            final distance = _currentLyricIndex != -1 
                ? (lyricIndex - _currentLyricIndex).abs() 
                : 3; // large distance when interlude is active

            return Container(
              key: _keys[index],
              child: LyricsLineWidget(
                line: line,
                state: state,
                currentTime: widget.currentTime,
                distance: distance,
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onSeek(line.startTime);
                  
                  setState(() => _isManualScrolling = false);
                  _resumeAutoScrollTimer?.cancel();
                },
              ),
            );
          }),
        ),
      ),
    );
  }
}
