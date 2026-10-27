import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/state/auth_store.dart';
import 'package:sporthub/core/state/ticket_store.dart';
import 'package:sporthub/main.dart';

void main() {
  setUp(() {
    AuthStore.instance.login('0901 234 567', '123456');
    TicketStore.instance.reset();
    CommunityFeedStore.instance.reset();
  });

  testWidgets('Community feed displays posts, switches modes, and joins a match', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    // Tap Tab 2 (Cộng đồng)
    await tester.tap(find.byIcon(Icons.groups_rounded));
    await tester.pumpAndSettle();

    // Verifies mode tabs exist
    expect(find.text('🔥 Kèo tuyển thành viên'), findsOneWidget);
    expect(find.text('✨ Gợi ý đối thủ AI'), findsOneWidget);

    // Verifies community post card exists
    expect(find.text('Tham gia ngay'), findsWidgets);

    // Tap join post
    await tester.tap(find.text('Tham gia ngay').first);
    await tester.pumpAndSettle();

    // Shows joined status or contact hotline modal
    expect(find.textContaining('0909 123 456'), findsOneWidget);

    // Close contact dialog
    if (find.text('Đóng').evaluate().isNotEmpty) {
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();
    }

    // Shows joined status
    expect(find.text('Đã tham gia ✓'), findsOneWidget);
  });

  testWidgets('Dual-mode selector toggles cleanly between Community Feed and AI Matchmaker', (tester) async {
    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    // Switch to Community Tab
    await tester.tap(find.byIcon(Icons.groups_rounded));
    await tester.pumpAndSettle();

    // Community Feed is default
    expect(find.text('🔥 Kèo tuyển thành viên'), findsOneWidget);
    expect(find.text('Tất cả môn'), findsOneWidget);

    // Switch to AI Mode
    await tester.tap(find.text('✨ Gợi ý đối thủ AI'));
    await tester.pumpAndSettle();

    expect(find.text('Trợ lý Matchmaker AI'), findsOneWidget);
    expect(find.text('✨ Phân tích đối thủ phù hợp'), findsOneWidget);

    // Switch back to Community mode
    await tester.tap(find.text('🔥 Kèo tuyển thành viên'));
    await tester.pumpAndSettle();

    expect(find.text('Tất cả môn'), findsOneWidget);
    expect(find.text('Tham gia ngay'), findsWidgets);
  });

  testWidgets('Sport filter chips filter posts dynamically', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    // Navigate to Community tab
    await tester.tap(find.byIcon(Icons.groups_rounded));
    await tester.pumpAndSettle();

    // Initial feed has posts from various sports
    expect(find.text('Tuyển 2 bạn đánh cầu lông tối nay'), findsOneWidget);
    expect(find.text('Tuyển 1 slot đánh Pickleball buổi tối Thảo Điền'), findsOneWidget);

    // Filter by Pickleball
    final pickleballChip = find.widgetWithText(FilterChip, '🏓 Pickleball');
    await tester.ensureVisible(pickleballChip);
    await tester.tap(pickleballChip);
    await tester.pumpAndSettle();

    expect(find.text('Tuyển 1 slot đánh Pickleball buổi tối Thảo Điền'), findsOneWidget);
    expect(find.text('Tuyển 2 bạn đánh cầu lông tối nay'), findsNothing);

    // Reset to All Sports
    final allSportsChip = find.widgetWithText(FilterChip, 'Tất cả môn');
    await tester.ensureVisible(allSportsChip);
    await tester.tap(allSportsChip);
    await tester.pumpAndSettle();

    expect(find.text('Tuyển 2 bạn đánh cầu lông tối nay'), findsOneWidget);
    expect(find.text('Tuyển 1 slot đánh Pickleball buổi tối Thảo Điền'), findsOneWidget);
  });

  testWidgets('Create post dialog allows creating a new community post', (tester) async {
    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    // Navigate to Community tab
    await tester.tap(find.byIcon(Icons.groups_rounded));
    await tester.pumpAndSettle();

    // Tap "+ Đăng kèo" button in AppBar
    await tester.tap(find.text('+ Đăng kèo'));
    await tester.pumpAndSettle();

    // Verify dialog opened
    expect(find.text('Đăng bài tuyển người chơi'), findsOneWidget);

    // Enter title
    final titleFinder = find.widgetWithText(TextField, 'Tiêu đề kèo đấu');
    await tester.enterText(titleFinder, 'Kèo Test Mới Nhất');
    await tester.pumpAndSettle();

    // Submit post
    final submitBtn = find.text('Đăng bài tuyển người');
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    // Verify dialog closed and new post is in feed
    expect(find.text('Đăng bài tuyển người chơi'), findsNothing);
    expect(find.text('Kèo Test Mới Nhất'), findsOneWidget);
  });

  testWidgets('TicketsScreen displays recruit button and opens prefilled dialog', (tester) async {
    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    // Navigate to Tab 3 (Vé của tôi)
    await tester.tap(find.byIcon(Icons.confirmation_number_rounded));
    await tester.pumpAndSettle();

    // Verify recruit button exists on ticket
    expect(find.text('📢 Tuyển thêm người chơi'), findsWidgets);

    // Tap recruit button
    await tester.tap(find.text('📢 Tuyển thêm người chơi').first);
    await tester.pumpAndSettle();

    // Dialog opens with prefilled title
    expect(find.text('Đăng bài tuyển người chơi'), findsOneWidget);
  });

  testWidgets('Recruiting from ticket creates community post and navigates to Community tab', (tester) async {
    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    // Navigate to Tab 3 (Vé của tôi)
    await tester.tap(find.byIcon(Icons.confirmation_number_rounded));
    await tester.pumpAndSettle();

    // Tap recruit button
    await tester.tap(find.text('📢 Tuyển thêm người chơi').first);
    await tester.pumpAndSettle();

    // Verify pre-filled venue and dialog title
    expect(find.text('Đăng bài tuyển người chơi'), findsOneWidget);
    expect(find.textContaining('Sân Cầu Lông Bình Thạnh'), findsWidgets);

    // Tap submit button: "Đăng bài ngay"
    final submitBtn = find.text('Đăng bài ngay');
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    // SnackBar appears with direct action to Community tab
    expect(find.text('Đã đăng bài tuyển thành viên lên Cộng đồng!'), findsOneWidget);
    expect(find.text('Xem ngay'), findsOneWidget);

    // Tap action to navigate to Tab 1 (Cộng đồng)
    await tester.tap(find.text('Xem ngay'));
    await tester.pumpAndSettle();

    // Verify we are now on Community tab and the recruited post is displayed
    expect(find.text('🔥 Kèo tuyển thành viên'), findsOneWidget);
    expect(find.textContaining('Cần tìm bạn chơi cùng tại Sân Cầu Lông Bình Thạnh'), findsOneWidget);
  });
}
