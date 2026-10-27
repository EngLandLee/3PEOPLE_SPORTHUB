import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sporthub/presentation/blocs/booking/booking_bloc.dart';
import 'package:sporthub/core/utils/seed_data.dart';
import 'package:sporthub/core/state/ticket_store.dart';
import 'package:sporthub/core/state/auth_store.dart';
import 'package:sporthub/main.dart';

final Uint8List _kTransparentImage = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
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

Finder _verticalScrollable() => find.byWidgetPredicate(
  (w) => w is Scrollable && (w.axisDirection == AxisDirection.down || w.axisDirection == AxisDirection.up),
).first;

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  setUp(() {
    AuthStore.instance.reset();
  });

  testWidgets('VenueDetailScreen dynamically renders real-time date starting today', (tester) async {
    final venue = SeedData.sampleVenues.first;
    final testDate = DateTime(2026, 10, 15);

    await tester.pumpWidget(
      BlocProvider(
        create: (_) => BookingBloc(),
        child: MaterialApp(
          home: VenueDetailScreen(venue: venue, initialDate: testDate),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Month and year header reflects 10/2026
    expect(find.text('Tháng 10/2026'), findsOneWidget);
    // Day 0 is 'Hôm nay' with day 15
    expect(find.text('Hôm nay'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
    // Day 1 is 16
    expect(find.text('16'), findsOneWidget);
  });

  testWidgets('VenueDetailScreen toggles between flexible and fixed schedule mode', (tester) async {
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

    // Scroll to mode tabs
    final fixedTab = find.byKey(const Key('booking_mode_fixed'));
    await tester.scrollUntilVisible(
      fixedTab,
      150,
      scrollable: _verticalScrollable(),
    );
    await tester.pumpAndSettle();

    // Both tabs exist
    final flexibleTab = find.byKey(const Key('booking_mode_flexible'));
    expect(flexibleTab, findsOneWidget);
    expect(fixedTab, findsOneWidget);

    // Tap Fixed Schedule Tab
    await tester.tap(fixedTab);
    await tester.pumpAndSettle();

    // Now fixed schedule section is visible, flexible date picker is hidden
    expect(find.text('Chọn ngày đặt sân'), findsNothing);
    expect(find.text('Đăng ký lịch cố định CLB & Đội'), findsOneWidget);
    expect(find.text('Lịch tập trong tuần'), findsOneWidget);
    expect(find.text('Khung giờ cố định (2 giờ / ca)'), findsOneWidget);
    expect(find.text('Tóm tắt hợp đồng cố định'), findsOneWidget);

    // Switch back to flexible
    await tester.tap(flexibleTab);
    await tester.pumpAndSettle();

    expect(find.text('Chọn ngày đặt sân'), findsOneWidget);
    expect(find.text('Đăng ký lịch cố định CLB & Đội'), findsNothing);
  });

  testWidgets('Fixed schedule section updates total sessions, pricing, and discounts when weekdays and duration change', (tester) async {
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

    // Scroll to and switch to fixed mode
    final fixedTab = find.byKey(const Key('booking_mode_fixed'));
    await tester.scrollUntilVisible(
      fixedTab,
      150,
      scrollable: _verticalScrollable(),
    );
    await tester.pumpAndSettle();
    await tester.tap(fixedTab);
    await tester.pumpAndSettle();

    // Default: T2, T4, T6 (3 days) x 1 month (4 weeks) = 12 sessions
    expect(find.text('3 buổi / tuần'), findsOneWidget);
    expect(find.text('12 buổi'), findsWidgets);

    // Scroll to package cards
    final duration3 = find.byKey(const Key('fixed_duration_3'));
    await tester.scrollUntilVisible(
      duration3,
      100,
      scrollable: _verticalScrollable(),
    );
    await tester.pumpAndSettle();

    // Tap 3 Months package
    await tester.tap(duration3);
    await tester.pumpAndSettle();

    // 3 days x 12 weeks = 36 sessions
    expect(find.text('36 buổi'), findsWidgets);
    expect(find.text('Ưu đãi gói (15%):'), findsOneWidget);

    // Tap 6 Months package
    final duration6 = find.byKey(const Key('fixed_duration_6'));
    await tester.tap(duration6);
    await tester.pumpAndSettle();

    // 3 days x 24 weeks = 72 sessions
    expect(find.text('72 buổi'), findsWidgets);
    expect(find.text('Ưu đãi gói (20%):'), findsOneWidget);
  });

  testWidgets('Fixed schedule VietQR checkout creates BK-FIXED ticket with badge and notification', (tester) async {
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

    // Scroll to and switch to fixed mode
    final fixedTab = find.byKey(const Key('booking_mode_fixed'));
    await tester.scrollUntilVisible(
      fixedTab,
      150,
      scrollable: _verticalScrollable(),
    );
    await tester.pumpAndSettle();
    await tester.tap(fixedTab);
    await tester.pumpAndSettle();

    // Scroll to checkout button
    final checkoutBtn = find.byKey(const Key('btn_fixed_checkout'));
    await tester.scrollUntilVisible(
      checkoutBtn,
      150,
      scrollable: _verticalScrollable(),
    );
    await tester.pumpAndSettle();

    expect(checkoutBtn, findsOneWidget);
    await tester.tap(checkoutBtn);
    await tester.pumpAndSettle();

    // Dialog opens with fixed title and contract details
    expect(find.text('Thanh Toán Lịch Cố Định'), findsOneWidget);
    expect(find.text('🔄 Thông tin hợp đồng cố định:'), findsOneWidget);
    expect(find.text('• Khung giờ:'), findsOneWidget);
    expect(find.text('⏱️ Giữ chỗ trong: 04:59'), findsOneWidget);

    // Confirm payment
    final confirmBtn = find.text('Xác nhận đã chuyển');
    await tester.tap(confirmBtn);
    await tester.pumpAndSettle();

    // SnackBar appears
    expect(find.textContaining('thanh toán đang chờ xác minh'), findsOneWidget);

    // Verify ticket stored with BK-FIXED
    final fixedTicket = TicketStore.instance.tickets.firstWhere(
      (t) => t.bookingId.startsWith('BK-FIXED'),
    );
    expect(fixedTicket, isNotNull);
    expect(fixedTicket.matchDate, contains('Cố định:'));
  });
}
