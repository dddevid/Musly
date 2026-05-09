import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class AppTheme {
  static const Color appleMusicRed = Color(0xFFFA243C);
  static const Color appleMusicPink = Color(0xFFFC5C65);

  static const Color spotifyGreen = Color(0xFF1DB954);
  static const Color spotifyGreenDim = Color(0xFF158A3E);

  static const Color lightBackground = Color(0xFFF2F2F7);
  static const Color lightSurface = Colors.white;
  static const Color lightCard = Colors.white;
  static const Color lightDivider = Color(0xFFE5E5EA);
  static const Color lightSecondaryText = Color(0xFF8E8E93);

  // Spotify-like Dark Mode Colors
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF121212);
  static const Color darkCard = Color(0xFF181818);
  static const Color darkElevated = Color(0xFF282828);
  static const Color darkDivider = Color(0xFF404040);
  static const Color darkSecondaryText = Color(0xFFB3B3B3);
  static const Color darkTertiaryText = Color(0xFF6B6B6B);

  // Sidebar specific
  static const Color sidebarBackground = Color(0xFF000000);
  static const Color sidebarCard = Color(0xFF121212);

  // Player bar specific
  static const Color playerBarDark = Color(0xFF181818);
  static const Color playerBarLight = Color(0xFFF8F8F8);
  static const Color playerBarBorder = Color(0xFF282828);

  static ThemeData lightThemeWith(Color accent) => _buildLightTheme(accent);

  static ThemeData darkThemeWith(Color accent) => _buildDarkTheme(accent);

  static ThemeData lightThemeFromScheme(ColorScheme scheme) =>
      _buildFromScheme(scheme);

  static ThemeData darkThemeFromScheme(ColorScheme scheme) =>
      _buildFromScheme(scheme);

  static ThemeData get lightTheme => _buildLightTheme(appleMusicRed);

  static ThemeData get darkTheme => _buildDarkTheme(appleMusicRed);

  static ThemeData _buildLightTheme(Color accent) => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: accent,
        scaffoldBackgroundColor: lightBackground,
        colorScheme: ColorScheme.light(
          primary: accent,
          secondary: accent.withAlpha(200),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        dividerTheme:
            const DividerThemeData(color: lightDivider, thickness: 0.5),
        textTheme: TextTheme(
          displayLarge: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: Colors.black,
          ),
          displayMedium: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: Colors.black,
          ),
          headlineLarge: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          headlineMedium: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
          titleLarge: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
          titleMedium: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          bodyLarge: const TextStyle(fontSize: 17, color: Colors.black),
          bodyMedium: const TextStyle(fontSize: 15, color: Colors.black),
          bodySmall: const TextStyle(fontSize: 13, color: lightSecondaryText),
          labelLarge: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: accent,
          ),
        ),
        iconTheme: IconThemeData(color: accent),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: accent,
          unselectedItemColor: lightSecondaryText,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        cupertinoOverrideTheme: CupertinoThemeData(
          primaryColor: accent,
        ),
      );

  static ThemeData _buildDarkTheme(Color accent) => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: accent,
        scaffoldBackgroundColor: darkBackground,
        colorScheme: ColorScheme.dark(
          primary: accent,
          secondary: accent.withAlpha(200),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        dividerTheme:
            const DividerThemeData(color: darkDivider, thickness: 0.5),
        textTheme: TextTheme(
          displayLarge: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
          displayMedium: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
          headlineLarge: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          headlineMedium: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          titleLarge: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          titleMedium: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          bodyLarge: const TextStyle(fontSize: 17, color: Colors.white),
          bodyMedium: const TextStyle(fontSize: 15, color: Colors.white),
          bodySmall: const TextStyle(fontSize: 13, color: darkSecondaryText),
          labelLarge: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: accent,
          ),
        ),
        iconTheme: IconThemeData(color: accent),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: const Color(0xFF1C1C1E),
          selectedItemColor: accent,
          unselectedItemColor: darkSecondaryText,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        cupertinoOverrideTheme: CupertinoThemeData(
          primaryColor: accent,
          brightness: Brightness.dark,
        ),
      );

  static ThemeData _buildFromScheme(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    final accent = scheme.primary;
    final bg = isDark ? darkBackground : lightBackground;
    final surface = isDark ? darkSurface : lightSurface;
    final secondary = isDark ? darkSecondaryText : lightSecondaryText;
    final divider = isDark ? darkDivider : lightDivider;
    final fg = isDark ? Colors.white : Colors.black;

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      primaryColor: accent,
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: fg,
          fontSize: 34,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(color: divider, thickness: 0.5),
      textTheme: TextTheme(
        displayLarge: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: fg),
        displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: fg),
        headlineLarge:
            TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: fg),
        headlineMedium:
            TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: fg),
        titleLarge:
            TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: fg),
        titleMedium:
            TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: fg),
        bodyLarge: TextStyle(fontSize: 17, color: fg),
        bodyMedium: TextStyle(fontSize: 15, color: fg),
        bodySmall: TextStyle(fontSize: 13, color: secondary),
        labelLarge:
            TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: accent),
      ),
      iconTheme: IconThemeData(color: accent),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        selectedItemColor: accent,
        unselectedItemColor: secondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cupertinoOverrideTheme: CupertinoThemeData(
        primaryColor: accent,
        brightness: scheme.brightness,
      ),
    );
  }
}
