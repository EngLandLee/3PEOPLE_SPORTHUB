import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/services/chatbot_service.dart';
import 'package:sporthub/main.dart';
import 'package:sporthub/presentation/blocs/booking/booking_bloc.dart';
import 'package:sporthub/presentation/widgets/chat/chatbot_bottom_sheet.dart';

void main() {
  testWidgets('ChatbotBottomSheet triggers onViewCourtMapAction with actionCard',
      (tester) async {
    Map<String, dynamic>? handledCard;

    ChatbotService.instance.resetMessages();
    ChatbotService.instance.addMessage(
      ChatMessage(
        id: 'msg_1',
        text: 'Tìm thấy sân phù hợp',
        sender: 'assistant',
        timestamp: DateTime.now(),
        actionCard: {
          'venueId': 'venue_01',
          'venueName': 'CLB Cầu Lông Tao Đàn',
          'sport': 'Cầu lông',
          'court': 'Sân 3',
          'startTime': '19:00',
          'endTime': '20:00',
          'price': 120000,
        },
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatbotBottomSheet(
            currentRoute: '/home',
            onViewCourtMapAction: (card) {
              handledCard = card;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final viewMapButton = find.byKey(const Key('btn_chat_view_court_map'));
    expect(viewMapButton, findsOneWidget);

    await tester.tap(viewMapButton);
    await tester.pumpAndSettle();

    expect(handledCard, isNotNull);
    expect(handledCard!['court'], equals('Sân 3'));
  });

  testWidgets('ChatbotBottomSheet navigates to VenueDetailScreen when onViewCourtMapAction is null',
      (tester) async {
    ChatbotService.instance.resetMessages();
    ChatbotService.instance.addMessage(
      ChatMessage(
        id: 'msg_2',
        text: 'Tìm thấy sân phù hợp',
        sender: 'assistant',
        timestamp: DateTime.now(),
        actionCard: {
          'venueId': 'venue_01',
          'venueName': 'CLB Cầu Lông Tao Đàn',
          'sport': 'Cầu lông',
          'court': 'Sân 3',
          'startTime': '19:00',
          'endTime': '20:00',
          'price': 120000,
        },
      ),
    );

    await tester.pumpWidget(
      BlocProvider(
        create: (_) => BookingBloc(),
        child: const MaterialApp(
          home: Scaffold(
            body: ChatbotBottomSheet(
              currentRoute: '/home',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final viewMapButton = find.byKey(const Key('btn_chat_view_court_map'));
    expect(viewMapButton, findsOneWidget);

    await tester.tap(viewMapButton);
    await tester.pumpAndSettle();

    expect(find.byType(VenueDetailScreen), findsOneWidget);
  });
}
