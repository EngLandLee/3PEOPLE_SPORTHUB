import 'package:flutter/foundation.dart';
import '../../data/models/ticket_model.dart';

class TicketStore {
  static final TicketStore instance = TicketStore._internal();

  TicketStore._internal() {
    reset();
  }

  static List<TicketModel> get defaultSampleTickets {
    final now = DateTime.now();
    final todayStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowStr =
        '${tomorrow.day.toString().padLeft(2, '0')}/${tomorrow.month.toString().padLeft(2, '0')}/${tomorrow.year}';
    final dateCode =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    return [
      TicketModel(
        id: 'ticket_01',
        bookingId: 'BK-$dateCode-889',
        venueName: 'Sân Cầu Lông Bình Thạnh',
        sportType: 'badminton',
        courtNumber: 1,
        matchDate: todayStr,
        startTime: '18:00',
        endTime: '20:00',
        totalPrice: 300000,
        qrCodeData: 'SPORTHUB|BK-$dateCode-889|300000',
        status: 'paid',
        createdAt: now.subtract(const Duration(hours: 3)).toIso8601String(),
        district: 'Bình Thạnh',
      ),
      TicketModel(
        id: 'ticket_02',
        bookingId: 'BK-$dateCode-312',
        venueName: 'Thảo Điền Pickleball Hub',
        sportType: 'pickleball',
        courtNumber: 2,
        matchDate: todayStr,
        startTime: '19:00',
        endTime: '21:00',
        totalPrice: 240000,
        qrCodeData: 'SPORTHUB|BK-$dateCode-312|240000',
        status: 'paid',
        createdAt: now.subtract(const Duration(hours: 1)).toIso8601String(),
        district: 'Thủ Đức',
      ),
      TicketModel(
        id: 'ticket_03',
        bookingId: 'BK-$dateCode-558',
        venueName: 'Sân Bóng Đá Mini Nam Sài Gòn',
        sportType: 'football',
        courtNumber: 5,
        matchDate: tomorrowStr,
        startTime: '19:30',
        endTime: '21:00',
        totalPrice: 450000,
        qrCodeData: 'SPORTHUB|BK-$dateCode-558|450000',
        status: 'paid',
        createdAt: now.toIso8601String(),
        district: 'Quận 7',
      ),
    ];
  }

  final ValueNotifier<List<TicketModel>> ticketsNotifier =
      ValueNotifier<List<TicketModel>>([]);

  List<TicketModel> get tickets => ticketsNotifier.value;

  void reset() {
    ticketsNotifier.value = List<TicketModel>.from(defaultSampleTickets);
  }

  void clearAll() {
    ticketsNotifier.value = const [];
  }

  static void Function(TicketModel ticket)? onTicketAdded;

  void addTicket(TicketModel ticket) {
    ticketsNotifier.value = [ticket, ...ticketsNotifier.value];
    // Adding a local pending ticket is not payment verification. Only a
    // server/provider-confirmed paid ticket may trigger paid UI updates.
    if (ticket.status == 'paid') {
      onTicketAdded?.call(ticket);
    }
  }

  void removeTicket(String id) {
    ticketsNotifier.value =
        ticketsNotifier.value.where((t) => t.id != id).toList();
  }

  void updateTicketStatus(String id, String status) {
    ticketsNotifier.value = ticketsNotifier.value.map((t) {
      if (t.id == id) {
        return TicketModel(
          id: t.id,
          bookingId: t.bookingId,
          venueName: t.venueName,
          sportType: t.sportType,
          courtNumber: t.courtNumber,
          matchDate: t.matchDate,
          startTime: t.startTime,
          endTime: t.endTime,
          totalPrice: t.totalPrice,
          qrCodeData: t.qrCodeData,
          status: status,
          createdAt: t.createdAt,
          district: t.district,
        );
      }
      return t;
    }).toList();
  }
}
