import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sporthub/presentation/blocs/booking/booking_bloc.dart';
import 'package:sporthub/core/utils/seed_data.dart';
import 'package:sporthub/presentation/widgets/time_slot_matrix.dart';
import 'package:sporthub/presentation/widgets/visual_court_header.dart';
import 'package:sporthub/main.dart';

final Uint8List _kTransparentImage = Uint8List.fromList(<int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
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

  testWidgets(
      'VenueDetailScreen renders gallery, amenities, date picker, addons, and policies',
      (tester) async {
    final venue = SeedData.sampleVenues.first;

    await tester.pumpWidget(
      BlocProvider(
        create: (_) => BookingBloc(),
        child: MaterialApp(
          home: VenueDetailScreen(venue: venue),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(venue.name), findsWidgets);
    expect(find.text('Dịch vụ & Thuê dụng cụ'), findsOneWidget);
    expect(find.text('Quy định sân & Chính sách'), findsOneWidget);
    expect(find.text('Đánh giá từ người chơi'), findsOneWidget);
  });

  testWidgets(
      'VenueDetailScreen displays gallery indicators and operating status',
      (tester) async {
    final venue = SeedData.sampleVenues.first;

    await tester.pumpWidget(
      BlocProvider(
        create: (_) => BookingBloc(),
        child: MaterialApp(
          home: VenueDetailScreen(venue: venue),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1/4'), findsOneWidget);
    expect(find.text('🟢 Đang mở cửa • 06:00 - 23:00'), findsOneWidget);
    expect(find.text(venue.hotline ?? '028 3511 8899'), findsOneWidget);
  });

  testWidgets(
      'Selecting add-on shows sticky bottom bar and opens VietQR dialog with itemized breakdown',
      (tester) async {
    final venue = SeedData.sampleVenues.first;

    await tester.pumpWidget(
      BlocProvider(
        create: (_) => BookingBloc(),
        child: MaterialApp(
          home: VenueDetailScreen(venue: venue),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Scroll to addon inc button
    final incBtn = find.byKey(const Key('addon_inc_rent_badminton'));
    await tester.scrollUntilVisible(
      incBtn,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(incBtn, findsOneWidget);
    await tester.tap(incBtn);
    await tester.pumpAndSettle();

    // Bottom bar should now be visible with 1 dịch vụ and 30.000 đ
    expect(find.text('1 dịch vụ'), findsOneWidget);
    expect(find.text('30.000 đ'), findsWidgets);
    expect(find.text('Thanh toán VietQR'), findsOneWidget);

    // Tap Thanh toán VietQR
    await tester.tap(find.text('Thanh toán VietQR'));
    await tester.pumpAndSettle();

    // Dialog should show breakdown
    expect(find.text('Thanh Toán VietQR'), findsOneWidget);
    expect(find.text('Tổng tiền: 30.000 đ'), findsOneWidget);
    expect(find.text('Chi tiết thanh toán:'), findsOneWidget);
    expect(find.text('• 1x Vợt Cầu Lông Yonex'), findsOneWidget);
    expect(find.text('⏱️ Giữ chỗ trong: 04:59'), findsOneWidget);

    // Advance 1 second and verify ticking countdown
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('⏱️ Giữ chỗ trong: 04:58'), findsOneWidget);

    // Advance another second
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('⏱️ Giữ chỗ trong: 04:57'), findsOneWidget);

    expect(find.text('Xác nhận đã chuyển'), findsOneWidget);

    // Confirm transfer
    await tester.tap(find.text('Xác nhận đã chuyển'));
    await tester.pumpAndSettle();

    // SnackBar appears
    expect(find.textContaining('thanh toán đang chờ xác minh'), findsOneWidget);
  });

  testWidgets(
      'VenueDetailScreen switches daily shifts dynamically and updates time slots',
      (tester) async {
    final venue = SeedData.sampleVenues.first;

    await tester.pumpWidget(
      BlocProvider(
        create: (_) => BookingBloc(),
        child: MaterialApp(
          home: VenueDetailScreen(venue: venue),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final shiftMorning = find.byKey(const Key('shift_morning'));
    await tester.scrollUntilVisible(
      shiftMorning,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    // Verify shift pills exist
    expect(shiftMorning, findsOneWidget);
    expect(find.byKey(const Key('shift_afternoon')), findsOneWidget);
    expect(find.byKey(const Key('shift_evening')), findsOneWidget);

    // Initial evening shift has 17:00 - 18:00
    expect(find.text('17:00 - 18:00'), findsWidgets);

    // Tap Morning shift
    await tester.tap(shiftMorning);
    await tester.pumpAndSettle();

    // Morning shift has 06:00 - 07:00
    expect(find.text('06:00 - 07:00'), findsWidgets);
    expect(find.text('17:00 - 18:00'), findsNothing);

    // Tap Afternoon shift
    await tester.tap(find.byKey(const Key('shift_afternoon')));
    await tester.pumpAndSettle();

    // Afternoon shift has 12:00 - 13:00
    expect(find.text('12:00 - 13:00'), findsWidgets);
    expect(find.text('06:00 - 07:00'), findsNothing);
  });

  testWidgets('VenueDetailScreen toggles half-hour minute offset :00 and :30',
      (tester) async {
    final venue = SeedData.sampleVenues.first;

    await tester.pumpWidget(
      BlocProvider(
        create: (_) => BookingBloc(),
        child: MaterialApp(
          home: VenueDetailScreen(venue: venue),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final minuteToggle30 = find.byKey(const Key('minute_toggle_30'));
    await tester.scrollUntilVisible(
      minuteToggle30,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    // Default is evening with :00
    expect(find.text('17:00 - 18:00'), findsWidgets);

    // Tap :30 toggle
    await tester.tap(minuteToggle30);
    await tester.pumpAndSettle();

    // Evening with :30 starts at 16:30 - 17:30
    expect(find.text('16:30 - 17:30'), findsWidgets);
    expect(find.text('17:00 - 18:00'), findsNothing);

    // Tap back to :00 toggle
    await tester.tap(find.byKey(const Key('minute_toggle_00')));
    await tester.pumpAndSettle();

    expect(find.text('17:00 - 18:00'), findsWidgets);
    expect(find.text('16:30 - 17:30'), findsNothing);
  });

  testWidgets(
      'VenueDetailScreen toggles between matrix view and 2D court overview map',
      (tester) async {
    final venue = SeedData.sampleVenues.first;

    await tester.pumpWidget(
      BlocProvider(
        create: (_) => BookingBloc(),
        child: MaterialApp(
          home: VenueDetailScreen(venue: venue),
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

    // Default view mode is matrix
    expect(find.byType(TimeSlotMatrix), findsOneWidget);

    // Tap 2D Court Overview Map toggle
    await tester.tap(courtMapToggle);
    await tester.pumpAndSettle();

    // Matrix should no longer be rendered
    expect(find.byType(TimeSlotMatrix), findsNothing);

    // VisualCourtHeaders rendered for court cards
    expect(find.byType(VisualCourtHeader), findsWidgets);
    expect(find.byKey(const Key('court_card_1')), findsOneWidget);
    expect(find.textContaining('slot trống'), findsWidgets);

    // Tap an available slot in the court overview map
    final availableSlotFinder = find.descendant(
      of: find.byKey(const Key('court_card_1')),
      matching: find.text('Còn trống'),
    ).first;
    await tester.ensureVisible(availableSlotFinder);
    await tester.tap(availableSlotFinder);
    await tester.pumpAndSettle();

    // Bottom sticky bar should appear with slot count
    expect(find.text('1 slot'), findsOneWidget);
    expect(find.text('Thanh toán VietQR'), findsOneWidget);

    // Switch back to matrix view
    final matrixToggle = find.byKey(const Key('view_mode_matrix'));
    await tester.ensureVisible(matrixToggle);
    await tester.tap(matrixToggle);
    await tester.pumpAndSettle();

    expect(find.byType(TimeSlotMatrix), findsOneWidget);
    expect(find.text('1 slot'), findsOneWidget);
  });
}
