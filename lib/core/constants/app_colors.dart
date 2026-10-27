import 'package:flutter/material.dart';
import '../theme/theme_store.dart';

class AppColors {
  // Dark Theme Palette Constants
  static const Color darkBackground = Color(0xFF0B0F19);
  static const Color darkSurface = Color(0xFF161F30);
  static const Color darkCardBorder = Color(0xFF223049);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // Light Theme Palette Constants
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCardBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // Sunset Athletic Orange Brand Palette (Strava & Playtomic Style)
  static const Color darkPrimary = Color(0xFFF97316);  // Vibrant Athletic Orange
  static const Color lightPrimary = Color(0xFFEA580C); // Deep Energy Orange
  static const Color primaryLight = Color(0xFFFFF7ED); // Soft Orange Light Background
  static const Color primaryHover = Color(0xFFC2410C); // Darker Orange Hover

  // Dynamic Getters driven by ThemeStore
  static bool get isDark => ThemeStore.instance.isDarkMode;
  static Color get background => isDark ? darkBackground : lightBackground;
  static Color get surface => isDark ? darkSurface : lightSurface;
  static Color get cardBorder => isDark ? darkCardBorder : lightCardBorder;
  static Color get textPrimary => isDark ? darkTextPrimary : lightTextPrimary;
  static Color get textSecondary =>
      isDark ? darkTextSecondary : lightTextSecondary;
  static Color get primary => isDark ? darkPrimary : lightPrimary;
  static Color get onPrimary => isDark ? Colors.black : Colors.white;

  // Shared Brand & Functional Colors
  static const Color accent = Color(0xFF00E676);
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
