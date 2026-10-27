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

  test('AppColors defines primary and status colors correctly', () {
    expect(AppColors.primary.toARGB32(), 0xFFEA580C);
    ThemeStore.instance.setThemeMode(ThemeMode.dark);
    expect(AppColors.primary.toARGB32(), 0xFFF97316);
    expect(AppColors.slotAvailable.toARGB32(), 0xFF10B981);
    expect(AppColors.slotBooked.toARGB32(), 0xFFEF4444);
    expect(AppColors.slotSelected.toARGB32(), 0xFFF59E0B);
  });
}
