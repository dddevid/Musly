import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class UiFeedback {
  UiFeedback._();

  static void showSuccess(BuildContext context, String message) {
    _showSnackBar(
      context,
      message: message,
      icon: Icons.check_circle_rounded,
      backgroundColor: const Color(0xFF1DB954),
      textColor: Colors.black,
      iconColor: Colors.black,
    );
  }

  static void showError(BuildContext context, String message) {
    _showSnackBar(
      context,
      message: message,
      icon: Icons.error_rounded,
      backgroundColor: const Color(0xFFE53935),
      textColor: Colors.white,
      iconColor: Colors.white,
    );
  }

  static void showInfo(BuildContext context, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _showSnackBar(
      context,
      message: message,
      icon: Icons.info_outline_rounded,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.grey[900]!,
      textColor: Colors.white,
      iconColor: AppTheme.brandGreen,
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
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: duration,
        elevation: 6,
      ),
    );
  }
}
