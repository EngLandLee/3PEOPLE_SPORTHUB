import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sporthub/core/services/chatbot_service.dart';
import 'package:sporthub/core/state/ticket_store.dart';
import 'package:sporthub/presentation/widgets/chat/action_proposal_card.dart';
import 'package:sporthub/presentation/widgets/chat/chat_message_bubble.dart';

void main() {
  setUp(() {
    TicketStore.instance.reset();
    ChatbotService.instance.resetMessages();
    ChatbotService.instance.httpClient = null;
  });

  tearDown(() {
    ChatbotService.instance.httpClient = null;
  });

  test('executeActionProposal tạo vé hợp lệ vào TicketStore khi approved', () async {
    final service = ChatbotService.instance;
    final ticketData = {
      'id': 'ticket_hitl_test',
      'courtName': 'Sân Cầu Lông 1',
      'venueName': 'CLB Chảo Lửa',
      'date': '2026-10-27',
      'timeSlot': '18:00 - 19:30',
      'totalPrice': 180000,
      'status': 'pending',
      'note': 'Test note',
    };

    service.handleExecutionSuccess(ticketData);

    expect(TicketStore.instance.tickets.any((t) => t.id == 'ticket_hitl_test'), isTrue);
    final ticket = TicketStore.instance.tickets.firstWhere((t) => t.id == 'ticket_hitl_test');
    expect(ticket.venueName, 'CLB Chảo Lửa');
    expect(ticket.courtNumber, 1);
    expect(ticket.startTime, '18:00');
    expect(ticket.endTime, '19:30');
    expect(ticket.totalPrice, 180000.0);
  });

  test('executeActionProposal calls POST /api/chatbot/action/execute and updates TicketStore when approved', () async {
    final service = ChatbotService.instance;
    final proposal = ActionProposal(
      id: 'prop_test_001',
      tool: 'create_court_booking',
      status: 'pending',
      target: {
        'venueName': 'CLB Cầu Lông Tao Đàn',
        'courtName': 'Sân 2',
        'date': '2026-10-28',
        'timeSlot': '19:00 - 20:30',
        'price': 200000,
      },
      form: [
        FormFieldSpec(
          key: 'note',
          label: 'Ghi chú',
          type: 'textarea',
          currentValue: '',
        ),
      ],
      expiresAt: DateTime.now().millisecondsSinceEpoch + 60000,
    );

    final msg = ChatMessage(
      id: 'msg_prop',
      text: 'Đề xuất đặt sân của bạn',
      sender: 'assistant',
      proposal: proposal,
    );
    service.addMessage(msg);

    service.httpClient = MockClient((request) async {
      expect(request.url.path, '/api/chatbot/action/execute');
      expect(request.method, 'POST');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['proposalId'], 'prop_test_001');
      expect(body['approved'], isTrue);
      expect(body['edits']['note'], 'Thuê 2 vợt');

      return http.Response(
        jsonEncode({
          'success': true,
          'message': 'Đặt sân thành công!',
          'ticket': {
            'id': 'ticket_prop_exec',
            'venueName': 'CLB Cầu Lông Tao Đàn',
            'courtName': 'Sân 2',
            'date': '2026-10-28',
            'timeSlot': '19:00 - 20:30',
            'totalPrice': 200000,
            'status': 'pending',
            'note': 'Thuê 2 vợt',
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final res = await service.executeActionProposal(
      proposalId: 'prop_test_001',
      approved: true,
      edits: {'note': 'Thuê 2 vợt'},
    );

    expect(res['success'], isTrue);
    expect(TicketStore.instance.tickets.any((t) => t.id == 'ticket_prop_exec'), isTrue);
    final updatedMsg = service.messagesNotifier.value.firstWhere((m) => m.id == 'msg_prop');
    expect(updatedMsg.proposal?.status, 'executed');
  });

  test('executeActionProposal calls POST /api/chatbot/action/cancel and updates proposal status to cancelled when !approved', () async {
    final service = ChatbotService.instance;
    final proposal = ActionProposal(
      id: 'prop_test_cancel',
      tool: 'create_court_booking',
      status: 'pending',
      target: {
        'venueName': 'CLB Cầu Lông Tao Đàn',
        'courtName': 'Sân 2',
        'date': '2026-10-28',
        'timeSlot': '19:00 - 20:30',
        'price': 200000,
      },
      form: [],
      expiresAt: DateTime.now().millisecondsSinceEpoch + 60000,
    );

    final msg = ChatMessage(
      id: 'msg_prop_cancel',
      text: 'Đề xuất đặt sân của bạn',
      sender: 'assistant',
      proposal: proposal,
    );
    service.addMessage(msg);

    service.httpClient = MockClient((request) async {
      expect(request.url.path, '/api/chatbot/action/cancel');
      expect(request.method, 'POST');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['proposalId'], 'prop_test_cancel');

      return http.Response(
        jsonEncode({
          'success': true,
          'message': 'Đã hủy đề xuất đặt sân.',
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final res = await service.executeActionProposal(
      proposalId: 'prop_test_cancel',
      approved: false,
    );

    expect(res['success'], isTrue);
    final updatedMsg = service.messagesNotifier.value.firstWhere((m) => m.id == 'msg_prop_cancel');
    expect(updatedMsg.proposal?.status, 'cancelled');
  });

  test('sendMessage parses proposal from server response JSON', () async {
    final service = ChatbotService.instance;
    service.httpClient = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'reply': 'Em đã chuẩn bị đề xuất đặt sân cho anh/chị:',
          'proposal': {
            'id': 'prop_server_123',
            'tool': 'create_court_booking',
            'status': 'pending',
            'target': {
              'venueName': 'CLB Tao Đàn',
              'courtName': 'Sân 3',
              'date': '2026-10-29',
              'timeSlot': '17:00 - 18:30',
              'price': 150000,
            },
            'form': [
              {
                'key': 'note',
                'label': 'Ghi chú',
                'type': 'textarea',
                'currentValue': '',
              }
            ],
            'expiresAt': DateTime.now().millisecondsSinceEpoch + 900000,
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final assistantMsg = await service.sendMessage('tôi muốn đặt sân lúc 17h');
    expect(assistantMsg.hasProposal, isTrue);
    expect(assistantMsg.proposal, isNotNull);
    expect(assistantMsg.proposal!.id, 'prop_server_123');
    expect(assistantMsg.proposal!.target['courtName'], 'Sân 3');
  });

  testWidgets('ChatMessageBubble renders ActionProposalCard when proposal is present', (tester) async {
    final proposal = ActionProposal(
      id: 'prop_widget_test',
      tool: 'create_court_booking',
      status: 'pending',
      target: {
        'venueName': 'CLB Cầu Lông Tao Đàn',
        'courtName': 'Sân 1',
        'date': 'Hôm nay',
        'timeSlot': '19:00 - 20:00',
        'price': 160000,
      },
      form: [],
      expiresAt: DateTime.now().millisecondsSinceEpoch + 60000,
    );

    final msg = ChatMessage(
      id: 'msg_widget_test',
      text: 'Đây là đề xuất đặt sân:',
      sender: 'assistant',
      proposal: proposal,
    );

    bool approveCalled = false;
    bool cancelCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageBubble(
            message: msg,
            enableAnimation: false,
            onApproveProposal: (edits) => approveCalled = true,
            onCancelProposal: () => cancelCalled = true,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(ActionProposalCard), findsOneWidget);
    expect(find.text('ĐỀ XUẤT ĐẶT SÂN'), findsOneWidget);
    expect(find.text('CLB Cầu Lông Tao Đàn'), findsOneWidget);

    await tester.tap(find.text('Xác nhận đặt sân'));
    await tester.pumpAndSettle();
    expect(approveCalled, isTrue);

    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(cancelCalled, isTrue);
  });
}
