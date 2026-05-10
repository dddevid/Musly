import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/now_playing_theme.dart';
import '../theme/app_theme.dart';

/// A card widget that shows a thumbnail preview of a Now Playing theme
class ThemePreviewCard extends StatelessWidget {
  final NowPlayingTheme theme;
  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onExport;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleSafeMode;

  const ThemePreviewCard({
    super.key,
    required this.theme,
    this.isActive = false,
    this.onTap,
    this.onEdit,
    this.onDuplicate,
    this.onExport,
    this.onDelete,
    this.onToggleSafeMode,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: isActive
              ? Border.all(color: AppTheme.appleMusicRed, width: 2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview thumbnail
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      gradient: _buildPreviewGradient(),
                    ),
                    child: Center(
                      child: ClipRect(
                        child: _buildPreviewContent(),
                      ),
                    ),
                  ),
                  if (isActive)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.appleMusicRed,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'ACTIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (theme.customFlutterCode.enabled)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: theme.safeMode
                              ? Colors.orange
                              : Colors.purple.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              theme.safeMode
                                  ? CupertinoIcons.shield_fill
                                  : CupertinoIcons.function,
                              size: 10,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              theme.safeMode ? 'SAFE' : 'CODE',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Theme info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    theme.themeName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'by ${theme.author}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      _buildTag(theme.background.type.toUpperCase()),
                      _buildTag(theme.artwork.shape.toUpperCase()),
                      if (theme.animations.coverRotation ||
                          theme.animations.pulse)
                        _buildTag('ANIM'),
                    ],
                  ),
                ],
              ),
            ),
            // Actions
            if (onEdit != null || onDuplicate != null || onDelete != null)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(12),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (onEdit != null)
                      _buildActionButton(
                        icon: CupertinoIcons.pencil,
                        onPressed: onEdit!,
                      ),
                    if (onDuplicate != null)
                      _buildActionButton(
                        icon: CupertinoIcons.doc_on_doc,
                        onPressed: onDuplicate!,
                      ),
                    if (onExport != null)
                      _buildActionButton(
                        icon: CupertinoIcons.square_arrow_up,
                        onPressed: onExport!,
                      ),
                    if (theme.customFlutterCode.enabled && onToggleSafeMode != null)
                      _buildActionButton(
                        icon: theme.safeMode
                            ? CupertinoIcons.shield_slash
                            : CupertinoIcons.shield,
                        onPressed: onToggleSafeMode!,
                        color: theme.safeMode ? Colors.orange : Colors.purple,
                      ),
                    if (onDelete != null && theme.id != 'default')
                      _buildActionButton(
                        icon: CupertinoIcons.trash,
                        onPressed: onDelete!,
                        color: AppTheme.appleMusicRed,
                      ),
                  ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return IconButton(
      icon: Icon(
        icon,
        size: 18,
        color: color ?? Colors.white.withOpacity(0.7),
      ),
      onPressed: onPressed,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(
        minWidth: 32,
        minHeight: 32,
      ),
    );
  }

  LinearGradient _buildPreviewGradient() {
    if (theme.background.type == 'solid') {
      final color = theme.background.getColor(0);
      return LinearGradient(
        colors: [color, color],
      );
    } else if (theme.background.type == 'gradient') {
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          theme.background.getColor(0),
          theme.background.getColor(1),
        ],
      );
    } else {
      // dynamic_blur - show a subtle gradient
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF1a1a2e),
          Color(0xFF16213e),
          Color(0xFF0f0f23),
        ],
      );
    }
  }

  Widget _buildPreviewContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Artwork preview
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.controls.getColor().withOpacity(0.2),
            borderRadius: BorderRadius.circular(
              theme.artwork.shape == 'circle'
                  ? 20
                  : theme.artwork.shape == 'rounded_rect'
                      ? theme.artwork.cornerRadius
                      : 0,
            ),
            boxShadow: theme.artwork.shadow
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            CupertinoIcons.music_note,
            color: theme.controls.getColor().withOpacity(0.5),
            size: 16,
          ),
        ),
        const SizedBox(height: 4),
        // Progress bar preview
        Container(
          width: 60,
          height: theme.progressBar.height.clamp(2.0, 3.5),
          decoration: BoxDecoration(
            color: theme.progressBar.getInactiveColor(),
            borderRadius: BorderRadius.circular(
              theme.progressBar.shape == 'rounded'
                  ? theme.progressBar.height / 2
                  : 0,
            ),
          ),
          child: FractionallySizedBox(
            widthFactor: 0.6,
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                color: theme.progressBar.getActiveColor(),
                borderRadius: BorderRadius.circular(
                  theme.progressBar.shape == 'rounded'
                      ? theme.progressBar.height / 2
                      : 0,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Play button preview
        Container(
          width: (theme.controls.size * 0.35).clamp(18.0, 24.0),
          height: (theme.controls.size * 0.35).clamp(18.0, 24.0),
          decoration: BoxDecoration(
            color: theme.controls.getColor(),
            shape: theme.controls.playShape == 'circle'
                ? BoxShape.circle
                : BoxShape.rectangle,
            borderRadius: theme.controls.playShape != 'circle'
                ? BorderRadius.circular(6)
                : null,
          ),
          child: Icon(
            CupertinoIcons.play_fill,
            color: theme.controls.getPlayButtonColor(),
            size: 12,
          ),
        ),
      ],
    );
  }
}
