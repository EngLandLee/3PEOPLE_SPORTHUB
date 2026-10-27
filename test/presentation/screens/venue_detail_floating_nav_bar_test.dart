import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/state/auth_store.dart';
import 'package:sporthub/core/utils/seed_data.dart';
import 'package:sporthub/main.dart';

void main() {
  setUp(() {
    AuthStore.instance.loginWithDemo(SeedData.demoUsers.first);
  });

  testWidgets('VenueDetailScreen displays floating bottom navigation bar and allows navigating back/to tabs', (tester) async {
    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    // Verify on ExploreVenuesScreen (Tab 0)
    expect(find.byKey(const Key('consumer_bottom_nav_bar')), findsOneWidget);

    // Scroll to first venue card and tap
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();

    final ctaFinder = find.text('Xem lịch sân').first;
    await tester.tap(ctaFinder);
    await tester.pumpAndSettle();

    // Verify VenueDetailScreen is open
    expect(find.byType(VenueDetailScreen), findsOneWidget);

    // Verify floating bottom navigation bar is present on VenueDetailScreen
    final detailNavBar = find.byKey(const Key('venue_detail_bottom_nav_bar'));
    expect(detailNavBar, findsOneWidget);

    // Tap "Vé của tôi" in the floating bottom nav bar
    final myTicketsNav = find.descendant(
      of: detailNavBar,
      matching: find.text('Vé của tôi'),
    );
    expect(myTicketsNav, findsOneWidget);
    await tester.tap(myTicketsNav);
    await tester.pumpAndSettle();

    // VenueDetailScreen should be popped, and user is on TicketsScreen (Tab 2)
    expect(find.byType(VenueDetailScreen), findsNothing);
    expect(find.byKey(const Key('venue_detail_bottom_nav_bar')), findsNothing);
    expect(find.byKey(const Key('consumer_bottom_nav_bar')), findsOneWidget);
    expect(find.text('Vé Đã Đặt (Offline Pass)'), findsOneWidget);
  });

  testWidgets('Tapping Đặt sân on VenueDetailScreen floating nav bar returns to venue catalog', (tester) async {
    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    // Scroll to first venue card and tap
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();

    final ctaFinder = find.text('Xem lịch sân').first;
    await tester.tap(ctaFinder);
    await tester.pumpAndSettle();

    expect(find.byType(VenueDetailScreen), findsOneWidget);
    final detailNavBar = find.byKey(const Key('venue_detail_bottom_nav_bar'));
    expect(detailNavBar, findsOneWidget);

    // Tap "Đặt sân" in the floating nav bar
    final bookingNav = find.descendant(
      of: detailNavBar,
      matching: find.text('Đặt sân'),
    );
    await tester.tap(bookingNav);
    await tester.pumpAndSettle();

    // Should pop back to ExploreVenuesScreen
    expect(find.byType(VenueDetailScreen), findsNothing);
    expect(find.byKey(const Key('venue_detail_bottom_nav_bar')), findsNothing);
    expect(find.byKey(const Key('consumer_bottom_nav_bar')), findsOneWidget);
  });
}
