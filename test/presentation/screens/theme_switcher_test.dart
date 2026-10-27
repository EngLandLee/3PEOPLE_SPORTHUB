import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/constants/app_colors.dart';
import 'package:sporthub/core/state/auth_store.dart';
import 'package:sporthub/core/state/venue_owner_store.dart';
import 'package:sporthub/core/theme/theme_store.dart';
import 'package:sporthub/core/utils/seed_data.dart';
import 'package:sporthub/main.dart';

void main() {
  setUp(() {
    ThemeStore.instance.reset();
    AuthStore.instance.reset();
    VenueOwnerStore.instance.reset();
  });

  testWidgets('Consumer Explore header displays quick theme toggle button and switches theme', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 850));
    final customer = SeedData.demoUsers.first;
    AuthStore.instance.login(customer.phone, '123456');

    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    expect(ThemeStore.instance.isLightMode, isTrue);
    final toggleFinder = find.byKey(const Key('theme_toggle_button'));
    expect(toggleFinder, findsOneWidget);

    final sportHubFinder = find.text('SportHub');
    expect(sportHubFinder, findsOneWidget);
    Text sportHubText = tester.widget<Text>(sportHubFinder);
    expect(sportHubText.style?.color, equals(AppColors.lightTextPrimary));

    await tester.tap(toggleFinder);
    await tester.pumpAndSettle();

    expect(ThemeStore.instance.isDarkMode, isTrue);
    sportHubText = tester.widget<Text>(sportHubFinder);
    expect(sportHubText.style?.color, equals(AppColors.darkTextPrimary));

    await tester.tap(toggleFinder);
    await tester.pumpAndSettle();

    expect(ThemeStore.instance.isLightMode, isTrue);
    sportHubText = tester.widget<Text>(sportHubFinder);
    expect(sportHubText.style?.color, equals(AppColors.lightTextPrimary));
  });

  testWidgets('Partner Owner header displays quick theme toggle button and switches theme', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 850));
    final owner = SeedData.demoUsers.firstWhere((u) => u.isOwner);
    AuthStore.instance.login(owner.phone, '123456');

    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    final ownerToggleFinder = find.byKey(const Key('theme_toggle_button_owner'));
    expect(ownerToggleFinder, findsOneWidget);

    final venueNameFinder = find.text(VenueOwnerStore.instance.activeVenueName);
    expect(venueNameFinder, findsOneWidget);
    Text venueNameText = tester.widget<Text>(venueNameFinder);
    expect(venueNameText.style?.color, equals(AppColors.lightTextPrimary));

    await tester.tap(ownerToggleFinder);
    await tester.pumpAndSettle();

    expect(ThemeStore.instance.isDarkMode, isTrue);
    venueNameText = tester.widget<Text>(venueNameFinder);
    expect(venueNameText.style?.color, equals(AppColors.darkTextPrimary));

    await tester.tap(ownerToggleFinder);
    await tester.pumpAndSettle();

    expect(ThemeStore.instance.isLightMode, isTrue);
    venueNameText = tester.widget<Text>(venueNameFinder);
    expect(venueNameText.style?.color, equals(AppColors.lightTextPrimary));
  });

  testWidgets('Profile settings theme toggle switches theme mode when tapped', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 850));
    final customer = SeedData.demoUsers.first;
    AuthStore.instance.login(customer.phone, '123456');

    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    // Tap Profile tab
    await tester.tap(find.text('Hồ sơ'));
    await tester.pumpAndSettle();

    final profileToggleFinder = find.byKey(const Key('profile_theme_toggle'));
    await tester.ensureVisible(profileToggleFinder);
    expect(profileToggleFinder, findsOneWidget);

    await tester.tap(profileToggleFinder);
    await tester.pumpAndSettle();

    expect(ThemeStore.instance.isDarkMode, isTrue);

    await tester.tap(profileToggleFinder);
    await tester.pumpAndSettle();

    expect(ThemeStore.instance.isLightMode, isTrue);
  });

  testWidgets('Owner settings theme toggle switches theme mode when tapped', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 850));
    final owner = SeedData.demoUsers.firstWhere((u) => u.isOwner);
    AuthStore.instance.login(owner.phone, '123456');

    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    // Switch to Owner Settings tab
    await tester.tap(find.byKey(const Key('owner_tab_settings')));
    await tester.pumpAndSettle();

    final ownerSettingToggleFinder = find.byKey(const Key('owner_settings_theme_toggle'));
    await tester.ensureVisible(ownerSettingToggleFinder);
    expect(ownerSettingToggleFinder, findsOneWidget);

    await tester.tap(ownerSettingToggleFinder);
    await tester.pumpAndSettle();

    expect(ThemeStore.instance.isDarkMode, isTrue);

    await tester.ensureVisible(ownerSettingToggleFinder);
    await tester.tap(ownerSettingToggleFinder);
    await tester.pumpAndSettle();

    expect(ThemeStore.instance.isLightMode, isTrue);
  });
}
