import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:musly/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:musly/services/tv_detection_service.dart';
import 'package:musly/widgets/common/album_artwork.dart';

class MediaCard extends StatefulWidget {
  final String? coverArt;
  final Widget? artwork;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final VoidCallback? onPlayPressed;
  final double size;
  final bool isRound;

  const MediaCard({
    super.key,
    this.coverArt,
    this.artwork,
    required this.title,
    this.subtitle,
    this.onTap,
    this.onPlayPressed,
    this.size = 180,
    this.isRound = false,
  });

  @override
  State<MediaCard> createState() => _MediaCardState();
}

class _MediaCardState extends State<MediaCard> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    bool isTv = false;
    try {
      isTv = Provider.of<TvDetectionService>(context).isTvMode;
    } catch (_) {}

    return RepaintBoundary(
      child: FocusableActionDetector(
        onShowFocusHighlight: (focused) {
          setState(() => _isFocused = focused);
          if (focused && isTv) {
            Scrollable.ensureVisible(context, alignment: 0.5, duration: const Duration(milliseconds: 300));
          }
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              if (widget.onTap != null) {
                widget.onTap!();
              } else if (widget.onPlayPressed != null) {
                widget.onPlayPressed!();
              }
              return null;
            },
          ),
        },
        child: MouseRegion(
          onEnter: (event) {
            if (event.kind == PointerDeviceKind.mouse) {
              setState(() => _isHovered = true);
            }
          },
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: const Cubic(0.23, 1, 0.32, 1),
              width: widget.size,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                borderRadius: BorderRadius.circular(8),
                border: isTv && _isFocused
                    ? Border.all(color: Colors.white, width: 3.0)
                    : Border.all(color: Colors.transparent, width: 3.0),
              ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedScale(
                  scale: (_isHovered || _isFocused) ? 1.04 : 1.0,
                  duration: const Duration(milliseconds: 180),
                  curve: const Cubic(0.23, 1, 0.32, 1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: const Cubic(0.23, 1, 0.32, 1),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(widget.isRound ? 999 : 4),
                        boxShadow: (_isHovered || _isFocused)
                          ? [
                              BoxShadow(
                                color: isTv 
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : Colors.black.withValues(alpha: 0.3),
                                blurRadius: isTv ? 24 : 16,
                                offset: Offset(0, isTv ? 0 : 8),
                              ),
                            ]
                          : [],
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(widget.isRound ? 999 : 4),
                          child: widget.artwork ??
                              AlbumArtwork(
                                coverArt: widget.coverArt,
                                size: widget.size - 24,
                                borderRadius: widget.isRound ? 999 : 4,
                              ),
                        ),
                        if (widget.onPlayPressed != null)
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: IgnorePointer(
                              ignoring: !_isHovered,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 180),
                                curve: const Cubic(0.23, 1, 0.32, 1),
                                opacity: _isHovered ? 1.0 : 0.0,
                                child: AnimatedScale(
                                  duration: const Duration(milliseconds: 180),
                                  curve: const Cubic(0.23, 1, 0.32, 1),
                                  scale: _isHovered ? 1.0 : 0.95,
                                  child: _PlayButton(
                                    onPressed: widget.onPlayPressed!,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppTheme.darkSecondaryText
                          : AppTheme.lightSecondaryText,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _PlayButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.brandGreen,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: const Icon(
            Icons.play_arrow_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
