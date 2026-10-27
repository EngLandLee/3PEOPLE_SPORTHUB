import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/domain/entities/chat_message.dart';

void main() {
  group('ActionProposal Entity', () {
    test('deserialize and serialize ActionProposal correctly', () {
      final json = {
        'id': 'prop_123',
        'tool': 'create_court_booking',
        'status': 'pending',
        'target': {
          'courtId': 'court_1',
          'courtName': 'Sân 1',
          'venueName': 'CLB Chảo Lửa',
          'date': '2026-10-27',
          'timeSlot': '18:00 - 19:30',
          'price': 150000,
        },
        'form': [
          {
            'key': 'timeSlot',
            'label': 'Khung giờ',
            'type': 'text',
            'required': true,
            'currentValue': '18:00 - 19:30',
          },
          {
            'key': 'note',
            'label': 'Ghi chú',
            'type': 'textarea',
            'required': false,
            'maxLength': 200,
            'currentValue': '',
          }
        ],
        'expiresAt': 1730000901000,
      };

      final proposal = ActionProposal.fromJson(json);
      expect(proposal.id, equals('prop_123'));
      expect(proposal.tool, equals('create_court_booking'));
      expect(proposal.status, equals('pending'));
      expect(proposal.target['courtName'], equals('Sân 1'));
      expect(proposal.form.length, equals(2));
      expect(proposal.form.first.key, equals('timeSlot'));
      expect(proposal.form.first.label, equals('Khung giờ'));
      expect(proposal.form.first.type, equals('text'));
      expect(proposal.form.first.required, isTrue);
      expect(proposal.form.first.currentValue, equals('18:00 - 19:30'));
      expect(proposal.form[1].key, equals('note'));
      expect(proposal.form[1].maxLength, equals(200));
      expect(proposal.expiresAt, equals(1730000901000));

      final serialized = proposal.toJson();
      expect(serialized['id'], equals('prop_123'));
      expect(serialized['form'], isA<List>());
      expect((serialized['form'] as List).length, equals(2));

      final message = ChatMessage(
        text: 'Em đã chuẩn bị sẵn thông tin đặt sân',
        isUser: false,
        timestamp: DateTime.now(),
        proposal: proposal,
      );

      expect(message.proposal, isNotNull);
      expect(message.proposal?.id, equals('prop_123'));
      expect(message.hasProposal, isTrue);
      expect(message.isUser, isFalse);
      expect(message.isAssistant, isTrue);
    });

    test('ChatMessage json round-trip with proposal', () {
      final msg = ChatMessage(
        id: 'msg_test_1',
        text: 'Đề xuất đặt sân',
        sender: 'assistant',
        timestamp: DateTime.parse('2026-10-27T10:00:00Z'),
        proposal: ActionProposal(
          id: 'prop_round_trip',
          tool: 'create_court_booking',
          status: 'pending',
          target: {'courtId': 'court_1', 'price': 100000},
          form: [
            FormFieldSpec(
              key: 'timeSlot',
              label: 'Giờ',
              type: 'text',
              currentValue: '17:00 - 18:00',
            ),
          ],
          expiresAt: 1730000000000,
        ),
      );

      final json = msg.toJson();
      expect(json['proposal'], isNotNull);
      expect(json['proposal']['id'], equals('prop_round_trip'));

      final parsed = ChatMessage.fromJson(json);
      expect(parsed.id, equals('msg_test_1'));
      expect(parsed.proposal, isNotNull);
      expect(parsed.proposal?.id, equals('prop_round_trip'));
      expect(parsed.proposal?.form.first.currentValue, equals('17:00 - 18:00'));
    });

    test('ChatMessage copyWith preserves or updates proposal', () {
      final proposal1 = ActionProposal(
        id: 'prop_1',
        tool: 'tool_1',
        target: {},
        form: [],
        expiresAt: 123456,
      );
      final proposal2 = ActionProposal(
        id: 'prop_2',
        tool: 'tool_2',
        target: {},
        form: [],
        expiresAt: 654321,
      );

      final msg = ChatMessage(
        id: 'msg_1',
        text: 'Hello',
        sender: 'assistant',
        timestamp: DateTime.now(),
        proposal: proposal1,
      );

      final copiedSame = msg.copyWith(text: 'Updated text');
      expect(copiedSame.proposal?.id, equals('prop_1'));
      expect(copiedSame.text, equals('Updated text'));

      final copiedNewProp = msg.copyWith(proposal: proposal2);
      expect(copiedNewProp.proposal?.id, equals('prop_2'));
    });

    test('FormFieldSpec copyWith and default values in fromJson', () {
      final field = FormFieldSpec.fromJson({
        'key': 'custom_field',
        'label': 'Custom Label',
        'currentValue': '123',
      });
      expect(field.key, equals('custom_field'));
      expect(field.label, equals('Custom Label'));
      expect(field.type, equals('text'));
      expect(field.required, isFalse);
      expect(field.maxLength, isNull);
      expect(field.currentValue, equals('123'));

      final updated = field.copyWith(currentValue: '456', required: true);
      expect(updated.currentValue, equals('456'));
      expect(updated.required, isTrue);
      expect(updated.key, equals('custom_field'));
    });

    test('ActionProposal status helpers and copyWith', () {
      final proposal = ActionProposal(
        id: 'prop_status',
        tool: 'book',
        status: 'pending',
        target: {},
        form: [],
        expiresAt: DateTime.now().millisecondsSinceEpoch + 60000,
      );
      expect(proposal.isPending, isTrue);
      expect(proposal.isApproved, isFalse);
      expect(proposal.isRejected, isFalse);
      expect(proposal.isExecuted, isFalse);
      expect(proposal.isExpired, isFalse);

      proposal.status = 'approved';
      expect(proposal.isPending, isFalse);
      expect(proposal.isApproved, isTrue);

      proposal.status = 'cancelled';
      expect(proposal.isRejected, isTrue);

      proposal.status = 'executed';
      expect(proposal.isExecuted, isTrue);
      expect(proposal.isApproved, isTrue);

      final expiredProp = proposal.copyWith(
        expiresAt: DateTime.now().millisecondsSinceEpoch - 1000,
      );
      expect(expiredProp.isExpired, isTrue);
    });

    test('ChatMessage constructor handles isUser flag and auto-generates id and timestamp', () {
      final userMsg = ChatMessage(
        text: 'Tin nhắn từ user',
        isUser: true,
      );
      expect(userMsg.isUser, isTrue);
      expect(userMsg.isAssistant, isFalse);
      expect(userMsg.sender, equals('user'));
      expect(userMsg.id, isNotEmpty);
      expect(userMsg.timestamp, isNotNull);
      expect(userMsg.hasProposal, isFalse);

      final assistantMsg = ChatMessage(
        text: 'Tin nhắn từ bot',
      );
      expect(assistantMsg.isUser, isFalse);
      expect(assistantMsg.isAssistant, isTrue);
      expect(assistantMsg.sender, equals('assistant'));
    });
  });
}
