import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import '../theme/app_theme.dart';

class GradientHeader extends StatefulWidget {
  final String? imageUrl;
  final String title;
  final String? subtitle;
  final Widget? actions;
  final double minHeight;
  final double maxHeight;

  const GradientHeader({
    super.key,
    this.imageUrl,
    required this.title,
    this.subtitle,
    this.actions,
    this.minHeight = 80,
    this.maxHeight = 320,
  });

  @override
  State<GradientHeader> createState() => _GradientHeaderState();
}

class _GradientHeaderState extends State<GradientHeader> {
  Color _dominantColor = AppTheme.appleMusicRed;

  @override
  void initState() {
    super.initState();
    _extractColor();
  }

  Future<void> _extractColor() async {
    if (widget.imageUrl == null) return;

    try {
      final imageProvider = NetworkImage(widget.imageUrl!);
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: 20,
      );

      if (mounted) {
        setState(() {
          _dominantColor = paletteGenerator.dominantColor?.color ??
              paletteGenerator.vibrantColor?.color ??
              AppTheme.appleMusicRed;
        });
      }
    } catch (e) {
      debugPrint('Error extracting color: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverAppBar(
      expandedHeight: widget.maxHeight,
      collapsedHeight: widget.minHeight,
      pinned: true,
      backgroundColor: isDark ? AppTheme.darkBackground : Colors.white,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final expandRatio = (constraints.maxHeight - widget.minHeight) /
              (widget.maxHeight - widget.minHeight);
          final opacity = expandRatio.clamp(0.0, 1.0);

          return FlexibleSpaceBar(
            titlePadding: EdgeInsets.only(
              left: 32,
              bottom: expandRatio > 0.5 ? 40 : 16,
            ),
            title: opacity > 0.3
                ? null
                : Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _dominantColor.withOpacity(0.8),
                        _dominantColor.withOpacity(0.3),
                        isDark ? AppTheme.darkBackground : Colors.white,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
                if (opacity > 0.2)
                  Positioned(
                    left: 32,
                    bottom: 40,
                    right: 32,
                    child: Opacity(
                      opacity: opacity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.subtitle != null) ...[
                            Text(
                              widget.subtitle!,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -1.0,
                              shadows: [
                                Shadow(
                                  color: Colors.black45,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.actions != null) ...[
                            const SizedBox(height: 16),
                            widget.actions!,
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
