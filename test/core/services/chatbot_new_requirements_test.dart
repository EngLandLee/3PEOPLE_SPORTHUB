import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sporthub/core/services/chatbot_service.dart';
import 'package:sporthub/core/state/venue_chat_store.dart';
import 'package:sporthub/core/utils/seed_data.dart';
import 'package:sporthub/presentation/blocs/booking/booking_bloc.dart';
import 'package:sporthub/main.dart';

void main() {
  setUp(() {
    ChatbotService.instance.resetMessages();
    VenueChatStore.instance.reset();
  });

  group('Chatbot Greetings & Intent Guard', () {
    test('Pure greetings return polite reply with NO booking action card', () async {
      final reply1 = await ChatbotService.instance.sendMessage('Xin chào');
      expect(reply1.actionCard, isNull);
      expect(reply1.text.toLowerCase(), contains('chào'));

      final reply2 = await ChatbotService.instance.sendMessage('Hello');
      expect(reply2.actionCard, isNull);

      final reply3 = await ChatbotService.instance.sendMessage('Chào bạn');
      expect(reply3.actionCard, isNull);
    });

    test('Greeting does not trigger booking card even with sport context', () async {
      final reply = await ChatbotService.instance.sendMessage(
        'Chào bạn nha',
        context: const ChatContext(
          preferredSport: 'Cầu lông',
          sport: 'Cầu lông',
        ),
      );
      expect(reply.actionCard, isNull);
      expect(reply.text.toLowerCase(), contains('chào'));
    });
  });

  group('Community Recruitment with Numbers and Free-form text', () {
    test('"Tuyển 2 thành viên đánh đôi cầu lông" creates recruitment_card, NOT booking_card', () async {
      final reply = await ChatbotService.instance.sendMessage(
        'Tuyển 2 thành viên đánh đôi cầu lông',
      );

      expect(reply.actionCard, isNotNull);
      expect(reply.actionCard!['type'], equals('recruitment_card'));
      expect(reply.actionCard!['sportType'], equals('badminton'));
      expect(reply.actionCard!['requiredPlayers'], equals(4));
      expect(reply.actionCard!['currentPlayers'], equals(2));
      expect(reply.text, contains('bài đăng tuyển thành viên'));
    });

    test('"Ghép kèo Pickleball 2.5 - 3.0" creates recruitment_card for Pickleball', () async {
      final reply = await ChatbotService.instance.sendMessage(
        'Ghép kèo Pickleball 2.5 - 3.0',
      );

      expect(reply.actionCard, isNotNull);
      expect(reply.actionCard!['type'], equals('recruitment_card'));
      expect(reply.actionCard!['sportType'], equals('pickleball'));
    });
  });

  group('Time Slot Modification', () {
    test('User requests to change time ("đổi sang 20h") updates booking card to 20:00', () async {
      // 1. Initial booking query
      await ChatbotService.instance.sendMessage('Đặt sân cầu lông Tao Đàn');
      expect(ChatbotService.instance.pendingBooking, isNotNull);

      // 2. Change time slot
      final reply = await ChatbotService.instance.sendMessage('Đổi sang 20h');
      expect(reply.actionCard, isNotNull);
      expect(reply.actionCard!['startTime'], equals('20:00'));
      expect(reply.actionCard!['endTime'], equals('21:00'));
      expect(reply.text, contains('20:00'));
    });

    test('User requests range ("chuyển sang 19h30 - 21h30") updates booking card duration', () async {
      await ChatbotService.instance.sendMessage('Đặt sân cầu lông Tao Đàn');

      final reply = await ChatbotService.instance.sendMessage('Chuyển sang 19h30 - 21h30');
      expect(reply.actionCard, isNotNull);
      expect(reply.actionCard!['startTime'], equals('19:30'));
      expect(reply.actionCard!['endTime'], equals('21:30'));
      expect(reply.actionCard!['durationHours'], equals(2.0));
    });

    test('User requests "đổi sang 14h đi" updates both booking card and action proposal to 14:00 - 15:00', () async {
      await ChatbotService.instance.sendMessage('Đặt sân cầu lông Tao Đàn');

      final reply = await ChatbotService.instance.sendMessage('đổi sang 14h đi');
      expect(reply.actionCard, isNotNull);
      expect(reply.actionCard!['startTime'], equals('14:00'));
      expect(reply.actionCard!['endTime'], equals('15:00'));
      expect(reply.hasProposal, isTrue);
      expect(reply.proposal!.target['timeSlot'], equals('14:00 - 15:00'));
      final timeSlotField = reply.proposal!.form.firstWhere((f) => f.key == 'timeSlot');
      expect(timeSlotField.currentValue, equals('14:00 - 15:00'));
      expect(reply.text, contains('14:00 - 15:00'));
      expect(reply.text, isNot(contains('không thể thực hiện')));
    });
  });

  group('User <-> Venue Owner Direct Chat (VenueChatStore)', () {
    test('Customer sends message and owner receives in thread', () {
      VenueChatStore.instance.sendMessage(
        venueId: 'venue_01',
        venueName: 'CLB Cầu Lông Tao Đàn',
        customerId: 'user_test_99',
        customerName: 'Trần Văn Test',
        senderRole: 'customer',
        text: 'Sân có chỗ để xe ô tô không ạ?',
      );

      final thread = VenueChatStore.instance.getThreadMessages(
        venueId: 'venue_01',
        customerId: 'user_test_99',
      );

      expect(thread.length, equals(1));
      expect(thread.first.text, equals('Sân có chỗ để xe ô tô không ạ?'));
      expect(thread.first.isFromCustomer, isTrue);

      final ownerThreads = VenueChatStore.instance.getOwnerThreads('venue_01');
      expect(ownerThreads.any((t) => t.customerId == 'user_test_99'), isTrue);
    });

    test('Owner replies back to customer in real-time', () {
      VenueChatStore.instance.sendMessage(
        venueId: 'venue_01',
        venueName: 'CLB Cầu Lông Tao Đàn',
        customerId: 'user_test_99',
        customerName: 'Trần Văn Test',
        senderRole: 'customer',
        text: 'Sân có chỗ để xe ô tô không ạ?',
      );

      VenueChatStore.instance.sendMessage(
        venueId: 'venue_01',
        venueName: 'CLB Cầu Lông Tao Đàn',
        customerId: 'user_test_99',
        customerName: 'Trần Văn Test',
        senderRole: 'owner',
        text: 'Dạ sân có bãi giữ xe ô tô rộng rãi phía sau sân nhé bạn!',
      );

      final thread = VenueChatStore.instance.getThreadMessages(
        venueId: 'venue_01',
        customerId: 'user_test_99',
      );

      expect(thread.length, equals(2));
      expect(thread.last.isFromOwner, isTrue);
      expect(thread.last.text, contains('bãi giữ xe ô tô'));
    });

    testWidgets('Tapping Nhắn tin CLB opens owner chat modal and sends customer message', (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 840));
      final venue = SeedData.sampleVenues.first;
      await tester.pumpWidget(BlocProvider(
        create: (_) => BookingBloc(),
        child: MaterialApp(
          home: VenueDetailScreen(venue: venue),
        ),
      ));
      await tester.pumpAndSettle();

      final chatBtn = find.byKey(const Key('btn_quick_action_chat_owner'));
      expect(chatBtn, findsOneWidget);
      await tester.tap(chatBtn);
      await tester.pumpAndSettle();

      // Verify chat bottom sheet opened
      expect(find.byKey(const Key('customer_venue_chat_input')), findsOneWidget);
      expect(find.byKey(const Key('btn_send_customer_venue_chat')), findsOneWidget);

      // Enter message and send
      await tester.enterText(find.byKey(const Key('customer_venue_chat_input')), 'Sân còn giờ trống sau 18h không ạ?');
      await tester.tap(find.byKey(const Key('btn_send_customer_venue_chat')));
      await tester.pumpAndSettle();

      expect(find.text('Sân còn giờ trống sau 18h không ạ?'), findsOneWidget);

      // Drain simulated club reply timer
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    });
  });
}
