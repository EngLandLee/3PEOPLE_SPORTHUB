import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/domain/entities/chat_message.dart';
import 'package:sporthub/presentation/widgets/chat/chat_booking_card.dart';
import 'package:sporthub/presentation/widgets/chat/chat_message_bubble.dart';

void main() {
  final testActionCard = {
    'type': 'booking_card',
    'venueId': 'venue_01',
    'venueName': 'CLB Cầu Lông Tao Đàn',
    'sport': 'Cầu lông',
    'date': 'Hôm nay',
    'time': '19:00',
    'startTime': '19:00',
    'endTime': '20:00',
    'court': 'Sân 2',
    'price': 120000,
  };

  group('ChatBookingCard', () {
    testWidgets('renders venue, court, time, date, sport, and formatted price',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatBookingCard(
              actionCard: testActionCard,
              onBookNow: () {},
              onViewCourtMap: (_) {},
            ),
          ),
        ),
      );

      // Verify venue name
      expect(find.text('CLB Cầu Lông Tao Đàn'), findsOneWidget);

      // Verify court
      expect(find.text('Sân 2'), findsOneWidget);

      // Verify date & time slot
      expect(find.textContaining('19:00 - 20:00'), findsOneWidget);
      expect(find.textContaining('Hôm nay'), findsOneWidget);

      // Verify sport
      expect(find.text('Cầu lông'), findsOneWidget);

      // Verify price formatted
      expect(find.text('120.000 đ'), findsOneWidget);

      // Verify status chip "Còn trống"
      expect(find.text('Còn trống'), findsOneWidget);

      // Verify action buttons
      expect(find.byKey(const Key('btn_chat_book_now')), findsOneWidget);
      expect(find.text('Xác nhận giữ chỗ & Thanh toán VietQR'), findsOneWidget);
      expect(find.byKey(const Key('btn_chat_view_court_map')), findsOneWidget);
      expect(find.text('🔍 Xem trên sơ đồ'), findsOneWidget);
    });

    testWidgets('triggers onBookNow callback when primary button is tapped',
        (tester) async {
      bool bookNowTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatBookingCard(
              actionCard: testActionCard,
              onBookNow: () => bookNowTapped = true,
              onViewCourtMap: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('btn_chat_book_now')));
      await tester.pumpAndSettle();

      expect(bookNowTapped, isTrue);
    });

    testWidgets('triggers onViewCourtMap callback when secondary button is tapped',
        (tester) async {
      Map<String, dynamic>? receivedCard;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatBookingCard(
              actionCard: testActionCard,
              onBookNow: () {},
              onViewCourtMap: (card) => receivedCard = card,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('btn_chat_view_court_map')));
      await tester.pumpAndSettle();

      expect(receivedCard, equals(testActionCard));
    });

    testWidgets('renders fallback time and string price gracefully',
        (tester) async {
      final fallbackCard = {
        'type': 'booking_card',
        'venueName': 'Sân Bóng Đá Phú Nhuận',
        'court': 'Sân 5A',
        'sport': 'football',
        'date': 'Ngày mai',
        'time': '18:00',
        'price': '250.000 đ',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatBookingCard(
              actionCard: fallbackCard,
            ),
          ),
        ),
      );

      expect(find.text('Sân Bóng Đá Phú Nhuận'), findsOneWidget);
      expect(find.text('Sân 5A'), findsOneWidget);
      expect(find.textContaining('18:00'), findsOneWidget);
      expect(find.text('250.000 đ'), findsOneWidget);
    });
  });

  group('ChatMessageBubble', () {
    testWidgets('renders user message on right with avatar and timestamp',
        (tester) async {
      final userMessage = ChatMessage(
        id: 'msg_1',
        text: 'Tìm sân cầu lông trống lúc 19h tối nay',
        sender: 'user',
        timestamp: DateTime(2026, 9, 8, 18, 45),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageBubble(
              message: userMessage,
            ),
          ),
        ),
      );

      // Verify message text
      expect(find.text('Tìm sân cầu lông trống lúc 19h tối nay'), findsOneWidget);

      // Verify timestamp formatted
      expect(find.text('18:45'), findsOneWidget);

      // Verify user avatar
      expect(find.byIcon(Icons.person), findsOneWidget);

      // Verify no booking card rendered
      expect(find.byType(ChatBookingCard), findsNothing);
    });

    testWidgets('renders assistant message on left with AI avatar and text',
        (tester) async {
      final assistantMessage = ChatMessage(
        id: 'msg_2',
        text: 'Em có thể hỗ trợ anh/chị tìm sân phù hợp.',
        sender: 'assistant',
        timestamp: DateTime(2026, 9, 8, 18, 46),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageBubble(
              message: assistantMessage,
            ),
          ),
        ),
      );

      expect(find.text('Em có thể hỗ trợ anh/chị tìm sân phù hợp.'), findsOneWidget);
      expect(find.text('18:46'), findsOneWidget);

      // Verify AI icon (either smart_toy or auto_awesome)
      expect(
        find.byWidgetPredicate(
          (w) => w is Icon && (w.icon == Icons.smart_toy || w.icon == Icons.auto_awesome),
        ),
        findsOneWidget,
      );

      // No booking card
      expect(find.byType(ChatBookingCard), findsNothing);
    });

    testWidgets(
        'renders assistant message with embedded ChatBookingCard and forwards callbacks',
        (tester) async {
      final assistantMessageWithCard = ChatMessage(
        id: 'msg_3',
        text: 'Em đã tìm thấy sân trống phù hợp!',
        sender: 'assistant',
        timestamp: DateTime(2026, 9, 8, 19, 0),
        actionCard: testActionCard,
      );

      bool bookNowCalled = false;
      bool viewCourtMapCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ChatMessageBubble(
                message: assistantMessageWithCard,
                onBookNow: () => bookNowCalled = true,
                onViewCourtMap: (card) => viewCourtMapCalled = true,
              ),
            ),
          ),
        ),
      );

      // Message text is rendered
      expect(find.text('Em đã tìm thấy sân trống phù hợp!'), findsOneWidget);

      // ChatBookingCard is rendered
      expect(find.byType(ChatBookingCard), findsOneWidget);
      expect(find.text('CLB Cầu Lông Tao Đàn'), findsOneWidget);

      // Tap book now
      await tester.tap(find.byKey(const Key('btn_chat_book_now')));
      await tester.pumpAndSettle();
      expect(bookNowCalled, isTrue);

      // Tap view court map
      await tester.tap(find.byKey(const Key('btn_chat_view_court_map')));
      await tester.pumpAndSettle();
      expect(viewCourtMapCalled, isTrue);
    });
  });
}
