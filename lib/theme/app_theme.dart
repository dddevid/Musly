import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class AppTheme {
  static const Color appleMusicRed = Color(0xFFFA243C);
  static const Color appleMusicPink = Color(0xFFFC5C65);

  // Spotify-like accent used on the desktop layout
  static const Color spotifyGreen = Color(0xFF1DB954);
  static const Color spotifyGreenDim = Color(0xFF158A3E);

  static const Color lightBackground = Color(0xFFF2F2F7);
  static const Color lightSurface = Colors.white;
  static const Color lightCard = Colors.white;
  static const Color lightDivider = Color(0xFFE5E5EA);
  static const Color lightSecondaryText = Color(0xFF8E8E93);

  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF1C1C1E);
  static const Color darkCard = Color(0xFF2C2C2E);
  static const Color darkDivider = Color(0xFF38383A);
  static const Color darkSecondaryText = Color(0xFF8E8E93);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: appleMusicRed,
    scaffoldBackgroundColor: lightBackground,
    colorScheme: const ColorScheme.light(
      primary: appleMusicRed,
      secondary: appleMusicPink,
      surface: lightSurface,
      onSurface: Colors.black,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: lightBackground,
      foregroundColor: Colors.black,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 34,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
    ),
    cardTheme: CardThemeData(
      color: lightCard,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: const DividerThemeData(color: lightDivider, thickness: 0.5),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
        color: Colors.black,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
        color: Colors.black,
      ),
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
      titleLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Colors.black,
      ),
      bodyLarge: TextStyle(fontSize: 17, color: Colors.black),
      bodyMedium: TextStyle(fontSize: 15, color: Colors.black),
      bodySmall: TextStyle(fontSize: 13, color: lightSecondaryText),
      labelLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: appleMusicRed,
      ),
    ),
    iconTheme: const IconThemeData(color: appleMusicRed),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: appleMusicRed,
      unselectedItemColor: lightSecondaryText,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    cupertinoOverrideTheme: const CupertinoThemeData(
      primaryColor: appleMusicRed,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: appleMusicRed,
    scaffoldBackgroundColor: darkBackground,
    colorScheme: const ColorScheme.dark(
      primary: appleMusicRed,
      secondary: appleMusicPink,
      surface: darkSurface,
      onSurface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBackground,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 34,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
    ),
    cardTheme: CardThemeData(
      color: darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: const DividerThemeData(color: darkDivider, thickness: 0.5),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
        color: Colors.white,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
        color: Colors.white,
      ),
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      titleLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      bodyLarge: TextStyle(fontSize: 17, color: Colors.white),
      bodyMedium: TextStyle(fontSize: 15, color: Colors.white),
      bodySmall: TextStyle(fontSize: 13, color: darkSecondaryText),
      labelLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: appleMusicRed,
      ),
    ),
    iconTheme: const IconThemeData(color: appleMusicRed),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1C1C1E),
      selectedItemColor: appleMusicRed,
      unselectedItemColor: darkSecondaryText,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    cupertinoOverrideTheme: const CupertinoThemeData(
      primaryColor: appleMusicRed,
      brightness: Brightness.dark,
    ),
  );
}
