import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/state/auth_store.dart';
import 'package:sporthub/core/state/venue_chat_store.dart';
import 'package:sporthub/core/utils/seed_data.dart';
import 'package:sporthub/main.dart';
import 'package:sporthub/presentation/screens/user_chat_tab.dart';

void main() {
  setUp(() {
    AuthStore.instance.reset();
    AuthStore.instance.loginWithDemo(SeedData.demoUsers.first);
    VenueChatStore.instance.reset();
  });

  testWidgets('Consumer bottom nav has "Tin nhắn" tab and switches to UserChatTab', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 840));
    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    // Verify 'Tin nhắn' tab exists on bottom nav bar
    expect(find.text('Tin nhắn'), findsOneWidget);

    // Tap 'Tin nhắn' tab
    await tester.tap(find.text('Tin nhắn'));
    await tester.pumpAndSettle();

    // Verify UserChatTab is displayed
    expect(find.byType(UserChatTab), findsOneWidget);
    expect(find.text('Hộp thư Tin nhắn'), findsOneWidget);
    expect(find.text('Trợ lý AI SportHub'), findsOneWidget);
    expect(find.byKey(const Key('btn_open_ai_chat_from_tab')), findsOneWidget);
  });

  testWidgets('UserChatTab allows starting chat with a suggested venue and sending message', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 840));
    await tester.pumpWidget(const MaterialApp(
      home: UserChatTab(),
    ));
    await tester.pumpAndSettle();

    // Find first 'Nhắn tin' button on suggested venue
    final nhanTinBtn = find.text('Nhắn tin').first;
    expect(nhanTinBtn, findsOneWidget);
    await tester.tap(nhanTinBtn);
    await tester.pumpAndSettle();

    // Verify direct chat view opened
    expect(find.byKey(const Key('user_chat_input_field')), findsOneWidget);
    expect(find.byKey(const Key('btn_send_user_chat')), findsOneWidget);

    // Enter message
    await tester.enterText(find.byKey(const Key('user_chat_input_field')), 'Shop có bán nước suối không ạ?');
    await tester.tap(find.byKey(const Key('btn_send_user_chat')));
    await tester.pumpAndSettle();

    expect(find.text('Shop có bán nước suối không ạ?'), findsOneWidget);

    // Drain timer from simulated club response
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });
}
