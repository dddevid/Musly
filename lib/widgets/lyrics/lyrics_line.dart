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
  final int distance;

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
          duration: const Duration(milliseconds: 250),
          switchInCurve: const Cubic(0.23, 1, 0.32, 1),
          switchOutCurve: const Cubic(0.23, 1, 0.32, 1),
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
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    switch (state) {
      case LyricLineState.past:
        final translationWidget = _buildTranslation(
          textAlign,
          Colors.white.withValues(alpha: 0.25),
        );
        return SizedBox(
          key: const ValueKey('past'),
          width: double.infinity,
          child: Column(
            crossAxisAlignment:
                isCentered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                line.text,
                textAlign: textAlign,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
              if (translationWidget != null) translationWidget,
            ],
          ),
        );
      case LyricLineState.future:
        final translationWidget = _buildTranslation(
          textAlign,
          Colors.white.withValues(alpha: 0.22),
        );
        final textWidget = Column(
          crossAxisAlignment:
              isCentered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              line.text,
              textAlign: textAlign,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white.withValues(alpha: 0.30),
              ),
            ),
            if (translationWidget != null) translationWidget,
          ],
        );

        if (!blurUnfocused) {
          return SizedBox(
            key: const ValueKey('future_clear'),
            width: double.infinity,
            child: textWidget,
          );
        }

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
        final currentChild = line.hasWords
            ? _buildWordByWord(textAlign, glowEffect)
            : _buildLineLevel(textAlign, glowEffect);

        final translationWidget = _buildTranslation(
          textAlign,
          Colors.white.withValues(alpha: 0.75),
        );

        final fullCurrentChild = translationWidget != null
            ? Column(
                crossAxisAlignment: isCentered
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  currentChild,
                  translationWidget,
                ],
              )
            : currentChild;

        return SizedBox(
          key: const ValueKey('current'),
          width: double.infinity,
          child: reduceMotion
              ? fullCurrentChild
              : TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1.0, end: 1.05),
                  duration: const Duration(milliseconds: 220),
                  curve: const Cubic(0.23, 1, 0.32, 1),
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      alignment: alignment,
                      child: child,
                    );
                  },
                  child: fullCurrentChild,
                ),
        );
    }
  }

  Widget? _buildTranslation(TextAlign textAlign, Color color) {
    if (!line.hasTranslation) return null;
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Text(
        line.translation!,
        textAlign: textAlign,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
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
            final duration =
                word.endTime.inMilliseconds - word.startTime.inMilliseconds;
            final elapsed =
                currentTime.inMilliseconds - word.startTime.inMilliseconds;
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
