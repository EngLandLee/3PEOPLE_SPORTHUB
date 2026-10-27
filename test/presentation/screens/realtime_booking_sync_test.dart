import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sporthub/presentation/blocs/booking/booking_bloc.dart';
import 'package:sporthub/core/state/auth_store.dart';
import 'package:sporthub/core/state/ticket_store.dart';
import 'package:sporthub/core/state/venue_owner_store.dart';
import 'package:sporthub/core/services/venue_sync_service.dart';
import 'package:sporthub/core/utils/seed_data.dart';
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
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

class _MockHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();
  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
}

class _MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => HttpStatus.ok;
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

  setUp(() {
    AuthStore.instance.reset();
    TicketStore.instance.reset();
    VenueOwnerStore.instance.reset();
    VenueSyncService.instance.reset();
  });

  testWidgets(
      'Booking flow updates slot status to Đã đặt, displays modal with options, and syncs with owner store',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final venue =
        SeedData.sampleVenues.firstWhere((v) => v.id == 'venue_q1_04');

    await tester.pumpWidget(
      BlocProvider(
        create: (_) => BookingBloc(),
        child: MaterialApp(
          home: VenueDetailScreen(venue: venue),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Find an available slot on Court Matrix
    final availableSlotFinder = find.text('Còn trống');
    expect(availableSlotFinder, findsWidgets);

    // Tap first available slot
    await tester.tap(availableSlotFinder.first, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Verify booking sticky bar appears
    final payBtn = find.text('Thanh toán VietQR');
    expect(payBtn, findsOneWidget);

    await tester.tap(payBtn);
    await tester.pumpAndSettle();

    // Confirm payment
    final confirmBtn = find.text('Xác nhận đã chuyển');
    expect(confirmBtn, findsOneWidget);

    await tester.tap(confirmBtn);
    await tester.pumpAndSettle();

    // Verify Success Modal appears
    expect(find.text('Đã ghi nhận yêu cầu đặt sân'), findsOneWidget);
    expect(find.byKey(const Key('btn_stay_on_venue_detail')), findsOneWidget);
    expect(find.byKey(const Key('btn_go_to_tickets')), findsOneWidget);

    // Tap 'Ở lại xem sân'
    await tester.tap(find.byKey(const Key('btn_stay_on_venue_detail')));
    await tester.pumpAndSettle();

    // Modal is dismissed, user is back on VenueDetailScreen
    expect(find.text('Đặt Sân Thành Công! 🎉'), findsNothing);

    // Slot is now marked as 'Đã đặt'
    expect(find.text('Đã đặt'), findsWidgets);

    // VenueSyncService has recorded the booking
    expect(VenueSyncService.instance.bookingsNotifier.value.isNotEmpty, isTrue);

    // TicketStore has stored the ticket
    expect(TicketStore.instance.tickets.length, greaterThan(3));
  });
}
