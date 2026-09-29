import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/services/chatbot_service.dart';
import 'package:sporthub/core/state/auth_store.dart';
import 'package:sporthub/core/state/ticket_store.dart';
import 'package:sporthub/domain/entities/venue.dart';
import 'package:sporthub/presentation/blocs/booking/booking_bloc.dart';
import 'package:sporthub/presentation/widgets/chat/chat_message_bubble.dart';
import 'package:sporthub/presentation/widgets/chat/chatbot_bottom_sheet.dart';
import 'package:sporthub/presentation/widgets/chat/floating_chat_bubble.dart';

void main() {
  const testVenue = Venue(
    id: 'venue_01',
    name: 'CLB Cầu Lông Tao Đàn',
    sportTypes: ['badminton'],
    address: 'Số 1 Huyền Trân Công Chúa, Q.1',
    district: 'Quận 1',
    courtCount: 6,
    hourlyRate: 120000,
    rating: 4.8,
    reviewCount: 156,
    imageUrls: ['https://images.unsplash.com/photo-1544717305-2782549b5136?w=800'],
    amenities: ['Máy lạnh', 'WiFi', 'Căn tin'],
  );

  setUp(() {
    ChatbotService.instance.resetMessages();
    AuthStore.instance.reset();
  });

  group('FloatingChatBubble', () {
    testWidgets('renders and tapping it opens ChatbotBottomSheet', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: FloatingChatBubble(
              currentVenue: testVenue,
              currentRoute: '/venue-detail',
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('floating_chat_bubble')), findsOneWidget);
      await tester.tap(find.byKey(const Key('floating_chat_bubble')));
      await tester.pumpAndSettle();

      expect(find.byType(ChatbotBottomSheet), findsOneWidget);
      expect(find.text('Trợ lý AI SportHub'), findsOneWidget);
    });

    testWidgets('calls custom onTap when provided', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: FloatingChatBubble(
              currentVenue: testVenue,
              currentRoute: '/venue-detail',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('floating_chat_bubble')));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
      expect(find.byType(ChatbotBottomSheet), findsNothing);
    });
  });

  group('ChatbotBottomSheet', () {
    testWidgets('renders context banner with venue name and user name', (tester) async {
      final userName = AuthStore.instance.currentUser?.fullName ?? 'Nguyễn Văn A';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatbotBottomSheet(
              currentVenue: testVenue,
              currentRoute: '/venue-detail',
            ),
          ),
        ),
      );

      final bannerFinder = find.byKey(const Key('chatbot_context_banner'));
      expect(bannerFinder, findsOneWidget);
      expect(
        find.descendant(of: bannerFinder, matching: find.textContaining(testVenue.name)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: bannerFinder, matching: find.textContaining(userName)),
        findsOneWidget,
      );
    });

    testWidgets('renders context banner with guest label when user is guest', (tester) async {
      AuthStore.instance.continueAsGuest();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatbotBottomSheet(
              currentVenue: testVenue,
              currentRoute: '/venue-detail',
            ),
          ),
        ),
      );

      final bannerFinder = find.byKey(const Key('chatbot_context_banner'));
      expect(bannerFinder, findsOneWidget);
      expect(
        find.descendant(of: bannerFinder, matching: find.textContaining('Khách vãng lai')),
        findsOneWidget,
      );
    });

    testWidgets('quick prompt chip tap sends message to ChatbotService', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatbotBottomSheet(
              currentVenue: testVenue,
              currentRoute: '/venue-detail',
            ),
          ),
        ),
      );

      final chipFinder = find.text('Sân trống tối nay?');
      expect(chipFinder, findsOneWidget);

      await tester.tap(chipFinder);
      await tester.pumpAndSettle();

      // Verify message was sent to ChatbotService and chat bubbles are rendered
      expect(
        ChatbotService.instance.messagesNotifier.value
            .any((m) => m.text == 'Sân trống tối nay?'),
        isTrue,
      );
      expect(find.byType(ChatMessageBubble), findsWidgets);
    });

    testWidgets('text field input and send button sends message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatbotBottomSheet(
              currentVenue: testVenue,
              currentRoute: '/venue-detail',
            ),
          ),
        ),
      );

      final inputFinder = find.byKey(const Key('chat_input_field'));
      final sendFinder = find.byKey(const Key('btn_chat_send'));

      expect(inputFinder, findsOneWidget);
      expect(sendFinder, findsOneWidget);

      await tester.enterText(inputFinder, 'Giá thuê sân bao nhiêu?');
      await tester.tap(sendFinder);
      await tester.pumpAndSettle();

      expect(find.text('Giá thuê sân bao nhiêu?'), findsOneWidget);
      expect(
        ChatbotService.instance.messagesNotifier.value
            .any((m) => m.text == 'Giá thuê sân bao nhiêu?'),
        isTrue,
      );
    });

    testWidgets(
        'tapping "⚡ Đặt & Thanh toán VietQR ngay" triggers booking flow and adds ticket',
        (tester) async {
      final initialTicketCount = TicketStore.instance.tickets.length;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatbotBottomSheet(
              currentVenue: testVenue,
              currentRoute: '/venue-detail',
            ),
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('chat_input_field')),
        'Đặt sân 19h tối nay',
      );
      await tester.tap(find.byKey(const Key('btn_chat_send')));
      await tester.pumpAndSettle();

      final bookNowButton = find.byKey(const Key('btn_chat_book_now'));
      expect(bookNowButton, findsOneWidget);

      await tester.tap(bookNowButton);
      await tester.pumpAndSettle();

      if (find.text('Xác nhận đã chuyển').evaluate().isNotEmpty) {
        await tester.tap(find.text('Xác nhận đã chuyển'));
        await tester.pumpAndSettle();
      }

      expect(TicketStore.instance.tickets.length, equals(initialTicketCount + 1));
      expect(find.textContaining('thành công'), findsWidgets);
    });

    testWidgets('custom onBookNowAction is called when provided', (tester) async {
      Map<String, dynamic>? handledCard;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatbotBottomSheet(
              currentVenue: testVenue,
              currentRoute: '/venue-detail',
              onBookNowAction: (card) => handledCard = card,
            ),
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('chat_input_field')),
        'Đặt sân 19h',
      );
      await tester.tap(find.byKey(const Key('btn_chat_send')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_chat_book_now')));
      await tester.pumpAndSettle();

      expect(handledCard, isNotNull);
    });

    testWidgets('tapping "🔍 Xem trên sơ đồ" dismisses bottom sheet when opened via show',
        (tester) async {
      await tester.pumpWidget(
        BlocProvider(
          create: (_) => BookingBloc(),
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  key: const Key('open_sheet_button'),
                  onPressed: () => ChatbotBottomSheet.show(
                    context,
                    currentVenue: testVenue,
                    currentRoute: '/venue-detail',
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('open_sheet_button')));
      await tester.pumpAndSettle();

      expect(find.byType(ChatbotBottomSheet), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('chat_input_field')),
        'Đặt sân',
      );
      await tester.tap(find.byKey(const Key('btn_chat_send')));
      await tester.pumpAndSettle();

      final viewCourtMapButton = find.byKey(const Key('btn_chat_view_court_map'));
      expect(viewCourtMapButton, findsOneWidget);

      await tester.tap(viewCourtMapButton);
      await tester.pumpAndSettle();

      expect(find.byType(ChatbotBottomSheet), findsNothing);
    });

    testWidgets('custom onViewCourtMapAction is called when provided', (tester) async {
      Map<String, dynamic>? handledCard;

      await tester.pumpWidget(
        BlocProvider(
          create: (_) => BookingBloc(),
          child: MaterialApp(
            home: Scaffold(
              body: ChatbotBottomSheet(
                currentVenue: testVenue,
                onViewCourtMapAction: (card) => handledCard = card,
              ),
            ),
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('chat_input_field')),
        'Đặt sân',
      );
      await tester.tap(find.byKey(const Key('btn_chat_send')));
      await tester.pumpAndSettle();

      final viewCourtMapBtn = find.byKey(const Key('btn_chat_view_court_map'));
      expect(viewCourtMapBtn, findsOneWidget);

      await tester.tap(viewCourtMapBtn);
      await tester.pumpAndSettle();

      expect(handledCard, isNotNull);
      expect(handledCard!['court'], contains('Sân'));
    });

    testWidgets('FloatingChatBubble passes onViewCourtMapAction to sheet', (tester) async {
      Map<String, dynamic>? handledCard;

      await tester.pumpWidget(
        BlocProvider(
          create: (_) => BookingBloc(),
          child: MaterialApp(
            home: Scaffold(
              floatingActionButton: FloatingChatBubble(
                currentVenue: testVenue,
                currentRoute: '/venue-detail',
                onViewCourtMapAction: (card) => handledCard = card,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('floating_chat_bubble')));
      await tester.pumpAndSettle();

      expect(find.byType(ChatbotBottomSheet), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('chat_input_field')),
        'Đặt sân',
      );
      await tester.tap(find.byKey(const Key('btn_chat_send')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_chat_view_court_map')));
      await tester.pumpAndSettle();

      expect(handledCard, isNotNull);
    });
  });
}
