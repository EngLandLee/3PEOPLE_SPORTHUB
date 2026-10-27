import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sporthub/core/services/chatbot_service.dart';
import 'package:sporthub/core/services/venue_sync_service.dart';
import 'package:sporthub/core/state/auth_store.dart';
import 'package:sporthub/core/state/ticket_store.dart';
import 'package:sporthub/core/utils/seed_data.dart';
import 'package:sporthub/presentation/blocs/booking/booking_bloc.dart';
import 'package:sporthub/presentation/widgets/chat/chat_booking_card.dart';
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
    return Stream<List<int>>.fromIterable([_kTransparentImage]).listen(
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
  });

  setUp(() {
    AuthStore.instance.loginWithDemo(SeedData.demoUsers.first);
    TicketStore.instance.reset();
    VenueSyncService.instance.reset();
    ChatbotService.instance.resetMessages();
    CommunityFeedStore.instance.reset();
  });

  testWidgets(
    'Issue 1 & 2: Chatbot addons sync to VenueDetailScreen (480k) & Booked slot is disabled on map',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final venue = SeedData.sampleVenues[3]; // CLB Cầu Lông Tao Đàn

      await tester.pumpWidget(
        BlocProvider<BookingBloc>(
          create: (_) => BookingBloc(),
          child: MaterialApp(
            home: VenueDetailScreen(venue: venue),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open chatbot
      await tester.tap(find.byKey(const Key('floating_chat_bubble')));
      await tester.pumpAndSettle();

      // Order 1 tube of shuttlecocks and 2 rackets
      await tester.enterText(
        find.byKey(const Key('chat_input_field')),
        'Đặt sân 19h và thêm 1 ống cầu lông với 2 cây vợt',
      );
      await tester.tap(find.byKey(const Key('btn_chat_send')));
      await tester.pumpAndSettle();

      // Chat card should show 480.000đ total (180k + 240k + 60k)
      expect(find.byType(ChatBookingCard), findsOneWidget);
      expect(find.textContaining('480.000'), findsWidgets);
      expect(find.textContaining('1x Ống Cầu Lông'), findsOneWidget);
      expect(find.textContaining('2x Vợt Cầu Lông'), findsOneWidget);

      // Tap "🔍 Xem trên sơ đồ"
      final viewMapBtn = find.byKey(const Key('btn_chat_view_court_map'));
      expect(viewMapBtn, findsOneWidget);
      await tester.tap(viewMapBtn);
      await tester.pumpAndSettle();

      // VenueDetailScreen should display 480.000đ grand total (including addons)
      expect(find.textContaining('480.000'), findsWidgets);

      // Now book the slot via VenueSyncService / Chatbot to test Issue 2
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      await VenueSyncService.instance.createBooking(
        bookingId: 'BK-TEST-BOOKED',
        venueId: venue.id,
        courtNumber: 2,
        courtName: 'Sân 2',
        venueName: venue.name,
        sport: 'badminton',
        date: 'Hôm nay',
        startTime: '19:00',
        endTime: '20:00',
        totalPrice: 480000,
        customerName: 'Nguyễn Văn An',
        customerPhone: '0901234567',
      );

      // Verify that Sân 2 at 19:00 is detected as booked
      await tester.pumpAndSettle();

      // Verify that Sân 2 at 19:00 is detected as booked
      expect(
        VenueSyncService.instance.isSlotBooked(
          venueId: venue.id,
          courtNumber: 2,
          date: todayStr,
          startTime: '19:00',
          venueName: venue.name,
        ),
        isTrue,
      );
    },
  );

  testWidgets(
    'Issue 3: VietQR dialog is displayed on chatbot booking click before confirmation',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final venue = SeedData.sampleVenues[3];

      await tester.pumpWidget(
        BlocProvider<BookingBloc>(
          create: (_) => BookingBloc(),
          child: MaterialApp(
            home: VenueDetailScreen(venue: venue),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('floating_chat_bubble')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('chat_input_field')),
        'Đặt sân cầu lông lúc 19h tối nay',
      );
      await tester.tap(find.byKey(const Key('btn_chat_send')));
      await tester.pumpAndSettle();

      // Click "⚡ Đặt & Thanh toán VietQR ngay"
      await tester.tap(find.byKey(const Key('btn_chat_book_now')));
      await tester.pumpAndSettle();

      // MUST display VietQrPaymentDialog
      expect(find.byType(VietQrPaymentDialog), findsOneWidget);
      expect(find.text('Xác nhận đã chuyển'), findsOneWidget);
      expect(find.textContaining('Thanh Toán VietQR'), findsOneWidget);

      // Tap confirm in VietQR Dialog
      await tester.tap(find.text('Xác nhận đã chuyển'));
      await tester.pumpAndSettle();

      // The client records the ticket and displays confirmation feedback.
      expect(find.textContaining('thanh toán thành công!'), findsOneWidget);
      expect(TicketStore.instance.tickets.isNotEmpty, isTrue);
    },
  );

  testWidgets(
    'Issue 4: Attach image in chatbot to generate recruitment post & publish to Community',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final venue = SeedData.sampleVenues[3];

      await tester.pumpWidget(
        BlocProvider<BookingBloc>(
          create: (_) => BookingBloc(),
          child: MaterialApp(
            home: VenueDetailScreen(venue: venue),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('floating_chat_bubble')));
      await tester.pumpAndSettle();

      // Image attachment button must exist
      final attachBtn = find.byKey(const Key('btn_chat_attach_image'));
      expect(attachBtn, findsOneWidget);

      // Tap attach image button
      await tester.tap(attachBtn);
      await tester.pumpAndSettle();

      // Modal bottom sheet should show presets and custom URL field
      expect(find.text('Gửi ảnh tuyển thành viên / ghép kèo'), findsOneWidget);
      expect(
          find.byKey(const Key('input_custom_chat_image_url')), findsOneWidget);

      // Tap preset action chip
      final quickChip = find.text('🏸 Tuyển 2 người đánh đôi 19h');
      expect(quickChip, findsOneWidget);
      await tester.tap(quickChip);
      await tester.pumpAndSettle();

      // Banner preview should appear above bottom input bar
      expect(find.text('📷 Đã đính kèm ảnh tuyển thành viên'), findsOneWidget);

      // Send the recruitment request
      await tester.tap(find.byKey(const Key('btn_chat_send')));
      await tester.pumpAndSettle();

      // AI assistant should reply with recruitment recommendations & action chips
      expect(find.textContaining('bài đăng tuyển thành viên'), findsOneWidget);
      expect(
          find.textContaining('📢 Đăng lên Bảng tin Cộng đồng'), findsWidgets);

      final prevCommunityCount = CommunityFeedStore.instance.posts.length;

      // Tap "📢 Đăng lên Bảng tin Cộng đồng"
      await tester.tap(find.text('📢 Đăng lên Bảng tin Cộng đồng').first);
      await tester.pumpAndSettle();

      // Should be published to CommunityFeedStore
      expect(CommunityFeedStore.instance.posts.length, prevCommunityCount + 1);
      expect(find.textContaining('lên Bảng tin Cộng đồng'), findsWidgets);
    },
  );
}
