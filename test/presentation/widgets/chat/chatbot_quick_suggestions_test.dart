import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/services/chatbot_service.dart';
import 'package:sporthub/presentation/widgets/chat/chatbot_bottom_sheet.dart';

void main() {
  setUp(() {
    ChatbotService.instance.resetMessages();
  });

  tearDown(() {
    ChatbotService.instance.resetMessages();
  });

  testWidgets('ChatbotBottomSheet renders dynamic quick suggestions from latest message',
      (tester) async {
    ChatbotService.instance.resetMessages();
    ChatbotService.instance.addMessage(
      ChatMessage(
        id: 'msg_1',
        text: 'Em đã chọn sẵn sân cho anh',
        sender: 'assistant',
        timestamp: DateTime.now(),
        quickSuggestions: ['🏓 Pickleball Thảo Điền', '🏸 Cầu lông Bình Thạnh'],
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChatbotBottomSheet(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('🏓 Pickleball Thảo Điền'), findsOneWidget);
    expect(find.text('🏸 Cầu lông Bình Thạnh'), findsOneWidget);
  });

  testWidgets('Tapping dynamic quick suggestion chip sends message to chat',
      (tester) async {
    ChatbotService.instance.resetMessages();
    ChatbotService.instance.addMessage(
      ChatMessage(
        id: 'msg_1',
        text: 'Gợi ý cho bạn',
        sender: 'assistant',
        timestamp: DateTime.now(),
        quickSuggestions: ['🏓 Pickleball Thảo Điền', '🏸 Cầu lông Bình Thạnh'],
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChatbotBottomSheet(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final suggestionChip = find.text('🏓 Pickleball Thảo Điền');
    expect(suggestionChip, findsOneWidget);

    await tester.tap(suggestionChip);
    await tester.pumpAndSettle();

    expect(
      ChatbotService.instance.messagesNotifier.value
          .any((m) => m.text == '🏓 Pickleball Thảo Điền'),
      isTrue,
    );
  });

  testWidgets('ChatbotBottomSheet renders default prompt chips when no quickSuggestions',
      (tester) async {
    ChatbotService.instance.resetMessages();

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChatbotBottomSheet(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tìm sân gần tôi'), findsOneWidget);
    // Default user is Nguyễn Văn An with preferredSport = 'pickleball'
    expect(find.text('Đặt sân pickleball 19h'), findsOneWidget);
    expect(find.text('Bảng giá sân'), findsOneWidget);
  });
}
