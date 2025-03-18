import 'package:flutter/material.dart';

// Light Mode Color Scheme (Purple and White)
const lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF9C27B0), // Purple (Primary)
  onPrimary: Color(0xFFFFFFFF), // White (On Primary)
  secondary: Color(0xFFCE93D8), // Lighter Purple (Secondary)
  onSecondary: Color(0xFF000000), // Black (On Secondary)
  error: Color(0xFFD32F2F), // Red (Error)
  onError: Color(0xFFFFFFFF), // White (On Error)
  background: Color(0xFFFFFFFF), // White (Background)
  onBackground: Color(0xFF000000), // Black (On Background)
  surface: Color(0xFFF3E5F5), // Very Light Purple (Surface)
  onSurface: Color(0xFF000000), // Black (On Surface)
  shadow: Color(0xFF000000),
  outlineVariant: Color(0xFFE0E0E0),
);

// Dark Mode Color Scheme (Dark Purple and Gray)
const darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFCE93D8), // Lighter Purple (Primary in Dark)
  onPrimary: Color(0xFF000000), // Black (On Primary in Dark)
  secondary: Color(0xFF9C27B0), // Purple (Secondary in Dark)
  onSecondary: Color(0xFFFFFFFF), // White (On Secondary in Dark)
  error: Color(0xFFEF9A9A), // Light Red (Error in Dark)
  onError: Color(0xFF000000), // Black (On Error in Dark)
  background: Color(0xFF1E1E1E), // Dark Gray (Background)
  onBackground: Color(0xFFE0E0E0), // Light Gray (On Background)
  surface: Color(0xFF303030), // Darker Gray (Surface)
  onSurface: Color(0xFFE0E0E0), // Light Gray (On Surface)
  shadow: Color(0xFF000000),
  outlineVariant: Color(0xFF424242),
);

// Light Mode ThemeData
ThemeData lightMode = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: lightColorScheme,
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: MaterialStateProperty.all<Color>(lightColorScheme.primary),
      foregroundColor: MaterialStateProperty.all<Color>(lightColorScheme.onPrimary),
      elevation: MaterialStateProperty.all<double>(5.0),
      padding: MaterialStateProperty.all<EdgeInsets>(
          const EdgeInsets.symmetric(horizontal: 20, vertical: 18)),
      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: lightColorScheme.primary,
    foregroundColor: lightColorScheme.onPrimary,
  ),
);

// Dark Mode ThemeData
ThemeData darkMode = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: darkColorScheme,
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: MaterialStateProperty.all<Color>(darkColorScheme.primary),
      foregroundColor: MaterialStateProperty.all<Color>(darkColorScheme.onPrimary),
      elevation: MaterialStateProperty.all<double>(5.0),
      padding: MaterialStateProperty.all<EdgeInsets>(
          const EdgeInsets.symmetric(horizontal: 20, vertical: 18)),
      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: darkColorScheme.primary,
    foregroundColor: darkColorScheme.onPrimary,
  ),
);