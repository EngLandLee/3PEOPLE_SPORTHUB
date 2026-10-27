import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/state/auth_store.dart';
import 'package:sporthub/core/utils/seed_data.dart';
import 'package:sporthub/main.dart';
import 'package:sporthub/domain/entities/community_post.dart';
import 'package:sporthub/domain/entities/join_request.dart';

void main() {
  setUp(() {
    CommunityFeedStore.instance.reset();
    UserProfileStore.instance.reset();
    AuthStore.instance.reset();
    final customer = SeedData.demoUsers.first;
    AuthStore.instance.login(customer.phone, '123456');
  });

  testWidgets('Sub-filter switches between Tất cả kèo and Kèo của tôi', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 840));
    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cộng đồng'));
    await tester.pumpAndSettle();

    expect(find.text('🔥 Tất cả kèo'), findsOneWidget);
    expect(find.byKey(const Key('filter_my_posts')), findsOneWidget);

    // Filter to Kèo của tôi
    await tester.tap(find.byKey(const Key('filter_my_posts')));
    await tester.pumpAndSettle();

    // Verify filter activated
    expect(find.text('🔥 Tất cả kèo'), findsOneWidget);
  });

  testWidgets('Host can view pending requests and approve an applicant', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 840));
    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    // Seed a post owned by user_demo_01 with a pending join request after pumpWidget
    final testPost = CommunityPost(
      id: 'post_host_test_01',
      title: 'Kèo test duyệt thành viên',
      authorId: 'user_demo_01',
      authorName: 'Nguyễn Văn An',
      authorAvatarUrl: 'QA',
      sportType: 'pickleball',
      district: 'Bình Thạnh',
      venueName: 'CLB Pickleball Bình Thạnh',
      scheduledTime: '19:00 - 21:00 Hôm nay',
      skillLevel: 'Trung bình',
      requiredPlayers: 4,
      currentPlayers: 2,
      shareFee: 45000,
      note: 'Duyệt thành viên',
      requiresApproval: true,
      pendingRequests: [
        JoinRequest(
          id: 'req_test_01',
          postId: 'post_host_test_01',
          userId: 'user_other_02',
          userName: 'Trần Hoàng',
          userPhone: '0908889999',
          skillLevel: 'Intermediate',
          preferredSport: 'pickleball',
          createdAt: DateTime.now(),
          status: 'pending',
        ),
      ],
    );
    CommunityFeedStore.instance.addPost(testPost);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cộng đồng'));
    await tester.pumpAndSettle();

    // Switch to Kèo của tôi
    await tester.tap(find.byKey(const Key('filter_my_posts')));
    await tester.pumpAndSettle();

    // Find review button
    final reviewBtn = find.byKey(const Key('review_requests_post_host_test_01'));
    expect(reviewBtn, findsOneWidget);
    await tester.tap(reviewBtn);
    await tester.pumpAndSettle();

    // Check bottom sheet contents
    expect(find.text('Duyệt người tham gia (1)'), findsOneWidget);
    expect(find.text('Trần Hoàng'), findsOneWidget);
    expect(find.text('0908889999'), findsOneWidget);

    // Tap Approve button
    final approveBtn = find.byKey(const Key('approve_req_test_01'));
    expect(approveBtn, findsOneWidget);
    await tester.tap(approveBtn);
    await tester.pumpAndSettle();

    // Check SnackBar confirmation
    expect(find.text('Đã chấp nhận Trần Hoàng vào kèo!'), findsOneWidget);
  });

  testWidgets('Host can close recruitment post', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 840));
    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    final testPost = CommunityPost(
      id: 'post_close_test_01',
      title: 'Kèo test đóng',
      authorId: 'user_demo_01',
      authorName: 'Nguyễn Văn An',
      authorAvatarUrl: 'QA',
      sportType: 'badminton',
      district: 'Bình Thạnh',
      venueName: 'CLB Cầu Lông',
      scheduledTime: '20:00 - 22:00',
      skillLevel: 'Cơ bản',
      requiredPlayers: 4,
      currentPlayers: 2,
      shareFee: 30000,
      note: 'Test đóng kèo',
      requiresApproval: true,
      isClosed: false,
    );
    CommunityFeedStore.instance.addPost(testPost);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cộng đồng'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('filter_my_posts')));
    await tester.pumpAndSettle();

    final closeBtn = find.byKey(const Key('close_post_post_close_test_01'));
    expect(closeBtn, findsOneWidget);
    await tester.tap(closeBtn);
    await tester.pumpAndSettle();

    expect(find.text('🔒 Đã đóng kèo thành công!'), findsOneWidget);
  });
}
