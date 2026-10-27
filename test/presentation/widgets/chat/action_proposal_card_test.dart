import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/domain/entities/chat_message.dart';
import 'package:sporthub/presentation/widgets/chat/action_proposal_card.dart';

void main() {
  group('ActionProposalCard Widget Tests', () {
    testWidgets('ActionProposalCard hiển thị thông tin và kích hoạt nút Xác nhận', (tester) async {
      final proposal = ActionProposal(
        id: 'prop_001',
        tool: 'create_court_booking',
        target: {
          'courtName': 'Sân Cầu Lông 1',
          'venueName': 'CLB Chảo Lửa',
          'date': '2026-10-27',
          'timeSlot': '18:00 - 19:30',
          'price': 180000,
        },
        form: [
          FormFieldSpec(
            key: 'note',
            label: 'Ghi chú cho chủ sân',
            type: 'textarea',
            currentValue: '',
          ),
        ],
        expiresAt: DateTime.now().add(const Duration(minutes: 15)).millisecondsSinceEpoch,
      );

      bool approved = false;
      Map<String, String>? submittedEdits;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ActionProposalCard(
                proposal: proposal,
                onApprove: (edits) {
                  approved = true;
                  submittedEdits = edits;
                },
                onCancel: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('ĐỀ XUẤT ĐẶT SÂN'), findsOneWidget);
      expect(find.text('Xác nhận (HITL)'), findsOneWidget);
      expect(find.textContaining('Sân Cầu Lông 1'), findsOneWidget);
      expect(find.textContaining('CLB Chảo Lửa'), findsOneWidget);
      expect(find.textContaining('180.000 đ'), findsOneWidget);
      expect(find.text('Xác nhận đặt sân'), findsOneWidget);
      expect(find.text('Hủy'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Mang giúp 2 vợt');
      await tester.tap(find.text('Xác nhận đặt sân'));
      await tester.pump();

      expect(approved, isTrue);
      expect(submittedEdits?['note'], equals('Mang giúp 2 vợt'));
    });

    testWidgets('ActionProposalCard nhấn Hủy gọi onCancel', (tester) async {
      final proposal = ActionProposal(
        id: 'prop_002',
        tool: 'create_court_booking',
        target: {
          'courtName': 'Sân Pickleball 2',
          'venueName': 'Sân Đào Duy Anh',
          'date': '2026-10-28',
          'timeSlot': '07:00 - 08:30',
          'price': 150000,
        },
        form: [],
        expiresAt: DateTime.now().add(const Duration(minutes: 15)).millisecondsSinceEpoch,
      );

      bool cancelled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ActionProposalCard(
                proposal: proposal,
                onApprove: (_) {},
                onCancel: () {
                  cancelled = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Hủy'));
      await tester.pump();

      expect(cancelled, isTrue);
    });

    testWidgets('ActionProposalCard hiển thị trạng thái đã duyệt thành công khi status == executed', (tester) async {
      final proposal = ActionProposal(
        id: 'prop_003',
        tool: 'create_court_booking',
        status: 'executed',
        target: {
          'courtName': 'Sân Cầu Lông 3',
          'venueName': 'CLB Chảo Lửa',
          'date': '2026-10-27',
          'timeSlot': '18:00 - 19:30',
          'price': 180000,
        },
        form: [
          FormFieldSpec(
            key: 'note',
            label: 'Ghi chú',
            type: 'text',
            currentValue: 'Lấy nước khoáng',
          ),
        ],
        expiresAt: DateTime.now().add(const Duration(minutes: 15)).millisecondsSinceEpoch,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ActionProposalCard(
                proposal: proposal,
              ),
            ),
          ),
        ),
      );

      expect(find.text('✅ Đã xác nhận & đặt sân thành công'), findsOneWidget);
      expect(find.textContaining('Lấy nước khoáng'), findsOneWidget);
      expect(find.text('Xác nhận đặt sân'), findsNothing);
      expect(find.text('Hủy'), findsNothing);
    });

    testWidgets('ActionProposalCard hiển thị trạng thái đã hủy khi status == cancelled', (tester) async {
      final proposal = ActionProposal(
        id: 'prop_004',
        tool: 'create_court_booking',
        status: 'cancelled',
        target: {
          'courtName': 'Sân Cầu Lông 4',
          'venueName': 'CLB Chảo Lửa',
          'date': '2026-10-27',
          'timeSlot': '18:00 - 19:30',
          'price': 180000,
        },
        form: [],
        expiresAt: DateTime.now().add(const Duration(minutes: 15)).millisecondsSinceEpoch,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ActionProposalCard(
                proposal: proposal,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Đã hủy đề xuất'), findsOneWidget);
      expect(find.text('Xác nhận đặt sân'), findsNothing);
      expect(find.text('Hủy'), findsNothing);
    });

    testWidgets('ActionProposalCard hiển thị hết hạn khi expired', (tester) async {
      final proposal = ActionProposal(
        id: 'prop_005',
        tool: 'create_court_booking',
        status: 'pending',
        target: {
          'courtName': 'Sân Bóng Đá 5',
          'venueName': 'Sân Hoa Lư',
          'startTime': '17:00',
          'endTime': '18:00',
          'price': '300000',
        },
        form: [],
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)).millisecondsSinceEpoch,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ActionProposalCard(
                proposal: proposal,
              ),
            ),
          ),
        ),
      );

      expect(find.text('⏰ Đề xuất đã hết hạn'), findsOneWidget);
      expect(find.text('Xác nhận đặt sân'), findsNothing);
      expect(find.textContaining('300.000 đ'), findsOneWidget);
      expect(find.textContaining('17:00 - 18:00'), findsOneWidget);
    });

    testWidgets('ActionProposalCard cập nhật khi proposal.id thay đổi', (tester) async {
      final proposal1 = ActionProposal(
        id: 'prop_006_a',
        tool: 'create_court_booking',
        target: {
          'courtName': 'Sân 1',
          'venueName': 'Sân A',
          'price': 100000,
        },
        form: [
          FormFieldSpec(
            key: 'note',
            label: 'Ghi chú',
            type: 'text',
            currentValue: 'Ghi chú A',
          ),
        ],
        expiresAt: DateTime.now().add(const Duration(minutes: 10)).millisecondsSinceEpoch,
      );

      final proposal2 = ActionProposal(
        id: 'prop_006_b',
        tool: 'create_court_booking',
        target: {
          'courtName': 'Sân 2',
          'venueName': 'Sân B',
          'price': 200000,
        },
        form: [
          FormFieldSpec(
            key: 'note',
            label: 'Ghi chú',
            type: 'text',
            currentValue: 'Ghi chú B',
          ),
        ],
        expiresAt: DateTime.now().add(const Duration(minutes: 10)).millisecondsSinceEpoch,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ActionProposalCard(
                proposal: proposal1,
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('Sân 1'), findsOneWidget);
      expect(find.text('Ghi chú A'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ActionProposalCard(
                proposal: proposal2,
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('Sân 2'), findsOneWidget);
      expect(find.text('Ghi chú B'), findsOneWidget);
    });
  });
}
