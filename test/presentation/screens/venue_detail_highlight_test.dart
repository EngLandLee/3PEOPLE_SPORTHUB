import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/services/venue_sync_service.dart';
import 'package:sporthub/core/utils/court_sport_partition.dart';
import 'package:sporthub/core/utils/seed_data.dart';
import 'package:sporthub/main.dart';
import 'package:sporthub/presentation/blocs/booking/booking_bloc.dart';
import 'package:sporthub/presentation/blocs/booking/booking_state.dart';

final Uint8List _kTransparentImage = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Duration? connectionTimeout;

  @override
  Duration idleTimeout = const Duration(seconds: 15);

  @override
  void close({bool force = false}) {}

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _MockHttpClientRequest();
  }
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async {
    return _MockHttpClientResponse();
  }
}

class _MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => _kTransparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_kTransparentImage).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  tearDownAll(() {
    HttpOverrides.global = null;
    VenueSyncService.instance.stopPolling();
  });

  testWidgets('VenueDetailScreen highlights court card and renders AI badge',
      (tester) async {
    final venue = SeedData.sampleVenues.first;

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<BookingBloc>(create: (_) => BookingBloc()),
        ],
        child: MaterialApp(
          home: VenueDetailScreen(
            venue: venue,
            targetCourtNumber: 1,
            targetStartTime: '19:00',
            targetEndTime: '20:00',
            initialViewMode: 'court_map',
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Verify view mode is court_map and AI badge is visible
    expect(find.text('🎯 Sân AI gợi ý'), findsOneWidget);
    expect(find.byKey(const Key('court_card_1')), findsOneWidget);
  });

  testWidgets('VenueDetailScreen auto-selects matching slot into BookingBloc',
      (tester) async {
    final venue = SeedData.sampleVenues.first;
    final bookingBloc = BookingBloc();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<BookingBloc>.value(value: bookingBloc),
        ],
        child: MaterialApp(
          home: VenueDetailScreen(
            venue: venue,
            initialDate: DateTime(2026, 9, 6),
            targetCourtNumber: 1,
            targetStartTime: '19:00',
            targetEndTime: '20:00',
            initialViewMode: 'court_map',
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Verify slot was auto-selected in BookingBloc
    expect(bookingBloc.state, isA<BookingSlotsUpdated>());
    final state = bookingBloc.state as BookingSlotsUpdated;
    expect(state.selectedSlots.isNotEmpty, isTrue);
    expect(
        state.selectedSlots.any((s) => s.courtNumber == 1 && s.startTime == '19:00'),
        isTrue);
  });

  testWidgets(
      'VenueDetailScreen auto-selects both consecutive slots for 2-hour booking into BookingBloc',
      (tester) async {
    final venue = SeedData.sampleVenues.first;
    final bookingBloc = BookingBloc();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<BookingBloc>.value(value: bookingBloc),
        ],
        child: MaterialApp(
          home: VenueDetailScreen(
            venue: venue,
            initialDate: DateTime(2026, 9, 6),
            targetCourtNumber: 1,
            targetStartTime: '18:00',
            targetEndTime: '20:00',
            initialViewMode: 'court_map',
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(bookingBloc.state, isA<BookingSlotsUpdated>());
    final state = bookingBloc.state as BookingSlotsUpdated;
    final court1Slots = state.selectedSlots.where((s) => s.courtNumber == 1).toList();
    expect(court1Slots.length, 2);
    expect(court1Slots.any((s) => s.startTime == '18:00'), isTrue);
    expect(court1Slots.any((s) => s.startTime == '19:00'), isTrue);
  });

  testWidgets('VenueDetailScreen switches filter when targetSport is provided',
      (tester) async {
    final multiSportVenue = SeedData.sampleVenues.firstWhere(
      (v) => v.sportTypes.length > 1,
      orElse: () => SeedData.sampleVenues.first,
    );
    final targetSport = multiSportVenue.sportTypes.last;
    final courts = CourtSportPartition.getCourtsForSport(
      venue: multiSportVenue,
      sportType: targetSport,
    );
    final targetCourtNumber = courts.first;

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<BookingBloc>(create: (_) => BookingBloc()),
        ],
        child: MaterialApp(
          home: VenueDetailScreen(
            venue: multiSportVenue,
            targetCourtNumber: targetCourtNumber,
            targetSport: targetSport,
            initialViewMode: 'court_map',
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(Key('court_card_$targetCourtNumber')), findsOneWidget);
    // Court 1 is badminton, should not be present in pickleball/football view
    expect(find.byKey(const Key('court_card_1')), findsNothing);
  });

  testWidgets(
      'VenueDetailScreen clears highlight after pulse animation timeout',
      (tester) async {
    final venue = SeedData.sampleVenues.first;

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<BookingBloc>(create: (_) => BookingBloc()),
        ],
        child: MaterialApp(
          home: VenueDetailScreen(
            venue: venue,
            targetCourtNumber: 1,
            targetStartTime: '19:00',
            targetEndTime: '20:00',
            initialViewMode: 'court_map',
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('🎯 Sân AI gợi ý'), findsOneWidget);

    // Fast-forward past 4 seconds
    await tester.pump(const Duration(seconds: 5));

    // Highlight and badge should disappear
    expect(find.text('🎯 Sân AI gợi ý'), findsNothing);
  });
}
