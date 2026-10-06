import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/state/auth_store.dart';
import 'package:sporthub/main.dart';

void main() {
  setUp(() {
    AuthStore.instance.reset();
    UserProfileStore.instance.reset();
  });

  testWidgets('Bottom navigation includes 4 tabs and switches to ProfileScreen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 840));
    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    // Verify 4 tabs exist
    expect(find.text('Đặt sân'), findsOneWidget);
    expect(find.text('Cộng đồng'), findsOneWidget);
    expect(find.text('Vé của tôi'), findsOneWidget);
    expect(find.text('Hồ sơ'), findsOneWidget);

    // Switch to Profile tab
    await tester.tap(find.text('Hồ sơ'));
    await tester.pumpAndSettle();

    // Profile screen header and stats
    expect(find.text('Nguyễn Văn An'), findsWidgets); // appears in header and pre-filled text field
    expect(find.text('⭐ Thành viên VIP'), findsOneWidget);
    expect(find.text('4.9 ⭐'), findsOneWidget);
    expect(find.text('18 Trận'), findsOneWidget);
    expect(find.text('98%'), findsOneWidget);
  });

  testWidgets('Tapping header avatar in Explore screen navigates to Profile tab', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 840));
    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    // Find avatar container with key
    final avatarFinder = find.byKey(const Key('header_user_avatar'));
    expect(avatarFinder, findsOneWidget);
    await tester.tap(avatarFinder);
    await tester.pumpAndSettle();

    // Should now be on Profile screen
    expect(find.text('⭐ Thành viên VIP'), findsOneWidget);
    expect(find.text('Thông tin cá nhân & Thể thao'), findsOneWidget);
  });

  testWidgets('Updating user profile form saves and reflects changes', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 840));
    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hồ sơ'));
    await tester.pumpAndSettle();

    // Change full name
    final nameField = find.byKey(const Key('profile_input_fullname'));
    await tester.enterText(nameField, 'Nguyễn Quốc Anh');

    // Tap Save button
    final saveButton = find.byKey(const Key('profile_save_button'));
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Verify updated name in header and text field
    expect(find.text('Nguyễn Quốc Anh'), findsWidgets);
    expect(find.text('Đã cập nhật hồ sơ thành công!'), findsOneWidget);
  });

  testWidgets('Activity cards navigate to corresponding tabs', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 840));
    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    // Go to profile tab
    await tester.tap(find.text('Hồ sơ'));
    await tester.pumpAndSettle();

    // Tap "Kèo tuyển của tôi" card -> navigate to tab 1 (Cộng đồng)
    final recruitCard = find.text('Kèo tuyển của tôi');
    expect(recruitCard, findsOneWidget);
    await tester.ensureVisible(recruitCard);
    await tester.tap(recruitCard);
    await tester.pumpAndSettle();

    expect(find.text('🔥 Kèo tuyển thành viên'), findsOneWidget);

    // Return to profile tab
    await tester.tap(find.text('Hồ sơ'));
    await tester.pumpAndSettle();

    // Tap "Vé đã đặt" card -> navigate to tab 2 (Vé của tôi)
    final ticketsCard = find.text('Vé đã đặt');
    expect(ticketsCard, findsOneWidget);
    await tester.ensureVisible(ticketsCard);
    await tester.tap(ticketsCard);
    await tester.pumpAndSettle();

    expect(find.text('SPORTHUB PASS'), findsWidgets);
  });
}
