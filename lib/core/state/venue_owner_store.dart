import 'package:flutter/foundation.dart';
import '../../domain/entities/court_slot_item.dart';
import '../services/chatbot_service.dart';

class VenueOwnerStore {
  VenueOwnerStore._internal() {
    reset();
  }

  static final VenueOwnerStore instance = VenueOwnerStore._internal();

  final ValueNotifier<bool> isOwnerModeNotifier = ValueNotifier<bool>(false);
  bool get isOwnerMode => isOwnerModeNotifier.value;

  String get activeVenueName => 'CLB Cầu Lông & Pickleball Tao Đàn';
  String get activeVenueId => 'venue_01';

  late final ValueNotifier<List<CourtSlotItem>> slotsNotifier =
      ValueNotifier<List<CourtSlotItem>>(_generateInitialSlots());

  List<CourtSlotItem> get slots => slotsNotifier.value;

  final Set<String> _checkedInTickets = <String>{};
  final Map<String, DateTime> _checkInTimestamps = <String, DateTime>{};

  void toggleOwnerMode(bool enabled) {
    isOwnerModeNotifier.value = enabled;
    ChatbotService.instance.resetMessages();
  }

  void recordAppBooking({
    required int courtNumber,
    required String startTime,
    required String endTime,
    required String ticketId,
    required String customerName,
    required String customerPhone,
    required double price,
  }) {
    final list = List<CourtSlotItem>.from(slotsNotifier.value);
    final targetRange = '$startTime - $endTime';
    final padCourt = courtNumber.toString().padLeft(2, '0');
    final index = list.indexWhere(
      (s) =>
          (s.courtName.contains('$courtNumber') || s.courtName.contains(padCourt)) &&
          (s.timeRange == targetRange || s.timeRange.startsWith(startTime)),
    );
    if (index != -1) {
      list[index] = list[index].copyWith(
        status: CourtSlotStatus.bookedApp,
        ticketId: ticketId,
        customerName: customerName,
        customerPhone: customerPhone,
        price: price,
      );
      slotsNotifier.value = list;
    } else {
      final courtNameStr = courtNumber <= 4
          ? 'Sân Cầu Lông $padCourt'
          : 'Sân Pickleball $padCourt';
      final sport = courtNumber <= 4 ? 'badminton' : 'pickleball';
      final newSlot = CourtSlotItem(
        slotId: 'court_${padCourt}_$ticketId',
        courtName: courtNameStr,
        sportType: sport,
        timeRange: targetRange,
        status: CourtSlotStatus.bookedApp,
        customerName: customerName,
        customerPhone: customerPhone,
        ticketId: ticketId,
        price: price,
      );
      list.insert(0, newSlot);
      slotsNotifier.value = list;
    }
  }

  void reserveSlot(
    String slotId, {
    required String customerName,
    required String customerPhone,
  }) {
    final list = List<CourtSlotItem>.from(slotsNotifier.value);
    final index = list.indexWhere((s) => s.slotId == slotId);
    if (index != -1) {
      list[index] = list[index].copyWith(
        status: CourtSlotStatus.reservedManual,
        customerName: customerName,
        customerPhone: customerPhone,
      );
      slotsNotifier.value = list;
    }
  }

  void lockMaintenance(String slotId) {
    final list = List<CourtSlotItem>.from(slotsNotifier.value);
    final index = list.indexWhere((s) => s.slotId == slotId);
    if (index != -1) {
      list[index] = list[index].copyWith(
        status: CourtSlotStatus.maintenance,
      );
      slotsNotifier.value = list;
    }
  }

  void unlockSlot(String slotId) {
    final list = List<CourtSlotItem>.from(slotsNotifier.value);
    final index = list.indexWhere((s) => s.slotId == slotId);
    if (index != -1) {
      list[index] = list[index].copyWith(
        status: CourtSlotStatus.available,
        clearCustomer: true,
      );
      slotsNotifier.value = list;
    }
  }

  void updateSlotPrice(String slotId, double newPrice) {
    final list = List<CourtSlotItem>.from(slotsNotifier.value);
    final index = list.indexWhere((s) => s.slotId == slotId);
    if (index != -1) {
      list[index] = list[index].copyWith(price: newPrice);
      slotsNotifier.value = List.unmodifiable(list);
    }
  }

  static double calculateDefaultSlotPrice({
    required String sportType,
    required int startHour,
  }) {
    final isBadminton = sportType == 'badminton';
    if (startHour >= 6 && startHour < 8) {
      return isBadminton ? 120000.0 : 160000.0;
    } else if (startHour >= 8 && startHour < 16) {
      return isBadminton ? 80000.0 : 130000.0;
    } else if (startHour >= 16 && startHour < 17) {
      return isBadminton ? 130000.0 : 170000.0;
    } else if (startHour >= 17 && startHour < 21) {
      return isBadminton ? 180000.0 : 240000.0;
    } else {
      return isBadminton ? 120000.0 : 150000.0;
    }
  }

