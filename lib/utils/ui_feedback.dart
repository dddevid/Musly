import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class UiFeedback {
  UiFeedback._();

  static void showSuccess(BuildContext context, String message) {
    HapticFeedback.lightImpact();
    final isApple = Theme.of(context).platform == TargetPlatform.iOS ||
        Theme.of(context).platform == TargetPlatform.macOS;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _showSnackBar(
      context,
      message: message,
      icon: isApple
          ? CupertinoIcons.checkmark_circle_fill
          : Icons.check_circle_rounded,
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      textColor: isDark ? Colors.white : Colors.black87,
      iconColor: const Color(0xFF34C759),
    );
  }

  static void showError(BuildContext context, String message) {
    HapticFeedback.heavyImpact();
    final isApple = Theme.of(context).platform == TargetPlatform.iOS ||
        Theme.of(context).platform == TargetPlatform.macOS;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _showSnackBar(
      context,
      message: message,
      icon: isApple
          ? CupertinoIcons.exclamationmark_circle_fill
          : Icons.error_rounded,
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      textColor: isDark ? Colors.white : Colors.black87,
      iconColor: const Color(0xFFFF3B30),
    );
  }

  static void showInfo(BuildContext context, String message) {
    HapticFeedback.lightImpact();
    final isApple = Theme.of(context).platform == TargetPlatform.iOS ||
        Theme.of(context).platform == TargetPlatform.macOS;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    _showSnackBar(
      context,
      message: message,
      icon: isApple ? CupertinoIcons.info_circle_fill : Icons.info_outline_rounded,
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      textColor: isDark ? Colors.white : Colors.black87,
      iconColor: primary,
    );
  }

  static void _showSnackBar(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Color textColor,
    required Color iconColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.08),
            width: 0.8,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        duration: duration,
        elevation: 6,
      ),
    );
  }
}
