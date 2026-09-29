import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sporthub/core/services/chatbot_service.dart';
import 'package:sporthub/core/state/ticket_store.dart';
import 'package:sporthub/data/models/ticket_model.dart';
import 'package:sporthub/domain/entities/chat_message.dart';

void main() {
  group('ChatMessage Entity Tests', () {
    test('constructs correctly and verifies helper getters', () {
      final now = DateTime.now();
      final userMsg = ChatMessage(
        id: 'msg_1',
        text: 'Xin chào',
        sender: 'user',
        timestamp: now,
      );

      expect(userMsg.id, 'msg_1');
      expect(userMsg.text, 'Xin chào');
      expect(userMsg.isUser, isTrue);
      expect(userMsg.isAssistant, isFalse);
      expect(userMsg.hasActionCard, isFalse);

      final assistantMsg = ChatMessage(
        id: 'msg_2',
        text: 'Em có thể giúp gì cho anh/chị?',
        sender: 'assistant',
        timestamp: now,
        actionCard: {'type': 'booking_card', 'venueId': 'venue_01'},
      );

      expect(assistantMsg.isUser, isFalse);
      expect(assistantMsg.isAssistant, isTrue);
      expect(assistantMsg.hasActionCard, isTrue);
      expect(assistantMsg.actionCard?['venueId'], 'venue_01');
    });

    test('serializes and deserializes ChatMessage via toJson and fromJson', () {
      final now = DateTime.parse('2026-09-08T19:00:00.000Z');
      final msg = ChatMessage(
        id: 'msg_test',
        text: 'Đặt sân cầu lông',
        sender: 'user',
        timestamp: now,
        actionCard: {'sport': 'badminton'},
      );

      final json = msg.toJson();
      expect(json['id'], 'msg_test');
      expect(json['text'], 'Đặt sân cầu lông');
      expect(json['sender'], 'user');
      expect(json['timestamp'], now.toIso8601String());
      expect(json['actionCard'], {'sport': 'badminton'});

      final parsed = ChatMessage.fromJson(json);
      expect(parsed.id, msg.id);
      expect(parsed.text, msg.text);
      expect(parsed.sender, msg.sender);
      expect(parsed.timestamp, msg.timestamp);
      expect(parsed.actionCard, msg.actionCard);
    });

    test('ChatMessage serializes and deserializes quickSuggestions', () {
      final msg = ChatMessage(
        id: '1',
        text: 'Gợi ý sân',
        sender: 'assistant',
        timestamp: DateTime.now(),
        quickSuggestions: ['🏸 Q.1', '🏓 Thảo Điền'],
      );
      final json = msg.toJson();
      expect(json['quickSuggestions'], equals(['🏸 Q.1', '🏓 Thảo Điền']));
      final fromJson = ChatMessage.fromJson(json);
      expect(fromJson.quickSuggestions, equals(['🏸 Q.1', '🏓 Thảo Điền']));
    });

    test('ChatMessage copyWith preserves or updates quickSuggestions', () {
      final msg = ChatMessage(
        id: '1',
        text: 'Gợi ý sân',
        sender: 'assistant',
        timestamp: DateTime.now(),
        quickSuggestions: ['🏸 Q.1'],
      );
      final copied = msg.copyWith(
        quickSuggestions: ['🏸 Q.1', '🏓 Thảo Điền'],
      );
      expect(copied.quickSuggestions, equals(['🏸 Q.1', '🏓 Thảo Điền']));
      expect(copied.id, '1');
    });
  });

  group('ChatContext Entity Tests', () {
    test('constructs and serializes ChatContext properly', () {
      final context = ChatContext(
        userId: 'user_01',
        userName: 'Nguyễn Văn An',
        userPhone: '0908123456',
        userRole: 'customer',
        currentRoute: '/venue-detail',
        venueId: 'venue_01',
        venueName: 'CLB Cầu Lông Tao Đàn',
        sport: 'Cầu lông',
        availableSlots: ['19:00 - 20:00', '20:00 - 21:00'],
      );

      final json = context.toJson();
      expect(json['userId'], 'user_01');
      expect(json['userName'], 'Nguyễn Văn An');
      expect(json['currentRoute'], '/venue-detail');
      expect(json['venueId'], 'venue_01');
      expect(json['venueName'], 'CLB Cầu Lông Tao Đàn');
      expect(json['sport'], 'Cầu lông');
      expect(json['availableSlots'], ['19:00 - 20:00', '20:00 - 21:00']);

      final parsed = ChatContext.fromJson(json);
      expect(parsed.userId, context.userId);
      expect(parsed.userName, context.userName);
      expect(parsed.venueId, context.venueId);
      expect(parsed.venueName, context.venueName);
      expect(parsed.sport, context.sport);
      expect(parsed.availableSlots, context.availableSlots);
    });

    test('supports alias keys in ChatContext.fromJson', () {
      final json = {
        'userId': 'u_99',
        'activeVenueId': 'venue_02',
        'activeVenueName': 'Sân Bóng Đá Kỳ Hòa',
        'selectedSport': 'Bóng đá',
      };

      final parsed = ChatContext.fromJson(json);
      expect(parsed.venueId, 'venue_02');
      expect(parsed.venueName, 'Sân Bóng Đá Kỳ Hòa');
      expect(parsed.sport, 'Bóng đá');
    });
  });

  group('ChatbotService Tests', () {
    late ChatbotService service;

    setUp(() {
      service = ChatbotService.instance;
      service.resetMessages();
      service.httpClient = null;
      service.currentContext = null;
    });

    tearDown(() {
      service.resetMessages();
      service.httpClient = null;
    });

    test('singleton instance maintains state and manages messages', () {
      expect(service, isNotNull);
      expect(service.messagesNotifier.value, isEmpty);

      final msg = ChatMessage(
        id: '1',
        text: 'test',
        sender: 'user',
        timestamp: DateTime.now(),
      );
      service.addMessage(msg);
      expect(service.messagesNotifier.value.length, 1);

      service.resetMessages();
      expect(service.messagesNotifier.value, isEmpty);
    });

    test('updateContext updates currentContext property', () {
      final context = ChatContext(
        userId: 'u_1',
        userName: 'Trần Bình',
        venueId: 'venue_01',
      );
      service.updateContext(context);
      expect(service.currentContext?.userName, 'Trần Bình');
      expect(service.currentContext?.venueId, 'venue_01');
    });

    test('sendMessage local engine handles booking intent with time and sport', () async {
      final context = ChatContext(
        userName: 'Lê Minh',
        venueId: 'venue_q1_04',
        venueName: 'CLB Cầu Lông Tao Đàn',
        sport: 'Cầu lông',
      );

      final assistantMsg = await service.sendMessage(
        'Tôi muốn đặt sân cầu lông lúc 19h tối nay',
        context: context,
      );

      // Verify messages appended to notifier
      expect(service.messagesNotifier.value.length, 2);
      expect(service.messagesNotifier.value[0].isUser, isTrue);
      expect(service.messagesNotifier.value[1].isAssistant, isTrue);

      // Verify assistant message
      expect(assistantMsg.isAssistant, isTrue);
      expect(assistantMsg.hasActionCard, isTrue);

      final card = assistantMsg.actionCard!;
      expect(card['type'], 'booking_card');
      expect(card['sport'], 'Cầu lông');
      expect(card['venueName'], 'CLB Cầu Lông Tao Đàn');
      expect(card['time'], '19:00');
      expect(card['startTime'], '19:00');
      expect(card['endTime'], '20:00');
      expect(card['court'], anyOf('Sân 1', 'Sân 2', 'Sân 3', 'Sân 4'));
      expect(card['price'], anyOf(120000, 180000));

      expect(assistantMsg.text, contains('CLB Cầu Lông Tao Đàn'));
      expect(assistantMsg.text, contains('19:00'));
      expect(assistantMsg.text, contains('VietQR'));
    });

    test('sendMessage extracts custom time with minutes and football sport', () async {
      final assistantMsg = await service.sendMessage(
        'Đặt sân bóng đá lúc 7h30 sáng mai',
      );

      expect(assistantMsg.hasActionCard, isTrue);
      final card = assistantMsg.actionCard!;
      expect(card['sport'], 'Bóng đá');
      expect(card['time'], '07:30');
      expect(card['startTime'], '07:30');
      expect(card['endTime'], '08:30');
    });

    test('sendMessage handles pricing FAQ question', () async {
      final assistantMsg = await service.sendMessage(
        'Giá thuê sân bao nhiêu tiền một giờ?',
      );

      expect(assistantMsg.isAssistant, isTrue);
      expect(assistantMsg.hasActionCard, isFalse);
      expect(assistantMsg.text, contains('dao động từ'));
      expect(assistantMsg.text, contains('100.000đ'));
    });

    test('sendMessage handles cancellation and policy question', () async {
      final assistantMsg = await service.sendMessage(
        'Chính sách hủy sân và hoàn tiền như thế nào?',
      );

      expect(assistantMsg.isAssistant, isTrue);
      expect(assistantMsg.hasActionCard, isFalse);
      expect(assistantMsg.text, contains('Chính sách SportHub'));
      expect(assistantMsg.text, contains('24 giờ'));
    });

    test('sendMessage handles greeting with user name in context', () async {
      final context = ChatContext(userName: 'Nguyễn Văn An');
      final assistantMsg = await service.sendMessage(
        'Chào bạn',
        context: context,
      );

      expect(assistantMsg.isAssistant, isTrue);
      expect(assistantMsg.text, contains('Chào anh/chị Nguyễn Văn An!'));
      expect(assistantMsg.text, contains('trợ lý AI SportHub'));
    });

    test('sendMessage handles generic greeting without user name', () async {
      final assistantMsg = await service.sendMessage('Hello');

      expect(assistantMsg.isAssistant, isTrue);
      expect(assistantMsg.text, contains('Xin chào!'));
      expect(assistantMsg.text, contains('trợ lý AI SportHub'));
    });

    test('sendMessage handles default unclassified question', () async {
      final assistantMsg = await service.sendMessage('Tôi có điều muốn hỏi');

      expect(assistantMsg.isAssistant, isTrue);
      expect(assistantMsg.text, contains('hỗ trợ anh/chị tìm sân trống'));
    });

    test('sendMessage handles realtime date/time query accurately', () async {
      final now = DateTime.now();
      final dateStr =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

      final assistantMsg = await service.sendMessage('hôm nay ngày bao nhiêu');

      expect(assistantMsg.isAssistant, isTrue);
      expect(assistantMsg.hasActionCard, isFalse);
      expect(assistantMsg.text, contains(dateStr));
      expect(assistantMsg.text, contains('Hôm nay là'));
    });

    test('sendMessage proxies to server endpoint when httpClient returns response', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/chatbot/message' && request.method == 'POST') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['message'], 'Server test message');
          expect(body['context']['userName'], 'VIP User');

          return http.Response(
            jsonEncode({
              'reply': 'Phản hồi từ AI Server',
              'actionCard': {'type': 'server_card', 'data': 123},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      service.httpClient = mockClient;
      final assistantMsg = await service.sendMessage(
        'Server test message',
        context: ChatContext(userName: 'VIP User'),
      );

      expect(assistantMsg.text, 'Phản hồi từ AI Server');
      expect(assistantMsg.hasActionCard, isTrue);
      expect(assistantMsg.actionCard?['type'], 'server_card');
    });

    test('sendMessage falls back to local engine when server returns error', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      service.httpClient = mockClient;
      final assistantMsg = await service.sendMessage(
        'Đặt sân cầu lông lúc 18h',
      );

      // Local engine fallback produced a booking card
      expect(assistantMsg.hasActionCard, isTrue);
      expect(assistantMsg.actionCard?['sport'], 'Cầu lông');
      expect(assistantMsg.actionCard?['time'], '18:00');
    });

    test('ChatbotService local fallback generates proactive card and quickSuggestions', () async {
      final reply = await service.sendMessage('tôi muốn đặt sân');
      expect(reply.hasActionCard, isTrue);
      expect(reply.quickSuggestions, isNotNull);
      expect(reply.quickSuggestions!.isNotEmpty, isTrue);
      expect(reply.quickSuggestions, contains('🏸 Cầu lông Q.1 (19h)'));
    });

    test('ChatbotService local fallback matches district keywords to target venues', () async {
      final btReply = await service.sendMessage('tôi muốn đặt sân ở Bình Thạnh');
      expect(btReply.actionCard?['venueId'], 'venue_bt_01');
      expect(btReply.actionCard?['venueName'], contains('Bình Thạnh'));

      final tdReply = await service.sendMessage('đặt sân ở Thảo Điền');
      expect(tdReply.actionCard?['venueId'], 'venue_td_02');
      expect(tdReply.actionCard?['venueName'], contains('Thảo Điền'));

      final q7Reply = await service.sendMessage('tìm sân bóng đá ở Quận 7');
      expect(q7Reply.actionCard?['venueId'], 'venue_q7_03');
      expect(q7Reply.actionCard?['sport'], 'Bóng đá');

      final tbReply = await service.sendMessage('đặt sân Tân Bình');
      expect(tbReply.actionCard?['venueId'], 'venue_tb_05');
      expect(tbReply.actionCard?['venueName'], contains('Tân Bình'));
    });

    test('sendMessage parses quickSuggestions from server response', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/chatbot/message') {
          return http.Response(
            jsonEncode({
              'reply': 'Gợi ý từ server',
              'quickSuggestions': ['🏸 Q.1', '🏓 Thảo Điền'],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      service.httpClient = mockClient;
      final reply = await service.sendMessage('Gợi ý sân cho tôi');
      expect(reply.quickSuggestions, equals(['🏸 Q.1', '🏓 Thảo Điền']));
    });

    test('notifyBookingPaid updates previous booking card and appends confirmation message', () async {
      service.resetMessages();
      service.httpClient = null;

      // User asks to book court
      await service.sendMessage('Đặt sân Thảo Điền Pickleball lúc 19h');
      expect(service.messagesNotifier.value.length, 2);
      final initialCard = service.messagesNotifier.value[1].actionCard;
      expect(initialCard?['isPaid'], isNot(true));

      final testTicket = TicketModel(
        id: 'ticket_test_123',
        bookingId: 'BK-1790128459401',
        venueName: 'Thảo Điền Pickleball Hub',
        sportType: 'pickleball',
        courtNumber: 2,
        matchDate: '2026-09-23',
        startTime: '19:00',
        endTime: '20:00',
        totalPrice: 220000,
        qrCodeData: 'SPORTHUB|BK-1790128459401|220000',
        status: 'paid',
        createdAt: '2026-09-23T08:55:00Z',
        district: 'Thủ Đức',
      );

      service.notifyBookingPaid(testTicket);

      // Verify previous card updated to isPaid = true and bookingId set
      final updatedCard = service.messagesNotifier.value[1].actionCard;
      expect(updatedCard?['isPaid'], isTrue);
      expect(updatedCard?['bookingId'], 'BK-1790128459401');

      // Verify new confirmation message appended
      expect(service.messagesNotifier.value.length, 3);
      final confirmMsg = service.messagesNotifier.value[2];
      expect(confirmMsg.isAssistant, isTrue);
      expect(confirmMsg.text, contains('Xác nhận thanh toán thành công'));
      expect(confirmMsg.text, contains('BK-1790128459401'));
      expect(confirmMsg.text, contains('Thảo Điền Pickleball Hub'));
      expect(confirmMsg.text, contains('220.000'));
      expect(confirmMsg.actionCard?['isPaid'], isTrue);
      expect(confirmMsg.quickSuggestions, contains('🎫 Xem vé của tôi'));
    });

    test('TicketStore.instance.addTicket triggers notifyBookingPaid automatically', () {
      service.resetMessages();

      final ticket = TicketModel(
        id: 'ticket_store_auto',
        bookingId: 'BK-AUTO-888',
        venueName: 'CLB Cầu Lông Tao Đàn',
        sportType: 'badminton',
        courtNumber: 1,
        matchDate: '2026-09-23',
        startTime: '18:00',
        endTime: '19:00',
        totalPrice: 180000,
        qrCodeData: 'SPORTHUB|BK-AUTO-888|180000',
        status: 'paid',
        createdAt: '2026-09-23T08:55:00Z',
        district: 'Quận 1',
      );

      TicketStore.instance.addTicket(ticket);

      final msgs = service.messagesNotifier.value;
      expect(msgs.isNotEmpty, isTrue);
      expect(msgs.last.text, contains('BK-AUTO-888'));
      expect(msgs.last.text, contains('Xác nhận thanh toán thành công'));
    });

    test('sendMessage handles payment confirmation query when paid ticket exists', () async {
      service.resetMessages();
      service.httpClient = null;

      final ticket = TicketModel(
        id: 'ticket_query_test',
        bookingId: 'BK-QUERY-999',
        venueName: 'Thảo Điền Pickleball Hub',
        sportType: 'pickleball',
        courtNumber: 2,
        matchDate: '2026-09-23',
        startTime: '19:00',
        endTime: '20:00',
        totalPrice: 220000,
        qrCodeData: 'SPORTHUB|BK-QUERY-999|220000',
        status: 'paid',
        createdAt: '2026-09-23T08:55:00Z',
        district: 'Thủ Đức',
      );
      TicketStore.instance.addTicket(ticket);

      final reply = await service.sendMessage('tôi vừa thanh toán rồi');
      expect(reply.isAssistant, isTrue);
      expect(reply.text, contains('BK-QUERY-999'));
      expect(reply.text, contains('Thảo Điền Pickleball Hub'));
      expect(reply.hasActionCard, isTrue);
      expect(reply.actionCard?['isPaid'], isTrue);
    });

    test('sanitizeServerActionCard switches booked Sân 1 to Sân 2 with 420k price for Nam Sài Gòn at 19:30', () {
      final rawCard = {
        'type': 'booking_card',
        'venueId': 'venue_q7_03',
        'venueName': 'Sân Bóng Đá Mini Nam Sài Gòn',
        'sport': 'Bóng đá',
        'court': 'Sân 1',
        'date': 'Hôm nay',
        'time': '19:30',
        'startTime': '19:30',
        'endTime': '20:30',
        'price': 380000,
      };

      final (sanitized, reply) = ChatbotService.sanitizeServerActionCard(
        rawCard,
        originalReply: 'Em đã chọn cho mình Sân 1 với giá 380.000đ nhé!',
      );

      expect(sanitized, isNotNull);
      expect(sanitized?['court'], 'Sân 2');
      expect(sanitized?['price'], 420000);
      expect(reply, contains('Sân 2'));
      expect(reply, contains('420.000đ'));
    });

    test('sendMessage sanitizes server response when Sân 1 is booked', () async {
      service.resetMessages();
      service.httpClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'reply': 'Em đã chọn Sân 1 giá 380.000đ ạ',
            'actionCard': {
              'type': 'booking_card',
              'venueId': 'venue_q7_03',
              'venueName': 'Sân Bóng Đá Mini Nam Sài Gòn',
              'sport': 'Bóng đá',
              'court': 'Sân 1',
              'date': 'Hôm nay',
              'time': '19:30',
              'startTime': '19:30',
              'endTime': '20:30',
              'price': 380000,
            },
            'quickSuggestions': ['⚡ Đặt ngay'],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final reply = await service.sendMessage('đặt sân bóng đá Quận 7 lúc 19h30');
      expect(reply.actionCard?['court'], 'Sân 2');
      expect(reply.actionCard?['price'], 420000);
      expect(reply.text, contains('Sân 2'));
      expect(service.pendingBooking?['court'], 'Sân 2');
      expect(service.pendingBooking?['price'], 420000);
    });
  });
}
