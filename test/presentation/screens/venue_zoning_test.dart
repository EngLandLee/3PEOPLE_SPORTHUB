import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/utils/seed_data.dart';
import 'package:sporthub/main.dart';
import 'package:sporthub/presentation/blocs/booking/booking_bloc.dart';

void main() {
  testWidgets('VenueDetailScreen renders Sport Zones for multi-sport venue Tân Bình Arena', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));

    final tanBinhVenue = SeedData.sampleVenues.firstWhere((v) => v.id == 'venue_tb_05');

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => BookingBloc()),
        ],
        child: MaterialApp(
          home: VenueDetailScreen(venue: tanBinhVenue),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Scroll until view_mode_court_map is visible
    final courtMapToggle = find.byKey(const Key('view_mode_court_map'));
    await tester.scrollUntilVisible(
      courtMapToggle,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    // Switch to 2D court overview map
    await tester.tap(courtMapToggle);
    await tester.pumpAndSettle();

    // Verify Zone Headers exist
    expect(find.byKey(const Key('zone_header_badminton')), findsOneWidget);
    expect(find.byKey(const Key('zone_header_pickleball')), findsOneWidget);
    expect(find.byKey(const Key('zone_header_football')), findsOneWidget);

    // Verify Zone details
    expect(find.textContaining('Cụm Sân Bóng Đá Mini'), findsOneWidget);
    expect(find.textContaining('FIFA Pro'), findsOneWidget);
    expect(find.textContaining('290k'), findsWidgets); // Football peak price
  });

  testWidgets('VenueDetailScreen filters Sport Zones when sport partition chips are tapped', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));

    final tanBinhVenue = SeedData.sampleVenues.firstWhere((v) => v.id == 'venue_tb_05');

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => BookingBloc()),
        ],
        child: MaterialApp(
          home: VenueDetailScreen(venue: tanBinhVenue),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final courtMapToggle = find.byKey(const Key('view_mode_court_map'));
    await tester.scrollUntilVisible(
      courtMapToggle,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(courtMapToggle);
    await tester.pumpAndSettle();

    // Filter to Football only
    final footballFilter = find.byKey(const Key('zone_filter_football'));
    await tester.scrollUntilVisible(
      footballFilter,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(footballFilter);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('zone_header_football')), findsOneWidget);
    expect(find.byKey(const Key('zone_header_badminton')), findsNothing);
    expect(find.byKey(const Key('zone_header_pickleball')), findsNothing);
    expect(find.byKey(const Key('court_card_8')), findsOneWidget);
    expect(find.byKey(const Key('court_card_1')), findsNothing);
  });

  testWidgets('Court cards render tiered slot pricing with peak and off-peak badges', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));

    final tanBinhVenue = SeedData.sampleVenues.firstWhere((v) => v.id == 'venue_tb_05');

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => BookingBloc()),
        ],
        child: MaterialApp(
          home: VenueDetailScreen(venue: tanBinhVenue),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final courtMapToggle = find.byKey(const Key('view_mode_court_map'));
    await tester.scrollUntilVisible(
      courtMapToggle,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(courtMapToggle);
    await tester.pumpAndSettle();

    // Verify peak hour tag '🔥 Vàng' is present
    expect(find.textContaining('🔥 Vàng'), findsWidgets);

    // Filter to football and verify 420k is rendered on slot chips
    final footballFilter = find.byKey(const Key('zone_filter_football'));
    await tester.scrollUntilVisible(
      footballFilter,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(footballFilter);
    await tester.pumpAndSettle();

    expect(find.text('290k'), findsWidgets);
    expect(find.textContaining('Từ 250k - 290k/slot'), findsWidgets);
  });
}
