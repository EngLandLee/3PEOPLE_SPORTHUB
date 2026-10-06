import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/services/chatbot_service.dart';
import 'package:sporthub/presentation/widgets/chat/chat_message_bubble.dart';
import 'package:sporthub/presentation/widgets/chat/chat_table_card.dart';

void main() {
  group('ChatTableCard Widget & Owner Table Tests', () {
    testWidgets('ChatTableCard renders headers, rows, and status badges',
        (tester) async {
      final sampleTable = {
        'type': 'table_card',
        'title': 'Bảng Vé Chờ Check-in',
        'subtitle': 'Lịch đón khách hôm nay',
        'icon': 'ticket',
        'headers': ['Mã vé', 'Khách hàng', 'Sân & Môn', 'Giờ', 'Trạng thái'],
        'rows': [
          ['SH-8291', 'Nguyễn Văn An', 'Sân 1 (Cầu lông)', '18:00', 'Chờ check-in'],
          ['SH-8292', 'Trần Thuỳ Linh', 'Sân 1 (Cầu lông)', '19:00', 'Chờ check-in'],
        ],
        'footer': '💡 Bấm mục Soát vé QR để quét mã nhanh.',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ChatTableCard(cardData: sampleTable),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('chat_table_card')), findsOneWidget);
      expect(find.text('Bảng Vé Chờ Check-in'), findsOneWidget);
      expect(find.text('Mã vé'), findsOneWidget);
      expect(find.text('SH-8291'), findsOneWidget);
      expect(find.text('Nguyễn Văn An'), findsOneWidget);
      expect(find.text('Chờ check-in'), findsNWidgets(2));
      expect(find.text('💡 Bấm mục Soát vé QR để quét mã nhanh.'), findsOneWidget);
    });

    testWidgets('ChatMessageBubble renders ChatTableCard when actionCard type is table_card',
        (tester) async {
      final msg = ChatMessage(
        id: 'msg_table_bubble_test',
        text: 'Dưới đây là bảng doanh thu hôm nay:',
        sender: 'assistant',
        timestamp: DateTime.now(),
        actionCard: const {
          'type': 'table_card',
          'title': 'Bảng Phân Tích Doanh Thu',
          'headers': ['Kênh', 'Lượt', 'Doanh thu'],
          'rows': [
            ['SportHub App', '4', '940.000đ'],
            ['TỔNG', '4', '940.000đ'],
          ],
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageBubble(
              message: msg,
              enableAnimation: false,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('chat_table_card')), findsOneWidget);
      expect(find.text('Bảng Phân Tích Doanh Thu'), findsOneWidget);
      expect(find.text('SportHub App'), findsOneWidget);
      expect(find.text('940.000đ'), findsNWidgets(2));
    });

    test('ChatbotService owner queries generate table_card actionCard', () async {
      final service = ChatbotService.instance;
      service.resetMessages();

      // 1. Revenue query
      final revReply = await service.sendMessage(
        'Xem doanh thu hôm nay',
        context: const ChatContext(userRole: 'owner', venueId: 'venue_01'),
      );
      expect(revReply.actionCard, isNotNull);
      expect(revReply.actionCard!['type'], 'table_card');
      expect(revReply.actionCard!['title'], contains('Doanh Thu'));

      // 2. Check-in query
      final checkinReply = await service.sendMessage(
        'Có bao nhiêu vé chờ check-in?',
        context: const ChatContext(userRole: 'owner', venueId: 'venue_01'),
      );
      expect(checkinReply.actionCard, isNotNull);
      expect(checkinReply.actionCard!['type'], 'table_card');
      expect(checkinReply.actionCard!['title'], contains('Check-in'));

      // 3. Court status query
      final courtReply = await service.sendMessage(
        'Tình trạng sân hôm nay thế nào',
        context: const ChatContext(userRole: 'owner', venueId: 'venue_01'),
      );
      expect(courtReply.actionCard, isNotNull);
      expect(courtReply.actionCard!['type'], 'table_card');
      expect(courtReply.actionCard!['title'], contains('Tình Trạng'));

      // 4. Policy query
      final policyReply = await service.sendMessage(
        'Chính sách hoàn hủy sân',
        context: const ChatContext(userRole: 'owner', venueId: 'venue_01'),
      );
      expect(policyReply.actionCard, isNotNull);
      expect(policyReply.actionCard!['type'], 'table_card');
      expect(policyReply.actionCard!['title'], contains('Hoàn Tiền'));
    });
  });
}
