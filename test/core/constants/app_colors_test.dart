import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/constants/app_colors.dart';
import 'package:sporthub/core/theme/theme_store.dart';

void main() {
  setUp(() {
    ThemeStore.instance.reset();
  });

  tearDown(() {
    ThemeStore.instance.reset();
  });

  group('AppColors', () {
    test('resolves light palette when in light mode', () {
      ThemeStore.instance.setThemeMode(ThemeMode.light);

      expect(AppColors.isDark, isFalse);
      expect(AppColors.background, AppColors.lightBackground);
      expect(AppColors.surface, AppColors.lightSurface);
      expect(AppColors.cardBorder, AppColors.lightCardBorder);
      expect(AppColors.textPrimary, AppColors.lightTextPrimary);
      expect(AppColors.textSecondary, AppColors.lightTextSecondary);
      expect(AppColors.primary, const Color(0xFFEA580C));

      expect(AppColors.background, const Color(0xFFF8FAFC));
      expect(AppColors.surface, const Color(0xFFFFFFFF));
      expect(AppColors.cardBorder, const Color(0xFFE2E8F0));
      expect(AppColors.textPrimary, const Color(0xFF0F172A));
      expect(AppColors.textSecondary, const Color(0xFF64748B));
    });

    test('resolves dark palette when in dark mode', () {
      ThemeStore.instance.setThemeMode(ThemeMode.dark);

      expect(AppColors.isDark, isTrue);
      expect(AppColors.background, AppColors.darkBackground);
      expect(AppColors.surface, AppColors.darkSurface);
      expect(AppColors.cardBorder, AppColors.darkCardBorder);
      expect(AppColors.textPrimary, AppColors.darkTextPrimary);
      expect(AppColors.textSecondary, AppColors.darkTextSecondary);
      expect(AppColors.primary, const Color(0xFFF97316));

      expect(AppColors.background, const Color(0xFF0B0F19));
      expect(AppColors.surface, const Color(0xFF161F30));
      expect(AppColors.cardBorder, const Color(0xFF223049));
      expect(AppColors.textPrimary, const Color(0xFFF8FAFC));
      expect(AppColors.textSecondary, const Color(0xFF94A3B8));
    });

    test('provides shared brand and functional colors regardless of theme', () {
      expect(AppColors.accent, const Color(0xFF00E676));
      expect(AppColors.secondary, const Color(0xFF06B6D4));
      expect(AppColors.warning, const Color(0xFFF59E0B));
      expect(AppColors.error, const Color(0xFFEF4444));
      expect(AppColors.slotAvailable, const Color(0xFF10B981));
      expect(AppColors.slotBooked, const Color(0xFFEF4444));
      expect(AppColors.slotSelected, const Color(0xFFF59E0B));
      expect(AppColors.available, AppColors.slotAvailable);
      expect(AppColors.booked, AppColors.slotBooked);
      expect(AppColors.selected, AppColors.slotSelected);
    });

    test('backward compatibility aliases return correct theme values', () {
      expect(AppColors.backgroundLight, AppColors.lightBackground);
      expect(AppColors.backgroundDark, AppColors.darkBackground);
      expect(AppColors.cardLight, AppColors.lightSurface);
      expect(AppColors.cardDark, AppColors.darkSurface);
    });
  });
}
