import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/state/auth_store.dart';
import 'package:sporthub/core/state/venue_owner_store.dart';
import 'package:sporthub/core/utils/seed_data.dart';
import 'package:sporthub/main.dart';

void main() {
  setUp(() {
    AuthStore.instance.reset();
    VenueOwnerStore.instance.reset();
  });

  testWidgets('Can switch from ProfileScreen to Owner Mode and switch back', (tester) async {
    final owner = SeedData.demoUsers.firstWhere((u) => u.isOwner);
    AuthStore.instance.login(owner.phone, '123456');
    VenueOwnerStore.instance.toggleOwnerMode(false);

    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    // Navigate to Profile tab
    await tester.tap(find.text('Hồ sơ'));
    await tester.pumpAndSettle();

    // Find and tap switch to owner mode button
    final switchBtn = find.byKey(const Key('switch_to_owner_mode_button'));
    await tester.ensureVisible(switchBtn);
    await tester.tap(switchBtn);
    await tester.pumpAndSettle();

    // Verify Owner Navigation Screen is shown with owner tabs
    expect(VenueOwnerStore.instance.isOwnerMode, isTrue);
    expect(find.byKey(const Key('owner_tab_schedule')), findsOneWidget);
    expect(find.byKey(const Key('owner_tab_checkin')), findsOneWidget);
    expect(find.byKey(const Key('owner_tab_revenue')), findsOneWidget);
    expect(find.byKey(const Key('owner_tab_settings')), findsOneWidget);

    // Switch to Settings tab in Owner mode
    await tester.tap(find.byKey(const Key('owner_tab_settings')));
    await tester.pumpAndSettle();

    // Tap exit owner mode button
    final exitBtn = find.byKey(const Key('exit_owner_mode_button'));
    await tester.ensureVisible(exitBtn);
    await tester.tap(exitBtn);
    await tester.pumpAndSettle();

    // Back to normal player mode
    expect(VenueOwnerStore.instance.isOwnerMode, isFalse);
    expect(find.byIcon(Icons.sports_tennis_rounded), findsOneWidget);
  });

  testWidgets('AuthScreen quick login as owner logs in and activates owner mode', (tester) async {
    AuthStore.instance.logout();
    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    final ownerHint = find.byKey(const Key('quick_login_chusan'));
    await tester.ensureVisible(ownerHint);
    await tester.tap(ownerHint);
    await tester.pumpAndSettle();

    final loginBtn = find.byKey(const Key('login_submit_button'));
    await tester.ensureVisible(loginBtn);
    await tester.tap(loginBtn);
    await tester.pumpAndSettle();

    expect(AuthStore.instance.currentUser?.userId, equals('user_owner_01'));
    expect(VenueOwnerStore.instance.isOwnerMode, isTrue);
    expect(find.byKey(const Key('owner_tab_schedule')), findsOneWidget);
  });
}
