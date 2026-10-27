import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/state/ticket_store.dart';
import 'package:sporthub/data/models/ticket_model.dart';

void main() {
  group('TicketStore Tests', () {
    late TicketStore store;

    setUp(() {
      store = TicketStore.instance;
      store.reset();
    });

    test('initializes with default tickets covering badminton, pickleball, and football', () {
      final tickets = store.tickets;
      expect(tickets.length, greaterThanOrEqualTo(3));

      final sports = tickets.map((t) => t.sportType).toSet();
      expect(sports.contains('badminton'), isTrue);
      expect(sports.contains('pickleball'), isTrue);
      expect(sports.contains('football'), isTrue);
    });

    test('addTicket prepends new ticket and notifies listeners', () {
      int notifyCount = 0;
      store.ticketsNotifier.addListener(() => notifyCount++);

      final newTicket = TicketModel(
        id: 'ticket_test_01',
        bookingId: 'BK-TEST-999',
        venueName: 'CLB Test',
        sportType: 'badminton',
        courtNumber: 3,
        matchDate: '07/09/2026',
        startTime: '10:00',
        endTime: '11:00',
        totalPrice: 120000,
        qrCodeData: 'SPORTHUB|BK-TEST-999|120000',
        status: 'paid',
        createdAt: '2026-09-07T10:00:00Z',
        district: 'Quận 1',
      );

      store.addTicket(newTicket);

      expect(store.tickets.first.bookingId, 'BK-TEST-999');
      expect(notifyCount, 1);
    });

    test('adding a pending ticket does not emit a payment-confirmed event', () {
      TicketModel? callbackTicket;
      TicketStore.onTicketAdded = (ticket) => callbackTicket = ticket;

      store.addTicket(
        TicketModel(
          id: 'ticket_pending_01',
          bookingId: 'BK-PENDING-01',
          venueName: 'CLB Test',
          sportType: 'badminton',
          courtNumber: 1,
          matchDate: '07/09/2026',
          startTime: '10:00',
          endTime: '11:00',
          totalPrice: 120000,
          qrCodeData: 'SPORTHUB|BK-PENDING-01|120000',
          status: 'pending',
          createdAt: '2026-09-07T10:00:00Z',
          district: 'Quận 1',
        ),
      );

      expect(callbackTicket, isNull);
      TicketStore.onTicketAdded = null;
    });

    test('updateTicketStatus updates matching ticket', () {
      final firstTicket = store.tickets.first;
      store.updateTicketStatus(firstTicket.id, 'checked_in');

      final updated = store.tickets.firstWhere((t) => t.id == firstTicket.id);
      expect(updated.status, 'checked_in');
    });

    test('removeTicket removes matching ticket', () {
      final firstId = store.tickets.first.id;
      final initialCount = store.tickets.length;

      store.removeTicket(firstId);

      expect(store.tickets.length, initialCount - 1);
      expect(store.tickets.any((t) => t.id == firstId), isFalse);
    });

    test('reset restores default sample tickets', () {
      store.removeTicket(store.tickets.first.id);
      expect(store.tickets.length, 2);

      store.reset();
      expect(store.tickets.length, 3);
    });
  });
}
