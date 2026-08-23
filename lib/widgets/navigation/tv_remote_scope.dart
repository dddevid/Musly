import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/player_provider.dart';
import '../../services/tv_detection_service.dart';

/// Wraps the entire application with D-Pad TV Remote Control navigation,
/// media key shortcuts, and high-visibility 10-foot focus management.
class TvRemoteScope extends StatelessWidget {
  final Widget child;

  const TvRemoteScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final tvService = Provider.of<TvDetectionService>(context);
    final player = Provider.of<PlayerProvider>(context, listen: false);

    return FocusTraversalGroup(
      policy: ReadingOrderTraversalPolicy(),
      child: CallbackShortcuts(
        bindings: {
          // Play / Pause media keys on TV remote controls
          const SingleActivator(LogicalKeyboardKey.mediaPlayPause): () => player.togglePlayPause(),
          const SingleActivator(LogicalKeyboardKey.mediaPlay): () => player.play(),
          const SingleActivator(LogicalKeyboardKey.mediaPause): () => player.pause(),
          const SingleActivator(LogicalKeyboardKey.mediaTrackNext): () => player.skipNext(),
          const SingleActivator(LogicalKeyboardKey.mediaFastForward): () => player.skipNext(),
          const SingleActivator(LogicalKeyboardKey.mediaTrackPrevious): () => player.skipPrevious(),
          const SingleActivator(LogicalKeyboardKey.mediaRewind): () => player.skipPrevious(),
          const SingleActivator(LogicalKeyboardKey.space): () {
            // Space toggles playback if focus is not on an editable text field
            final currentFocus = FocusManager.instance.primaryFocus;
            if (currentFocus == null || currentFocus.context?.widget is! EditableText) {
              player.togglePlayPause();
            }
          },
        },
        child: FocusScope(
          autofocus: tvService.isTvMode,
          child: child,
        ),
      ),
    );
  }
}

/// Helper widget to make any card or list tile D-Pad focusable with a TV glow ring.
class TvFocusableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool autoFocus;

  const TvFocusableCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius,
    this.padding,
    this.autoFocus = false,
  });

  @override
  State<TvFocusableCard> createState() => _TvFocusableCardState();
}

class _TvFocusableCardState extends State<TvFocusableCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTv = Provider.of<TvDetectionService>(context).isTvMode;
    final primary = theme.colorScheme.primary;
    final radius = widget.borderRadius ?? BorderRadius.circular(16);

    return FocusableActionDetector(
      autofocus: widget.autoFocus,
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap?.call();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: widget.padding,
          transform: isTv && _isFocused ? Matrix4.diagonal3Values(1.03, 1.03, 1.0) : Matrix4.identity(),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: _isFocused
                ? Border.all(
                    color: isTv ? const Color(0xFFFFD700) : primary,
                    width: isTv ? 2.5 : 2.0,
                  )
                : Border.all(color: Colors.transparent, width: 2.0),
            boxShadow: _isFocused && isTv
                ? [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
