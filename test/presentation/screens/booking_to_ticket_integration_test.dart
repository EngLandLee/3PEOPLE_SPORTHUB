import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sporthub/presentation/blocs/booking/booking_bloc.dart';
import 'package:sporthub/core/state/auth_store.dart';
import 'package:sporthub/core/state/ticket_store.dart';
import 'package:sporthub/core/utils/seed_data.dart';
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
  });

  testWidgets('Booking a football venue shows dynamic football VietQR copy and stores ticket in TicketStore', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Football venue (Sân Bóng Đá Mini Nam Sài Gòn)
    final footballVenue = SeedData.sampleVenues.firstWhere((v) => v.id == 'venue_q7_03');

    await tester.pumpWidget(
      BlocProvider(
        create: (_) => BookingBloc(),
        child: MaterialApp(
          home: VenueDetailScreen(venue: footballVenue),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Scroll to football addon
    final incBtn = find.byKey(const Key('addon_inc_rent_football_ball'));
    await tester.scrollUntilVisible(
      incBtn,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(incBtn, findsOneWidget);
    await tester.tap(incBtn);
    await tester.pumpAndSettle();

    // Verify sticky bottom bar appeared with VietQR checkout button
    final payButtonFinder = find.text('Thanh toán VietQR');
    expect(payButtonFinder, findsOneWidget);

    // Tap payment button
    await tester.tap(payButtonFinder);
    await tester.pumpAndSettle();

    // Verify VietQR dialog
    expect(find.text('Thanh Toán VietQR'), findsOneWidget);
    expect(find.textContaining('• 1x Bóng Đá Thi Đấu Động Lực'), findsOneWidget);

    final initialTicketCount = TicketStore.instance.tickets.length;

    // Confirm payment
    final confirmButton = find.text('Xác nhận đã chuyển');
    expect(confirmButton, findsOneWidget);
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    // Verify ticket count increased and newly created ticket has sportType 'football'
    expect(TicketStore.instance.tickets.length, initialTicketCount + 1);
    final latestTicket = TicketStore.instance.tickets.first;
    expect(latestTicket.sportType, 'football');
    expect(latestTicket.venueName, footballVenue.name);
    expect(latestTicket.status, 'pending');

    // Verify SnackBar was shown
    expect(find.textContaining('thanh toán đang chờ'), findsOneWidget);
  });
}
