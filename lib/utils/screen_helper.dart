import 'package:flutter/material.dart';

/// Helper for adapting layouts to small screens (e.g. iPhone SE 375×667).
class ScreenHelper {
  static bool isSmallScreen(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width < 380;
  }

  static bool isCompactHeight(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.height < 700;
  }

  static double horizontalPadding(BuildContext context,
      {double normal = 24, double small = 16}) {
    return isSmallScreen(context) ? small : normal;
  }

  static double playerHorizontalPadding(BuildContext context) {
    return isSmallScreen(context) ? 16 : 32;
  }

  static double titleFontSize(BuildContext context,
      {double normal = 22, double small = 18}) {
    return isSmallScreen(context) ? small : normal;
  }

  static double subtitleFontSize(BuildContext context,
      {double normal = 18, double small = 14}) {
    return isSmallScreen(context) ? small : normal;
  }

  static double radioTitleFontSize(BuildContext context) {
    return isSmallScreen(context) ? 22 : 28;
  }

  static double radioIconSize(BuildContext context) {
    return isSmallScreen(context) ? 72 : 100;
  }

  static double radioPlayButtonSize(BuildContext context) {
    return isSmallScreen(context) ? 64 : 80;
  }

  static double radioPlayIconSize(BuildContext context) {
    return isSmallScreen(context) ? 36 : 48;
  }

  static double loginLogoSize(BuildContext context) {
    return isSmallScreen(context) ? 72 : 100;
  }

  static double loginPadding(BuildContext context) {
    return isSmallScreen(context) ? 16 : 32;
  }

  static double playButtonContainerSize(BuildContext context) {
    return isSmallScreen(context) ? 58 : 70;
  }

  static double playButtonIconSize(BuildContext context) {
    return isSmallScreen(context) ? 28 : 34;
  }

  static double skipButtonIconSize(BuildContext context) {
    return isSmallScreen(context) ? 28 : 36;
  }

  static double miniPlayerIconSize(BuildContext context) {
    return isSmallScreen(context) ? 20 : 24;
  }

  static double miniPlayerPlayIconSize(BuildContext context) {
    return isSmallScreen(context) ? 28 : 32;
  }

  static double miniPlayerSkipIconSize(BuildContext context) {
    return isSmallScreen(context) ? 24 : 28;
  }
}