  bool checkInTicket(String ticketId) {
    final hasTicket = slotsNotifier.value.any((s) => s.ticketId == ticketId);
    if (!hasTicket) return false;
    _checkedInTickets.add(ticketId);
    _checkInTimestamps[ticketId] = DateTime.now();
    slotsNotifier.value = List<CourtSlotItem>.from(slotsNotifier.value);
    return true;
  }

  bool checkIn(String ticketId) => checkInTicket(ticketId);

  bool isCheckedIn(String ticketId) => _checkedInTickets.contains(ticketId);

  DateTime? getCheckInTime(String ticketId) => _checkInTimestamps[ticketId];

  void reset() {
    isOwnerModeNotifier.value = false;
    _checkedInTickets.clear();
    _checkInTimestamps.clear();
    slotsNotifier.value = _generateTaoDanSchedule();
  }

  static List<CourtSlotItem> _generateInitialSlots() => _generateTaoDanSchedule();

  static List<CourtSlotItem> _generateTaoDanSchedule() {
    final List<CourtSlotItem> result = [];

    // Tao Đàn: Courts 1-4 Badminton, Courts 5-8 Pickleball
    final courts = [
      {'id': '01', 'name': 'Sân Cầu Lông 01', 'sport': 'badminton'},
      {'id': '02', 'name': 'Sân Cầu Lông 02', 'sport': 'badminton'},
      {'id': '03', 'name': 'Sân Cầu Lông 03', 'sport': 'badminton'},
      {'id': '04', 'name': 'Sân Cầu Lông 04', 'sport': 'badminton'},
      {'id': '05', 'name': 'Sân Pickleball 05', 'sport': 'pickleball'},
      {'id': '06', 'name': 'Sân Pickleball 06', 'sport': 'pickleball'},
      {'id': '07', 'name': 'Sân Pickleball 07', 'sport': 'pickleball'},
      {'id': '08', 'name': 'Sân Pickleball 08', 'sport': 'pickleball'},
    ];

    // Slots from 06:00 to 22:00
    for (int hour = 6; hour < 22; hour++) {
      final startStr = '${hour.toString().padLeft(2, '0')}:00';
      final endStr = '${(hour + 1).toString().padLeft(2, '0')}:00';
      final timeRange = '$startStr - $endStr';
      final hourSuffix = hour.toString().padLeft(2, '0');

      for (final court in courts) {
        final courtId = court['id'] as String;
        final courtName = court['name'] as String;
        final sport = court['sport'] as String;
        final price = calculateDefaultSlotPrice(sportType: sport, startHour: hour);
        final slotId = 'court_${courtId}_${hourSuffix}_00';

        CourtSlotStatus status = CourtSlotStatus.available;
        String? customerName;
        String? customerPhone;
        String? ticketId;

        // Specific pre-seeded slots
        if (slotId == 'court_01_18_00') {
          status = CourtSlotStatus.bookedApp;
          customerName = 'Nguyễn Văn An';
          customerPhone = '0909 123 456';
          ticketId = 'SH-8291';
        } else if (slotId == 'court_01_19_00') {
          status = CourtSlotStatus.bookedApp;
          customerName = 'Trần Thuỳ Linh';
          customerPhone = '0977 666 555';
          ticketId = 'SH-8292';
        } else if (slotId == 'court_02_17_00') {
          status = CourtSlotStatus.reservedManual;
          customerName = 'Chú Ba (Khách quen Tao Đàn)';
          customerPhone = '0913 222 333';
        } else if (slotId == 'court_03_07_00') {
          status = CourtSlotStatus.reservedManual;
          customerName = 'Anh Long (Hội sáng)';
          customerPhone = '0903 555 777';
        } else if (slotId == 'court_04_12_00') {
          status = CourtSlotStatus.maintenance;
        } else if (slotId == 'court_05_18_00') {
          status = CourtSlotStatus.bookedApp;
          customerName = 'Lê Minh';
          customerPhone = '0918 888 999';
          ticketId = 'SH-7714';
        } else if (slotId == 'court_06_19_00') {
          status = CourtSlotStatus.reservedManual;
          customerName = 'Chị Mai (Pickleball Pro)';
          customerPhone = '0982 444 666';
        } else if (slotId == 'court_07_14_00') {
          status = CourtSlotStatus.maintenance;
        }

        result.add(
          CourtSlotItem(
            slotId: slotId,
            courtName: courtName,
            sportType: sport,
            timeRange: timeRange,
            status: status,
            customerName: customerName,
            customerPhone: customerPhone,
            ticketId: ticketId,
            price: price,
          ),
        );
      }
    }

    return result;
  }
}
