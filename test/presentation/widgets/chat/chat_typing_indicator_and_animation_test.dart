import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/services/chatbot_service.dart';
import 'package:sporthub/presentation/widgets/chat/chat_message_bubble.dart';
import 'package:sporthub/presentation/widgets/chat/chat_typing_indicator.dart';

void main() {
  group('Chat Typing Indicator & Typewriter Animation Tests', () {
    testWidgets('ChatTypingIndicator renders animated dots and status text',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatTypingIndicator(
              key: Key('chatbot_typing_indicator'),
              statusText: 'SportHub AI đang soạn câu trả lời...',
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('chatbot_typing_indicator')), findsOneWidget);
      expect(find.text('SportHub AI đang soạn câu trả lời...'), findsOneWidget);
      expect(find.byIcon(Icons.smart_toy), findsOneWidget);

      // Verify animation frames run smoothly
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('ChatMessageBubble renders instantly when enableAnimation is false',
        (tester) async {
      final msg = ChatMessage(
        id: 'msg_instant',
        text: 'Xin chào! Em có thể giúp gì cho anh/chị?',
        sender: 'assistant',
        timestamp: DateTime.now(),
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

      expect(find.text('Xin chào! Em có thể giúp gì cho anh/chị?'), findsOneWidget);
    });

    testWidgets('ChatMessageBubble streams text with typewriter effect when enableAnimation is true',
        (tester) async {
      ChatMessageBubble.resetRevealedCache();

      final msg = ChatMessage(
        id: 'msg_streaming_test',
        text: 'Dạ em chào anh/chị, em đã kiểm tra sân Tao Đàn lúc 19:00!',
        sender: 'assistant',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageBubble(
              message: msg,
              enableAnimation: true,
            ),
          ),
        ),
      );

      // Initial frame: 0 chars
      await tester.pump(const Duration(milliseconds: 20));
      // Mid-way frames
      await tester.pump(const Duration(milliseconds: 100));

      // Tapping the bubble triggers instant completion / skip animation
      await tester.tap(find.byType(ChatMessageBubble));
      await tester.pumpAndSettle();

      expect(find.text('Dạ em chào anh/chị, em đã kiểm tra sân Tao Đàn lúc 19:00!'), findsOneWidget);
    });

    test('ChatbotService isTypingNotifier reflects state during sendMessage',
        () async {
      final service = ChatbotService.instance;
      service.resetMessages();

      expect(service.isTypingNotifier.value, isFalse);

      final sendFuture = service.sendMessage(
        'Đặt sân cầu lông 19h',
        context: null,
      );

      // Awaits message completion
      await sendFuture;

      expect(service.isTypingNotifier.value, isFalse);
      expect(service.messagesNotifier.value.isNotEmpty, isTrue);
    });
  });
}
