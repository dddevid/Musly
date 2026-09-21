import 'package:flutter/material.dart';
import 'package:musly/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:musly/services/tv_detection_service.dart';
import 'package:musly/widgets/common/album_artwork.dart';

class MediaCard extends StatefulWidget {
  final String? coverArt;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final VoidCallback? onPlayPressed;
  final double size;
  final bool isRound;

  const MediaCard({
    super.key,
    this.coverArt,
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
    final isTv = Provider.of<TvDetectionService>(context).isTvMode;

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
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
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
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
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
                          child: AlbumArtwork(
                            coverArt: widget.coverArt,
                            size: widget.size - 24,
                            borderRadius: widget.isRound ? 999 : 4,
                          ),
                        ),
                        if (_isHovered && widget.onPlayPressed != null)
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: _PlayButton(
                              onPressed: widget.onPlayPressed!,
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

class _PlayButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _PlayButton({required this.onPressed});

  @override
  State<_PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<_PlayButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
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
              onTap: widget.onPressed,
              customBorder: const CircleBorder(),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
