import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/lyric_line.dart';
import '../../services/player_ui_settings_service.dart';

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
    final uiSettings = PlayerUiSettingsService();
    final isCentered = uiSettings.getLyricsAlignment() == 'center';
    final blurUnfocused = uiSettings.getLyricsBlurUnfocused();
    final glowEffect = uiSettings.getLyricsGlowEffect();
    final textAlign = isCentered ? TextAlign.center : TextAlign.left;
    final alignment = isCentered ? Alignment.center : Alignment.centerLeft;

    switch (state) {
      case LyricLineState.past:
        return SizedBox(
          key: const ValueKey('past'),
          width: double.infinity,
          child: Text(
            line.text,
            textAlign: textAlign,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ),
        );
      case LyricLineState.future:
        final textWidget = Text(
          line.text,
          textAlign: textAlign,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white.withValues(alpha: 0.30),
          ),
        );

        if (!blurUnfocused) {
          return SizedBox(
            key: const ValueKey('future_clear'),
            width: double.infinity,
            child: textWidget,
          );
        }

        // Calculate blur based on distance if blur enabled
        final double sigma = (distance * 0.8).clamp(0.0, 3.0);
        return SizedBox(
          key: const ValueKey('future_blur'),
          width: double.infinity,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            child: textWidget,
          ),
        );
      case LyricLineState.current:
        return SizedBox(
          key: const ValueKey('current'),
          width: double.infinity,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 1.0, end: 1.05),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                alignment: alignment,
                child: child,
              );
            },
            child: line.hasWords 
                ? _buildWordByWord(textAlign, glowEffect) 
                : _buildLineLevel(textAlign, glowEffect),
          ),
        );
    }
  }

  Widget _buildLineLevel(TextAlign textAlign, bool glowEffect) {
    return Text(
      line.text,
      textAlign: textAlign,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        height: 1.4,
        shadows: glowEffect
            ? [
                Shadow(
                  color: Colors.white.withValues(alpha: 0.6),
                  blurRadius: 16.0,
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildWordByWord(TextAlign textAlign, bool glowEffect) {
    return RichText(
      textAlign: textAlign,
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

          return WidgetSpan(
            child: ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.white.withValues(alpha: 0.4),
                  ],
                  stops: [progress, progress],
                ).createShader(bounds);
              },
              child: Text(
                '${word.text} ',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.4,
                  shadows: glowEffect
                      ? [
                          Shadow(
                            color: Colors.white.withValues(alpha: 0.6),
                            blurRadius: 16.0,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
