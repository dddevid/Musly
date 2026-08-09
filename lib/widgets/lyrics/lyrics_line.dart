import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/lyric_line.dart';

enum LyricLineState { past, current, future }

class LyricsLineWidget extends StatelessWidget {
  final LyricLine line;
  final LyricLineState state;
  final Duration currentTime;
  final VoidCallback onTap;
  final int distance; // Distance from current line (0 for current, 1 for next/prev, etc.)

  const LyricsLineWidget({
    super.key,
    required this.line,
    required this.state,
    required this.currentTime,
    required this.onTap,
    this.distance = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (state) {
      case LyricLineState.past:
        return Container(
          key: const ValueKey('past'),
          width: double.infinity,
          child: Text(
            line.text,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ).copyWith(color: Colors.white.withOpacity(0.32)),
          ),
        );
      case LyricLineState.future:
        // Calculate blur based on distance
        final double sigma = (distance * 0.8).clamp(0.0, 3.0);
        return Container(
          key: const ValueKey('future'),
          width: double.infinity,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            child: Text(
              line.text,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ).copyWith(color: Colors.white.withOpacity(0.22)),
            ),
          ),
        );
      case LyricLineState.current:
        return Container(
          key: const ValueKey('current'),
          width: double.infinity,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 1.0, end: 1.06),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                alignment: Alignment.centerLeft,
                child: child,
              );
            },
            child: line.hasWords 
                ? _buildWordByWord() 
                : _buildLineLevel(),
          ),
        );
    }
  }

  Widget _buildLineLevel() {
    return Text(
      line.text,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800, // Slightly bolder for current
        color: Colors.white,
        height: 1.4,
      ),
    );
  }

  Widget _buildWordByWord() {
    // Advanced word-by-word reveal (karaoke style)
    return RichText(
      text: TextSpan(
        children: line.words!.map((word) {
          double progress = 0.0;
          if (currentTime >= word.startTime && currentTime <= word.endTime) {
             final duration = word.endTime.inMilliseconds - word.startTime.inMilliseconds;
             final elapsed = currentTime.inMilliseconds - word.startTime.inMilliseconds;
             progress = (elapsed / duration).clamp(0.0, 1.0);
          } else if (currentTime > word.endTime) {
            progress = 1.0;
          }

          // Use a ShaderMask to "fill" the word from left to right
          return WidgetSpan(
            child: ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.white.withOpacity(0.4),
                  ],
                  stops: [progress, progress],
                ).createShader(bounds);
              },
              child: Text(
                '${word.text} ',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
