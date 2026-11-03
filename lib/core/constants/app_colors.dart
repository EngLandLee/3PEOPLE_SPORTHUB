import 'package:flutter/material.dart';
import '../theme/theme_store.dart';

class AppColors {
  // Night Court Dark Theme Palette Constants
  static const Color darkBackground = Color(0xFF070B14);
  static const Color darkSurface = Color(0xFF0F1626);
  static const Color darkCardBorder = Color(0xFF1E2A3D);
  static const Color darkTextPrimary = Color(0xFFF5F7FA);
  static const Color darkTextSecondary = Color(0xFF8B98AD);

  // Daylight Court Light Theme Palette Constants
  static const Color lightBackground = Color(0xFFFAFAF7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCardBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // Night Court Electric Lime & Daylight Lime Brand Palette (Playtomic & Nike NRC Style)
  static const Color darkPrimary = Color(0xFFC6F432);  // Electric Lime Neon
  static const Color lightPrimary = Color(0xFF4D7C0F); // Deep Athletic Lime (WCAG AA)
  static const Color primaryLight = Color(0xFFF7FEE7); // Soft Lime Tint Background
  static const Color primaryHover = Color(0xFF3F6212); // Deeper Lime Hover

  // Dynamic Getters driven by ThemeStore
  static bool get isDark => ThemeStore.instance.isDarkMode;
  static Color get background => isDark ? darkBackground : lightBackground;
  static Color get surface => isDark ? darkSurface : lightSurface;
  static Color get cardBorder => isDark ? darkCardBorder : lightCardBorder;
  static Color get textPrimary => isDark ? darkTextPrimary : lightTextPrimary;
  static Color get textSecondary =>
      isDark ? darkTextSecondary : lightTextSecondary;
  static Color get primary => isDark ? darkPrimary : lightPrimary;
  static Color get onPrimary => isDark ? const Color(0xFF070B14) : Colors.white;

  // Shared Brand & Functional Colors
  static const Color accent = Color(0xFFFF6B2C);
  static const Color secondary = Color(0xFF06B6D4);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Time-Slot Matrix Status Colors
  static const Color slotAvailable = Color(0xFF10B981);
  static const Color slotBooked = Color(0xFFEF4444);
  static const Color slotSelected = Color(0xFFF59E0B);

  // Backward compatibility aliases
  static const Color available = slotAvailable;
  static const Color booked = slotBooked;
  static const Color selected = slotSelected;
  static Color get backgroundLight => lightBackground;
  static Color get backgroundDark => darkBackground;
  static Color get cardLight => lightSurface;
  static Color get cardDark => darkSurface;
}
