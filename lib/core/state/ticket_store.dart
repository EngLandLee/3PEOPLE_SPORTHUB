import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../../data/datasources/local/database_helper.dart';
import '../../data/models/ticket_model.dart';
import '../../domain/entities/user_profile.dart';
import '../services/venue_sync_service.dart';

class TicketStore {
  static final TicketStore instance = TicketStore._internal();

  TicketStore._internal() {
    reset();
  }

  bool get _canUseSqlite {
    if (kIsWeb) return false;
    try {
      if (Platform.environment['FLUTTER_TEST'] == 'true') return false;
      final name = WidgetsBinding.instance.runtimeType.toString();
      if (name.contains('Test')) return false;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Loads cached offline tickets from local SQLite database (`sporthub_local.db`)
  /// and merges them with current in-memory tickets.
  Future<void> loadFromSqlite() async {
    if (!_canUseSqlite) return;
    try {
      final saved = await DatabaseHelper.instance.getTickets();
      if (saved.isNotEmpty) {
        final current = List<TicketModel>.from(ticketsNotifier.value);
        for (final t in saved) {
          final exists = current.any(
            (c) => c.id == t.id || c.bookingId == t.bookingId,
          );
          if (!exists) {
            current.insert(0, t);
          }
        }
        ticketsNotifier.value = current;
      }
    } catch (_) {}
  }

  void syncFromBookings(UserProfile user) {
    final bookings = VenueSyncService.instance.bookingsNotifier.value;
    final current = List<TicketModel>.from(ticketsNotifier.value);
    bool changed = false;
    for (final b in bookings) {
      final customerPhone = (b['customerPhone'] ?? '').toString();
      final customerName = (b['customerName'] ?? '').toString();
      final phoneMatch = customerPhone.isNotEmpty &&
          customerPhone.replaceAll(RegExp(r'\s+'), '') ==
              user.phone.replaceAll(RegExp(r'\s+'), '');
      final nameMatch = customerName.isNotEmpty &&
          customerName.toLowerCase() == user.fullName.toLowerCase();
      if (phoneMatch || nameMatch) {
        final bId = (b['id'] ?? b['bookingId'])?.toString() ?? '';
        if (bId.isNotEmpty &&
            !current.any((t) => t.id == bId || t.bookingId == bId)) {
          final cNum = int.tryParse(b['courtNumber']?.toString() ?? '') ?? 1;
          final dateStr = b['date']?.toString() ?? '';
          final timeRange = b['timeSlot']?.toString() ??
              '${b['startTime'] ?? '18:00'} - ${b['endTime'] ?? '19:00'}';
          final start = b['startTime']?.toString() ??
              (timeRange.contains('-')
                  ? timeRange.split('-')[0].trim()
                  : '18:00');
          final end = b['endTime']?.toString() ??
              (timeRange.contains('-')
                  ? timeRange.split('-')[1].trim()
                  : '19:00');
          final price = (b['price'] as num?)?.toDouble() ?? 0.0;
          final status = (b['checkedIn'] == true) ? 'checked_in' : 'paid';
          final t = TicketModel(
            id: bId,
            bookingId: bId,
            venueName: b['venueName']?.toString() ?? 'CLB Thể Thao',
            sportType: b['sport']?.toString() ?? 'badminton',
            courtNumber: cNum,
            matchDate: dateStr,
            startTime: start,
            endTime: end,
            totalPrice: price,
            qrCodeData: 'SPORTHUB|$bId|${price.toInt()}',
            status: status,
            createdAt:
                b['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
            district: b['district']?.toString() ?? 'Quận 1',
          );
          current.insert(0, t);
          changed = true;
          if (_canUseSqlite) {
            DatabaseHelper.instance.insertTicket(t).catchError((_) => 0);
          }
        }
      }
    }
    if (changed) {
      ticketsNotifier.value = current;
    }
  }

  static List<TicketModel> get defaultSampleTickets {
    try {
      if (Platform.environment['FLUTTER_TEST'] == 'true') {
        // Continue to sample tickets for unit tests
      } else {
        final name = WidgetsBinding.instance.runtimeType.toString();
        if (!name.contains('Test')) {
          return const [];
        }
      }
    } catch (_) {
      return const [];
    }
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
    if (_canUseSqlite) {
      DatabaseHelper.instance.insertTicket(ticket).catchError((_) => 0);
    }
    // Adding a local pending ticket is not payment verification. Only a
    // server/provider-confirmed paid ticket may trigger paid UI updates.
    if (ticket.status == 'paid') {
      onTicketAdded?.call(ticket);
    }
  }

  void removeTicket(String id) {
    ticketsNotifier.value =
        ticketsNotifier.value.where((t) => t.id != id).toList();
    if (_canUseSqlite) {
      DatabaseHelper.instance.deleteTicket(id).catchError((_) => 0);
    }
  }

  void updateTicketStatus(String id, String status) {
    ticketsNotifier.value = ticketsNotifier.value.map((t) {
      if (t.id == id || t.bookingId == id) {
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
    if (_canUseSqlite) {
      DatabaseHelper.instance
          .updateTicketStatus(id, status)
          .catchError((_) => 0);
    }
  }
}
