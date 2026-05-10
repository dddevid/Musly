import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/now_playing_theme.dart';
import '../services/now_playing_theme_service.dart';

/// Mixin to provide theme-aware values for Now Playing screen elements
mixin ThemedNowPlaying on Widget {
  NowPlayingTheme getEffectiveTheme(BuildContext context) {
    final service = context.watch<NowPlayingThemeService>();
    return service.getEffectiveTheme();
  }

  bool hasCustomTheme(BuildContext context) {
    final service = context.watch<NowPlayingThemeService>();
    return service.hasActiveTheme;
  }
}

/// Extension methods to easily apply theme styling
extension ThemedColors on NowPlayingTheme {
  Color getTitleColor() => text.title.getColor();
  Color getArtistColor() => text.artist.getColor();
  Color getAlbumColor() => text.album.getColor();
  Color getDurationColor() => text.duration.getColor();

  TextStyle getTitleTextStyle() => TextStyle(
        color: getTitleColor(),
        fontSize: text.title.fontSize,
        fontWeight: text.title.getFontWeight(),
        fontFamily: text.title.fontFamily,
      );

  TextStyle getArtistTextStyle() => TextStyle(
        color: getArtistColor(),
        fontSize: text.artist.fontSize,
        fontWeight: text.artist.getFontWeight(),
        fontFamily: text.artist.fontFamily,
      );

  TextStyle getAlbumTextStyle() => TextStyle(
        color: getAlbumColor(),
        fontSize: text.album.fontSize,
        fontWeight: text.album.getFontWeight(),
        fontFamily: text.album.fontFamily,
      );

  TextStyle getDurationTextStyle() => TextStyle(
        color: getDurationColor(),
        fontSize: text.duration.fontSize,
        fontWeight: text.duration.getFontWeight(),
        fontFamily: text.duration.fontFamily,
      );

  BorderRadius getArtworkBorderRadius() {
    if (artwork.shape == 'circle') {
      return BorderRadius.circular(9999);
    } else if (artwork.shape == 'rounded_rect') {
      return BorderRadius.circular(artwork.cornerRadius);
    } else if (artwork.shape == 'square' && artwork.cornerRadius > 0) {
      return BorderRadius.circular(artwork.cornerRadius);
    }
    return BorderRadius.zero;
  }

  BoxShape getArtworkBoxShape() {
    return artwork.shape == 'circle' ? BoxShape.circle : BoxShape.rectangle;
  }

  List<BoxShadow>? getArtworkShadow() {
    if (!artwork.shadow) return null;
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 20,
        offset: const Offset(0, 10),
        spreadRadius: 5,
      ),
    ];
  }

  BorderRadius getProgressBarBorderRadius() {
    if (progressBar.shape == 'rounded') {
      return BorderRadius.circular(progressBar.height / 2);
    }
    return BorderRadius.zero;
  }

  Gradient? getBackgroundGradient() {
    if (background.type == 'solid') {
      final color = background.getColor(0).withOpacity(background.opacity);
      return LinearGradient(
        colors: [color, color],
      );
    } else if (background.type == 'gradient') {
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          background.getColor(0).withOpacity(background.opacity),
          background.getColor(1).withOpacity(background.opacity),
        ],
      );
    }
    return null;
  }
}

/// Helper to determine if we should use themed values or defaults
class ThemeAwareBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, NowPlayingTheme theme, bool isCustom) builder;

  const ThemeAwareBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NowPlayingThemeService>(
      builder: (context, service, _) {
        final theme = service.getEffectiveTheme();
        final isCustom = service.hasActiveTheme;
        return builder(context, theme, isCustom);
      },
    );
  }
}
