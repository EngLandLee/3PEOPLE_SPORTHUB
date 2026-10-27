import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sporthub/core/services/chatbot_service.dart';
import 'package:sporthub/core/state/auth_store.dart';
import 'package:sporthub/core/state/notification_store.dart';
import 'package:sporthub/core/state/ticket_store.dart';
import 'package:sporthub/core/utils/seed_data.dart';
import 'package:sporthub/presentation/blocs/booking/booking_bloc.dart';
import 'package:sporthub/presentation/widgets/auth_guard_sheet.dart';
import 'package:sporthub/presentation/widgets/chat/chat_booking_card.dart';
import 'package:sporthub/presentation/widgets/chat/chatbot_bottom_sheet.dart';
import 'package:sporthub/presentation/widgets/chat/floating_chat_bubble.dart';
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
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed; // 
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
    ChatbotService.instance.resetMessages();
    AuthStore.instance.reset();
  });

  testWidgets(
    'E2E Journey 1: Open chatbot from VenueDetailScreen -> Context detected -> Book slot -> Ticket created & Notified',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // 1. Authenticate user
      AuthStore.instance.loginWithDemo(SeedData.demoUsers.first);

      final venue = SeedData.sampleVenues[3]; // CLB Cầu Lông Tao Đàn - Quận 1

      await tester.pumpWidget(
        BlocProvider<BookingBloc>(
          create: (_) => BookingBloc(),
          child: MaterialApp(
            home: VenueDetailScreen(venue: venue),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 2. Locate and tap FloatingChatBubble
      expect(find.byType(FloatingChatBubble), findsOneWidget);
      await tester.tap(find.byKey(const Key('floating_chat_bubble')));
      await tester.pumpAndSettle();

      // 3. Confirm ChatbotBottomSheet is open with Context Awareness Banner
      expect(find.byType(ChatbotBottomSheet), findsOneWidget);
      final contextBanner = find.byKey(const Key('chatbot_context_banner'));
      expect(contextBanner, findsOneWidget);
      expect(
        find.descendant(of: contextBanner, matching: find.textContaining('Tao Đàn')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: contextBanner, matching: find.textContaining('Nguyễn Văn An')),
        findsOneWidget,
      );

      // 4. Send booking request in chat
      await tester.enterText(
        find.byKey(const Key('chat_input_field')),
        'Đặt sân cầu lông lúc 19h tối nay',
      );
      await tester.tap(find.byKey(const Key('btn_chat_send')));
      await tester.pumpAndSettle();

      // 5. Verify ChatBookingCard appears with correct details
      expect(find.byType(ChatBookingCard), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ChatBookingCard),
          matching: find.textContaining('19:00 - 20:00'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(ChatBookingCard),
          matching: find.textContaining(RegExp(r'120\.000|180\.000')),
        ),
        findsOneWidget,
      );

      final prevTicketCount = TicketStore.instance.tickets.length;

      // 6. Tap "⚡ Đặt & Thanh toán VietQR ngay"
      final bookNowBtn = find.byKey(const Key('btn_chat_book_now'));
      expect(bookNowBtn, findsOneWidget);
      await tester.tap(bookNowBtn);
      await tester.pumpAndSettle();

      // Verify VietQR dialog appears
      expect(find.byType(VietQrPaymentDialog), findsOneWidget);
      expect(find.text('Xác nhận đã chuyển'), findsOneWidget);

      // Confirm payment in VietQR dialog
      await tester.tap(find.text('Xác nhận đã chuyển'));
      await tester.pumpAndSettle();

      // 7. Verify Ticket was stored in TicketStore
      expect(TicketStore.instance.tickets.length, prevTicketCount + 1);
      final newTicket = TicketStore.instance.tickets.first;
      expect(newTicket.venueName, contains('Tao Đàn'));
      expect(newTicket.status, 'pending');
      expect(newTicket.startTime, '19:00');

      // 8. Verify Notification was logged in NotificationStore
      expect(
        NotificationStore.instance.notifications.any((n) =>
            n.title.contains('ghi nhận') || n.message.contains('chờ xác minh')),
        isTrue,
      );

      // 9. Verify chatbot displays payment confirmation message.
      expect(find.textContaining('thanh toán thành công!'), findsOneWidget);
    },
  );

  testWidgets(
    'E2E Journey 2: Guest user attempting to book via Chatbot triggers AuthGuardSheet',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Ensure Guest Mode
      AuthStore.instance.continueAsGuest();
      expect(AuthStore.instance.isGuest, isTrue);

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

      // Verify Context Banner shows Guest
      final contextBanner = find.byKey(const Key('chatbot_context_banner'));
      expect(
        find.descendant(of: contextBanner, matching: find.textContaining('Khách vãng lai')),
        findsOneWidget,
      );

      // Ask to book
      await tester.enterText(
        find.byKey(const Key('chat_input_field')),
        'Đặt sân 20h',
      );
      await tester.tap(find.byKey(const Key('btn_chat_send')));
      await tester.pumpAndSettle();

      // Tap Book now as guest
      await tester.tap(find.byKey(const Key('btn_chat_book_now')));
      await tester.pumpAndSettle();

      // Should display AuthGuardSheet
      expect(find.byType(AuthGuardSheet), findsOneWidget);
      expect(find.textContaining('Cần đăng nhập để tiếp tục'), findsOneWidget);
    },
  );

  testWidgets(
    'E2E Journey 3: Chatbot FAQ and Quick chips answering court policy and pricing',
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

      // 1. Tap quick prompt chip 'Sân trống tối nay?'
      final chipFinder = find.text('Sân trống tối nay?');
      expect(chipFinder, findsOneWidget);
      await tester.tap(chipFinder);
      await tester.pumpAndSettle();

      // Confirm chip sent message to chat
      expect(
        ChatbotService.instance.messagesNotifier.value.any((m) => m.text == 'Sân trống tối nay?'),
        isTrue,
      );

      // 2. Ask cancellation policy query in chat input
      await tester.enterText(
        find.byKey(const Key('chat_input_field')),
        'Chính sách hủy sân thế nào?',
      );
      await tester.tap(find.byKey(const Key('btn_chat_send')));
      await tester.pumpAndSettle();

      // Confirm policy answer
      expect(find.textContaining('Chính sách SportHub: Quý khách được phép hủy'), findsOneWidget);

      // 3. Ask pricing query in chat input
      await tester.enterText(
        find.byKey(const Key('chat_input_field')),
        'Giá thuê sân là bao nhiêu?',
      );
      await tester.tap(find.byKey(const Key('btn_chat_send')));
      await tester.pumpAndSettle();

      // Confirm pricing answer
      expect(find.textContaining('Giá thuê sân cầu lông dao động từ'), findsOneWidget);
    },
  );
}
